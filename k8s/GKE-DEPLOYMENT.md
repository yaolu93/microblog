GKE 部署指南（Google Kubernetes Engine）

## 前置条件

- **Google Cloud 账户**（已创建项目）
- **gcloud CLI** 已安装和配置
- **kubectl** 已安装
- **Docker** 已安装
- 在 GCP 启用以下 API：
  - Kubernetes Engine API
  - Cloud Build API（可选，用于自动构建）
  - Artifact Registry API（推荐）或 Container Registry API

### 快速检查和初始化

```bash
# 列出现有的 GCP 项目
gcloud projects list

# 设置当前项目（替换 YOUR_PROJECT_ID）
export PROJECT_ID="your-gcp-project-id"
gcloud config set project $PROJECT_ID

# 启用所需的 API
gcloud services enable container.googleapis.com
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloud-build.googleapis.com
```

## 第 1 步：配置镜像仓库（Artifact Registry）

### 创建 Artifact Registry 仓库

```bash
# 设置区域（选择离你最近的）
export REGION="asia-east1"  # 或 us-central1, europe-west1 等
export REPOSITORY="microblog"

# 创建仓库
gcloud artifacts repositories create $REPOSITORY \
  --repository-format=docker \
  --location=$REGION \
  --description="Microblog Docker images"

# 验证仓库创建
gcloud artifacts repositories list --location=$REGION
```

### 配置 Docker 身份认证

```bash
# 配置 gcloud 为 Docker 认证提供者
gcloud auth configure-docker ${REGION}-docker.pkg.dev

# 验证配置
docker ps  # 如果成功，没有错误信息
```

## 第 2 步：构建并推送 Docker 镜像

### 构建镜像并推送到 Artifact Registry

```bash
cd /home/yao/fromGithub/microblog

# 定义镜像的完整路径
export IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}/microblog:latest"

# 构建镜像
docker build -t $IMAGE .

# 验证镜像已构建
docker images | grep microblog

# 推送镜像到 Artifact Registry
docker push $IMAGE

# 验证推送成功
gcloud artifacts docker images list ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPOSITORY}
```

### （可选）使用 Cloud Build 进行自动构建

```bash
# Cloud Build 自动从 GitHub/Cloud Source Repositories 构建
gcloud builds submit \
  --tag=${IMAGE} \
  --region=$REGION

# 查看构建历史
gcloud builds list --region=$REGION
```

## 第 3 步：创建 GKE 集群

### 创建生产级别的 GKE 集群

```bash
# 设置集群参数
export CLUSTER_NAME="microblog-cluster"
export ZONE="asia-east1-a"  # 选择 REGION 内的可用区
export NUM_NODES=2
export MACHINE_TYPE="n1-standard-2"  # 生产推荐：2 核心 CPU，7.5GB 内存

# 创建集群（可能需要 5-10 分钟）
gcloud container clusters create $CLUSTER_NAME \
  --zone=$ZONE \
  --num-nodes=$NUM_NODES \
  --machine-type=$MACHINE_TYPE \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=5 \
  --enable-stackdriver-kubernetes \
  --addons=HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver

# 获取集群凭据（自动更新 .kube/config）
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# 验证连接
kubectl cluster-info
kubectl get nodes
```

### （可选）高级配置选项

```bash
# 为生产环境启用更多功能的集群创建
gcloud container clusters create $CLUSTER_NAME \
  --zone=$ZONE \
  --num-nodes=$NUM_NODES \
  --machine-type=$MACHINE_TYPE \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-autoscaling \
  --min-nodes=2 \
  --max-nodes=10 \
  --enable-stackdriver-kubernetes \
  --enable-network-policy \
  --enable-pod-security-policy \
  --enable-shielded-nodes \
  --addons=HorizontalPodAutoscaling,HttpLoadBalancing,GcePersistentDiskCsiDriver,GkeBackupAgentAddon \
  --enable-vertical-pod-autoscaling \
  --enable-cloud-logging \
  --logging=SYSTEM,WORKLOAD \
  --enable-cloud-monitoring \
  --monitoring=SYSTEM,WORKLOAD \
  --maintenance-window-start=2026-02-20T00:00:00Z \
  --maintenance-window-duration=4h
```

## 第 4 步：为 GCR/Artifact Registry 创建 ImagePullSecret

由于 GKE 集群需要从 Artifact Registry 拉取私有镜像，需要创建认证密钥：

```bash
# 创建服务账户（如果尚未创建）
gcloud iam service-accounts create gke-microblog-sa \
  --display-name="GKE Microblog Service Account"

# 授予 Artifact Registry 读取权限
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:gke-microblog-sa@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"

# 创建密钥文件
gcloud iam service-accounts keys create key.json \
  --iam-account=gke-microblog-sa@${PROJECT_ID}.iam.gserviceaccount.com

# 在 Kubernetes 集群中创建 Secret
kubectl create namespace microblog

kubectl create secret docker-registry gcr-json-key \
  --docker-server=${REGION}-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat key.json)" \
  --docker-email=user@example.com \
  -n microblog

# 清理临时密钥文件
rm key.json

# 验证 Secret 创建
kubectl get secret -n microblog gcr-json-key
```

### （推荐）使用 Workload Identity（更安全）

```bash
# 启用 Workload Identity（如果创建集群时未启用）
gcloud container clusters update $CLUSTER_NAME \
  --workload-pool=${PROJECT_ID}.svc.id.goog \
  --zone=$ZONE

# 创建 Kubernetes Service Account
kubectl create serviceaccount microblog-ksa -n microblog

# 为 KSA 绑定 GSA（Google Service Account）
gcloud iam service-accounts add-iam-policy-binding \
  gke-microblog-sa@${PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${PROJECT_ID}.svc.id.goog[microblog/microblog-ksa]"

# 在 Pod 中配置 Workload Identity
# 在 Kubernetes manifests 中添加：
# serviceAccountName: microblog-ksa
# 和 Pod annotation:
# iam.gke.io/gcp-service-account: gke-microblog-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

## 第 5 步：配置持久化存储

### 为 PostgreSQL 创建 PersistentVolumeClaim

```bash
# GKE 默认提供 gce-pd（Google 持久磁盘）storage class
# 检查可用的 storage classes
kubectl get storageclass

# 创建 1. 创建 ConfigMap 和 Secret
kubectl apply -f k8s/1-namespace.yaml
kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml

# 2. 应用 PostgreSQL（使用 PersistentVolume）
kubectl apply -f k8s/4-postgres-gke.yaml

# 3. 应用 Redis
kubectl apply -f k8s/5-redis-gke.yaml

# 4. 应用 Web 应用和 Worker
kubectl apply -f k8s/6-web-gke.yaml
kubectl apply -f k8s/7-worker-gke.yaml

# 5. （可选）应用 HPA 和 Ingress
kubectl apply -f k8s/8-hpa.yaml
kubectl apply -f k8s/9-ingress-gke.yaml
```

### 检查部署进度

```bash
# 实时监看 Pod 创建
kubectl get pods -n microblog -w

# 等待所有 Pod 就绪
kubectl wait --for=condition=ready pod -l app=postgres -n microblog --timeout=120s
kubectl wait --for=condition=ready pod -l app=redis -n microblog --timeout=120s
kubectl wait --for=condition=ready pod -l app=web -n microblog --timeout=120s

# 检查服务和 Ingress
kubectl get svc -n microblog
kubectl get ingress -n microblog
```

## 第 6 步：访问应用

### 通过 LoadBalancer 服务访问

```bash
# 获取 Web 服务的外部 IP（LoadBalancer）
kubectl get svc -n microblog web

# 在 EXTERNAL-IP 列找到公网 IP，访问：
# http://<EXTERNAL-IP>:8000

# 获取 IP 的懒办法
kubectl get svc -n microblog web -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

### 通过 Ingress 使用自定义域名（推荐）

```bash
# 获取 Ingress 的外部 IP
kubectl get ingress -n microblog

# 配置你的 DNS 指向这个 IP
# 例如在 GCP Cloud DNS 或你的域名提供商中添加：
# A 記錄: microblog.example.com -> <INGRESS-IP>

# 然后访问：
# https://microblog.example.com
```

## 第 7 步：创建初始用户（可选）

```bash
# 进入 Web Pod 的 Flask shell
kubectl exec -it -n microblog deployment/web -- flask shell

# 在 Python REPL 中执行（参考本项目的 microblog.py）
>>> from app import db
>>> from app.models import User
>>> u = User(username='admin', email='admin@example.com')
>>> u.set_password('your-password')
>>> db.session.add(u)
>>> db.session.commit()
>>> exit()
```

## 第 8 步：监控和日志

### 查看 GKE 监控仪表板

```bash
# 在 GCP Console 中查看
# https://console.cloud.google.com/kubernetes/workloads

# 或使用 gcloud 查看集群信息
gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE
```

### 查看应用日志

```bash
# 实时日志（Web）
kubectl logs -f -n microblog -l app=web

# 查看特定 Pod 日志
kubectl logs -f -n microblog pod/web-xxxxx

# 使用 gcloud 查看集群级别的日志
gcloud logging read "resource.type=k8s_container AND resource.labels.namespace_name=microblog" \
  --order=DESC \
  --limit=50
```

### 性能监控

```bash
# 查看 Pod 资源使用
kubectl top pods -n microblog

# 查看节点资源使用
kubectl top nodes
```

## 第 9 步：配置自动缩放（HPA）

已在 `k8s/8-hpa.yaml` 中配置。检查状态：

```bash
kubectl get hpa -n microblog

# 查看自动缩放历史
kubectl describe hpa web -n microblog
```

## 常用 GKE 命令

```bash
# 列出所有集群
gcloud container clusters list

# 描述特定集群
gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE

# 升级集群
gcloud container clusters upgrade $CLUSTER_NAME --zone=$ZONE

# 增加节点数
gcloud container clusters resize $CLUSTER_NAME --num-nodes=5 --zone=$ZONE

# 删除集群（谨慎）
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE

# 配置 kubectl 认证
gcloud container clusters get-credentials $CLUSTER_NAME --zone=$ZONE

# 在 GCP Console 中打开集群
gcloud container clusters describe $CLUSTER_NAME --zone=$ZONE --format='value(selfLink)' \
  | xargs -I{} echo "https://console.cloud.google.com/kubernetes/workloads?project=${PROJECT_ID}"
```

## 生产环境最佳实践

### 1. 安全性
- ✅ 使用 Workload Identity（而不是服务账户密钥）
- ✅ 启用 Network Policy
- ✅ 启用 Pod Security Policy
- ✅ 定期更新 GKE 版本和节点

### 2. 成本优化
- ✅ 启用自动缩放（已配置）
- ✅ 使用 Preemptible VMs（便宜但可被抢占）
  ```bash
  --preemptible  # 在创建集群命令中添加
  ```
- ✅ 使用 Committed Use Discounts（如果长期使用）

### 3. 可用性
- ✅ 多个节点和 Pod 副本（已配置）
- ✅ PersistentVolume 用于数据库（已配置）
- ✅ 定期备份数据库

### 4. 监控和告警
- ✅ 启用 Cloud Logging 和 Monitoring（默认启用）
- ✅ 创建告警规则监控 CPU、内存、Pod 重启

### 5. CI/CD 集成
- ✅ 使用 Cloud Build 进行自动构建和部署
  ```bash
  gcloud builds submit --tag=${IMAGE}
  ```
- ✅ 配置 GitOps（例如 ArgoCD、Flux）

## 故障排查

### Pod 无法拉取镜像

```bash
# 检查 imagePullSecrets
kubectl describe pod <pod-name> -n microblog

# 验证 secret 存在
kubectl get secret -n microblog

# 手动测试镜像拉取
kubectl run -it --image=${IMAGE} --restart=Never test-pull \
  --overrides='{"spec":{"serviceAccountName":"microblog-ksa"}}' \
  -n microblog -- bash
```

### 无法连接到数据库

```bash
# 检查 PostgreSQL Pod 状态
kubectl get pods -n microblog -l app=postgres

# 进入 Web Pod 测试连接
kubectl exec -it -n microblog deployment/web -- \
  psql -h postgres -U postgres -d microblog -c "SELECT 1"

# 检查 PersistentVolume
kubectl get pvc -n microblog
kubectl describe pvc postgres-storage-postgres-0 -n microblog
```

### 成本过高

```bash
# 检查资源使用
kubectl top nodes
kubectl top pods -n microblog --all-namespaces

# 调整 Pod 资源请求/限制
# 编辑 manifests 中的 resources.requests/limits

# 考虑使用 Preemptible 节点
# 在集群开始时添加 --preemptible 标志
```

## 清理资源

```bash
# 删除应用（保留集群）
kubectl delete namespace microblog

# 删除整个集群（谨慎：会删除所有数据）
gcloud container clusters delete $CLUSTER_NAME --zone=$ZONE

# 删除 Artifact Registry 仓库
gcloud artifacts repositories delete $REPOSITORY --location=$REGION

# 删除负载均衡器和磁盘（如未自动删除）
gcloud compute forwarding-rules list
gcloud compute disks list
```

## 参考资源

- **GKE 文档**：https://cloud.google.com/kubernetes-engine/docs
- **Artifact Registry**：https://cloud.google.com/artifact-registry/docs
- **Cloud Build**：https://cloud.google.com/build/docs
- **Gke Pricing**：https://cloud.google.com/kubernetes-engine/pricing

---

有任何问题或需要进一步帮助，请告诉我！
