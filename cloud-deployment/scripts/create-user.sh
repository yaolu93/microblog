#!/bin/bash

# 👤 创建初始用户脚本

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

echo "════════════════════════════════════════════════════════════════"
echo "👤 创建初始用户"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 加载环境变量
if [ ! -f "cloud-deployment/.env.cloud" ]; then
    echo "❌ 找不到 cloud-deployment/.env.cloud"
    exit 1
fi

source cloud-deployment/.env.cloud

# 检查虚拟环境
if [ ! -d ".venv" ]; then
    echo "❌ 虚拟环境不存在，创建中..."
    python -m venv .venv
fi

source .venv/bin/activate

echo "请输入新用户信息:"
echo ""
read -p "用户名: " username
read -p "邮箱: " email
read -sp "密码: " password
echo ""

echo ""
echo "⏳ 正在创建用户..."

python << PYEOF
import os
import sys

# 设置数据库 URL
os.environ['DATABASE_URL'] = """$DATABASE_URL"""
os.environ['REDIS_URL'] = """$REDIS_URL"""

from app import app, db
from app.models import User

with app.app_context():
    # 检查用户是否已存在
    existing_user = db.session.scalar(db.select(User).where(User.username == "$username"))
    if existing_user:
        print(f"❌ 用户 '$username' 已存在")
        sys.exit(1)
    
    # 创建新用户
    user = User(username="$username", email="$email")
    user.set_password("$password")
    db.session.add(user)
    db.session.commit()
    
    print(f"✅ 用户 '$username' 创建成功!")
    print(f"   用户名: $username")
    print(f"   邮箱: $email")

PYEOF

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ 用户创建完成"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "现在可以登录应用:"
echo "  URL: https://microblog-613015340025.us-central1.run.app"
echo "  用户名: $username"
echo ""
