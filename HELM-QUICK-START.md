# Helm 快速参考卡片

## 🚀 最快开始（3 步）

```bash
# 1. 安装 Helm（如果还没安装）
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 2. Minikube 部署
helm install microblog ./helm/microblog \
  -f helm/microblog/values-minikube.yaml \
  -n microblog --create-namespace

# 3. 获取服务 URL
kubectl get svc -n microblog web
minikube service web -n microblog
```

## 📋 命令速查表

### 安装和部署

| 任務 | 命令 |
|------|------|
| **Minikube 安装** | `helm install microblog ./helm/microblog -f helm/microblog/values-minikube.yaml -n microblog --create-namespace` |
| **GKE 安装** | `helm install microblog ./helm/microblog -f helm/microblog/values-gke.yaml -n microblog --create-namespace` |
| **验证语法** | `helm lint ./helm/microblog` |
| **生成 YAML** | `helm template microblog ./helm/microblog -f helm/microblog/values-gke.yaml` |
| **查看状态** | `helm status microblog -n microblog` |
| **查看值** | `helm get values microblog -n microblog` |

### 更新和升级

| 任務 | 命令 |
|------|------|
| **升级应用** | `helm upgrade microblog ./helm/microblog -f helm/microblog/values-gke.yaml -n microblog` |
| **修改副本数** | `helm upgrade microblog ./helm/microblog -f helm/microblog/values-gke.yaml --set web.replicaCount=5 -n microblog` |
| **查看版本历史** | `helm history microblog -n microblog` |
| **回滚上一版本** | `helm rollback microblog -n microblog` |
| **回滚特定版本** | `helm rollback microblog 2 -n microblog` |

### 卸载

| 任務 | 命令 |
|------|------|
| **卸载应用** | `helm uninstall microblog -n microblog` |
| **删除 Namespace** | `kubectl delete namespace microblog` |

### Kubernetes 监控

| 任務 | 命令 |
|------|------|
| **查看 Pod 列表** | `kubectl get pods -n microblog` |
| **实时监控 Pod** | `kubectl get pods -n microblog -w` |
| **查看服務和 IP** | `kubectl get svc -n microblog` |
| **查看 Pod 日誌** | `kubectl logs -f -n microblog deployment/web` |
| **查看 Pod 詳情** | `kubectl describe pod <pod-name> -n microblog` |
| **進入 Pod 命令行** | `kubectl exec -it -n microblog deployment/web -- bash` |
| **查看 HPA 狀態** | `kubectl get hpa -n microblog` |
| **查看資源使用** | `kubectl top pods -n microblog` |

## 🔧 常见配置

### 修改密码和密钥

```bash
# 编辑 values 文件
vim helm/microblog/values-gke.yaml

# 修改以下部分：
secrets:
  secretKey: "YOUR-RANDOM-STRING-HERE"
  postgres:
    password: "YOUR-PASSWORD-HERE"

# 升级应用
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml -n microblog
```

### 快速生成强密钥

```bash
# 方法 1: Python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"

# 方法 2: OpenSSL
openssl rand -base64 32

# 方法 3: Linux/macOS
head -c 32 /dev/urandom | base64
```

### 修改副本数

```bash
# 通过 Helm 命令直接修改
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set web.replicaCount=5 \
  --set worker.replicaCount=3 \
  -n microblog

# 或编辑 values 文件后再 upgrade
vim helm/microblog/values-gke.yaml
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog
```

### 修改镜像

```bash
# GKE 推送新镜像后
export IMAGE="asia-east1-docker.pkg.dev/PROJECT_ID/microblog/microblog:v2"

helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set image.repository="${REGION}-docker.pkg.dev/${PROJECT_ID}/microblog/microblog" \
  --set image.tag="v2" \
  -n microblog
```

## 📊 自动缩放配置

### 启用 HPA

```bash
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set autoscaling.enabled=true \
  --set webAutoscaling.minReplicas=2 \
  --set webAutoscaling.maxReplicas=10 \
  -n microblog

# 查看 HPA 状态
kubectl get hpa -n microblog
kubectl describe hpa web-hpa -n microblog
```

### 修改 CPU 阈值

```bash
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set webAutoscaling.targetCPUUtilizationPercentage=70 \
  -n microblog
```

## 🌐 Ingress 和自定义域名 (GKE)

### 启用 Ingress

```bash
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host="microblog.example.com" \
  -n microblog

# 获取 Ingress IP
kubectl get ingress -n microblog
```

### 设置自定义域名

```bash
# 编辑 values 文件
vim helm/microblog/values-gke.yaml

# 修改 ingress 部分：
ingress:
  enabled: true
  hosts:
    - host: my-microblog.example.com
      paths:
        - path: /
          pathType: Prefix

helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml -n microblog
```

## 🔐 Workload Identity (GKE)

### 启用 Workload Identity

```bash
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set workloadIdentity.enabled=true \
  --set workloadIdentity.googleServiceAccount="gke-microblog-sa@PROJECT_ID.iam.gserviceaccount.com" \
  -n microblog
```

## 🐛 故障排查命令

```bash
# 查看最近的错误
kubectl get events -n microblog --sort-by='.lastTimestamp'

# 检查 Pod 的完整日志
kubectl logs <pod-name> -n microblog --all-containers=true --timestamps=true

# 进入 Pod 调试
kubectl debug pod <pod-name> -n microblog -it -- bash

# 测试数据库连接
kubectl exec -it -n microblog postgres-0 -- \
  psql -U postgres -d microblog -c "SELECT 1"

# 查看 PersistentVolumeClaim 状态
kubectl get pvc -n microblog
kubectl describe pvc postgres-storage-postgres-0 -n microblog
```

## 📚 快速參考文件

| 文件 | 說明 |
|------|------|
| `HELM-DEPLOYMENT.md` | 詳細部署指南 |
| `helm/microblog/README.md` | Chart 文檔 |
| `helm/microblog/values.yaml` | 默認配置值 |
| `helm/microblog/values-minikube.yaml` | Minikube 覆蓋值 |
| `helm/microblog/values-gke.yaml` | GKE 覆蓋值 |
| `helm/microblog/Chart.yaml` | Chart 元數據 |

## 🎯 实用链接

- [Helm 官方文档](https://helm.sh/docs/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
- [Chart 最佳实践](https://helm.sh/docs/chart_best_practices/)
- [Helm Hub](https://artifacthub.io/)
