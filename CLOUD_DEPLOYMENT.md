# 🚀 Microblog 项目 - 云部署指南

欢迎! 如果你想把这个项目部署到云端，请按照以下步骤操作:

## ⭐ 快速开始 (5分钟)

所有的云部署文件都已整理到 `cloud-deployment/` 文件夹中:

```bash
# 方式1: 进入云部署目录并查看快速指南
cd cloud-deployment
cat DEPLOYMENT_START_HERE.md    # 👈 从这里开始！

# 方式2: 直接运行本地测试
bash scripts/test-cloud-deployment.sh

# 方式3: 查看详细过程清单
cat DEPLOYMENT_CHECKLIST.md
```

---

## 📁 云部署文件结构

```
cloud-deployment/                    ← ⭐ 所有云部署文件在这里
│
├── 📋 DEPLOYMENT_START_HERE.md      ← 👈 从这里开始！（选择你的路线）
├── 🚀 QUICK_START.md                ← 5分钟快速指南
├── ✅ DEPLOYMENT_CHECKLIST.md       ← 完整分步清单（60分钟）
├── 📖 README.md                     ← 文件夹导航说明
├── 🐳 Dockerfile                    ← Docker镜像配置（已修复✨）
├── 🚫 .dockerignore                 
│
├── 🛠️ setup-env.sh                  ← 环境初始化脚本
├── 🔐 .env.cloud.example            ← 部署凭证模板
├── 🔐 .env.cloud                    ← 你的部署凭证（git忽略⭐）
│
├── scripts/                          ← ⚙️ 自动化脚本
│   ├── test-cloud-deployment.sh    (本地Docker测试)
│   ├── deploy-to-docker-hub.sh     (推送镜像到Docker Hub)
│   └── deploy-to-cloud-run.sh      (部署到Google Cloud Run)
│
└── config/                           ← ⚙️ 配置文件参考
    └── .env.gcp.example            (GCP环境变量参考)
```

**✨ 新增改进：**
- `DEPLOYMENT_START_HERE.md` - 帮助你选择合适的部署指南
- `setup-env.sh` - 自动初始化你的部署配置
- `.env.cloud` - 安全的本地凭证存储（git忽略）
- `Dockerfile` - 修复了权限问题，可直接部署

---

## 🎯 快速部署步骤

### 第一次部署（一次性）

**Step 1: 初始化部署环境**
```bash
cd cloud-deployment
bash setup-env.sh
nano .env.cloud  # 填入你的GCP项目ID、Docker Hub用户名、数据库URL等
```

**Step 2: 本地测试**
```bash
bash scripts/test-cloud-deployment.sh
```

### 常规部署流程

**Step 1: 加载环境变量**
```bash
source cloud-deployment/.env.cloud
```

**Step 2: 推送镜像到Docker Hub**
```bash
docker build -f cloud-deployment/Dockerfile -t $DOCKER_USERNAME/microblog:latest .
docker push $DOCKER_USERNAME/microblog:latest
```

**Step 3: 部署到Google Cloud Run**
```bash
gcloud run deploy microblog \
  --project=$GCP_PROJECT_ID \
  --image=$DOCKER_USERNAME/microblog:latest \
  --region=us-central1 \
  --allow-unauthenticated \
  --set-env-vars="DATABASE_URL=$DATABASE_URL,REDIS_URL=$REDIS_URL"
```

**Step 4: 完成！** 🎉
```bash
# 获取应用URL
gcloud run services describe microblog --project=$GCP_PROJECT_ID --format='value(status.url)'
```

⏱️ **部署耗时**: 
- 首次设置: 10分钟
- 常规部署: 5-10分钟

---

## 📚 根据你的情况选择文档

### 🏃 我有20分钟，想快速上线
👉 打开: `cloud-deployment/DEPLOYMENT_START_HERE.md`
👉 然后: `cloud-deployment/QUICK_START.md`

### 👨‍💼 我想每一步都验证成功
👉 打开: `cloud-deployment/DEPLOYMENT_CHECKLIST.md`
- 10个详细步骤
- 每步都有验证方法
- 耗时: 60分钟

**答案**: 完全免费! ($0/月在免费额度内)

### 👨‍🔧 我是DevOps，想深入了解
👉 打开: `cloud-deployment/DEPLOYMENT_CHECKLIST.md`
👉 或查看: `cloud-deployment/` 中的脚本源代码

---

## ⚡ 一行命令快速开始

```bash
# 从项目根目录运行
cd cloud-deployment && cat DEPLOYMENT_START_HERE.md
```

然后按照指南操作！

---

## 💰 成本预算

| 服务 | 免费额度 | 月费 |
|------|---------|------|
| Google Cloud Run | 2M请求/月 + 50万GB-秒 | $0 |
| Neon PostgreSQL | 512MB存储 | $0 |
| Upstash Redis | 10K命令/天 | $0 |
| Cloudflare | 无限请求 | $0 |
| **总计** | | **$0/月** |

---

## 📖 文档导航

| 文件 | 关键内容 | 推荐给 |
|------|--------|--------|
| [DEPLOYMENT_START_HERE.md](cloud-deployment/DEPLOYMENT_START_HERE.md) | 选择你的路线 | **所有人** ⭐ |
| [QUICK_START.md](cloud-deployment/QUICK_START.md) | 5分钟快速启动 | 想快速上线的人 |
| [DEPLOYMENT_CHECKLIST.md](cloud-deployment/DEPLOYMENT_CHECKLIST.md) | 10步完整清单 | 想边验证边做的人 |
| [README.md](cloud-deployment/README.md) | 文件夹导航 | 所有人 |
| [setup-env.sh](cloud-deployment/setup-env.sh) | 环境初始化脚本 | 第一次部署 |

---

## 🔐 部署前的安全检查

- [ ] 创建强密码
- [ ] 不在Git中提交 .env.cloud
- [ ] 启用 Cloudflare WAF
- [ ] 定期轮换密钥
- [ ] 监控日志

---

## ✅ 完整的检查清单

**部署前:**
- [ ] 阅读 `cloud-deployment/DEPLOYMENT_START_HERE.md`
- [ ] 创建云账户 (Google Cloud, Neon, Upstash)
- [ ] Docker已安装
- [ ] gcloud CLI已安装

**部署:** 
- [ ] 运行 `bash cloud-deployment/setup-env.sh`
- [ ] 编辑 `.env.cloud` 填入凭证
- [ ] 运行本地测试脚本
- [ ] 推送Docker镜像
- [ ] 部署到Cloud Run

**部署后:**
- [ ] 测试应用可用性
- [ ] 检查日志
- [ ] 设置监控

---

## 🎓 推荐学习路径

### 快速上线 (20分钟)
1. 查看: `cloud-deployment/DEPLOYMENT_START_HERE.md`
2. 按步骤: `cloud-deployment/QUICK_START.md`
3. 完成 ✅

### 稳妥部署 (60分钟)
1. 查看: `cloud-deployment/DEPLOYMENT_START_HERE.md`
2. 执行: `bash cloud-deployment/setup-env.sh`
3. 按照: `cloud-deployment/DEPLOYMENT_CHECKLIST.md`
4. 完成 ✅

---

## 💡 快速提示

- **第一次部署**: 从 `DEPLOYMENT_START_HERE.md` 开始
- **问题排查**: 查看相应文档的常见问题部分
- **后续更新**: 加载 `.env.cloud` 后使用部署脚本
- **成本监控**: 在Google Cloud Console中设置预算告警

---

## 🎉 准备好了吗?

执行这个命令开始：

```bash
cd cloud-deployment
bash setup-env.sh
```

然后编辑 `.env.cloud` 填入你的凭证，按照 `DEPLOYMENT_START_HERE.md` 操作即可！

**30分钟内，你的应用将上线，完全免费！** 🚀

---

## 📞 需要帮助?

1. **不知道从何开始**: 查看 `cloud-deployment/DEPLOYMENT_START_HERE.md`
2. **想快速部署**: 查看 `cloud-deployment/QUICK_START.md`  
3. **想每步验证**: 查看 `cloud-deployment/DEPLOYMENT_CHECKLIST.md`
4. **遇到问题**: 查看文档中的常见问题部分
- 📊 架构理解: `cloud-deployment/docs/DEPLOYMENT_SUMMARY.md`
- 🗂️ 文件导航: `cloud-deployment/README.md`

祝你部署顺利! 🚀

---

**版本**: 1.0  
**日期**: 2026-03-10  
**状态**: ✅ 所有部署文件已完成并整理
