#!/bin/bash
# minikube-setup.sh
# 一键部署 Microblog 到 Minikube

set -e

echo "================================================"
echo " Microblog Minikube Deployment Script"
echo "================================================"

# 【1】檢查 minikube 狀態
echo -e "\n[1] 檢查 minikube 狀態..."
if ! minikube status &>/dev/null; then
    echo "❌ Minikube 未運行。請先執行："
    echo "   minikube start --driver=docker --cpus=4 --memory=4096"
    exit 1
fi
echo "✅ Minikube 運行中"

# 【2】啟用本地 Docker daemon
echo -e "\n[2] 配置 Docker 環境..."
eval $(minikube docker-env)
echo "✅ Docker 環境已配置"

# 【3】構建鏡像
echo -e "\n[3] 構建 Docker 鏡像..."
cd "$(dirname "$0")/.."
docker build -t microblog:latest .
echo "✅ 鏡像構建完成"

# 【4】部署 Kubernetes 資源
echo -e "\n[4] 部署 Kubernetes 資源..."

echo "   - 創建命名空間..."
kubectl apply -f k8s/1-namespace.yaml

echo "   - 創建 ConfigMap..."
kubectl apply -f k8s/2-configmap.yaml

echo "   - 創建 Secret..."
kubectl apply -f k8s/3-secret.yaml

echo "   - 部署 PostgreSQL..."
kubectl apply -f k8s/4-postgres.yaml

echo "   - 部署 Redis..."
kubectl apply -f k8s/5-redis.yaml

echo "   - 部署 Web 應用（minikube 優化）..."
kubectl apply -f k8s/6-web-minikube.yaml

echo "   - 部署 Worker（minikube 優化）..."
kubectl apply -f k8s/7-worker-minikube.yaml

echo "✅ 所有資源部署完成"

# 【5】等待部署就緒
echo -e "\n[5] 等待 Pod 就緒（最多 120 秒）..."
echo "   等待 PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n microblog --timeout=180s 2>/dev/null || {
    echo "⚠️  PostgreSQL 超時。檢查日誌："
    kubectl logs -n microblog -l app=postgres --tail=20
}

echo "   等待 Redis..."
kubectl wait --for=condition=ready pod -l app=redis -n microblog --timeout=120s 2>/dev/null || true

echo "   等待 Web..."
kubectl wait --for=condition=ready pod -l app=web -n microblog --timeout=180s 2>/dev/null || {
    echo "⚠️  Web Pod 超時。檢查日誌："
    kubectl logs -n microblog -l app=web --tail=30
}

echo "✅ 所有 Pod 就緒"

# 【6】顯示訪問方式
echo -e "\n[6] 部署完成！訪問應用的方式："
echo ""

SERVICE_IP=$(minikube ip)
NODEPORT=$(kubectl get svc -n microblog web -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "unknown")

echo "   方式 1: Port Forward（推薦）"
echo "   $ kubectl port-forward -n microblog svc/web 8000:8000"
echo "   訪問：http://localhost:8000"
echo ""

echo "   方式 2: NodePort（完整 URL）"
echo "   訪問：http://${SERVICE_IP}:${NODEPORT}"
echo ""

echo "   方式 3: 自動打開 Minikube 服務"
echo "   $ minikube service web -n microblog"
echo ""

# 【7】顯示有用的命令
echo "================================================"
echo " 常用命令"
echo "================================================"
echo ""
echo "查看 Pod 狀態："
echo "  kubectl get pods -n microblog"
echo ""
echo "查看服務："
echo "  kubectl get svc -n microblog"
echo ""
echo "查看 Web 日誌："
echo "  kubectl logs -f -n microblog -l app=web"
echo ""
echo "進入 Web Pod Shell："
echo "  kubectl exec -it -n microblog deployment/web -- /bin/bash"
echo ""
echo "重啟部署（編輯代碼後）："
echo "  docker build -t microblog:latest ."
echo "  kubectl rollout restart deployment/web -n microblog"
echo ""
echo "刪除所有資源："
echo "  kubectl delete namespace microblog"
echo ""
echo "================================================"
echo "✅ 部署完成！"
echo "================================================"
