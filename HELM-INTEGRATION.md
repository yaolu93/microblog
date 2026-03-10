# Helm Chart 整合说明

## 📚 概述

您现在拥有一个完整的 **Helm Chart** 来部署 Microblog 应用！这使得在 Minikube 和 GKE 上的部署变得更加简单、可重复和可维护。

## 🎯 Helm vs 原始 YAML 的优势

| 特性 | 原始 YAML | Helm Chart |
|------|---------|-----------|
| **参数化配置** | ❌ 需要手动编辑每个文件 | ✅ `values.yaml` 集中管理 |
| **环境差异** | ❌ 需要多个文件副本 | ✅ `values-*.yaml` 覆盖 |
| **版本管理** | ❌ Git 管理 | ✅ `helm history` 和 `rollback` |
| **重用性** | ❌ 特定于项目 | ✅ 可发布到 Helm Hub |
| **模板化** | ❌ 很难重用代码 | ✅ Go 模板化减少重复 |
| **依赖管理** | ❌ 手动 | ✅ `Chart.yaml` 声明 |
| **验证** | ❌ 部署时才发现问误 | ✅ `helm lint` 提前检查 |
| **一键部署** | ❌ 需要运行多个命令 | ✅ 单一 `helm install` 命令 |

## 📁 Helm Chart 目录结构

```
helm/microblog/
├── Chart.yaml                 # Chart 元数据（名称、版本等）
├── values.yaml                # 默认配置值（所有可配置参数）
├── values-minikube.yaml       # Minikube 环境覆盖值
├── values-gke.yaml            # GKE 生产环境覆盖值
├── README.md                  # Chart 详细文档
└── templates/                 # Kubernetes 资源模板
    ├── 0-namespace.yaml       # Namespace
    ├── 1-configmap.yaml       # ConfigMap（应用配置）
    ├── 2-secret.yaml          # Secret（密码、密钥）
    ├── 3-postgres.yaml        # PostgreSQL StatefulSet
    ├── 4-redis.yaml           # Redis Deployment
    ├── 5-web.yaml             # Flask Web 应用 Deployment
    ├── 6-worker.yaml          # RQ Worker Deployment
    ├── 7-hpa.yaml             # 水平自动缩放配置
    ├── 8-ingress.yaml         # Ingress 配置
    └── 9-serviceaccount.yaml  # Workload Identity ServiceAccount
```

## 🚀 快速开始

### 方法 1：使用自动化脚本（推荐）

```bash
# 交互式选择环境（Minikube 或 GKE）并自动部署
bash helm-deploy.sh
```

### 方法 2：手动部署

#### Minikube
```bash
helm install microblog ./helm/microblog \
  -f helm/microblog/values-minikube.yaml \
  -n microblog \
  --create-namespace
```

#### GKE
```bash
helm install microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  -n microblog \
  --create-namespace
```

## 📊 配置管理

### 默认值（values.yaml）

包含所有资源的基础配置：
- PostgreSQL、Redis、Web、Worker 的镜像和资源
- 默认副本数、端口、健康检查配置
- 自动缩放参数
- Ingress 和 Workload Identity 配置

### 环境覆盖

**Minikube** (`values-minikube.yaml`)：
- 使用本地 Docker 镜像（`imagePullPolicy: Never`）
- NodePort 而非 LoadBalancer
- 较低的资源请求
- 禁用 Ingress 和 Workload Identity

**GKE** (`values-gke.yaml`)：
- 使用 Artifact Registry 镜像
- LoadBalancer 服务
- 更高的资源限制
- 启用 Workload Identity 和 Pod 反亲和性
- 启用 Ingress 和自动缩放

### 动态覆盖值

无需编辑文件，直接通过命令行修改：

```bash
# 修改副本数
helm upgrade microblog ./helm/microblog \
  -f helm/microblog/values-gke.yaml \
  --set web.replicaCount=5 \
  --set worker.replicaCount=3 \
  -n microblog

# 修改镜像标签
helm upgrade microblog ./helm/microblog \
  --set image.tag=v2.0 \
  -n microblog

# 修改多个参数
helm upgrade microblog ./helm/microblog \
  --set postgres.storage.size=50Gi \
  --set webAutoscaling.maxReplicas=20 \
  --set ingress.enabled=true \
  -n microblog
```

## 🔄 工作流程

### 1. 开发迭代

```bash
# 修改代码并构建新镜像
docker build -t microblog:dev .

# 更新部署（使用新镜像）
helm upgrade microblog ./helm/microblog \
  --set image.tag=dev \
  -n microblog

# 查看日志
kubectl logs -f -n microblog deployment/web

# 如果有问题，立即回滚
helm rollback microblog -n microblog
```

### 2. 配置管理

```bash
# 修改 values 文件
vim helm/microblog/values-gke.yaml

# 验证修改（生成 YAML 预览）
helm template microblog ./helm/microblog -f helm/microblog/values-gke.yaml

# 应用修改
helm upgrade microblog ./helm/microblog -f helm/microblog/values-gke.yaml -n microblog
```

### 3. 版本管理

```bash
# 查看版本历史
helm history microblog -n microblog

# 输出示例：
# REVISION  UPDATED                 STATUS    CHART              DESCRIPTION
# 1         Mon Mar 09 ...          deployed  microblog-1.0.0    Install complete
# 2         Mon Mar 09 ...          deployed  microblog-1.0.0    Upgrade complete

# 回滚到特定版本
helm rollback microblog 1 -n microblog
```

## 🔐 安全配置

### 修改密钥和密码（必须！）

编辑 `helm/microblog/values-gke.yaml`：

```yaml
secrets:
  secretKey: "CHANGE-ME-STRONG-RANDOM-STRING"  # Flask SECRET_KEY
  postgres:
    password: "CHANGE-ME-STRONG-PASSWORD"       # 数据库密码
```

生成强随机值：
```bash
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

### 使用 GCP Secret Manager（推荐用于生产）

```bash
# 创建 Secret
kubectl create secret generic app-secret \
  --from-literal=SECRET_KEY="$(openssl rand -base64 32)" \
  --from-literal=POSTGRES_PASSWORD="$(openssl rand -base64 32)" \
  -n microblog
```

## 📈 性能调优

### 资源请求和限制

编辑 `values.yaml` 中的资源配置：

```yaml
web:
  resources:
    requests:
      memory: "512Mi"  # 初始分配
      cpu: "250m"
    limits:
      memory: "1Gi"    # 最大允许
      cpu: "1000m"
```

### 自动缩放

启用 HPA 自动扩展 Pod：

```bash
helm upgrade microblog ./helm/microblog \
  --set autoscaling.enabled=true \
  --set webAutoscaling.targetCPUUtilizationPercentage=70 \
  -n microblog
```

## 📚 相关文档

| 文件 | 内容 |
|------|------|
| [HELM-DEPLOYMENT.md](./HELM-DEPLOYMENT.md) | 详细的分步部署指南 |
| [HELM-QUICK-START.md](./HELM-QUICK-START.md) | 快速参考卡片和命令速查表 |
| [helm/microblog/README.md](./helm/microblog/README.md) | Chart 的完整文档 |
| [helm/microblog/values.yaml](./helm/microblog/values.yaml) | 所有可配置参数的注释说明 |

## 🆚 与之前的 YAML 部署的关系

### 旧方式（保留用于参考）
- `k8s/1-namespace.yaml` → `helm/microblog/templates/0-namespace.yaml`
- `k8s/2-configmap.yaml` → `helm/microblog/templates/1-configmap.yaml`
- `k8s/3-secret.yaml` → `helm/microblog/templates/2-secret.yaml`
- `k8s/4-postgres-gke.yaml` → `helm/microblog/templates/3-postgres.yaml`
- `k8s/5-redis-gke.yaml` → `helm/microblog/templates/4-redis.yaml`
- `k8s/6-web-gke.yaml` → `helm/microblog/templates/5-web.yaml`
- `k8s/7-worker-gke.yaml` → `helm/microblog/templates/6-worker.yaml`
- `k8s/8-hpa.yaml` → `helm/microblog/templates/7-hpa.yaml`
- `k8s/9-ingress-gke.yaml` → `helm/microblog/templates/8-ingress.yaml`

> **注意**：原始的 `k8s/` 目录下的 YAML 文件仍然存在，可以继续使用，但建议迁移到 Helm Chart 以获得更好的可维护性。

## ✨ Helm 的最佳实践

1. **使用版本控制** - 跟踪所有 `values-*.yaml` 的变化
2. **验证语法** - 部署前运行 `helm lint`
3. **预览修改** - 使用 `helm template` 查看生成的 YAML
4. **环境隔离** - 为每个环境使用不同的 values 文件
5. **记录变更** - 在 `helm upgrade` 时添加 `--description` 说明
6. **自动化测试** - 在 CI/CD 中集成 `helm lint` 和 `helm test`

## 🎓 学习 Helm

- [官方 Helm 文档](https://helm.sh/docs/)
- [Chart 最佳实践](https://helm.sh/docs/chart_best_practices/)
- [Helm Hub](https://artifacthub.io/) - 查看其他 charts 学习
- [Go 模板语言](https://pkg.go.dev/text/template) - 理解 `values` 如何注入到模板

## 🆘 获помощь

```bash
# Helm 帮助
helm help

# Chart 帮助
helm show chart ./helm/microblog
helm show values ./helm/microblog
helm show readme ./helm/microblog

# Kubernetes 帮助
kubectl help
kubectl explain deployment.spec.template.spec.containers
```

---

**总结**：Helm Chart 提供了一个强大、灵活、可重复的方式来部署和管理 Microblog 应用。无论是本地开发还是生产部署，都可以使用同一个 Chart，只需改变配置值即可。
