#!/bin/bash

# ☁️ Google Cloud Run 部署脚本 - 故障排除版本
# 这个版本禁用了RUN_MIGRATIONS来避免数据库迁移超时

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLOUD_DEP_DIR="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ ! -f "$CLOUD_DEP_DIR/.env.cloud" ]; then
    echo "❌ 错误: $CLOUD_DEP_DIR/.env.cloud 未找到!"
    echo "请先运行: bash $CLOUD_DEP_DIR/setup-env.sh"
    exit 1
fi

source "$CLOUD_DEP_DIR/.env.cloud"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}☁️  Google Cloud Run 部署${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 验证必要的环境变量
if [ -z "$GCP_PROJECT_ID" ] || [ -z "$DOCKER_USERNAME" ] || [ -z "$DATABASE_URL" ] || [ -z "$REDIS_URL" ]; then
    echo -e "${RED}❌ 缺少必要的环境变量!${NC}"
    echo "请编辑 $CLOUD_DEP_DIR/.env.cloud 并填入所有必需的值"
    exit 1
fi

echo -e "${YELLOW}📋 部署配置：${NC}"
echo "   项目ID: $GCP_PROJECT_ID"
echo "   Docker镜像: $DOCKER_USERNAME/microblog:latest"
echo "   地区: us-central1"
echo ""

# 询问是否跳过数据库迁移（解决超时问题）
echo -e "${YELLOW}⚠️  故障排除选项：${NC}"
echo ""
read -p "是否禁用数据库迁移 (RUN_MIGRATIONS=false) 来解决启动超时? (y/N): " skip_migration
echo ""

if [ "$skip_migration" = "y" ] || [ "$skip_migration" = "Y" ]; then
    echo -e "${YELLOW}📝 说明：${NC}"
    echo "   - 将禁用 RUN_MIGRATIONS=false"
    echo "   - 应用仅用于测试连接"
    echo "   - 之后可以手动运行数据库迁移"
    echo ""
    RUN_MIGRATIONS="false"
else
    RUN_MIGRATIONS="true"
fi

echo -e "${BLUE}🚀 开始部署到 Cloud Run...${NC}"
echo ""

gcloud run deploy microblog \
  --project=$GCP_PROJECT_ID \
  --image=$DOCKER_USERNAME/microblog:latest \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --timeout 300 \
  --allow-unauthenticated \
  --set-env-vars="\
DATABASE_URL=$DATABASE_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production,\
LOG_TO_STDOUT=true,\
RUN_MIGRATIONS=$RUN_MIGRATIONS" \
  || {
    echo ""
    echo -e "${RED}❌ 部署失败${NC}"
    echo ""
    echo -e "${YELLOW}🔍 查看日志来诊断问题：${NC}"
    echo "   gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 50"
    echo ""
    exit 1
  }

echo ""
echo -e "${GREEN}✅ 部署成功!${NC}"
echo ""

# 获取服务URL
SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

echo -e "${GREEN}🎉 你的应用已上线！${NC}"
echo "URL: $SERVICE_URL"
echo ""

# 查看日志
echo -e "${YELLOW}📊 应用启动日志（最近10条）：${NC}"
echo ""
sleep 2
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 10 2>/dev/null || echo "等待日志就绪..."
echo ""

echo -e "${BLUE}🔗 后续步骤：${NC}"
echo "1. 测试应用: curl $SERVICE_URL"
echo "2. 健康检查: curl $SERVICE_URL/health"
echo "3. 查看更多日志: gcloud run logs read microblog --project=$GCP_PROJECT_ID"
echo ""

if [ "$RUN_MIGRATIONS" = "false" ]; then
    echo -e "${YELLOW}⚠️  提示：${NC}"
    echo "您已禁用了数据库迁移。应用已部署但数据库可能未初始化。"
    echo "一旦连接问题解决，请运行迁移："
    echo ""
    echo "   gcloud run execute ... (或通过其他方法运行数据库迁移)"
    echo ""
fi
