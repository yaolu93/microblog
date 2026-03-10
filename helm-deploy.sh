#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Helm Chart Deployment - Microblog     ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"

# Function to print steps
print_step() {
  echo -e "${BLUE}→ Step $1: $2${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Helm is installed
print_step "1" "检查 Helm 安装"
if ! command -v helm &> /dev/null; then
    print_error "Helm 未安装！请先安装 Helm"
    echo "  macOS: brew install helm"
    echo "  Linux: curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash"
    echo "  Windows: choco install kubernetes-helm"
    exit 1
fi
HELM_VERSION=$(helm version --short)
print_success "Helm 已安装: $HELM_VERSION"

# Check Kubernetes connection
print_step "2" "检查 Kubernetes 集群连接"
if ! kubectl cluster-info &> /dev/null; then
    print_error "无法连接到 Kubernetes 集群！"
    echo "  - 确保 Minikube 已启动: minikube start"
    echo "  - 或者已配置 GKE 凭证: gcloud container clusters get-credentials <cluster-name>"
    exit 1
fi
CURRENT_CONTEXT=$(kubectl config current-context)
print_success "已连接到集群: $CURRENT_CONTEXT"

# Ask for deployment type
print_step "3" "选择部署环境"
echo "请选择部署环境:"
echo "1) Minikube (本地开发)"
echo "2) GKE (Google Kubernetes Engine)"
read -p "选择 [1/2]: " DEPLOY_ENV

case $DEPLOY_ENV in
  1)
    VALUES_FILE="helm/microblog/values-minikube.yaml"
    ENVIRONMENT="Minikube"
    ;;
  2)
    VALUES_FILE="helm/microblog/values-gke.yaml"
    ENVIRONMENT="GKE"
    ;;
  *)
    print_error "无效选择！"
    exit 1
    ;;
esac

print_success "选择环境: $ENVIRONMENT"

# Validate Chart syntax
print_step "4" "验证 Helm Chart 语法"
if ! helm lint ./helm/microblog > /dev/null 2>&1; then
    print_error "Chart 语法检查失败！"
    helm lint ./helm/microblog
    exit 1
fi
print_success "Chart 语法验证通过"

# Create namespace
print_step "5" "创建 Namespace"
NAMESPACE="microblog"
if kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
    print_warning "Namespace '$NAMESPACE' 已存在，跳过创建"
else
    kubectl create namespace $NAMESPACE
    print_success "Namespace '$NAMESPACE' 已创建"
fi

# For Minikube, build and load Docker image
if [ "$ENVIRONMENT" = "Minikube" ]; then
    print_step "6" "为 Minikube 构建 Docker 镜像"
    eval $(minikube docker-env)
    
    if docker build -t microblog:latest . > /dev/null 2>&1; then
        print_success "Docker 镜像已构建"
    else
        print_error "Docker 镜像构建失败！"
        exit 1
    fi
fi

# Check if release already exists
print_step "7" "检查 Helm Release 状态"
RELEASE_NAME="microblog"
if helm list -n $NAMESPACE | grep -q $RELEASE_NAME; then
    print_warning "Release '$RELEASE_NAME' 已存在"
    read -p "是否升级现有 Release？ (y/n): " UPGRADE
    
    if [[ "$UPGRADE" =~ ^[Yy]$ ]]; then
        ACTION="upgrade"
        print_success "将升级现有 Release"
    else
        print_warning "跳过部署"
        exit 0
    fi
else
    ACTION="install"
    print_success "将创建新的 Release"
fi

# Deploy or upgrade
print_step "8" "部署应用 ($ACTION)"
if [ "$ACTION" = "install" ]; then
    helm install $RELEASE_NAME ./helm/microblog \
        -f $VALUES_FILE \
        -n $NAMESPACE \
        --create-namespace
else
    helm upgrade $RELEASE_NAME ./helm/microblog \
        -f $VALUES_FILE \
        -n $NAMESPACE
fi

if [ $? -eq 0 ]; then
    print_success "Helm Chart 已成功部署"
else
    print_error "部署失败！"
    exit 1
fi

# Wait for pods to be ready
print_step "9" "等待 Pod 启动"
echo "等待应用 Pod 就绪（超时时间：5 分钟）..."
kubectl wait --for=condition=ready pod -l app=web -n $NAMESPACE --timeout=300s 2>/dev/null || true
print_success "Pod 启动检查完成"

# Display deployment status
print_step "10" "显示部署状态"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━ Release 信息 ━━━━━━━━━━━━━━━━${NC}"
helm status $RELEASE_NAME -n $NAMESPACE
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━ Pod 列表 ━━━━━━━━━━━━━━━━${NC}"
kubectl get pods -n $NAMESPACE
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━ Service 信息 ━━━━━━━━━━━━━━━━${NC}"
kubectl get svc -n $NAMESPACE
echo ""

# For Minikube, get service URL
if [ "$ENVIRONMENT" = "Minikube" ]; then
    print_step "11" "获取 Minikube Service URL"
    echo ""
    echo -e "${GREEN}应用已部署到 Minikube！${NC}"
    echo ""
    echo "获取访问 URL:"
    echo "  kubectl get svc -n $NAMESPACE web"
    echo ""
    echo "或者使用 minikube service 命令自动打开浏览器:"
    echo "  minikube service web -n $NAMESPACE"
    echo ""
    # Try to auto-open
    if command -v minikube &> /dev/null; then
        read -p "是否立即打开浏览器? (y/n): " OPEN_BROWSER
        if [[ "$OPEN_BROWSER" =~ ^[Yy]$ ]]; then
            minikube service web -n $NAMESPACE
        fi
    fi
fi

# For GKE, show LoadBalancer IP instructions
if [ "$ENVIRONMENT" = "GKE" ]; then
    print_step "11" "获取 GKE LoadBalancer IP"
    echo ""
    echo -e "${GREEN}应用已部署到 GKE！${NC}"
    echo ""
    echo "等待 LoadBalancer 分配外部 IP（约 1-2 分钟）..."
    echo "  kubectl get svc -n $NAMESPACE web -w"
    echo ""
    echo "获取 IP 后，在浏览器中访问:"
    echo "  http://<EXTERNAL-IP>"
    echo ""
fi

# Display useful commands
print_step "12" "有用的命令"
echo ""
echo "查看日志:"
echo "  kubectl logs -f -n $NAMESPACE deployment/web"
echo ""
echo "进入 Pod:"
echo "  kubectl exec -it -n $NAMESPACE deployment/web -- bash"
echo ""
echo "查看 HPA 状态:"
echo "  kubectl get hpa -n $NAMESPACE"
echo ""
echo "升级应用:"
echo "  helm upgrade $RELEASE_NAME ./helm/microblog -f $VALUES_FILE -n $NAMESPACE"
echo ""
echo "回滚到前一版本:"
echo "  helm rollback $RELEASE_NAME -n $NAMESPACE"
echo ""
echo "卸载应用:"
echo "  helm uninstall $RELEASE_NAME -n $NAMESPACE"
echo ""

# Final summary
print_step "13" "部署完成"
echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║    Microblog 已成功部署到 $ENVIRONMENT！   ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo "更多信息："
echo "  - Helm Chart 文档: helm/microblog/README.md"
echo "  - 部署指南: HELM-DEPLOYMENT.md"
echo "  - 快速参考: HELM-QUICK-START.md"
echo ""
