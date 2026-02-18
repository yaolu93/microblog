#!/bin/bash
# gke-setup.sh - 自动化 GKE 部署脚本

set -e

echo "=================================================="
echo "  Microblog GKE Deployment Setup Script"
echo "=================================================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 配置变量
PROJECT_ID="${GCP_PROJECT_ID:-}"
REGION="${GCP_REGION:-asia-east1}"
CLUSTER_NAME="${CLUSTER_NAME:-microblog-cluster}"
ZONE="${GCP_ZONE:-asia-east1-a}"
REPOSITORY="${REPOSITORY:-microblog}"
MACHINE_TYPE="${MACHINE_TYPE:-n1-standard-2}"

# 第 1 步：验证必要工具和凭据
echo -e "\n${YELLOW}【1】Checking tools and credentials...${NC}"

# 检查 gcloud
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ gcloud CLI not found. Please install it.${NC}"
    echo "   https://cloud.google.com/sdk/docs/install"
    exit 1
fi
echo -e "${GREEN}✅ gcloud CLI found${NC}"

# 检查 kubectl
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl not found. Installing...${NC}"
    gcloud components install kubectl
fi
echo -e "${GREEN}✅ kubectl found${NC}"

# 检查 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install it.${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker found${NC}"

# 检查 GCP 认证
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  Not authenticated with gcloud. Running 'gcloud auth login'...${NC}"
    gcloud auth login
fi
echo -e "${GREEN}✅ GCP authenticated${NC}"

# 获取 PROJECT_ID
if [ -z "$PROJECT_ID" ]; then
    echo -e "\n${YELLOW}Please enter your GCP Project ID:${NC}"
    read -p "Project ID: " PROJECT_ID
fi

echo -e "Using Project ID: ${GREEN}${PROJECT_ID}${NC}"
gcloud config set project $PROJECT_ID

# 第 2 步：启用所需的 API
echo -e "\n${YELLOW}【2】Enabling required APIs...${NC}"

gcloud services enable container.googleapis.com --quiet &
gcloud services enable artifactregistry.googleapis.com --quiet &
gcloud services enable cloud-build.googleapis.com --quiet &
wait
echo -e "${GREEN}✅ APIs enabled${NC}"

# 第 3 步：创建 Artifact Registry
echo -e "\n${YELLOW}【3】Creating Artifact Registry...${NC}"

if gcloud artifacts repositories describe $REPOSITORY --location=$REGION &>/dev/null; then
    echo -e "${GREEN}✅ Repository ${REPOSITORY} already exists${NC}"
else
    gcloud artifacts repositories create $REPOSITORY \
        --repository-format=docker \
        --location=$REGION \
        --description="Microblog Docker images" \
        --quiet
    echo -e "${GREEN}✅ Repository created${NC}"
fi

# 第 4 步：配置 Docker 认证
echo -e "\n${YELLOW}【4】Configuring Docker authentication...${NC}"

gcloud auth configure-docker ${REGION}-docker.pkg.dev --quiet
echo -e "${GREEN}✅ Docker configured${NC}"

# 第 5 步：构建和推送镜像
echo -e "\n${YELLOW}【5】Building and pushing Docker image...${NC}"

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/microblog:latest"
echo "Image: $IMAGE"

cd "$(dirname "$0")/.."
docker build -t $IMAGE .
docker push $IMAGE

echo -e "${GREEN}✅ Image pushed to Artifact Registry${NC}"

# 第 6 步：创建 GKE 集群（如果不存在）
echo -e "\n${YELLOW}【6】Creating GKE cluster...${NC}"

if gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE &>/dev/null; then
    echo -e "${GREEN}✅ Cluster ${CLUSTER_NAME} already exists${NC}"
else
    echo "Creating cluster (this may take 5-10 minutes)..."
    gcloud container clusters create $CLUSTER_NAME \
        --zone=$ZONE \
        --num-nodes=2 \
        --machine-type=$MACHINE_TYPE \
        --enable-autorepair \
        --enable-autoupgrade \
        --enable-ip-alias \
        --enable-autoscaling \
        --min-nodes=1 \
        --max-nodes=5 \
        --enable-stackdriver-kubernetes \
        --addons=HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver \
        --workload-pool=${PROJECT_ID}.svc.id.goog \
        --quiet
    echo -e "${GREEN}✅ Cluster created${NC}"
fi

# 第 7 步：获取集群凭据
echo -e "\n${YELLOW}【7】Getting cluster credentials...${NC}"

gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE --quiet
echo -e "${GREEN}✅ Credentials configured${NC}"

# 第 8 步：创建 Service Account 和 IAM 绑定
echo -e "\n${YELLOW}【8】Setting up Workload Identity...${NC}"

GSA_NAME="gke-microblog-sa"
KSA_NAME="microblog-ksa"

# 创建 Google Service Account
if gcloud iam service-accounts describe ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com &>/dev/null; then
    echo -e "${GREEN}✅ GSA ${GSA_NAME} already exists${NC}"
else
    gcloud iam service-accounts create $GSA_NAME \
        --display-name="GKE Microblog Service Account" \
        --quiet
    echo -e "${GREEN}✅ GSA created${NC}"
fi

# 授予权限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
    --role="roles/artifactregistry.reader" \
    --quiet || true

echo -e "${GREEN}✅ IAM permissions configured${NC}"

# 第 9 步：创建 Namespace 和 Service Account
echo -e "\n${YELLOW}【9】Creating Kubernetes namespace and service account...${NC}"

kubectl apply -f k8s/1-namespace.yaml

kubectl create serviceaccount $KSA_NAME -n microblog --dry-run=client -o yaml | kubectl apply -f -

# 绑定 GSA 和 KSA
gcloud iam service-accounts add-iam-policy-binding \
    ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:${PROJECT_ID}.svc.id.goog[microblog/${KSA_NAME}]" \
    --quiet || true

# 添加 KSA annotation
kubectl annotate serviceaccount $KSA_NAME \
    -n microblog \
    iam.gke.io/gcp-service-account=${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
    --overwrite 2>/dev/null || true

echo -e "${GREEN}✅ Namespace and service accounts created${NC}"

# 第 10 步：创建 ConfigMap 和 Secret
echo -e "\n${YELLOW}【10】Creating ConfigMap and secrets...${NC}"

kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml

echo -e "${GREEN}✅ ConfigMap and secrets created${NC}"

# 第 11 步：部署应用
echo -e "\n${YELLOW}【11】Deploying application...${NC}"

# 替换镜像名称在 manifests 中
sed -i.bak "s|REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/microblog:latest|${IMAGE}|g" k8s/6-web-gke.yaml
sed -i.bak "s|REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/microblog:latest|${IMAGE}|g" k8s/7-worker-gke.yaml
sed -i.bak "s|PROJECT_ID|${PROJECT_ID}|g" k8s/6-web-gke.yaml
sed -i.bak "s|PROJECT_ID|${PROJECT_ID}|g" k8s/7-worker-gke.yaml

# 部署
kubectl apply -f k8s/4-postgres-gke.yaml
kubectl apply -f k8s/5-redis-gke.yaml
kubectl apply -f k8s/6-web-gke.yaml
kubectl apply -f k8s/7-worker-gke.yaml
kubectl apply -f k8s/8-hpa.yaml

# 清理临时备份
rm -f k8s/6-web-gke.yaml.bak k8s/7-worker-gke.yaml.bak

echo -e "${GREEN}✅ Application deployed${NC}"

# 第 12 步：等待部署就绪
echo -e "\n${YELLOW}【12】Waiting for deployments to be ready (max 5 min)...${NC}"

echo "Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n microblog --timeout=300s 2>/dev/null || echo "⚠️  PostgreSQL still initializing..."

echo "Waiting for Redis..."
kubectl wait --for=condition=ready pod -l app=redis -n microblog --timeout=120s 2>/dev/null || true

echo "Waiting for Web..."
kubectl wait --for=condition=ready pod -l app=web -n microblog --timeout=180s 2>/dev/null || echo "⚠️  Web still initializing..."

echo -e "${GREEN}✅ Deployments ready${NC}"

# 第 13 步：显示访问信息
echo -e "\n${GREEN}=================================================="
echo "  ✅ Deployment Complete!"
echo "==================================================${NC}\n"

echo -e "Cluster: ${GREEN}${CLUSTER_NAME}${NC} (Zone: ${ZONE})"
echo -e "Project: ${GREEN}${PROJECT_ID}${NC}"
echo -e "Region: ${GREEN}${REGION}${NC}\n"

echo "Next steps:"
echo ""

# 获取 LoadBalancer IP
EXTERNAL_IP=$(kubectl get svc -n microblog web -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "pending")

echo "1. Check service status:"
echo "   kubectl get svc -n microblog"
echo ""

if [ "$EXTERNAL_IP" != "pending" ] && [ ! -z "$EXTERNAL_IP" ]; then
    echo "2. Access the application:"
    echo "   http://${EXTERNAL_IP}:80"
    echo ""
else
    echo "2. Wait for LoadBalancer to get external IP, then:"
    echo "   kubectl get svc -n microblog web"
    echo ""
fi

echo "3. View logs:"
echo "   kubectl logs -f -n microblog -l app=web"
echo ""

echo "4. Create initial user:"
echo "   kubectl exec -it -n microblog deployment/web -- flask shell"
echo ""

echo "5. Access GKE dashboard:"
echo "   https://console.cloud.google.com/kubernetes/workloads?project=${PROJECT_ID}"
echo ""

echo -e "${GREEN}✅ Happy deploying!${NC}"
