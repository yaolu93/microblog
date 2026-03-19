# Microblog 部署管理指南

## 📋 概述

本指南介绍如何使用 Ansible playbooks 进行 Microblog 应用的部署、管理、重启和卸载操作。

---

## 🚀 快速开始

### 前置要求
- Ansible 2.14+
- 目标服务器: 192.168.118.132 (用户: yao)
- Ubuntu 系统，Python 3.11+
- Sudo 权限

### 检查 Inventory
```bash
cd /home/yao/fromGithub/microblog/ansible
cat inventory
```

---

## 📚 Playbooks 说明

### 1️⃣ 完整部署 (`site.yml`)
**用途**: 首次部署或完整重新部署整个应用堆栈

**包含内容**:
- 系统依赖安装
- PostgreSQL 15 + Redis 7 安装和配置
- Python 3.11 虚拟环境设置
- Gunicorn Web 服务器配置
- RQ Worker 后台任务配置
- Nginx 反向代理配置
- SSL/TLS 证书配置
- 数据库初始化

**执行命令**:
```bash
ansible-playbook site.yml -i inventory
```

**预期时间**: 15-25 分钟

**输出结果**:
- ✅ 完整的应用堆栈
- ✅ 所有服务启动并运行
- ✅ 数据库已初始化，包含7个表
- ✅ 应用可通过 https://192.168.118.132/ 访问

---

### 2️⃣ 应用更新 (`deploy.yml`)
**用途**: 快速更新应用代码（不修改服务和配置）

**包含内容**:
- 从 GitHub 拉取最新代码
- 更新 Python 依赖
- 数据库迁移（如需要）
- Gunicorn 重启

**执行命令**:
```bash
ansible-playbook deploy.yml -i inventory
```

**预期时间**: 2-5 分钟

**适用场景**: 
- 代码更新不需要修改系统工具
- 快速推送功能修复或更新

---

### 3️⃣ 服务重启 (`restart.yml`) ⭐ NEW
**用途**: 快速重启所有服务（不修改代码或配置）

**重启内容**:
- PostgreSQL
- Redis
- Gunicorn
- RQ Worker
- Nginx

**执行命令**:
```bash
ansible-playbook restart.yml -i inventory
```

**预期时间**: 1-3 分钟

**验证项**:
- ✅ 所有服务启动状态检查
- ✅ PostgreSQL 连接测试
- ✅ Redis PING 测试
- ✅ Web 应用响应测试

**适用场景**:
- 日常服务重启（无需代码变更）
- 测试服务故障恢复
- 清理服务状态
- 释放内存资源

---

### 4️⃣ 项目卸载 (`undeploy.yml`) ⭐ NEW
**用途**: 移除应用（清理服务和代码，保留数据库）

**移除内容**:
- ❌ Gunicorn 服务和配置
- ❌ RQ Worker 服务和配置
- ❌ Nginx 配置
- ❌ Python 虚拟环境
- ❌ 应用代码

**保留内容**:
- ✅ PostgreSQL 和数据库
- ✅ Redis 和缓存数据
- ✅ 应用用户账户

**执行命令**:
```bash
ansible-playbook undeploy.yml -i inventory
```

**预期时间**: 1-2 分钟

**验证项**:
- ✅ 所有服务已停止
- ✅ 应用文件已删除
- ✅ Systemd daemon 已重新加载
- ✅ 数据库完好无损

**适用场景**:
- 清理测试环境
- 快速测试部署流程
- 移除应用保留数据库

---

### 5️⃣ 健康检查 (`health-check.yml`)
**用途**: 验证所有服务的运行状态

**检查内容**:
- PostgreSQL 连接和表数量
- Redis 连接和键统计
- Nginx 运行状态
- Gunicorn 进程数
- RQ Worker 活动状态
- Web 应用响应

**执行命令**:
```bash
ansible-playbook health-check.yml -i inventory
```

**预期时间**: 30-60 秒

**输出示例**:
```
✅ PostgreSQL - 活跃, 7 个表
✅ Redis - 活跃, 可响应
✅ Nginx - 活跃
✅ Gunicorn - 活跃, 5 个进程 (1 master + 4 workers)
✅ RQ Worker - 活跃
✅ Web 应用 - 运行正常
```

---

## 🔄 常见工作流

### 工作流 1: 快速测试循环
```bash
# 1. 卸载应用
ansible-playbook undeploy.yml -i inventory

# 2. 修改代码...

# 3. 重新部署
ansible-playbook site.yml -i inventory

# 4. 验证
ansible-playbook health-check.yml -i inventory
```

### 工作流 2: 日常服务重启
```bash
# 简单重启所有服务
ansible-playbook restart.yml -i inventory
```

### 工作流 3: 更新应用代码
```bash
# 1. 拉取最新代码并重启
ansible-playbook deploy.yml -i inventory

# 2. 验证应用
ansible-playbook health-check.yml -i inventory
```

### 工作流 4: 调试模式
```bash
# 1. 停止应用（保留数据库）
ansible-playbook undeploy.yml -i inventory

# 2. 在本地调试/测试...
# 本地调试 Flask 应用...

# 3. 重新部署
ansible-playbook site.yml -i inventory

# 4. 健康检查
ansible-playbook health-check.yml -i inventory
```

---

## 🔗 服务访问地址

| 服务 | 地址 | 认证 |
|------|------|------|
| Web 应用 | https://192.168.118.132/ | 用户登录 |
| PostgreSQL | localhost:5432 | 密码: microblog_secure_pwd_2024 |
| Redis | localhost:6379 | 密码: redis_secure_pwd_2024 |
| Nginx | port 80/443 | HTTPS 强制重定向 |

---

## 📊 查看日志

### 实时查看 Gunicorn 日志
```bash
journalctl -u gunicorn -f
```

### 实时查看 RQ Worker 日志
```bash
journalctl -u rq-worker -f
```

### 查看 Nginx 错误日志
```bash
tail -f /var/log/nginx/error.log
```

### 查看应用日志
```bash
tail -f /var/log/microblog/microblog.log
```

---

## 🐛 故障排除

### 问题 1: Gunicorn 无法启动
```bash
# 查看错误日志
journalctl -u gunicorn -n 50

# 检查虚拟环境
ls -la /home/microblog/venv

# 重新部署
ansible-playbook site.yml -i inventory
```

### 问题 2: 数据库无法连接
```bash
# 检查 PostgreSQL 状态
systemctl status postgresql

# 测试连接
sudo -u postgres psql -d microblog_db -c "SELECT 1;"

# 查看 PostgreSQL 日志
journalctl -u postgresql -n 50
```

### 问题 3: Redis 连接失败
```bash
# 检查 Redis 状态
systemctl status redis-server

# 测试连接
redis-cli -a redis_secure_pwd_2024 ping

# 查看 Redis 日志
journalctl -u redis-server -n 50
```

### 问题 4: Nginx 返回 502 错误
```bash
# 检查 Gunicorn 状态
systemctl status gunicorn

# 检查 socket 权限
ls -la /tmp/gunicorn.sock

# 重启 Gunicorn
systemctl restart gunicorn
```

---

## ⚙️ 高级操作

### 手动重启特定服务
```bash
# 仅重启 Gunicorn
systemctl restart gunicorn

# 仅重启 Nginx
systemctl restart nginx

# 仅重启 RQ Worker
systemctl restart rq-worker
```

### 手动检查服务状态
```bash
# 查看所有服务状态
systemctl status gunicorn
systemctl status rq-worker
systemctl status nginx
systemctl status postgresql
systemctl status redis-server
```

### 查看 Gunicorn 进程数
```bash
ps aux | grep gunicorn | grep -v grep
```

### 查看应用配置
```bash
cat /home/microblog/microblog/config.py
```

---

## 📝 Playbook 文件位置

```
/home/yao/fromGithub/microblog/ansible/
├── site.yml              # 完整部署
├── deploy.yml            # 应用更新
├── restart.yml           # 服务重启 ⭐ NEW
├── undeploy.yml          # 项目卸载 ⭐ NEW
├── health-check.yml      # 健康检查
├── inventory             # 主机清单
└── roles/                # Playbook 角色
    ├── common/
    ├── database/
    ├── cache/
    ├── web/
    └── config/
```

---

## 🎯 最佳实践

1. **备份优先**: 重要更新前备份数据库
2. **分步骤**: 使用 `deploy.yml` 进行小的更新，`site.yml` 进行大的变更
3. **验证服务**: 每次部署后运行 `health-check.yml`
4. **监控日志**: 部署时监控实时日志
5. **测试环境**: 先在测试服务器上验证新的 playbook 版本

---

## 🔐 安全建议

1. 更改默认密码:
   ```bash
   # PostgreSQL 密码在 roles/database/defaults/main.yml
   # Redis 密码在 roles/cache/defaults/main.yml
   ```

2. 启用防火墙:
   ```bash
   sudo ufw allow 22/tcp
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw enable
   ```

3. 定期备份数据库：
   ```bash
   sudo pg_dump -U microblog microblog_db > backup.sql
   ```

---

## 📞 支持

遇到问题？按以下步骤排查：

1. 查看实时日志: `journalctl -u <service> -f`
2. 运行健康检查: `ansible-playbook health-check.yml -i inventory`
3. 检查服务状态: `systemctl status <service>`
4. 查阅故障排除部分

---

**最后更新**: 2024年
**Ansible 版本**: 2.14.18+
**应用**: Microblog Flask
