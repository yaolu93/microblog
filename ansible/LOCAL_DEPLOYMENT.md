# 🖥️ 本地单机部署指南（本地部署）

你的情况：
- ✅ 在同一台机器上运行所有服务（PostgreSQL、Redis、Elasticsearch、Flask 应用）
- ✅ 机器 IP: **192.168.118.132**
- ✅ 用户名: **yao**
- ✅ 无需 SSH 密钥配置（本地 localhost 连接）

## ⚙️ 配置汇总

你的 Ansible 已配置为：

| 项目 | 配置 | 说明 |
|------|------|------|
| **连接方式** | `ansible_connection=local` | 本地连接，不走网络 |
| **连接主机** | `localhost` | 本地主机 |
| **用户名** | `yao` | 你的用户名 |
| **数据库连接** | `localhost:5432` | 本机 PostgreSQL |
| **缓存连接** | `localhost:6379` | 本机 Redis |
| **搜索连接** | `localhost:9200` | 本机 Elasticsearch |

## ✨ 不需要做的事

❌ ~~生成 SSH 密钥~~ (已跳过)
❌ ~~分发公钥~~ (已跳过)
❌ ~~配置 SSH 连接~~ (已跳过)

## 📋 你需要做的事

### 步骤 1: 安装 Ansible（在 192.168.118.132 上）

```bash
# 进入项目目录
cd /home/yao/fromGithub/microblog

# 安装 Ansible 依赖
pip install ansible paramiko

# 验证安装
ansible --version
```

### 步骤 2: 修改必要的配置

编辑 `ansible/group_vars/all.yml`：

```bash
vim ansible/group_vars/all.yml
```

修改这些内容：

```yaml
# 改为你的 GitHub 仓库地址
git_repo: https://github.com/你的用户名/microblog.git

# 改为一个随机的 Flask 密钥
secret_key: your-super-secret-key-change-me-$(date +%s)

# 如果要配置邮件（可选）
mail_server: smtp.gmail.com
mail_username: your-email@gmail.com
mail_password: your-app-password
```

### 步骤 3: 测试 Ansible 连接

```bash
cd ansible

# 测试能否连接到 localhost
ansible all -i inventory -m ping

# 应该显示：
# localhost | SUCCESS => {
#     "ping": "pong"
# }
```

如果看到 `"ping": "pong"` 说明连接成功！

### 步骤 4: 干运行（模拟部署，不实际修改）

```bash
# 显示 Ansible 会做什么，但不实际执行
ansible-playbook site.yml -i inventory --check

# 应该显示很多 "changed" 的任务
```

### 步骤 5: 执行实际部署

```bash
# 执行完整部署
ansible-playbook site.yml -i inventory

# 这会花 5-15 分钟，根据你的网络速度
```

### 步骤 6: 验证部署结果

```bash
# 检查所有服务健康状态
ansible-playbook health-check.yml -i inventory

# 应该显示所有服务已启动
```

## 🔍 如何监控部署进度

### 方式 A: 实时查看日志

```bash
# 在另一个终端
tail -f /var/log/ansible.log
```

### 方式 B: 显示详细输出

```bash
# 加上 -v 参数显示更多信息
ansible-playbook site.yml -i inventory -v

# 或更详细
ansible-playbook site.yml -i inventory -vv

# 或最详细（调试)
ansible-playbook site.yml -i inventory -vvv
```

### 方式 C: 显示执行时间

```bash
# 显示每个任务耗时
ANSIBLE_STDOUT_CALLBACK=profile_tasks ansible-playbook site.yml -i inventory
```

## ✅ 部署完成后的验证

### 1️⃣ 检查服务状态

```bash
# PostgreSQL
sudo systemctl status postgresql

# Redis
sudo systemctl status redis-server

# Elasticsearch
sudo systemctl status elasticsearch

# Gunicorn (Flask)
sudo systemctl status gunicorn

# Nginx
sudo systemctl status nginx

# RQ Worker
sudo systemctl status rq-worker
```

### 2️⃣ 测试数据库连接

```bash
# 测试 PostgreSQL
psql -h localhost -U microblog_user -d microblog_db -c "SELECT NOW();"
# 需要输入密码：microblog_secure_pwd_2024

# 或使用 psql 不询问密码的方式
PGPASSWORD=microblog_secure_pwd_2024 psql -h localhost -U microblog_user -d microblog_db -c "SELECT NOW();"
```

### 3️⃣ 测试 Redis 连接

```bash
# 测试 Redis
redis-cli -a redis_secure_pwd_2024 ping
# 应该返回 PONG
```

### 4️⃣ 测试 Elasticsearch 连接

```bash
# 测试 Elasticsearch
curl http://localhost:9200/
# 应该返回 JSON 信息
```

### 5️⃣ 测试 Flask 应用

```bash
# 测试 Gunicorn
curl http://127.0.0.1:8000/

# 测试 Nginx 代理
curl http://localhost/

# 或用浏览器访问
# http://localhost
# http://192.168.118.132
```

### 6️⃣ 查看应用日志

```bash
# Gunicorn 日志
sudo tail -f /var/log/microblog/error.log

# Nginx 日志
sudo tail -f /var/log/microblog/nginx/access.log

# 系统日志
sudo journalctl -u gunicorn -n 50
```

## 🔐 修改默认密码

**非常重要！** 改为强密码：

编辑 `ansible/group_vars/all.yml`：

```yaml
# PostgreSQL 密码（数据库）
postgres_password: your_strong_postgres_password_here_32_chars

# Redis 密码（缓存）
redis_password: your_strong_redis_password_here_32_chars

# Flask 密钥
secret_key: your_random_flask_secret_key_here_very_long_string
```

然后重新运行部署来应用新密码：

```bash
ansible-playbook site.yml -i inventory
```

## 📊 部署架构（单机）

```
┌─────────────────────────────────────────┐
│   192.168.118.132 (yao@server)         │
│                                          │
│  ┌──────────────────────────────────┐ │
│  │ PostgreSQL (localhost:5432)      │ │
│  │ Database for Flask app           │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Redis (localhost:6379)           │ │
│  │ Cache & Task Queue               │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Elasticsearch (localhost:9200)   │ │
│  │ Full-text Search Engine          │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Gunicorn (127.0.0.1:8000)        │ │
│  │ Flask Application Server         │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ RQ Worker (Background Jobs)      │ │
│  │ Handles async tasks              │ │
│  └──────────────────────────────────┘ │
│  ┌──────────────────────────────────┐ │
│  │ Nginx (localhost:80/443)         │ │
│  │ Reverse Proxy & Web Server       │ │
│  └──────────────────────────────────┘ │
│                                         │
│  互联网 → Nginx → Gunicorn → Flask App │
└─────────────────────────────────────────┘
```

## 🚀 快速命令速览

```bash
# 进入项目目录
cd /home/yao/fromGithub/microblog/ansible

# 1. 测试连接
ansible all -i inventory -m ping

# 2. 模拟部署（检查）
ansible-playbook site.yml -i inventory --check

# 3. 实际部署
ansible-playbook site.yml -i inventory

# 4. 验证部署
ansible-playbook health-check.yml -i inventory

# 5. 查看所有主机
ansible all -i inventory --list-hosts

# 6. 检查服务
ansible all -i inventory -m systemd -a "name=gunicorn state=started"

# 7. 查看日志
ansible all -i inventory -m shell -a "sudo journalctl -u gunicorn -n 20"
```

## ❌ 常见错误排查

### 错误 1: "permission denied" 或 "sudo"

如果看到权限错误，可能是 `yao` 用户没有 sudo 权限：

```bash
# 检查是否在 sudoers 组中
groups yao

# 如果没有 sudo 权限，需要以 root 添加
sudo usermod -aG sudo yao

# 或者以 root 用户运行
sudo ansible-playbook site.yml -i inventory
```

### 错误 2: "ansible: command not found"

Ansible 没有安装或 PATH 问题：

```bash
# 重新安装 Ansible
pip install --upgrade ansible

# 验证安装
which ansible
ansible --version
```

### 错误 3: "FAILED - UNREACHABLE"

localhost 连接失败：

```bash
# 测试 localhost 连接
ansible localhost -c local -m ping

# 或检查 inventory 文件
cat ansible/inventory | grep -A5 webservers
```

### 错误 4: 端口已占用

如果某个端口（5432、6379、9200 等）已被占用：

```bash
# 查看占用情况
sudo netstat -tlnp | grep LISTEN

# 或
sudo ss -tlnp | grep LISTEN

# 杀死占用的进程
sudo kill -9 <PID>

# 或修改 group_vars/all.yml 中的端口号
```

### 错误 5: 磁盘空间不足

Elasticsearch 需要较大空间：

```bash
# 检查空间
df -h

# 清理不需要的文件
sudo apt-get autoremove
sudo apt-get autoclean
```

## 🔧 如果需要重新部署

```bash
# 如果要重新部署（删除旧部署）
sudo rm -rf /home/microblog/
sudo -u postgres dropdb microblog_db
sudo -u postgres dropuser microblog_user
redis-cli flushall

# 然后重新运行
ansible-playbook site.yml -i inventory
```

## 📚 下一步

完成部署后：

1. ✅ 创建管理员用户
2. ✅ 配置 HTTPS 证书
3. ✅ 配置邮件服务
4. ✅ 设置备份计划
5. ✅ 配置监控（Prometheus/Grafana）

## 📞 快速参考

**Ansible 配置文件：**
- `ansible/inventory` - 主机清单（已配置 localhost）
- `ansible/group_vars/all.yml` - 全局变量（需要修改密码和 git_repo）
- `ansible/site.yml` - 完整部署剧本
- `ansible/health-check.yml` - 健康检查剧本

**关键配置说明：**

```ini
# inventory 中：
# ansible_connection=local 表示本地连接，不走 SSH
# ansible_user=yao 表示用 yao 用户运行
# ansible_become=yes 表示需要 sudo 权限

# group_vars/all.yml 中：
# postgres_host: localhost 表示本机 PostgreSQL
# redis_host: localhost 表示本机 Redis
# elasticsearch_host: localhost 表示本机 Elasticsearch
```

---

**现在你可以直接运行：**

```bash
cd /home/yao/fromGithub/microblog/ansible
ansible-playbook site.yml -i inventory
```

**祝部署成功！🚀**
