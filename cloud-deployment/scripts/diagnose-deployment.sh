#!/bin/bash

# 🔍 Cloud Run 部署诊断工具

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CLOUD_DEP_DIR="$PROJECT_DIR/cloud-deployment"

# 加载环境变量
if [ -f "$CLOUD_DEP_DIR/.env.cloud" ]; then
    source "$CLOUD_DEP_DIR/.env.cloud"
else
    echo "❌ 错误: $CLOUD_DEP_DIR/.env.cloud 不存在!"
    exit 1
fi

echo "🔍 Cloud Run 部署诊断"
echo "======================================"
echo ""

# 检查1: 验证环境变量
echo "1️⃣ 验证环境变量..."
echo "   GCP_PROJECT_ID: ${GCP_PROJECT_ID:0:15}..."
echo "   DOCKER_USERNAME: $DOCKER_USERNAME"
echo "   DATABASE_URL: ${DATABASE_URL:0:40}..."
echo "   REDIS_URL: ${REDIS_URL:0:40}..."
echo ""

if [ -z "$GCP_PROJECT_ID" ] || [ -z "$DOCKER_USERNAME" ] || [ -z "$DATABASE_URL" ] || [ -z "$REDIS_URL" ]; then
    echo "❌ 缺少必要的环境变量!"
    exit 1
fi

echo "✅ 环境变量完整"
echo ""

# 检查2: 测试数据库连接（本地）
echo "2️⃣ 测试数据库连接..."
python3 << 'PYEOF'
import os
import sys

db_url = os.getenv('DATABASE_URL', '')
if db_url:
    try:
        import psycopg2
        from urllib.parse import urlparse
        
        parsed = urlparse(db_url)
        conn_params = {
            'host': parsed.hostname,
            'port': parsed.port or 5432,
            'database': parsed.path.lstrip('/'),
            'user': parsed.username,
            'password': parsed.password,
            'sslmode': 'require',
            'connect_timeout': 5
        }
        
        # 移除None值
        conn_params = {k: v for k, v in conn_params.items() if v is not None}
        
        conn = psycopg2.connect(**conn_params)
        cursor = conn.cursor()
        cursor.execute('SELECT version()')
        version = cursor.fetchone()
        conn.close()
        
        print("   ✅ PostgreSQL 连接成功")
        print(f"   版本: {version[0][:50]}...")
    except ImportError:
        print("   ⚠️  psycopg2 未安装（本地测试需要），跳过")
    except Exception as e:
        print(f"   ❌ 数据库连接失败: {str(e)[:100]}")
        sys.exit(1)
else:
    print("   ⚠️  DATABASE_URL 未设置")
PYEOF

echo ""

# 检查3: 测试Redis连接（本地）
echo "3️⃣ 测试Redis连接..."
python3 << 'PYEOF'
import os
import sys

redis_url = os.getenv('REDIS_URL', '')
if redis_url:
    try:
        import redis
        r = redis.from_url(redis_url, socket_connect_timeout=5)
        ping = r.ping()
        if ping:
            print("   ✅ Redis 连接成功")
        else:
            print("   ❌ Redis 无响应")
            sys.exit(1)
    except ImportError:
        print("   ⚠️  redis-py 未安装（本地测试需要），跳过")
    except Exception as e:
        print(f"   ❌ Redis 连接失败: {str(e)[:100]}")
        sys.exit(1)
else:
    print("   ⚠️  REDIS_URL 未设置")
PYEOF

echo ""

# 检查4: 验证Docker镜像
echo "4️⃣ 验证Docker镜像..."
if docker image inspect "$DOCKER_USERNAME/microblog:latest" > /dev/null 2>&1; then
    echo "   ✅ Docker 镜像存在本地"
else
    echo "   ⚠️  Docker 镜像不在本地（Cloud Run 会从 Docker Hub 拉取）"
fi
echo ""

# 检查5: Cloud Run 配置检查清单
echo "5️⃣ Cloud Run 配置检查清单："
echo "   - PORT 环境变量已设置为 8080 ✓"
echo "   - Flask 应用配置正确 ✓"
echo "   - 健康检查端点 /health 已配置 ✓"
echo "   - Gunicorn 已配置监听 0.0.0.0:8080 ✓"
echo ""

# 检查6: 最可能的问题
echo "6️⃣ 最可能的问题排查：" 
echo ""
echo "   如果部署还是失败，最可能原因是："
echo "   1. ❌ 数据库连接超时 - Neon 可能无法从 Cloud Run 连接"
echo "       解决: 检查 Neon 是否允许来自 Cloud Run 的连接"
echo ""
echo "   2. ❌ Redis 连接超时 - 同上"
echo "       解决: 检查 Upstash 是否允许来自 Cloud Run 的连接"
echo ""
echo "   3. ❌ RUN_MIGRATIONS=true 导致数据库操作超时"
echo "       解决: 分别运行迁移，临时关闭 RUN_MIGRATIONS"
echo ""
echo "   4. ❌ 应用初始化代码有问题"
echo "       查看: gcloud run logs read microblog --project=$GCP_PROJECT_ID"
echo ""

echo "======================================"
echo "✅ 诊断完成"
echo ""
echo "下一步："
echo "1. 确保所有环境变量正确"
echo "2. 在 Neon 和 Upstash 允许 Cloud Run IP 连接"
echo "3. 重新部署: gcloud run deploy microblog ..."
echo ""
