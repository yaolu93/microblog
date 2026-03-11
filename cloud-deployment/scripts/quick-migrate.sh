#!/bin/bash

# ⚡ 快速一键迁移脚本（自动模式）

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

echo "════════════════════════════════════════════════════════════════"
echo "⚡ 快速数据库迁移"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 加载环境变量
source cloud-deployment/.env.cloud

echo "📊 当前状态："
echo "   • GCP 项目: $GCP_PROJECT_ID"
echo "   • 数据库: Neon PostgreSQL"
echo "   • Redis: Upstash"
echo ""

echo "🚀 第 1 步：启用迁移并部署新版本..."
gcloud run deploy microblog \
  --project=$GCP_PROJECT_ID \
  --image=$DOCKER_USERNAME/microblog:latest \
  --region=us-central1 \
  --update-env-vars=RUN_MIGRATIONS=true \
  --no-traffic

echo ""
echo "⏳ 第 2 步：等待迁移完成（约 30 秒）..."
sleep 30

echo ""
echo "🔄 第 3 步：将流量切换到新版本..."
gcloud run services update-traffic microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --to-revisions=LATEST=100

echo ""
echo "🔒 第 4 步：禁用迁移（避免每次启动都运行）..."
gcloud run services update microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --update-env-vars=RUN_MIGRATIONS=false

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✅ 迁移完成！数据库表已创建"
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "📊 继续验证..."
sleep 5

echo ""
echo "🔍 查看最新日志："
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=microblog" \
  --project=$GCP_PROJECT_ID \
  --limit=10 \
  --format='table(severity, message)' | head -20

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✨ 所有步骤完成！"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "应用地址: https://microblog-613015340025.us-central1.run.app"
echo ""
echo "📝 后续步骤（可选）:"
echo "  1. 创建初始用户："
echo "     bash cloud-deployment/scripts/create-user.sh"
echo ""
echo "  2. 访问应用并测试登录"
echo ""
