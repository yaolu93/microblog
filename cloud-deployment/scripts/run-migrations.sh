#!/bin/bash

# 🗄️ 在 Cloud Run 上运行数据库迁移

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

echo "════════════════════════════════════════════════════════════════"
echo "🗄️ Cloud Run 数据库迁移脚本"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 加载环境变量
if [ ! -f "cloud-deployment/.env.cloud" ]; then
    echo "❌ 找不到 cloud-deployment/.env.cloud"
    exit 1
fi

source cloud-deployment/.env.cloud

echo "选择迁移方式:"
echo ""
echo "1️⃣  方法 A: 更新 Cloud Run 环境变量，自动运行迁移（推荐）"
echo "2️⃣  方法 B: 使用 Cloud Run Job 运行一次性迁移"
echo "3️⃣  方法 C: 本地运行迁移（需要本地数据库访问）"
echo ""
read -p "请选择 (1/2/3): " choice

case $choice in
    1)
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "📝 方法 A: 通过环境变量运行迁移"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "本方法会:"
        echo "  1. 更新 Cloud Run 环境变量 RUN_MIGRATIONS=true"
        echo "  2. 部署新版本（会自动运行迁移）"
        echo "  3. 部署完成后自动禁用迁移"
        echo ""
        read -p "继续？(y/n): " confirm
        if [ "$confirm" != "y" ]; then
            echo "已取消"
            exit 0
        fi
        
        echo ""
        echo "⏳ 部署新版本（启用迁移）..."
        gcloud run deploy microblog \
          --project=$GCP_PROJECT_ID \
          --image=$DOCKER_USERNAME/microblog:latest \
          --region=us-central1 \
          --set-env-vars="\
DATABASE_URL=$DATABASE_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production,\
LOG_TO_STDOUT=true,\
RUN_MIGRATIONS=true"
        
        echo ""
        echo "⏳ 等待 30 秒让迁移完成..."
        sleep 30
        
        echo ""
        echo "⏳ 部署新版本（禁用迁移）..."
        gcloud run deploy microblog \
          --project=$GCP_PROJECT_ID \
          --image=$DOCKER_USERNAME/microblog:latest \
          --region=us-central1 \
          --set-env-vars="\
DATABASE_URL=$DATABASE_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production,\
LOG_TO_STDOUT=true,\
RUN_MIGRATIONS=false"
        
        echo ""
        echo "✅ 迁移完成！"
        ;;
        
    2)
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "📝 方法 B: 使用 Cloud Run Job"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        echo "创建一个一次性的 Cloud Run Job 来运行迁移..."
        echo ""
        
        # 创建 Cloud Run Job
        gcloud run jobs create microblog-db-migrate-$(date +%s) \
          --project=$GCP_PROJECT_ID \
          --image=$DOCKER_USERNAME/microblog:latest \
          --region=us-central1 \
          --set-env-vars="\
DATABASE_URL=$DATABASE_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production" \
          --command="flask" \
          --args="db,upgrade" \
          --tasks=1 \
          --max-retries=1 \
          --task-timeout=1800s
        
        echo ""
        echo "✅ Cloud Run Job 已创建并启动"
        echo "   查看状态："
        echo "   gcloud run jobs list --project=$GCP_PROJECT_ID"
        ;;
        
    3)
        echo ""
        echo "════════════════════════════════════════════════════════════════"
        echo "📝 方法 C: 本地运行迁移"
        echo "════════════════════════════════════════════════════════════════"
        echo ""
        
        # 检查虚拟环境
        if [ ! -d ".venv" ]; then
            echo "❌ 虚拟环境不存在，创建中..."
            python -m venv .venv
        fi
        
        source .venv/bin/activate
        
        echo "⏳ 运行数据库迁移..."
        export DATABASE_URL="$DATABASE_URL"
        export REDIS_URL="$REDIS_URL"
        
        flask db upgrade
        
        echo ""
        echo "✅ 迁移完成！"
        ;;
        
    *)
        echo "❌ 无效的选择"
        exit 1
        ;;
esac

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "📋 迁移完成后的后续步骤:"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "1️⃣ 查看应用日志："
echo "   gcloud logging read 'resource.type=cloud_run_revision AND resource.labels.service_name=microblog' \\"
echo "     --project=$GCP_PROJECT_ID --limit=20"
echo ""
echo "2️⃣ 访问应用："
echo "   https://microblog-613015340025.us-central1.run.app"
echo ""
echo "3️⃣ 可选：创建初始用户"
echo "   bash cloud-deployment/scripts/create-user.sh"
echo ""
