# ☁️ Cloud Deployment - 云部署完整方案

> Microblog 项目 Google Cloud Run + Cloudflare 部署方案

## 📁 目录结构

```
cloud-deployment/
├── README.md (本文件)
├── Dockerfile (多阶段构建优化)
├── .dockerignore (减少构建上下文)
│
├── docs/
│   ├── QUICK_START.md ⭐ 【从这里开始!】
│   ├── CLOUD_DEPLOYMENT_GUIDE.md (50+页详细指南)
│   ├── DEPLOYMENT_SUMMARY.md (部署总结)
│   ├── DEPLOYMENT_QUICK_REFERENCE.md (快速参考卡)
│   ├── CLOUD_DEPLOYMENT_PLAN.md (部署计划)
│   └── DEPLOYMENT_COMPLETED.txt (完成报告)
│
├── scripts/
│   ├── test-cloud-deployment.sh ✓ (本地测试)
│   ├── deploy-to-docker-hub.sh ✓ (推送到Docker Hub)
│   └── deploy-to-cloud-run.sh ✓ (一键部署到Cloud Run)
│
└── config/
    └── .env.gcp.example (环境变量模板)
```

---

## 🎯 快速开始 (5分钟)

### 1️⃣ 先读这个:
```bash
cat docs/QUICK_START.md
```

### 2️⃣ 本地测试:
```bash
cd ../.. # 返回项目根目录
chmod +x cloud-deployment/scripts/test-cloud-deployment.sh
./cloud-deployment/scripts/test-cloud-deployment.sh
```

### 3️⃣ 推送到Docker Hub:
```bash
chmod +x cloud-deployment/scripts/deploy-to-docker-hub.sh
./cloud-deployment/scripts/deploy-to-docker-hub.sh YOUR_DOCKER_USERNAME latest
```

### 4️⃣ 部署到Google Cloud Run:
```bash
chmod +x cloud-deployment/scripts/deploy-to-cloud-run.sh
cp cloud-deployment/config/.env.gcp.example .env.gcp
nano .env.gcp  # 编辑填入数据库和Redis URL
./cloud-deployment/scripts/deploy-to-cloud-run.sh YOUR_GCP_PROJECT YOUR_DOCKER_USERNAME/microblog:latest
```

---

## 📚 文档导航

### 根据你的角色选择:

#### 👤 完全小白 / 快速上线
```
docs/QUICK_START.md
  → 5分钟快速启动
  → 按照步骤执行即可上线
```

#### 👨‍💼 创业者 / 小企业主
```
docs/QUICK_START.md (快速启动)
  ↓
docs/DEPLOYMENT_QUICK_REFERENCE.md (快速查询)
  → 常用命令速查
  → 成本监控建议
  → 安全提示
```

#### 👨‍🔧 DevOps工程师 / 技术负责人
```
docs/DEPLOYMENT_SUMMARY.md (架构理解)
  ↓
docs/CLOUD_DEPLOYMENT_GUIDE.md (深入细节)
  → 完整的部署步骤
  → 故障排除指南
  → 性能优化建议
  → 成本控制策略
```

#### 🔍 遇到问题需要帮助
```
docs/CLOUD_DEPLOYMENT_GUIDE.md
  → 搜索 "🆘 故障排除" 部分
  → 找到你遇到的问题
  → 按照解决方案操作
```

---

## 🚀 三种部署方式

### 方式1: 完全自动化 (推荐)
```bash
# 从项目根目录运行
cd /path/to/microblog
./cloud-deployment/scripts/deploy-to-cloud-run.sh PROJECT_ID USER/IMAGE:TAG
```

### 方式2: 分步骤执行 (学习用)
```bash
# Step 1: 本地测试
./cloud-deployment/scripts/test-cloud-deployment.sh

# Step 2: 推送镜像
./cloud-deployment/scripts/deploy-to-docker-hub.sh YOUR_USERNAME latest

# Step 3: 部署应用
./cloud-deployment/scripts/deploy-to-cloud-run.sh YOUR_PROJECT YOUR_USERNAME/microblog:latest
```

### 方式3: 手动配置 (深度定制)
```bash
# 使用Dockerfile手动构建
docker build -f cloud-deployment/Dockerfile -t microblog:latest .

# 参考scripts/中的脚本逻辑进行自定义配置
# 参考docs/CLOUD_DEPLOYMENT_GUIDE.md的详细步骤
```

---

## 💰 成本预估

| 服务 | 免费额度 | 月费 |
|------|--------|------|
| Google Cloud Run | 2M请求、50万GB-s | $0 |
| Neon PostgreSQL | 512MB存储 | $0 |
| Upstash Redis | 10K命令/天 | $0 |
| Cloudflare | 无限请求 | $0 |
| **总计** | | **$0/月** |

---

## 🔐 使用前的安全检查清单

- [ ] 不在Git中提交 .env.gcp 文件
- [ ] 不在Git中提交 Dockerfile 中的敏感信息
- [ ] 使用 Secret Manager 存储API密钥
- [ ] 启用 Cloudflare WAF 防护
- [ ] 定期轮换 Secret 密钥
- [ ] 监控异常访问日志

---

## ✅ 完整的检查清单

### 部署前
- [ ] 阅读 docs/QUICK_START.md
- [ ] 创建必要的云账户 (Google Cloud, Neon, Upstash, Cloudflare)
- [ ] 确保Docker已安装
- [ ] 修改 config/.env.gcp.example 为 .env.gcp
- [ ] 填入数据库和Redis连接URL

### 部署中
- [ ] 运行 scripts/test-cloud-deployment.sh
- [ ] 推送镜像到Docker Hub
- [ ] 部署到Google Cloud Run
- [ ] 配置Cloudflare DNS

### 部署后
- [ ] 测试应用可用性 (curl /health)
- [ ] 检查日志没有错误
- [ ] 验证数据库连接正常
- [ ] 性能测试 (响应时间 < 1秒)
- [ ] 配置监控告警

---

## 🎓 学习资源

### 官方文档
- [Google Cloud Run](https://cloud.google.com/run/docs)
- [Cloudflare API](https://developers.cloudflare.com)
- [Neon PostgreSQL](https://neon.tech/docs)
- [Upstash Redis](https://upstash.com/docs)

### 本项目文档
```
docs/
├── QUICK_START.md → 5分钟快速启动
├── CLOUD_DEPLOYMENT_GUIDE.md → 50+页详细指南
├── DEPLOYMENT_SUMMARY.md → 部署架构总结
├── DEPLOYMENT_QUICK_REFERENCE.md → 常用命令查询
└── CLOUD_DEPLOYMENT_PLAN.md → 原始部署计划
```

---

## 📞 常见问题

### Q: 为什么把部署文件单独放在一个文件夹?
**A:** 
- 保持项目结构清晰
- 便于维护和更新
- 便于团队理解
- 敏感配置文件集中管理

### Q: 可以直接在这个文件夹运行脚本吗?
**A:** 
不建议。脚本需要在项目根目录运行，因为它们需要访问项目的代码文件:
```bash
# ✓ 正确做法 (从项目根目录)
./cloud-deployment/scripts/test-cloud-deployment.sh

# ✗ 错误做法 (从脚本所在目录)
cd cloud-deployment/scripts/
./test-cloud-deployment.sh
```

### Q: 如何自定义部署配置?
**A:**
1. 复制 config/.env.gcp.example 为 .env.gcp
2. 编辑环境变量
3. 脚本会自动读取 .env.gcp

### Q: Docker镜像放在哪里?
**A:** 
Dockerfile 在 cloud-deployment/ 根目录
```bash
docker build -f cloud-deployment/Dockerfile -t microblog:latest .
```

---

## 🔄 工作流程

```
┌─────────────────────────────────────────────────────────┐
│  1. 本地开发和测试                                       │
│     (修改代码 → 本地测试)                                │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  2. 运行本地Docker测试                                   │
│     ./cloud-deployment/scripts/test-cloud-deployment.sh│
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  3. 构建和推送Docker镜像                                 │
│     ./cloud-deployment/scripts/deploy-to-docker-hub.sh │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  4. 部署到Google Cloud Run                              │
│     ./cloud-deployment/scripts/deploy-to-cloud-run.sh  │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  5. 配置Cloudflare和DNS                                 │
│     (浏览器中完成)                                       │
└──────────────┬──────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────┐
│  6. 产品上线 🎉                                          │
│     应用现在运行在生产环境中                              │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 下一步

1. **阅读**: `docs/QUICK_START.md`
2. **测试**: `scripts/test-cloud-deployment.sh`
3. **上线**: `scripts/deploy-to-cloud-run.sh`
4. **配置**: Cloudflare DNS
5. **验证**: 应用访问测试

---

## 📄 文件说明

### 📖 文档 (docs/)

| 文件 | 用途 | 读者 |
|------|------|------|
| [QUICK_START.md](docs/QUICK_START.md) | 5分钟快速启动 | 所有人 ⭐ |
| [CLOUD_DEPLOYMENT_GUIDE.md](docs/CLOUD_DEPLOYMENT_GUIDE.md) | 50+页详细指南 | DevOps/技术负责 |
| [DEPLOYMENT_SUMMARY.md](docs/DEPLOYMENT_SUMMARY.md) | 部署总结 | 架构师/决策者 |
| [DEPLOYMENT_QUICK_REFERENCE.md](docs/DEPLOYMENT_QUICK_REFERENCE.md) | 快速查询卡 | 日常主动 |
| [CLOUD_DEPLOYMENT_PLAN.md](docs/CLOUD_DEPLOYMENT_PLAN.md) | 部署计划 | 项目管理 |
| [DEPLOYMENT_COMPLETED.txt](docs/DEPLOYMENT_COMPLETED.txt) | 完成报告 | 参考资料 |

### 🔧 脚本 (scripts/)

| 脚本 | 功能 | 耗时 |
|------|------|------|
| [test-cloud-deployment.sh](scripts/test-cloud-deployment.sh) | 本地Docker测试 | 3-5分钟 |
| [deploy-to-docker-hub.sh](scripts/deploy-to-docker-hub.sh) | 推送到Docker Hub | 2-3分钟 |
| [deploy-to-cloud-run.sh](scripts/deploy-to-cloud-run.sh) | 部署到Cloud Run | 3-5分钟 |

### ⚙️ 配置 (config/)

| 文件 | 用途 |
|------|------|
| [.env.gcp.example](config/.env.gcp.example) | 环境变量模板 |

### 🐳 Docker配置

| 文件 | 用途 |
|------|------|
| [Dockerfile](Dockerfile) | 多阶段构建配置 |
| [.dockerignore](.dockerignore) | 构建优化配置 |

---

## 🎉 成功指标

✅ Docker镜像成功构建  
✅ 镜像推送到Docker Hub  
✅ 应用部署到Cloud Run  
✅ /health 端点响应 200 OK  
✅ Cloudflare DNS解析正确  
✅ HTTPS证书生效  
✅ 应用功能测试通过  
✅ 监控告警配置完成  

---

## 💡 建议

1. **第一次部署**: 按照 docs/QUICK_START.md 的步骤逐个执行
2. **遇到问题**: 查阅 docs/CLOUD_DEPLOYMENT_GUIDE.md 的故障排除部分
3. **日常运维**: 使用 docs/DEPLOYMENT_QUICK_REFERENCE.md 查询常用命令
4. **性能优化**: 阅读 docs/CLOUD_DEPLOYMENT_GUIDE.md 的优化部分
5. **成本控制**: 定期查看 docs/DEPLOYMENT_QUICK_REFERENCE.md 的成本监控

---

## 📞 需要帮助?

- 🚀 **快速部署**: 见 docs/QUICK_START.md
- 🔍 **问题诊断**: 见 docs/CLOUD_DEPLOYMENT_GUIDE.md 的故障排除
- ⚡ **快速查询**: 见 docs/DEPLOYMENT_QUICK_REFERENCE.md
- 📊 **架构理解**: 见 docs/DEPLOYMENT_SUMMARY.md

---

**版本**: 1.0  
**完成日期**: 2026-03-10  
**状态**: ✅ 完全就绪

祝你部署顺利! 🚀
