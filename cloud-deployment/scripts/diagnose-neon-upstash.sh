#!/bin/bash

# 🔍 Neon 和 Upstash 网络诊断脚本

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

# 加载环境变量
if [ ! -f "cloud-deployment/.env.cloud" ]; then
    echo "❌ 找不到 .env.cloud 文件"
    exit 1
fi

source cloud-deployment/.env.cloud

echo "════════════════════════════════════════════════════════════════"
echo "🔍 Neon PostgreSQL 和 Upstash Redis 网络诊断"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 1️⃣ 诊断 Neon PostgreSQL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "1️⃣ 诊断 Neon PostgreSQL"
echo "────────────────────────────────────────────────────────────────"

if [ -z "$DATABASE_URL" ]; then
    echo "❌ DATABASE_URL 未设置"
else
    echo "✅ DATABASE_URL 已设置"
    
    # 提取主机名和端口
    NEON_HOST=$(echo "$DATABASE_URL" | grep -oP '(?<=@)[^/:?]*' | head -1)
    NEON_PORT=$(echo "$DATABASE_URL" | grep -oP '(?<::)\d+' || echo "5432")
    
    echo "   • 主机: $NEON_HOST"
    echo "   • 端口: $NEON_PORT"
    echo ""
    
    # 测试 DNS 解析
    echo "   🔍 测试 DNS 解析..."
    if nslookup "$NEON_HOST" > /dev/null 2>&1; then
        echo "   ✅ DNS 可以解析"
        NEON_IP=$(nslookup "$NEON_HOST" 2>/dev/null | grep "Address" | tail -1 | awk '{print $NF}')
        echo "      IP 地址: $NEON_IP"
    else
        echo "   ❌ DNS 解析失败 - 检查网络连接"
    fi
    echo ""
    
    # 测试端口连接
    echo "   🔍 测试端口 $NEON_PORT 连接..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$NEON_HOST/$NEON_PORT" 2>/dev/null; then
        echo "   ✅ 端口 $NEON_PORT 可访问"
    else
        echo "   ⚠️  端口 $NEON_PORT 无法访问"
        echo "      • 这通常意味着 Neon 的 IP Whitelist 阻止了连接"
        echo "      • 或者防火墙/网络问题"
        echo ""
        echo "      💡 解决方案:"
        echo "      1. 访问 https://console.neon.tech"
        echo "      2. 进入你的项目"
        echo "      3. Project Settings → Network (或 Database)"
        echo "      4. 禁用 IP Whitelist 或添加 0.0.0.0/0"
        echo "      5. 保存并重试"
    fi
    echo ""
    
    # 尝试 psycopg2 连接
    echo "   🔍 尝试实际数据库连接..."
    python3 << 'PYEOF'
import os
import sys

try:
    import psycopg2
    db_url = os.getenv('DATABASE_URL')
    
    if not db_url:
        print("   ❌ DATABASE_URL 环境变量未设置")
        sys.exit(1)
    
    print(f"   📍 尝试连接到 Neon...")
    # 不要显示完整的 URL（包含密码）
    safe_url = db_url.split('@')[1].split('?')[0] if '@' in db_url else "unknown"
    print(f"      主机: {safe_url}")
    
    conn = psycopg2.connect(db_url, connect_timeout=5)
    print("   ✅ Neon PostgreSQL 连接成功！")
    
    # 尝试查询
    cur = conn.cursor()
    cur.execute("SELECT 1")
    result = cur.fetchone()
    print(f"   ✅ 数据库响应: SELECT 1 → {result}")
    
    conn.close()
    
except ImportError:
    print("   ⚠️  psycopg2 未安装 - 跳过数据库连接测试")
    print("      运行以安装: pip install psycopg2-binary")
except psycopg2.OperationalError as e:
    print(f"   ❌ 数据库连接失败:")
    error_msg = str(e)
    if "timeout" in error_msg.lower():
        print("      • 原因: 连接超时（IP白名单或防火墙可能在阻止）")
    elif "auth" in error_msg.lower():
        print("      • 原因: 身份验证失败（检查密码）")
    elif "could not resolve" in error_msg.lower():
        print("      • 原因: DNS 解析失败")
    else:
        print(f"      • 原因: {error_msg}")
    print("")
    print("      💡 快速修复:")
    print("      1. 访问 https://console.neon.tech")
    print("      2. Project Settings → Network")
    print("      3. 禁用 IP Whitelist")
except Exception as e:
    print(f"   ❌ 连接错误: {e}")
PYEOF
fi

echo ""
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 2️⃣ 诊断 Upstash Redis
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "2️⃣ 诊断 Upstash Redis"
echo "────────────────────────────────────────────────────────────────"

if [ -z "$REDIS_URL" ]; then
    echo "❌ REDIS_URL 未设置"
else
    echo "✅ REDIS_URL 已设置"
    
    # 提取主机名
    REDIS_HOST=$(echo "$REDIS_URL" | grep -oP '(?<=@)[^/:]*' | head -1)
    REDIS_PORT=$(echo "$REDIS_URL" | grep -oP '(?<::)\d+' || echo "6379")
    
    echo "   • 主机: $REDIS_HOST"
    echo "   • 端口: $REDIS_PORT"
    echo "   • 协议: rediss:// (TLS 加密)"
    echo ""
    
    # 测试 DNS 解析
    echo "   🔍 测试 DNS 解析..."
    if nslookup "$REDIS_HOST" > /dev/null 2>&1; then
        echo "   ✅ DNS 可以解析"
        REDIS_IP=$(nslookup "$REDIS_HOST" 2>/dev/null | grep "Address" | tail -1 | awk '{print $NF}')
        echo "      IP 地址: $REDIS_IP"
    else
        echo "   ❌ DNS 解析失败"
    fi
    echo ""
    
    # 测试端口连接
    echo "   🔍 测试端口 $REDIS_PORT 连接..."
    if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$REDIS_HOST/$REDIS_PORT" 2>/dev/null; then
        echo "   ✅ 端口 $REDIS_PORT 可访问"
    else
        echo "   ⚠️  端口 $REDIS_PORT 无法访问"
        echo "      • 这可能意味着网络连接被阻止"
        echo ""
        echo "      💡 解决方案:"
        echo "      1. 访问 https://console.upstash.com"
        echo "      2. 找到你的 Redis 实例"
        echo "      3. 点击实例进入详情"
        echo "      4. 寻找 \"Settings\", \"Network\", 或 \"Security\" 选项"
        echo "      5. 禁用任何 IP 限制或添加 0.0.0.0/0"
        echo "      6. 保存并重试"
    fi
    echo ""
    
    # 尝试 Redis Connection
    echo "   🔍 尝试实际 Redis 连接..."
    python3 << 'PYEOF'
import os
import sys

try:
    import redis
    redis_url = os.getenv('REDIS_URL')
    
    if not redis_url:
        print("   ❌ REDIS_URL 环境变量未设置")
        sys.exit(1)
    
    print(f"   📍 尝试连接到 Upstash Redis...")
    
    # 创建连接（带有 TLS）
    r = redis.from_url(redis_url, socket_connect_timeout=5, socket_timeout=5)
    
    # 测试 PING
    ping_result = r.ping()
    if ping_result:
        print("   ✅ Upstash Redis 连接成功！")
        print(f"   ✅ PING 响应: {ping_result}")
    
except ImportError:
    print("   ⚠️  redis-py 未安装 - 跳过 Redis 连接测试")
    print("      运行以安装: pip install redis")
except redis.ConnectionError as e:
    error_msg = str(e)
    print(f"   ❌ Redis 连接失败:")
    if "timeout" in error_msg.lower():
        print("      • 原因: 连接超时（IP白名单或网络可能在阻止）")
    elif "name or service not known" in error_msg.lower():
        print("      • 原因: DNS 解析失败")
    else:
        print(f"      • 原因: {error_msg}")
    print("")
    print("      💡 快速修复:")
    print("      1. 访问 https://console.upstash.com")
    print("      2. 找到你的 Redis 实例")
    print("      3. 寻找 \"Allowed Sources\" 或 \"Network\" 设置")
    print("      4. 禁用任何 IP 限制")
except Exception as e:
    print(f"   ❌ Redis 错误: {e}")
PYEOF
fi

echo ""
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 3️⃣ 总结
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "════════════════════════════════════════════════════════════════"
echo "📋 诊断总结"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "如果你看到:"
echo ""
echo "✅ Neon: 连接成功"
echo "✅ Redis: 连接成功"
echo ""
echo "   → 问题不在网络配置上"
echo "   → 可能是 Cloud Run 配置或应用代码问题"
echo "   → 运行: bash cloud-deployment/scripts/deploy-to-cloud-run-safe.sh"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "如果你看到:"
echo ""
echo "⚠️  Neon: 无法访问或连接超时"
echo ""
echo "   → 需要修改 Neon 网络设置"
echo "   → 参考: cat cloud-deployment/NEON_NETWORK_CONFIG.md"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "如果你看到:"
echo ""
echo "⚠️  Redis: 无法访问或连接超时"
echo ""
echo "   → 需要修改 Upstash 网络设置"
echo "   → 参考: cat cloud-deployment/UPSTASH_NETWORK_CONFIG.md"
echo ""
echo "════════════════════════════════════════════════════════════════"
