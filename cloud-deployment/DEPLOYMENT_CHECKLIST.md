# ☁️ Google Cloud Run 部署操作清单

> 按照本清单依次执行每一步，确保上云成功

---

## 📋 第0步: 前置检查 (5分钟)

### 本地环境检查
```bash
# 进入项目目录
cd ~/fromGithub/microblog

# 检查Docker是否安装
docker --version
# 预期: Docker version 20.10+

# 检查gcloud CLI是否安装
gcloud --version
# 预期: Google Cloud SDK version

# 如果没有，安装gcloud CLI
# macOS: brew install google-cloud-sdk
# Linux: curl https://sdk.cloud.google.com | bash

# 初始化gcloud
gcloud init
```

### ✅ 检查清单
- [ ] Docker已安装并可运行
- [ ] gcloud CLI已安装
- [ ] 已登录Google账户 (`gcloud auth list`)
- [ ] GCP项目已创建

---

## 📝 第1步: 本地Docker测试 (10分钟)

### 1.1 运行测试脚本

```bash
cd ~/fromGithub/microblog

# 给脚本执行权限
chmod +x cloud-deployment/scripts/test-cloud-deployment.sh

# 运行测试
bash cloud-deployment/scripts/test-cloud-deployment.sh
```

### ✅ 预期输出
```
Testing Docker image build...
✅ Docker build successful
Image size: ~500MB
✅ All Tests Passed!
```

### ❌ 如果测试失败
```bash
# 查看详细错误信息
docker build -f cloud-deployment/Dockerfile -t microblog-test:latest .

# 常见问题：
# - 磁盘空间不足：docker system prune
# - Python依赖冲突：删除虚拟环境重建
```

### ✅ 检查清单
- [ ] Docker镜像构建成功
- [ ] 本地测试通过

---

## 🐳 第2步: 推送到Docker Hub (15分钟)

### 2.1 创建Docker Hub账户
1. 访问 https://hub.docker.com
2. 使用邮箱注册或GitHub登录
3. 创建一个新Repository (保持为Public):
   - Repository名称: `microblog`
   - Description: `Flask microblog application`

### 2.2 获取Docker Hub用户名

```bash
# 记住你的Docker Hub用户名，如: yaouser
export DOCKER_USERNAME="your_actual_docker_username"
echo $DOCKER_USERNAME
```

### 2.3 本地登录Docker Hub

```bash
docker login
# 输入Docker Hub用户名和密码
```

### ✅ 验证登录
```bash
# 如果没有错误，说明登录成功
echo $DOCKER_USERNAME
```

### 2.4 构建和推送镜像

```bash
# 进入项目目录
cd ~/fromGithub/microblog

# 设置变量（替换为你的用户名）
export DOCKER_USERNAME="your_actual_docker_username"

# 构建镜像
echo "🔨 Building Docker image..."
docker build -f cloud-deployment/Dockerfile -t $DOCKER_USERNAME/microblog:latest .

# 推送到Docker Hub
echo "⬆️ Pushing to Docker Hub..."
docker push $DOCKER_USERNAME/microblog:latest

# 验证推送成功
echo "✅ Verifying push..."
docker pull $DOCKER_USERNAME/microblog:latest
```

### ✅ 预期输出
```
Pushed image successfully
Latest: 154.8MB compressed
Successfully pulled $DOCKER_USERNAME/microblog:latest
```

### ✅ 检查清单
- [ ] Docker Hub账户已创建
- [ ] 本地已登录Docker Hub
- [ ] 镜像已全部推送 (可在Docker Hub网站上看到)

---

## 🗄️ 第3步: 设置Neon PostgreSQL数据库 (5分钟)

### 3.1 创建Neon账户

1. 访问 https://neon.tech
2. 使用GitHub/Google账户注册
3. 点击 "Create a project"

### 3.2 创建数据库并获取连接字符串

1. 在Neon项目中点击 "Database"
2. 默认会创建一个 `neondb_owner` 用户
3. 在 "Connection string" 中选择 "Pooled connection"
4. 复制连接字符串，格式如下：

```
postgresql://user:password@ep-xxxxx.xx.neon.tech/neondb?sslmode=require
```

### 3.3 保存连接字符串

```bash
# 在项目根目录创建临时文件记录（不要commit）
cat > /tmp/neon_credentials.txt << 'EOF'
DATABASE_URL=postgresql://user:password@ep-xxxxx.xx.neon.tech/neondb?sslmode=require
EOF

# 查看内容确认无误
cat /tmp/neon_credentials.txt
```

### ✅ 验证数据库连接

```bash
# 在本地测试连接
psql "postgresql://user:password@ep-xxxxx.xx.neon.tech/neondb?sslmode=require" -c "SELECT version();"
```

### ✅ 检查清单
- [ ] Neon账户已创建
- [ ] PostgreSQL数据库已创建
- [ ] 连接字符串已复制并保存

---

## 💾 第4步: 设置Upstash Redis (5分钟)

### 4.1 创建Upstash账户

1. 访问 https://upstash.com
2. 使用GitHub/Google账户注册
3. 进入控制面板 (Console)

### 4.2 创建Redis实例

1. 点击 "Create Database"
2. 选择Redis
3. 选择 "Free" 计划（Monthly: $0）
4. Region: 选择离你最近的region
5. 点击 "Create"

### 4.3 获取Redis连接信息

1. 进入创建好的Redis实例
2. 点击 "Details"
3. 获取连接URL，格式如下：

```
redis://:password@hostname:port
```

或在 "REST API" 标签中：

```
https://your-redis-url.upstash.io
```

### 4.4 保存Redis连接字符串

```bash
# 追加到临时文件
cat >> /tmp/neon_credentials.txt << 'EOF'
REDIS_URL=redis://:password@hostname:port
EOF

# 查看所有凭证
cat /tmp/neon_credentials.txt
```

### ✅ 验证Redis连接

```bash
# 使用redis-cli测试连接（需要装redis）
# 或者简单地在后续部署中验证
```

### ✅ 检查清单
- [ ] Upstash账户已创建
- [ ] Redis实例已创建
- [ ] 连接字符串已复制并保存

---

## 🔐 第5步: 创建Google Cloud项目 (5分钟)

### 5.1 创建GCP项目

1. 访问 https://console.cloud.google.com
2. 点击左上角 "Select a project"
3. 点击 "NEW PROJECT"
4. 项目名称: `microblog-production`
5. 点击 "CREATE"

### 5.2 获取项目ID

```bash
# 在我的项目列表中找到新创建的项目
# 记下项目ID（与名称可能不同）

# 设置本地变量
export GCP_PROJECT_ID="microblog-production-ab1234"
echo $GCP_PROJECT_ID
```

### 5.3 启用必要的服务

```bash
# 启用Cloud Run API
gcloud services enable run.googleapis.com --project=$GCP_PROJECT_ID

# 启用Container Registry API
gcloud services enable containerregistry.googleapis.com --project=$GCP_PROJECT_ID

# 预期输出: Operation "... " finished successfully
```

### ✅ 检查清单
- [ ] GCP项目已创建
- [ ] 项目ID已记录
- [ ] Cloud Run API已启用

---

## 🚀 第6步: 部署到Google Cloud Run (10分钟)

### 6.1 准备部署所需的环境变量

```bash
# 设置所有变量（替换为你自己的值）
export GCP_PROJECT_ID="microblog-production-ab1234"
export DOCKER_USERNAME="your_actual_docker_username"
export DB_URL="postgresql://user:password@ep-xxxxx.xx.neon.tech/neondb?sslmode=require"
export REDIS_URL="redis://:password@hostname:port"

# 验证所有变量
echo "GCP Project: $GCP_PROJECT_ID"
echo "Docker Image: $DOCKER_USERNAME/microblog:latest"
echo "DB URL: ${DB_URL:0:50}..."
echo "Redis URL: ${REDIS_URL:0:50}..."
```

### 6.2 执行部署

```bash
gcloud run deploy microblog \
  --project=$GCP_PROJECT_ID \
  --image=$DOCKER_USERNAME/microblog:latest \
  --platform managed \
  --region us-central1 \
  --memory 512Mi \
  --timeout 300 \
  --allow-unauthenticated \
  --set-env-vars="\
DATABASE_URL=$DB_URL,\
REDIS_URL=$REDIS_URL,\
FLASK_ENV=production,\
LOG_TO_STDOUT=true,\
RUN_MIGRATIONS=true" \
  --source . \
  2>&1 | tee /tmp/deploy_output.txt
```

### ⏳ 等待部署完成

```
Deploying...
✓ Creating Revision
✓ Routing traffic
✓ Done
```

### 6.3 获取Cloud Run服务URL

```bash
# 从输出中复制Service URL，或运行：
gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)'

# 输出示例: https://microblog-xxxxx.run.app
```

### ✅ 验证部署成功

```bash
# 获取服务URL
export SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

# 测试服务是否正常响应
curl -I $SERVICE_URL
# 预期: HTTP/1.1 200 OK

# 检查健康检查端点
curl $SERVICE_URL/health
# 预期: {"status":"ok"}
```

### ✅ 检查清单
- [ ] 部署命令执行成功
- [ ] 获得了Cloud Run URL
- [ ] 健康检查端点 (`/health`) 返回 200
- [ ] 首页可以访问

---

## 🌐 第7步: 域名配置 (可选，5-15分钟)

### 7.1 如果你有自己的域名

```bash
# 1. 在Cloudflare添加域名 (https://dash.cloudflare.com)
# 2. 更新域名的NS记录指向Cloudflare
# 3. 在Cloudflare DNS中添加CNAME记录：
#    名称: www (或 @)
#    内容: microblog-xxxxx.run.app
#    TTL: Auto
#    代理状态: 已代理 (或不代理)
```

### 7.2 验证域名

```bash
# 等待10-20分钟后测试
curl https://yourdomain.com
```

### ✅ 检查清单
- [ ] Cloudflare域名已添加
- [ ] DNS记录已配置
- [ ] 域名解析正常

---

## 📊 第8步: 验证应用功能 (10分钟)

### 8.1 测试核心功能

```bash
# 获取Service URL
export SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

# 测试1: 首页
echo "✓ 测试首页..."
curl $SERVICE_URL

# 测试2: 健康检查
echo "✓ 测试健康检查..."
curl $SERVICE_URL/health

# 测试3: API端点
echo "✓ 测试API端点..."
curl $SERVICE_URL/api/users

# 测试4: 查看日志
echo "✓ 查看最新日志..."
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 50
```

### ✅ 检查清单
- [ ] 首页返回200
- [ ] `/health` 端点正常
- [ ] API端点正常
- [ ] 日志输出无错误

---

## 🔄 第9步: 设置自动部署 (推荐，5分钟)

使用提供的部署脚本自动化后续部署：

```bash
cd ~/fromGithub/microblog

# 查看可用的部署脚本
ls -la cloud-deployment/scripts/

# 下次更新代码后，使用脚本快速部署：
bash cloud-deployment/scripts/deploy-to-cloud-run.sh
```

### ✅ 检查清单
- [ ] 了解部署脚本的位置和用法

---

## 📈 第10步: 监控和日志 (推荐)

### 10.1 实时查看日志

```bash
# 查看最新N条日志
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 100

# 持续跟踪日志
gcloud run logs read microblog --project=$GCP_PROJECT_ID --follow
```

### 10.2 设置警报

在Google Cloud Console:
1. 访问 "Cloud Run" → "microblog"
2. 点击 "Metrics"
3. 监控以下指标：
   - Request count
   - Error rate
   - Latency

### ✅ 检查清单
- [ ] 能够查看实时日志
- [ ] 了解如何查找错误

---

## 🎯 快速参考

### 常用命令

```bash
# 查看应用日志
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 50

# 查看应用详情
gcloud run services describe microblog --project=$GCP_PROJECT_ID

# 查看部署历史
gcloud run revisions list --filter="SERVICE:microblog" --project=$GCP_PROJECT_ID

# 更新应用
gcloud run deploy microblog --image $DOCKER_USERNAME/microblog:latest --project=$GCP_PROJECT_ID

# 查看成本
# https://console.cloud.google.com/billing
```

### 部署变更工作流

```bash
# 1. 修改代码
# 2. 提交到Git
git add .
git commit -m "description"

# 3. 构建新镜像并推送
docker build -f cloud-deployment/Dockerfile -t $DOCKER_USERNAME/microblog:latest .
docker push $DOCKER_USERNAME/microblog:latest

# 4. 在Cloud Run中更新镜像
gcloud run deploy microblog \
  --image=$DOCKER_USERNAME/microblog:latest \
  --project=$GCP_PROJECT_ID
```

---

## ❓ 常见问题

### Q: 部署过程中出现"镜像拉取失败"
**A:** 检查Docker镜像是否正确推送到Docker Hub
```bash
docker pull $DOCKER_USERNAME/microblog:latest
```

### Q: Health check 失败
**A:** 检查数据库连接
```bash
# 查看日志了解具体错误
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 20
```

### Q: "Permission denied" 错误
**A:** 确保已授权gcloud访问GCP
```bash
gcloud auth login
gcloud config set project $GCP_PROJECT_ID
```

### Q: 成本会不会超出预算
**A:** 在免费额度内：Cloud Run 200万请求/月足够，Redis和PostgreSQL也都在免费额度内

---

## ✅ 部署完成检查清单

所有步骤完成后，验证：

- [ ] 已成功通过第0-10步
- [ ] Cloud Run应用正常运行
- [ ] 数据库和Redis连接成功
- [ ] 应用日志无重大错误
- [ ] 可通过公网URL访问应用
- [ ] 了解如何更新应用（重新部署）

---

## 🎉 恭喜！

你的Flask微博应用现在运行在Google Cloud Run上，完全免费！

**下一步：**
1. 定期检查日志和监控
2. 定期部署代码更新
3. 根据需要调整资源配置

**有问题？** 查看 `CLOUD_DEPLOYMENT_GUIDE.md` 获取更详细的说明。
