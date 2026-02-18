# Minikube 部署指南（Microblog Kubernetes）

## 前置条件

- **minikube** 已安装（[安装指南](https://minikube.sigs.k8s.io/docs/start/)）
- **kubectl** 已安装  
- **Docker** 已安装

## 快速開始（3 步）

### 第 1 步：啟動 Minikube

```bash
# 以 docker 驅動啟動（macOS/Linux），分配足夠資源
minikube start --driver=docker --cpus=4 --memory=4096 --disk-size=20GB

# 如果在 Windows，用 Hyper-V 或 VirtualBox
# minikube start --driver=hyperv --cpus=4 --memory=4096 --disk-size=20GB
```

驗證 minikube 運行中：
```bash
minikube status
kubectl cluster-info
```

### 第 2 步：使用本地構建的 Docker 鏡像

由於 minikube 可以訪問本地 Docker daemon，無須推送到仓库：

```bash
# 告訴 minikube 使用本地 Docker daemon（避免鏡像拉取）
eval $(minikube docker-env)

# 構建鏡像（將被存儲在 minikube 的 Docker daemon 中）
cd /home/yao/fromGithub/microblog
docker build -t microblog:latest .

# 驗證鏡像已創建
docker images | grep microblog
```

### 第 3 步：部署到 Minikube

使用優化的 minikube 配置（已包含更低的資源要求）：

```bash
# 一鍵部署
bash k8s/minikube-setup.sh

# 或手動部署每個組件
kubectl apply -f k8s/1-namespace.yaml
kubectl apply -f k8s/2-configmap.yaml
kubectl apply -f k8s/3-secret.yaml
kubectl apply -f k8s/4-postgres.yaml
kubectl apply -f k8s/5-redis.yaml
kubectl apply -f k8s/6-web-minikube.yaml      # ← minikube 優化版
kubectl apply -f k8s/7-worker-minikube.yaml   # ← minikube 優化版
```

## 驗證部署

```bash
# 查看所有 pod 和服務
kubectl get pods -n microblog
kubectl get svc -n microblog

# 等待 PostgreSQL StatefulSet 就緒（可能需要 30-60 秒）
kubectl wait --for=condition=ready pod -l app=postgres -n microblog --timeout=120s

# 查看具體 pod 的日誌
kubectl logs -n microblog -l app=web -f
kubectl logs -n microblog -l app=postgres --tail=50
```

## 訪問應用

### 方式 1：Port Forward（最簡單）

```bash
# 本地轉發 web 服務
kubectl port-forward -n microblog svc/web 8000:8000

# 訪問 http://localhost:8000
```

### 方式 2：獲取 Minikube 服務 IP

```bash
# 獲取 web 服務的外部 IP 或 NodePort
minikube service web -n microblog

# 自動在瀏覽器打開
```

### 方式 3：直接訪問 minikube IP + NodePort

```bash
# 獲取 minikube IP
MINIKUBE_IP=$(minikube ip)

# 查看 web 服務的 NodePort
kubectl get svc -n microblog web -o jsonpath='{.spec.ports[0].nodePort}'

# 訪問 http://<MINIKUBE_IP>:<NodePort>
# 例如：http://192.168.49.2:30123
```

## 常用命令

### 進入容器 shell（調試）

```bash
# 進入 web pod 的 shell
kubectl exec -it -n microblog deployment/web -- /bin/bash

# 運行 Flask CLI 命令
kubectl exec -n microblog deployment/web -- flask shell
```

### 查看實時日誌

```bash
# 所有 microblog pods
kubectl logs -n microblog -f -l app=web

# 特定 pod
kubectl logs -n microblog pod/web-xxxxx -f

# 跟隨 worker 日誌
kubectl logs -n microblog -f -l app=worker
```

### 重建/重啟服務

```bash
# 重啟 web deployment（清除舊 pod）
kubectl rollout restart deployment/web -n microblog

# 查看滾動更新狀態
kubectl rollout status deployment/web -n microblog

# 重新部署（修改代碼後重新構建鏡像並重啟）
docker build -t microblog:latest .
kubectl rollout restart deployment/web -n microblog
```

### 刪除/清理

```bash
# 刪除整個 microblog 命名空間（包含所有資源）
kubectl delete namespace microblog

# 或只刪除特定資源
kubectl delete deployment web -n microblog
kubectl delete svc postgres -n microblog
```

## 故障排查

### Pod 卡在 Pending

```bash
# 查看具體原因
kubectl describe pod <pod-name> -n microblog

# 檢查節點資源
kubectl top nodes
kubectl top pods -n microblog
```

### Pod CrashLoopBackOff

```bash
# 查看前面的日誌（已終止的容器）
kubectl logs <pod-name> -n microblog --previous

# 或查看當前日誌
kubectl logs <pod-name> -n microblog
```

### 無法連接到數據庫

```bash
# 驗證 postgres pod 運行中
kubectl get pods -n microblog -l app=postgres

# 檢查 postgres 日誌
kubectl logs -n microblog -l app=postgres -f

# 測試連接性（從 web pod 內）
kubectl exec -it -n microblog deployment/web -- \
  psql -h postgres -U postgres -d microblog -c "SELECT 1"
```

## 性能調優（可選）

### 增加 minikube 資源

```bash
# 停止 minikube
minikube stop

# 重新設置資源（例如 8 CPU，8GB 內存）
minikube start --cpus=8 --memory=8192

# 或直接編輯
minikube config set cpus 8
minikube config set memory 8192
minikube start
```

### 啟用 metrics-server（資源監控）

```bash
minikube addons enable metrics-server
kubectl top nodes
kubectl top pods -n microblog
```

## 開發工作流

編輯代碼後，快速部署步驟：

```bash
# 1. 重新構建鏡像
eval $(minikube docker-env)
docker build -t microblog:latest .

# 2. 強制重啟 pod（會拉取新鏡像）
kubectl rollout restart deployment/web -n microblog
kubectl rollout restart deployment/worker -n microblog

# 3. 監控部署
kubectl rollout status deployment/web -n microblog
kubectl logs -f -n microblog -l app=web
```

## 遷移到真實 Kubernetes 集群

當準備好部署到真實集群（EKS、GKE、AKS 等）時：

1. **推送鏡像到仓库**：
   ```bash
   docker build -t achillesly/microblog:latest .
   docker push achillesly/microblog:latest
   ```

2. **使用原始清單（6-web.yaml、7-worker.yaml）**：
   ```bash
   kubectl apply -f k8s/
   ```

3. **更新 imagePullPolicy**：若鏡像需要從私有仓库拉取，添加 Secret 和更新 imagePullSecrets。

---

有任何問題或需要調整，請告訴我！
