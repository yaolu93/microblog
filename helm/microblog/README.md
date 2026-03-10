# Microblog Helm Chart

完整的 Helm Chart，用于在 Kubernetes、Minikube 和 GKE 上部署 Microblog Flask 应用。

## 📋 快速开始

### Minikube（本地开发）

```bash
# 1. 查看预览（不部署）
helm template microblog ./helm/microblog -f helm/microblog/values-minikube.yaml

# 2. 安装应用
helm install microblog ./helm/microblog -f helm/microblog/values-minikube.yaml -n microblog --create-namespace

# 3. 获取访问 URL
kubectl get svc -n microblog web
minikube service web -n microblog
```

### GKE（生产环境）

```bash
# 1. 更新 secrets（必须！）
vim helm/microblog/values-gke.yaml
# 修改: secrets.secretKey 和 secrets.postgres.password

# 2. 查看预览
helm template microblog ./helm/microblog -f helm/microblog/values-gke.yaml

# 3. 安装应用
helm install microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog \
  --create-namespace

# 4. 监控部署
helm status microblog -n microblog
kubectl get pods -n microblog -w
```

## 📁 Chart 文件结构

```
helm/microblog/
├── Chart.yaml                  # Chart 元数据
├── values.yaml                 # 默认值
├── values-minikube.yaml        # Minikube 覆盖值
├── values-gke.yaml             # GKE 覆盖值
└── templates/                  # Kubernetes 资源模板
    ├── 0-namespace.yaml        # Namespace
    ├── 1-configmap.yaml        # ConfigMap
    ├── 2-secret.yaml           # Secret
    ├── 3-postgres.yaml         # PostgreSQL StatefulSet
    ├── 4-redis.yaml            # Redis Deployment
    ├── 5-web.yaml              # Flask web application
    ├── 6-worker.yaml           # RQ worker
    ├── 7-hpa.yaml              # 水平自动缩放
    ├── 8-ingress.yaml          # Ingress (GKE)
    └── 9-serviceaccount.yaml   # Workload Identity (GKE)
```

## 🔧 常用命令

### 查看和诊断

```bash
# 查看 values（当前配置）
helm get values microblog -n microblog

# 查看生成的 YAML（不部署）
helm template microblog ./helm/microblog -f helm/microblog/values-gke.yaml

# 查看部署状态
helm status microblog -n microblog

# 查看部署历史
helm history microblog -n microblog
```

### 更新和升级

```bash
# 更新已部署的应用（修改 values 后）
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog

# 回滚到前一个版本
helm rollback microblog -n microblog

# 回滚到特定版本
helm rollback microblog 1 -n microblog  # 版本号从 helm history 获取
```

### 卸载

```bash
# 删除应用（保留 namespace）
helm uninstall microblog -n microblog

# 删除 namespace（同时删除所有资源）
kubectl delete namespace microblog
```

## 📊 可配置项

### 关键配置字段

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `global.environment` | 环境名称 | development |
| `image.repository` | 容器镜像仓库 | microblog |
| `image.tag` | 镜像标签 | latest |
| `secrets.secretKey` | Flask SECRET_KEY | you-will-never-guess |
| `secrets.postgres.password` | 数据库密码 | example |
| `postgres.storage.size` | PostgreSQL 存储大小 | 5Gi (Minikube) / 20Gi (GKE) |
| `web.replicaCount` | Web Pod 副本数 | 2 |
| `web.service.type` | Service 类型 | LoadBalancer (GKE) / NodePort (Minikube) |
| `webAutoscaling.minReplicas` | 最少 Pod 数 | 2 |
| `webAutoscaling.maxReplicas` | 最多 Pod 数 | 10 |

### 环境变量注入

Web 和 Worker Pod 通过 ConfigMap 和 Secret 注入环境变量：

```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      configMapKeyRef:
        name: app-config
        key: DATABASE_URL
  - name: SECRET_KEY
    valueFrom:
      secretKeyRef:
        name: app-secret
        key: SECRET_KEY
```

## 🔐 安全建议

### 生产部署前必须：

1. **修改 Secret 值**
   ```bash
   vim helm/microblog/values-gke.yaml
   # 修改以下字段，使用强密码：
   # - secrets.secretKey
   # - secrets.postgres.password
   ```

2. **使用 GCP Secret Manager**
   ```bash
   # 创建 secret 而不是硬编码在 values
   kubectl create secret generic app-secret \
     --from-literal=SECRET_KEY="$(openssl rand -base64 32)" \
     --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 32)" \
     -n microblog
   ```

3. **启用 Workload Identity**（GKE）
   ```bash
   # 在 values-gke.yaml 中设置
   workloadIdentity:
     enabled: true
     googleServiceAccount: gke-microblog-sa@YOUR_PROJECT.iam.gserviceaccount.com
   ```

4. **使用 TLS/HTTPS**
   ```bash
   # 在 values-gke.yaml 中启用 Ingress 和 ManagedCertificate
   ingress:
     enabled: true
     managedCertificate:
       enabled: true
   ```

## 📈 性能调优

### 资源请求/限制

根据工作负载调整资源：

```yaml
web:
  resources:
    requests:
      memory: "512Mi"  # 初始请求
      cpu: "250m"
    limits:
      memory: "1Gi"    # 最大允许
      cpu: "1000m"
```

### 自动缩放

启用 HPA 自动扩展 Pod：

```yaml
webAutoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## 🐛 故障排查

### Pod 无法启动

```bash
# 查看 Pod 日志
kubectl logs -n microblog deployment/web

# 查看 Pod 事件
kubectl describe pod -n microblog <pod-name>

# 进入 Pod
kubectl exec -it -n microblog deployment/web -- bash
```

### 数据库连接错误

```bash
# 检查 ConfigMap
kubectl get configmap -n microblog app-config -o yaml

# 检查 Secret
kubectl get secret -n microblog app-secret -o yaml

# 测试数据库连接
kubectl exec -it -n microblog postgres-0 -- \
  psql -U postgres -d microblog -c "SELECT 1"
```

### 镜像拉取失败

```bash
# 对于 Minikube（本地镜像）
eval $(minikube docker-env)
docker build -t microblog:latest .

# 为 GKE 设置镜像仓库
# 更新 values-gke.yaml 中的 image.repository 为您的 Artifact Registry URL
```

## 🔄 升级和回滚

```bash
# 查看部署历史和版本
helm history microblog -n microblog

# 升级到新版本
helm upgrade microblog ./helm/microblog -f helm/microblog/values-gke.yaml -n microblog

# 如果升级失败，立即回滚
helm rollback microblog -n microblog

# 回滚到特定版本
helm rollback microblog 2 -n microblog  # 版本2
```

## 🌐 Ingress/自定义域名（GKE）

1. 更新 values-gke.yaml
   ```yaml
   ingress:
     enabled: true
     hosts:
       - host: microblog.yourdomain.com
         paths:
           - path: /
             pathType: Prefix
   ```

2. 配置 DNS 指向 Ingress IP
   ```bash
   # 获取 Ingress IP
   kubectl get ingress -n microblog
   # 在 DNS 提供商配置 CNAME 或 A 记录
   ```

## 📚 更多资源

- [Helm 官方文档](https://helm.sh/docs/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
- [GKE 文档](https://cloud.google.com/kubernetes-engine/docs)
- [Chart 最佳实践](https://helm.sh/docs/chart_best_practices/)
