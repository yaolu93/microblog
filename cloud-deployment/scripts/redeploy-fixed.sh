#!/bin/bash

# 🚀 快速重新部署脚本（修复了 Gunicorn 问题）

set -e

PROJECTDIR="/home/yao/fromGithub/microblog"
cd "$PROJECTDIR"

echo "════════════════════════════════════════════════════════════════"
echo "🔧 修复 Gunicorn 问题并重新部署"
echo "════════════════════════════════════════════════════════════════"
echo ""

# 加载环境变量
source cloud-deployment/.env.cloud

echo "✅ 环境变量已加载"
echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 步骤 1: 构建新的 Docker 镜像（带修复）
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "1️⃣ 删除旧镜像..."
docker rmi "$DOCKER_USERNAME/microblog:latest" 2>/dev/null || true
echo "✅ 完成"
echo ""

echo "2️⃣ 构建新的 Docker 镜像（修复了虚拟环境配置）..."
echo "⏳ 这可能需要 2-3 分钟..."
echo ""

docker build \
  --no-cache \
  -f cloud-deployment/Dockerfile \
  -t "$DOCKER_USERNAME/microblog:latest" \
  . 2>&1 | tail -20

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Docker 镜像构建成功"
    echo ""
    docker images | grep microblog
else
    echo "❌ Docker 镜像构建失败"
    exit 1
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 步骤 2: 推送到 Docker Hub
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "3️⃣ 推送镜像到 Docker Hub..."
docker push "$DOCKER_USERNAME/microblog:latest"

if [ $? -eq 0 ]; then
    echo "✅ 镜像推送成功"
else
    echo "❌ 镜像推送失败"
    exit 1
fi

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 步骤 3: 部署到 Cloud Run
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "4️⃣ 部署到 Cloud Run..."
echo "⏳ 这可能需要 1-2 分钟..."
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

echo ""

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# 步骤 4: 验证部署
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo "5️⃣ 等待应用启动..."
sleep 15

echo ""
echo "6️⃣ 获取应用 URL..."
SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

echo "✅ 应用 URL: $SERVICE_URL"
echo ""

echo "7️⃣ 测试应用..."
echo "⏳ 测试健康检查端点..."

HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$SERVICE_URL/health" 2>&1)
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -1)
BODY=$(echo "$HEALTH_RESPONSE" | head -1)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 健康检查成功 (HTTP 200)"
    echo "   响应: $BODY"
elif [ "$HTTP_CODE" = "000" ]; then
    echo "⏳ 应用可能仍在启动，查看完整日志..."
else
    echo "⚠️ 健康检查 HTTP $HTTP_CODE"
    echo "   响应: $BODY"
fi

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "✨ 部署完成！"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📍 应用地址: $SERVICE_URL"
echo ""
echo "📝 后续步骤:"
echo ""
echo "1️⃣ 验证应用是否运行正常:"
echo "   curl $SERVICE_URL/health"
echo ""
echo "2️⃣ 查看实时日志:"
echo "   gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit=50"
echo ""
echo "3️⃣ 访问应用:"
echo "   打开浏览器: $SERVICE_URL"
echo ""
echo "4️⃣ 如果应用仍然启动失败，运行:"
echo "   gcloud run logs read microblog --project=$GCP_PROJECT_ID --format='value(severity, message)' --limit=100"
echo ""
