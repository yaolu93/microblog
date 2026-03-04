# Prometheus + Grafana 監控指南

## 概述

本文檔說明如何使用 Prometheus 和 Grafana 監控 Microblog 應用程序。

## 架構

```
Web App (Flask)
    ├── /metrics 端點 (Prometheus 格式)
    └── 暴露 HTTP 請求、延遲、連接等指標

Prometheus
    ├── 定期拉取 /metrics 端點
    ├── 存儲時間序列數據
    └── 提供查詢 API

Grafana
    ├── 連接 Prometheus 數據源
    ├── 顯示預配置儀表板
    └── 可視化應用程序指標
```

## 快速開始

### 1. 啟動服務

使用 Docker Compose 啟動所有服務（包括 Prometheus 和 Grafana）：

```bash
docker-compose up -d
```

### 2. 訪問 Grafana

打開瀏覽器訪問：
- **URL**: http://localhost:3000
- **默認用戶名**: admin
- **默認密碼**: admin

第一次登錄時，系統會提示您更改密碼。

### 3. 訪問 Prometheus

打開瀏覽器訪問：
- **URL**: http://localhost:9090

## 監控指標

### 應用程序指標

應用程序暴露以下 Prometheus 指標（在 `/metrics` 端點）：

#### 1. HTTP 請求指標
- **`http_requests_total`**：總 HTTP 請求數
  - 標籤：方法（GET、POST 等）、端點、HTTP 狀態碼
  - 類型：計數器

- **`http_request_duration_seconds`**：HTTP 請求延遲
  - 標籤：方法、端點
  - 類型：直方圖
  - 用途：計算 p50、p95、p99 延遲

#### 2. 連接指標
- **`db_connections_total`**：數據庫連接數
  - 類型：測量器

- **`redis_connections_total`**：Redis 連接狀態
  - 類型：測量器

#### 3. 應用程序信息
- **`microblog_app_info`**：應用程序版本和狀態
  - 標籤：版本

## 預配置儀表板

系統自動配置了一個 Microblog 監控儀表板，包括：

1. **HTTP 請求速率**（每分鐘請求數）
2. **請求延遲**（p95 百分位數）
3. **總 HTTP 請求計數**
4. **數據庫連接狀態**
5. **Redis 連接狀態**

## 自定義儀表板

### 添加新儀表板

1. 在 Grafana 中點擊「+」創建新儀表板
2. 添加面板，選擇 Prometheus 作為數據源
3. 編寫 PromQL 查詢以可視化指標

### 常用 PromQL 查詢

```promql
# 每秒的 HTTP 請求
rate(http_requests_total[1m])

# 請求延遲的 p95
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[1m]))

# 特定端點的失敗率
rate(http_requests_total{status=~"5.."}[1m])

# 數據庫連接狀態
db_connections_total

# Redis 可用性
redis_connections_total
```

## 告警配置

### 在 Prometheus 中設置告警

編輯 `prometheus.yml` 以添加告警規則：

```yaml
rule_files:
  - /etc/prometheus/rules/*.yml

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']
```

### 創建告警規則文件示例

創建 `prometheus-rules.yml`：

```yaml
groups:
- name: microblog
  rules:
  - alert: HighErrorRate
    expr: rate(http_requests_total{status=~"5.."}[1m]) > 0.05
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High error rate detected"
      description: "{{ $value }} errors per second"

  - alert: HighLatency
    expr: histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m])) > 1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Request latency is high"
      description: "p95 latency is {{ $value }}s"
```

## 故障排除

### Prometheus 無法連接到應用程序

1. 檢查該應用程序是否正在運行：`docker-compose ps`
2. 驗證 `/metrics` 端點是否可訪問：`curl http://localhost:8000/metrics`
3. 檢查 Prometheus 日誌：`docker-compose logs prometheus`

### Grafana 無法連接到 Prometheus

1. 檢查 Prometheus 是否正在運行：`docker-compose ps`
2. 在 Grafana 中驗證 Prometheus 數據源配置
3. 檢查網絡連接性：`docker-compose exec grafana curl http://prometheus:9090`

### 儀表板不顯示數據

1. 等待至少 15 秒以便 Prometheus 收集指標
2. 檢查時間範圍選擇器（在 Grafana 中默認為「最後 6 小時」）
3. 驗證查詢語法（檢查 Prometheus UI 中的 PromQL）

## 生產環境配置

### 安全性

1. 更改 Grafana 默認密碼
2. 使用反向代理（nginx/traefik）
3. 啟用 HTTPS
4. 限制 Prometheus `/metrics` 端點的訪問

### 性能調整

在 `docker-compose.yml` 中修改 Prometheus 配置：

```yaml
prometheus:
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--storage.tsdb.retention.time=30d'  # 保留 30 天數據
    - '--storage.tsdb.max-block-duration=2h'
```

### 存儲擴展

使用遠程存儲（如 Thanos、Cortex）進行長期數據保留：

```yaml
prometheus:
  command:
    - '--config.file=/etc/prometheus/prometheus.yml'
    - '--storage.tsdb.path=/prometheus'
    - '--storage.remote.write-url=http://remote-storage:9009/api/v1/write'
```

## 額外資源

- [Prometheus 文檔](https://prometheus.io/docs/)
- [Grafana 文檔](https://grafana.com/docs/)
- [PromQL 查詢語言](https://prometheus.io/docs/prometheus/latest/querying/basics/)

## 接下來的步驟

1. 根據業務需求自定義儀表板
2. 配置告警並將其集成到您的通知系統
3. 設置日誌聚合（ELK、Loki）以補充指標
4. 實施分布式追踪（Jaeger、Zipkin）進行深度分析
