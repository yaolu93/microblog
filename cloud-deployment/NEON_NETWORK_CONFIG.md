# 🛠️ Neon PostgreSQL 网络配置指南

## Neon 中禁用 IP Whitelist 的正确步骤

### ✅ 推荐方法（适用于最新的 Neon UI）

```
1. 打开 https://console.neon.tech
2. 登录你的账户
3. 在屏幕左侧，找到你的项目（例如 "microblog-project"）
4. 点击进入项目
5. 在项目顶部，找到菜单或标签栏
6. 点击 "Project Settings" 或 "Settings" 图标（⚙️）
```

### 在 Settings 中找网络设置

```
Settings 页面应该显示这些选项：
├─ General
├─ Database
├─ Network  ← 👈 这个！
├─ Security
├─ API Keys
└─ Billing
```

**点击 "Network"** 你应该看到：

```
🔒 Network Security

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IP Whitelist:
  ☑️ Enable IP Whitelist  ← 如果打开，点击禁用
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

或者：

Allowed IPs:
  0.0.0.0/0  (或 ::/0)  ← 已允许所有IP
```

---

## 如果找不到 "Network" 页面

### 备选位置 1️⃣: 通过"Database"设置

```
1. Settings → Database
2. 在此寻找：
   - "Connection Security"
   - "IP Whitelist"
   - "Network Access"
3. 如果看到 "Enable IP Whitelist"，禁用它
4. 或手动添加：0.0.0.0/0
```

### 备选位置 2️⃣: 在分支/连接级别

```
1. 进入你的项目
2. 找到 "Branches" 或 "SQL Editor"
3. 选择你的数据库分支（默认是 "main"）
4. 查看分支的网络设置
```

### 备选位置 3️⃣: 通过"Account Settings"（全局设置）

```
1. 右上角点击你的用户头像或 "Settings"
2. 找到 "Account Settings" 或 "Organization Settings"
3. 寻找 IP Whitelist 或 Network 选项
```

---

## Neon IP Whitelist 的完整说明

如果你找到了 IP Whitelist 设置，这是你会看到的：

```
════════════════════════════════════════════════════════════════
Enable IP Whitelist
════════════════════════════════════════════════════════════════

目前状态: ☑️ 启用

Allowed IPs:
✕ 192.168.1.100
✕ 10.0.0.0/8
✕ 203.0.113.50

要允许云服务器连接，你需要：

选项 A（简单但不安全 - 用于测试）:
  □ 禁用整个 IP Whitelist
  
选项 B（推荐 - 允许所有IP）:
  ☑ Enable IP Whitelist
  添加一个条目: 0.0.0.0/0

选项 C（最安全 - 允许特定IP）:
  ☑ Enable IP Whitelist
  添加 Google Cloud Run IP 范围：
    - 199.36.153.4/30  (Cloud Run NAT IP)
    - 或 0.0.0.0/0      (如果上面不工作)
```

---

## 最简单的修复（推荐）

### 步骤 1: 禁用 IP Whitelist（临时解决方案）

```
1. https://console.neon.tech
2. Project Settings → Network (或 Database)
3. 找到 "IP Whitelist" 设置
4. ☑️ 点击勾选框以**禁用**它
5. 保存
```

### 步骤 2: 测试连接

```bash
cd /home/yao/fromGithub/microblog

# 重新加载环境变量
source cloud-deployment/.env.cloud

# 快速测试连接
python3 << 'PYEOF'
import psycopg2
import os

db_url = os.getenv('DATABASE_URL')
try:
    conn = psycopg2.connect(db_url)
    print("✅ Neon 数据库连接成功！")
    conn.close()
except Exception as e:
    print(f"❌ 连接失败: {e}")
PYEOF
```

---

## 验证：你的 DATABASE_URL 应该包含这些信息

从 Neon 复制的连接字符串应该看起来像：

```
postgresql://neondb_owner:[密码]@[hostname].neon.tech/neondb?sslmode=require
```

检查清单：
- ✅ `postgresql://` 前缀
- ✅ `[username]:[password]@` 
- ✅ `.neon.tech` 结尾（或你的 Pool 主机名）
- ✅ `?sslmode=require` 或 `?sslmode=require&channel_binding=require`

---

## 常见问题排查

### ❌ "Unable to reach the Neon endpoint"

**原因**: IP Whitelist 正在阻止你的请求

**解决方案**:
```
1. Neon Console
2. Project Settings → Network
3. 禁用 IP Whitelist 或添加 0.0.0.0/0
4. 等待 2-5 秒
5. 重试连接
```

### ❌ "connection refused"

**原因**: 连接字符串可能有错误

**解决方案**:
```
1. 返回 Neon 控制台
2. 复制最新的连接字符串
3. 在本地测试连接
4. 确保使用 "Pooled Connection" 字符串（用于 Cloud Run）
```

### ❌ "password authentication failed"

**原因**: 密码过期或不正确

**解决方案**:
```
1. Neon Console
2. Database Settings
3. 重置你的数据库用户密码
4. 复制新的连接字符串
5. 更新 .env.cloud
```

---

## 最关键的部分：验证设置

运行这个命令来验证你的 Neon 设置：

```bash
# 在项目根目录
source cloud-deployment/.env.cloud

# 显示当前设置
echo "DATABASE_URL: ${DATABASE_URL:0:80}..."
echo ""

# 如果安装了 psycopg2
python3 << 'PYEOF'
import os
try:
    import psycopg2
    db_url = os.getenv('DATABASE_URL')
    if db_url:
        print(f"尝试连接到: {db_url.split('@')[1].split('?')[0]}")
        conn = psycopg2.connect(db_url, connect_timeout=5)
        print("✅ 成功！Neon 网络设置正确")
        conn.close()
    else:
        print("❌ DATABASE_URL 未设置")
except ImportError:
    print("⚠️  psycopg2 未安装，跳过连接测试")
except Exception as e:
    print(f"❌ 连接失败: {e}")
    print("💡 提示: 检查 Neon Console 中的 IP Whitelist 设置")
PYEOF
```

---

## 如果问题仍然存在

在 https://console.neon.tech 中：

1. **检查数据库状态**
   - Settings → Database
   - 确保数据库状态是 "Ready" 不是 "Suspended"

2. **查看最近的日志**
   - 可能有错误日志显示连接被拒绝的原因

3. **重新生成连接字符串**
   - Database → Users & Roles
   - 重置密码
   - 复制新的连接字符串

4. **检查你的计划** 
   - 某些免费计划可能有连接限制

---

## 完整的网络故障排查流程

```bash
#!/bin/bash

echo "🔍 Neon 网络故障排查"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# 1. 检查 URL 格式
echo "1️⃣ 验证 DATABASE_URL 格式..."
source cloud-deployment/.env.cloud

if [[ $DATABASE_URL == postgresql://* ]]; then
  echo "   ✅ URL 格式正确"
  HOSTNAME=$(echo $DATABASE_URL | grep -oP '(?<=@)[^/]*' | cut -d: -f1)
  echo "   主机: $HOSTNAME"
else
  echo "   ❌ URL 格式错误"
  exit 1
fi

# 2. 测试 DNS 解析
echo ""
echo "2️⃣ 测试 DNS 解析..."
if nslookup $HOSTNAME > /dev/null 2>&1; then
  echo "   ✅ DNS 可以解析"
else
  echo "   ❌ DNS 解析失败"
fi

# 3. 测试端口连接
echo ""
echo "3️⃣ 测试 Port 5432 连接..."
PORT=5432
timeout 5 bash -c "cat < /dev/null > /dev/tcp/$HOSTNAME/$PORT" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "   ✅ 端口 5432 可访问"
else
  echo "   ⚠️  端口 5432 无法访问（可能被防火墙/IP白名单阻止）"
  echo "   💡 请检查 Neon 的 IP Whitelist 设置"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

保存为 `test-neon.sh` 并运行：
```bash
bash test-neon.sh
```

---

**下一步**: 告诉我你在 Neon Console 中看到的具体选项，或者告诉我运行诊断脚本的结果！
