#!/bin/bash

# 🛠️ Cloud Run 启动失败 - 快速修复指南

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CLOUD_DEP_DIR="$(dirname "$SCRIPT_DIR")"

# 加载环境变量
if [ -f "$CLOUD_DEP_DIR/.env.cloud" ]; then
    source "$CLOUD_DEP_DIR/.env.cloud"
fi

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE} 🆘 Cloud Run 启动问题诊断与修复${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

echo -e "${YELLOW}容器无法启动的常见原因：${NC}"
echo ""

echo "1️⃣  ${RED}数据库或Redis连接超时${NC}"
echo "    症状: 'container failed to start and listen on the port'"
echo "    原因: Neon/Upstash 无法从 Cloud Run 连接"
echo ""
echo "    ✅ 修复方案:"
echo "       a) 在 Neon 中允许所有连接 (危险，仅用于测试)"
echo "       b) 在 Upstash 中配置 IP 白名单"
echo "       c) 使用 VPC 连接器 (生产环境推荐)"
echo ""

echo "2️⃣  ${RED}数据库迁移失败${NC}"
echo "    症状: 集器启动超时"
echo "    原因: RUN_MIGRATIONS=true 但迁移导致连接或其他问题"
echo ""
echo "    ✅ 修复方案:"
echo "       运行: bash $CLOUD_DEP_DIR/scripts/deploy-to-cloud-run-safe.sh"
echo "       选择禁用迁移，先验证连接"
echo ""

echo "3️⃣  ${RED}环境变量未设置或不正确${NC}"
echo "    症状: 应用无法找到数据库 URL"
echo "    原因: DATABASE_URL 或 REDIS_URL 为空或格式错误"
echo ""
echo "    ✅ 修复方案:"
echo "       检查: nano $CLOUD_DEP_DIR/.env.cloud"
echo "       重新部署"
echo ""

echo "4️⃣  ${RED}应用依赖问题${NC}"
echo "    症状: 导入错误、模块未找到"
echo "    原因: requirements.txt 缺少依赖"
echo ""
echo "    ✅ 修复方案:"
echo "       运行: bash $CLOUD_DEP_DIR/scripts/test-cloud-deployment.sh"
echo "       检查本地 Docker 构建是否成功"
echo ""

echo "═══════════════════════════════════════════"
echo ""

echo -e "${BLUE}🔍 快速诊断：${NC}"
echo ""

if [ -z "$GCP_PROJECT_ID" ]; then
    echo -e "${RED}❌ .env.cloud 未配置${NC}"
    echo "   请运行: bash $CLOUD_DEP_DIR/setup-env.sh"
    exit 1
fi

# 检查最近的日志
echo -e "${YELLOW}📊 最近的Cloud Run日志：${NC}"
echo ""

gcloud run logs read microblog \
  --project=$GCP_PROJECT_ID \
  --limit 20 \
  2>/dev/null || {
    echo -e "${YELLOW}⚠️  无法读取日志，请在以下URL查看：${NC}"
    echo "https://console.cloud.google.com/run/detail/us-central1/microblog/logs?project=$GCP_PROJECT_ID"
    echo ""
}

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}💡 建议的修复步骤：${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

echo "第1步: 禁用数据库迁移并重新部署"
echo "       bash $CLOUD_DEP_DIR/scripts/deploy-to-cloud-run-safe.sh"
echo ""

echo "第2步: 验证应用能否启动"
echo "       curl https://microblog-xxxxx.run.app/health"
echo ""

echo "第3步: 如果成功，再编辑部署命令启用迁移"
echo "       gcloud run deploy microblog ... RUN_MIGRATIONS=true"
echo ""

echo "第4步: 查看完整日志"
echo "       gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 50"
echo ""

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""
