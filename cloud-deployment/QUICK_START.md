# 🚀 5分钟快速上云指南

> 最精简的部署流程 - 从代码到线上只需5个步骤

---

## 📊 部署流程图

```
┌──────────────────────────────────────────────────────────────┐
│ 1️⃣  本地测试     │ 2️⃣  推送到Docker Hub │ 3️⃣  配置云数据库 │
│  (10分钟)        │     (15分钟)         │   (5分钟)      │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────────────────────────────────────────────────────┐
│ 4️⃣  部署到Cloud Run  │ 5️⃣  配置域名(可选) │ ✅ 完成！     │
│  (10分钟)            │    (5分钟)         │              │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 四条命令快速部署

如果你赶时间，就按这四条命令执行（假设已装Docker和gcloud CLI）：

```bash
# 【第0步】进入项目目录
cd ~/fromGithub/microblog

# 【第1步】本地测试Docker镜像 (~10分钟)
bash cloud-deployment/scripts/test-cloud-deployment.sh

# 【第2步】推送到Docker Hub (~15分钟)
export DOCKER_USERNAME="你的_docker_hub_用户名"
docker login
docker build -f cloud-deployment/Dockerfile -t $DOCKER_USERNAME/microblog:latest .
docker push $DOCKER_USERNAME/microblog:latest

# 【第3步】设置云数据库凭证 (~5分钟)
# 创建Neon PostgreSQL: https://neon.tech → Create project → 复制连接字符串
# 创建Upstash Redis: https://upstash.com → Create database → 复制Redis URL
export DB_URL="复制的Neon连接字符串"
export REDIS_URL="复制的Upstash Redis URL"

# 【第4步】部署到Cloud Run (~10分钟)
export GCP_PROJECT_ID="你的_GCP项目ID"
gcloud run deploy microblog \
  --image=$DOCKER_USERNAME/microblog:latest \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --memory=512Mi \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=$DB_URL,REDIS_URL=$REDIS_URL,FLASK_ENV=production,LOG_TO_STDOUT=true,RUN_MIGRATIONS=true"

# 【完成！】获取应用URL
gcloud run services describe microblog --project=$GCP_PROJECT_ID --region=us-central1 --format='value(status.url)'
```

---

## 📋 **必须做的5件事**

按这个顺序做就行：

### 1️⃣ **本地Docker测试** (10分钟)
```bash
cd ~/fromGithub/microblog
bash cloud-deployment/scripts/test-cloud-deployment.sh
```
✅ 如果看到 "All Tests Passed!" 就可以继续

---

### 2️⃣ **创建Docker Hub账户并推送镜像** (15分钟)

**在浏览器打开：** https://hub.docker.com
- 注册或登录
- 创建一个Public Repository叫 `microblog`
- 记住你的用户名

**在终端执行：**
```bash
# 设置你的用户名
export DOCKER_USERNAME="你的docker_hub_用户名"

# 登录Docker
docker login
# 输入你的Docker Hub用户名和密码

# 进入项目目录
cd ~/fromGithub/microblog

# 构建镜像 (会比较慢，~ 10分钟)
docker build -f cloud-deployment/Dockerfile -t $DOCKER_USERNAME/microblog:latest .

# 推送镜像 (根据网速可能5-10分钟)
docker push $DOCKER_USERNAME/microblog:latest

# 验证推送成功
docker pull $DOCKER_USERNAME/microblog:latest
```

✅ 看到 "Successfully pulled" 说明成功

---

### 3️⃣ **创建云数据库** (5分钟)

**创建Neon PostgreSQL：**
- 打开 https://neon.tech
- 使用GitHub/Google账户登录
- "Create a project"
- 复制连接字符串，类似：
  ```
  postgresql://user:password@ep-xxxxx.neon.tech/neondb?sslmode=require
  ```

**创建Upstash Redis：**
- 打开 https://upstash.com
- 使用GitHub/Google账户登录
- "Create Database" → Redis → Free
- 复制Redis URL，类似：
  ```
  redis://:password@hostname:port
  ```

**在终端保存这两个凭证：**
```bash
export DB_URL="粘贴你的Neon连接字符串"
export REDIS_URL="粘贴你的Upstash Redis URL"

# 验证没有遗漏
echo "DB: ${DB_URL:0:50}..."
echo "Redis: ${REDIS_URL:0:50}..."
```

---

### 4️⃣ **在Google Cloud创建项目** (5分钟)

**第一次部署前的一次性设置：**

```bash
# 1. 打开 https://console.cloud.google.com
#    - 右上角 "Select Project" → "NEW PROJECT"
#    - 名称: microblog-production
#    - 点 "CREATE"
#    - 等待创建完成

# 2. 获取项目ID（记住！）
#    在项目列表中查看项目ID，例如：microblog-production-abc123

# 3. 在终端设置项目ID
export GCP_PROJECT_ID="你的项目ID"

# 4. 启用必要的服务
gcloud services enable run.googleapis.com --project=$GCP_PROJECT_ID
gcloud services enable containerregistry.googleapis.com --project=$GCP_PROJECT_ID
```

---

### 5️⃣ **部署到Cloud Run** (10分钟)

**执行部署命令：**
```bash
# 确保所有变量已设置
echo "Project: $GCP_PROJECT_ID"
echo "Image: $DOCKER_USERNAME/microblog:latest"
echo "DB: ${DB_URL:0:50}..."

# 执行部署
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
RUN_MIGRATIONS=true"
```

⏳ 等待部署完成（通常2-5分钟）... 

✅ 看到类似这样的输出：
```
✓ Revision 'microblog-00001-abc' deployed successfully
Service URL: https://microblog-xxxxx.run.app
```

---

## 🔍 验证部署成功

```bash
# 获取应用URL
export SERVICE_URL=$(gcloud run services describe microblog \
  --project=$GCP_PROJECT_ID \
  --region=us-central1 \
  --format='value(status.url)')

# 测试应用是否正常运行
curl -I $SERVICE_URL
# 应该看到 HTTP/1.1 200 OK

# 测试健康检查
curl $SERVICE_URL/health
# 应该看到 {"status":"ok"}

# 在浏览器打开查看：
echo "应用URL: $SERVICE_URL"
```

在浏览器中打开 URL，应该能看到你的微博应用！

---

## 🌐 配置域名 (可选)

如果你有自己的域名，想让应用在自己的域名上运行：

```bash
# 1. 打开 https://dash.cloudflare.com
#    - 添加你的域名
#    - 按说明修改域名的NS记录

# 2. 在Cloudflare中添加CNAME记录：
#    名称: www (或 @)
#    内容: microblog-xxxxx.run.app
#    TTL: Auto
#    Proxy状态: 可选

# 3. 等待10-20分钟后，访问你的域名测试
```

---

## 📊 成本

✅ **完全免费！** 在自由配额内：

| 服务 | 免费额度 | 你的用量 |
|------|--------|--------|
| Cloud Run | 200万 API调用/月 | ~10万(小应用) |
| Neon PostgreSQL | 免费 | 足够 |
| Upstash Redis | 10K命令/天 | 足够 |
| **总成本** | - | **$0/月** |

---

## 🆘 遇到问题？

### "镜像拉取失败"
```bash
# 检查镜像是否推送成功
docker pull $DOCKER_USERNAME/microblog:latest
# 应该显示 "Successfully pulled ..."
```

### "Health check 失败"
```bash
# 查看详细错误日志
gcloud run logs read microblog --project=$GCP_PROJECT_ID --limit 50
```

### "Permission denied"
```bash
# 重新登录Google账户
gcloud auth login
gcloud config set project $GCP_PROJECT_ID
```

### "Port already in use" (本地测试时)
```bash
# 释放端口
lsof -ti:5000 | xargs kill -9
```

---

## 📚 更详细的说明

如果需要更详细的步骤说明，查看：
- [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md) - 完整的分步清单（含验证）
- [`CLOUD_DEPLOYMENT_GUIDE.md`](./docs/CLOUD_DEPLOYMENT_GUIDE.md) - 详细的技术指南

---

## ✅ 部署完成后的下一步

1. **监控应用**
   ```bash
   gcloud run logs read microblog --project=$GCP_PROJECT_ID --follow
   ```

2. **更新应用**
   - 修改代码 → 提交Git
   - 重新构建镜像 → 推送到Docker Hub
   - 部署新版本到Cloud Run（使用第5️⃣步的命令）

3. **优化性能**
   - 监控Cloud Run的CPU和内存使用
   - 根据需要调整`--memory`参数

---

## 🎉 成功了！

你的Flask微博应用现在运行在**Google Cloud Run**上，完全免费，自动扩展，世界各地都可以访问！

**现在可以：**
- ✅ 分享你的应用URL
- ✅ 继续开发新功能
- ✅ 专注于产品而不是服务器管理
