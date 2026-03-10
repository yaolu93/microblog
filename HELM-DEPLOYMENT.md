# Helm 部署指南 - Microblog

使用 Helm Chart 部署 Microblog 应用到 Minikube 或 GKE。

## 📦 安装 Helm

### macOS
```bash
brew install helm
```

### Debian/Linux
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Windows
```bash
choco install kubernetes-helm
```

### 验证安装
```bash
helm version
```

## 🚀 快速部署（一键）

### Minikube（本地开发）

```bash
# 假设 Minikube 已经运行
minikube start

# 部署应用
helm install microblog ./helm/microblog \
  -f helm/microblog/values-minikube.yaml \
  -n microblog \
  --create-namespace

# 获取服务 IP 和端口
kubectl get svc -n microblog web

# 在浏览器打开
minikube service web -n microblog

# 或者手动打开（使用 NodePort）
# http://<MINIKUBE_IP>:<NODE_PORT>
```

### GKE（Google Kubernetes Engine）

```bash
# 权限检查
export PROJECT_ID="microblog-487821"
gcloud config set project $PROJECT_ID

# 创建 GKE 集群（如果还没有）
gcloud container clusters create microblog-cluster \
  --zone=asia-east1-a \
  --num-nodes=2 \
  --machine-type=n1-standard-2 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --workload-pool=${PROJECT_ID}.svc.id.goog

# 获取集群凭据
gcloud container clusters get-credentials microblog-cluster --zone=asia-east1-a

# 构建并推送镜像
export REGION="asia-east1"
export IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog/microblog:latest"
docker build -t $IMAGE .
docker push $IMAGE

# 部署应用
helm install microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set image.repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog/microblog" \
  -n microblog \
  --create-namespace

# 获取 LoadBalancer 外部 IP
kubectl get svc -n microblog web

# 在浏览器中打开（等待 EXTERNAL-IP 分配，约 1-2 分钟）
# http://<EXTERNAL-IP>
```

## 📋 分步部署

### 1. 验证 Chart

```bash
# 验证 YAML 语法
helm lint ./helm/microblog

# 生成最终 YAML（不部署）
helm template microblog ./helm/microblog \
  -f helm/microblog/values-minikube.yaml
```

### 2. 预先检查

```bash
# 确保命名空间和存储可用
kubectl get storageclass
kubectl get nodes
```

### 3. 安装 Chart

```bash
# Minikube
helm install microblog ./helm/microblog \
  -f helm/microblog/values-minikube.yaml \
  -n microblog \
  --create-namespace \
  --debug  # 添加 --debug 查看详细日志

# GKE
helm install microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog \
  --create-namespace
```

### 4. 监控部署

```bash
# 查看安装状态
helm status microblog -n microblog

# 实时监控 Pod 启动
kubectl get pods -n microblog -w

# 查看详细事件
kubectl describe pod -n microblog deployment/web

# 查看日志
kubectl logs -f -n microblog deployment/web
```

### 5. 验证部署成功

```bash
# 所有 Pod 应该是 Running
kubectl get pods -n microblog

# 检查服务
kubectl get svc -n microblog

# 测试数据库连接
kubectl exec -it -n microblog deployment/web -- \
  psql -h postgres -U postgres -d microblog -c "SELECT 1"
```

## 🔄 更新部署

### 修改配置后升级

```bash
# 编辑 values 文件
vim helm/microblog/values-gke.yaml

# 升级应用
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog

# 监控升级进度
kubectl rollout status deployment/web -n microblog
```

### 回滚到前一个版本

```bash
# 查看版本历史
helm history microblog -n microblog

# 立即回滚（如果有问题）
helm rollback microblog -n microblog

# 回滚到特定版本
helm rollback microblog 1 -n microblog
```

## 🔐 配置安全

### 修改密码和密钥

```bash
# 方法 1: 编辑 values 文件（不推荐用于生产）
vim helm/microblog/values-gke.yaml
```

**values-gke.yaml 中需要修改的部分：**
```yaml
secrets:
  secretKey: "CHANGE-ME-STRONG-RANDOM-STRING"  # 生成随机的强密钥
  postgres:
    password: "CHANGE-ME-STRONG-PASSWORD"       # 生成随机的强密码
```

生成强密钥的方法：
```bash
# Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# OpenSSL
openssl rand -base64 32

# Linux/macOS
head -c 32 /dev/urandom | base64
```

### 方法 2: 使用 GCP Secret Manager（推荐用于生产）

```bash
# 创建 Secret
kubectl create secret generic app-secret \
  --from-literal=SECRET_KEY="$(openssl rand -base64 32)" \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 32)" \
  -n microblog

# 然后需要修改 templates 中的 secret.yaml 来引用外部 secret
```

## 🐳 Docker 镜像

### Minikube（使用本地镜像）

```bash
# 使用 Minikube 的 Docker 环境
eval $(minikube docker-env)

# 构建镜像（无需 push）
docker build -t microblog:latest .

# Helm 自动使用或手动提供
helm install microblog ./helm/microblog -f helm/microblog/values-minikube.yaml
```

### GKE（使用 Artifact Registry）

```bash
# 打开 Docker 推送权限
gcloud auth configure-docker asia-east1-docker.pkg.dev

# 构建镜像
export REGION="asia-east1"
export PROJECT_ID="microblog-487821"
export IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog/microblog:latest"

docker build -t $IMAGE .

# 推送到 Artifact Registry
docker push $IMAGE

# 在 Helm 中使用
helm install microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set image.repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog/microblog" \
  -n microblog
```

## 📊 监控和日志

### 实时日志查看

```bash
# Web 日志
kubectl logs -f -n microblog deployment/web

# Worker 日志
kubectl logs -f -n microblog deployment/worker

# PostgreSQL 日志
kubectl logs -f -n microblog statefulset/postgres

# 所有容器
kubectl logs -f -n microblog -l app=web --all-containers=true
```

### Pod 资源使用

```bash
# 查看 CPU 和内存使用
kubectl top pods -n microblog

# 查看节点资源
kubectl top nodes
```

### 获取 HPA 状态

```bash
# 查看自动缩放状态
kubectl get hpa -n microblog

# 详细 HPA 信息
kubectl describe hpa web-hpa -n microblog
```

## 🗑️ 清理资源

```bash
# 卸载应用（保留 namespace）
helm uninstall microblog -n microblog

# 删除 PersistentVolumeClaim（数据）
kubectl delete pvc -n microblog postgres-storage-postgres-0

# 删除 namespace（删除所有资源）
kubectl delete namespace microblog

# GKE 专用：删除集群
gcloud container clusters delete microblog-cluster --zone=asia-east1-a
```

## ❓ 常见问题

### Q: Pod 一直在 Pending 状态？
A: 检查资源可用性：
```bash
kubectl describe node  # 查看节点资源
kubectl describe pvc -n microblog  # 检查存储
```

### Q: ImagePullBackOff 错误？
A: 检查镜像：
```bash
# Minikube：确保镜像已构建
docker images | grep microblog

# GKE：确保镜像已推送
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog
```

### Q: 数据库连接失败？
```bash
# 确保 PostgreSQL Pod 运行中
kubectl get pod -n microblog postgres-0

# 测试连接
kubectl exec -it -n microblog postgres-0 -- psql -U postgres -d microblog -c "SELECT 1"
```

### Q: 如何修改配置而不重新部署？
使用 `helm upgrade`：
```bash
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set web.replicaCount=3 \
  -n microblog
```

## 📚 更多帮助

```bash
# Helm 官方帮助
helm help

# Chart 文本
helm show chart ./helm/microblog

# 查看完整的 values
helm show values ./helm/microblog

# 相关 Kubernetes 命令
kubectl help
```

## 🔗 相关文档

- [Helm Chart README](./helm/microblog/README.md)
- [GKE 部署指南](./k8s/GKE-DEPLOYMENT.md)
- [Minikube 快速开始](./k8s/MINIKUBE-QUICK-START.md)
