#!/bin/bash

# 🚀 Cloud Run 快速重新部署脚本（带日志检查）

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

echo "════════════════════════════════════════════════════════════════"
echo "🚀 Cloud Run 重新部署脚本"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 加载环境变量
if [ ! -f "cloud-deployment/.env.cloud" ]; then
    echo "❌ 找不到 cloud-deployment/.env.cloud"
    exit 1
fi

source cloud-deployment/.env.cloud

echo "📋 部署配置:"
echo "   • GCP 项目: $GCP_PROJECT_ID"
echo "   • Docker 用户名: $DOCKER_USERNAME"
echo "   • 服务名称: microblog"
echo "   • 区域: us-central1"
echo ""

# 第一步：构建 Docker 镜像
echo "════════════════════════════════════════════════════════════════"
echo "1️⃣ 构建 Docker 镜像..."
echo "════════════════════════════════════════════════════════════════"
echo ""

docker build -f cloud-deployment/Dockerfile -t "$DOCKER_USERNAME/microblog:latest" .

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker 镜像构建成功"
else
    echo "❌ Docker 镜像构建失败"
    exit 1
fi

echo ""

# 第二步：推送到 Docker Hub
echo "════════════════════════════════════════════════════════════════"
echo "2️⃣ 推送镜像到 Docker Hub..."
echo "════════════════════════════════════════════════════════════════"
echo ""

docker push "$DOCKER_USERNAME/microblog:latest"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 镜像推送成功"
else
    echo "❌ 镜像推送失败"
    exit 1
fi

echo ""

# 第三步：部署到 Cloud Run
echo "════════════════════════════════════════════════════════════════"
echo "3️⃣ 部署到 Cloud Run..."
echo "════════════════════════════════════════════════════════════════"
echo ""

gcloud run deploy microblog \
  --project=$GCP_PROJECT_ID \
  --image=$DOCKER_USERNAME/microblog:latest \
  --region=us-central1 \
  --allow-unauthenticated \
  --set-env-vars="\
DATABASE_URL=$DATABASE_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production,\
LOG_TO_STDOUT=true,\
RUN_MIGRATIONS=false" \
  --memory=512Mi \
  --cpu=1 \
  --timeout=3600 \
  --max-instances=10 \
  --platform=managed

# 获取服务 URL
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "4️⃣ 获取服务信息..."
echo "════════════════════════════════════════════════════════════════"
echo ""

SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

echo "✅ 服务已部署！"
echo "   URL: $SERVICE_URL"
echo ""

# 第四步：等待并检查日志
echo "════════════════════════════════════════════════════════════════"
echo "5️⃣ 等待应用启动并检查日志..."
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "⏳ 等待 10 秒让应用启动..."
sleep 10

echo ""
echo "📜 最近的日志 (最新 30 条):"
echo "────────────────────────────────────────────────────────────────"
gcloud run logs read microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --limit=30 \
  --format='value(severity, message)'

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "6️⃣ 测试应用..."
echo "════════════════════════════════════════════════════════════════"
echo ""

echo "🔍 测试健康检查端点..."
HEALTH_CHECK=$(curl -s -w "%{http_code}" -o /tmp/health_response.txt "$SERVICE_URL/health")

if [ "$HEALTH_CHECK" = "200" ]; then
    echo "✅ 健康检查成功 (HTTP 200)"
    echo "   响应: $(cat /tmp/health_response.txt)"
else
    echo "❌ 健康检查失败 (HTTP $HEALTH_CHECK)"
    echo "   响应: $(cat /tmp/health_response.txt)"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✨ 部署完成！"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "应用 URL: $SERVICE_URL"
echo ""
echo "📝 后续步骤:"
echo "  1. 访问 $SERVICE_URL 测试网站"
echo "  2. 查看更多日志: gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit=100"
echo "  3. 如果有错误，检查 App 配置: gcloud run services describe microblog --project=$GCP_PROJECT_ID"
echo ""
