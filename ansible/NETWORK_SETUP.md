# 🌐 4个服务器网络配置指南

## 📊 你的网络架构

```
互联网用户 (0.0.0.0)
    ↓
    ↓ HTTP/HTTPS
    ↓ (:80, :443)
    ↓
[Nginx Web 服务器] (192.168.1.10) ← 唯一对外开放的
    ├──→ [PostgreSQL] (192.168.1.11) - 内网通信 (:5432)
    ├──→ [Redis]      (192.168.1.12) - 内网通信 (:6379)
    └──→ [Elasticsearch] (192.168.1.13) - 内网通信 (:9200)
```

## ✅ 配置清单

修改以下文件，根据你的实际 IP 地址配置：

### 1. 修改 `ansible/inventory` 文件

**你需要修改这些行：**

```ini
# 更改这 4 行为你实际的 IP 地址：
web01 ansible_host=192.168.1.10            # Web 服务器 IP
db01 ansible_host=192.168.1.11             # Database 服务器 IP
cache01 ansible_host=192.168.1.12          # Cache 服务器 IP
search01 ansible_host=192.168.1.13         # Search 服务器 IP
```

### 2. 修改 `ansible/group_vars/all.yml` 文件

**已经为你更新了这些配置：**

```yaml
postgres_host: 192.168.1.11          # ← 改为你的 Database 服务器 IP
redis_host: 192.168.1.12             # ← 改为你的 Cache 服务器 IP
elasticsearch_host: 192.168.1.13     # ← 改为你的 Search 服务器 IP
```

**修改密码（必须！）：**

```yaml
postgres_password: changeme123        # ← 改为强密码！
redis_password: changeme123           # ← 改为强密码！
```

## 🔥 防火墙规则配置

### 📍 Web 服务器 (192.168.1.10)

```bash
# 该服务器需要向外开放的端口：
sudo ufw allow 22/tcp      # SSH (Ansible 连接)
sudo ufw allow 80/tcp      # HTTP (用户访问)
sudo ufw allow 443/tcp     # HTTPS (用户访问)
sudo ufw allow from 192.168.1.0/24  # 允许内网通信

# 启用防火墙
sudo ufw enable
```

### 📍 Database 服务器 (192.168.1.11)

```bash
# 该服务器需要向外开放的端口：
sudo ufw allow 22/tcp                               # SSH (Ansible 连接)
sudo ufw allow from 192.168.1.10 to any port 5432  # 仅允许 Web 连接

# 启用防火墙
sudo ufw enable
```

### 📍 Cache 服务器 (192.168.1.12)

```bash
# 该服务器需要向外开放的端口：
sudo ufw allow 22/tcp                               # SSH (Ansible 连接)
sudo ufw allow from 192.168.1.10 to any port 6379  # 仅允许 Web 连接

# 启用防火墙
sudo ufw enable
```

### 📍 Search 服务器 (192.168.1.13)

```bash
# 该服务器需要向外开放的端口：
sudo ufw allow 22/tcp                               # SSH (Ansible 连接)
sudo ufw allow from 192.168.1.10 to any port 9200  # 仅允许 Web 连接

# 启用防火墙
sudo ufw enable
```

## 🧪 测试网络连接

### 验证步骤 1️⃣ : 物理连接（在任意服务器上运行）

```bash
# 测试能否 ping 其他服务器
ping 192.168.1.10  # Web
ping 192.168.1.11  # Database
ping 192.168.1.12  # Cache
ping 192.168.1.13  # Search

# 应该都能收到回复
```

### 验证步骤 2️⃣ : 端口连接（在 Web 服务器上运行）

```bash
# 测试是否能连接各个服务的端口

# 测试 PostgreSQL (装完 Ansible 之前需要先装 postgresql-client)
sudo apt-get install postgresql-client -y
psql -h 192.168.1.11 -U microblog_user -d microblog_db -c "SELECT NOW();"

# 测试 Redis
redis-cli -h 192.168.1.12 -p 6379 -a changeme123 ping
# 应该返回: PONG

# 测试 Elasticsearch (装完 Ansible 之前需要先装 curl)
curl -u elastic:password http://192.168.1.13:9200/_cluster/health?pretty
```

### 验证步骤 3️⃣ : Ansible 连接测试

```bash
cd ansible

# 测试 Ansible 能否连接所有服务器
ansible all -i inventory -m ping

# 应该显示所有主机都返回 pong
#  192.168.1.10 | SUCCESS => {
#      "ping": "pong"
#  }
```

## 🚀 完整部署流程

### 第 1 步：配置文件

```bash
# 1. 修改 inventory 文件
vim ansible/inventory
# 改这些行为你的实际 IP：
# web01 ansible_host=192.168.1.10
# db01 ansible_host=192.168.1.11
# cache01 ansible_host=192.168.1.12
# search01 ansible_host=192.168.1.13

# 2. 修改 group_vars/all.yml
vim ansible/group_vars/all.yml
# 改这些配置为你的 Python 仓库等设置
```

### 第 2 步：测试网络

```bash
# Test 1: Ping 所有服务器
for i in 10 11 12 13; do
  echo "Testing 192.168.1.$i..."
  ping -c 1 192.168.1.$i
done

# Test 2: Ansible 连接测试
ansible all -i ansible/inventory -m ping
```

### 第 3 步：运行 Ansible 部署

```bash
# 全量部署
ansible-playbook ansible/site.yml -i ansible/inventory

# 或分步部署（推荐）
# 1. 部署数据库
ansible-playbook ansible/site.yml -i ansible/inventory -l dbservers

# 2. 部署缓存
ansible-playbook ansible/site.yml -i ansible/inventory -l cacheservers

# 3. 部署搜索
ansible-playbook ansible/site.yml -i ansible/inventory -l searchservers

# 4. 部署应用
ansible-playbook ansible/site.yml -i ansible/inventory -l webservers
```

### 第 4 步：验证部署

```bash
# 检查所有服务健康状态
ansible-playbook ansible/health-check.yml -i ansible/inventory
```

## 🔐 安全建议

### 1. 更改默认密码

编辑 `ansible/group_vars/all.yml`：

```yaml
postgres_password: your_strong_password_here_32_chars_min
redis_password: your_strong_password_here_32_chars_min
secret_key: your_flask_secret_key_here_random_string
```

### 2. SSH 密钥设置

```bash
# 在 **Ansible 控制节点** 上生成 SSH 密钥
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""

# 将公钥分发到所有服务器
# (注：部署到服务器后自动配置)
```

### 3. 防火墙策略（更严格）

**不要使用 `allow from 192.168.1.0/24`，改为：**

```bash
# 仅允许特定 IP 访问
sudo ufw allow from 192.168.1.10 to any port 5432   # 只允许 Web 访问数据库
sudo ufw allow from 192.168.1.10 to any port 6379   # 只允许 Web 访问 Redis
sudo ufw allow from 192.168.1.10 to any port 9200   # 只允许 Web 访问 ES
```

## 📝 排查常见问题

### 问题 1: Ping 不通某个服务器

```bash
# 检查物理网络
traceroute 192.168.1.11

# 检查服务器是否在线
nmap -sn 192.168.1.0/24

# 检查网络配置
ip addr show
ip route show
```

### 问题 2: Ansible 能 ping 通但端口连不了

```bash
# 检查防火墙规则
sudo ufw status

# 检查服务是否启动
sudo systemctl status postgresql
sudo systemctl status redis-server
sudo systemctl status elasticsearch

# 检查服务是否监听该端口
sudo ss -tlnp | grep 5432   # PostgreSQL
sudo ss -tlnp | grep 6379   # Redis
sudo ss -tlnp | grep 9200   # Elasticsearch
```

### 问题 3: 应用连接失败

```bash
# 在 Web 服务器上检查连接
# 检查数据库
psql -h 192.168.1.11 -U microblog_user -d microblog_db -c "SELECT 1"

# 检查 Redis
redis-cli -h 192.168.1.12 ping

# 检查 Elasticsearch
curl http://192.168.1.13:9200/
```

## 🎯 关键配置总结

| 项目 | 文件 | 关键配置 |
|------|------|---------|
| **Ansible 目标** | `inventory` | `ansible_host=IP地址` |
| **数据库地址** | `group_vars/all.yml` | `postgres_host: 192.168.1.11` |
| **缓存地址** | `group_vars/all.yml` | `redis_host: 192.168.1.12` |
| **搜索地址** | `group_vars/all.yml` | `elasticsearch_host: 192.168.1.13` |
| **防火墙** | 各服务器 | `ufw allow from IP port X` |

## ✨ 快速检查清单

- [ ] 所有 4 个服务器互相 ping 通
- [ ] 修改了 `inventory` 中的 4 个 IP 地址
- [ ] 修改了 `group_vars/all.yml` 中的服务地址
- [ ] 配置了防火墙规则
- [ ] `ansible-playbook -i inventory all -m ping` 都成功
- [ ] 所有密码已修改为强密码
- [ ] 运行 Ansible 部署 (`site.yml`)
- [ ] 运行健康检查 (`health-check.yml`)

## 📚 相关资源

- PostgreSQL 远程连接: https://www.postgresql.org/docs/current/runtime-config-connection.html
- Redis 远程访问: https://redis.io/topics/security
- Elasticsearch 网络配置: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-network.html
- UFW 防火墙: https://help.ubuntu.com/community/UFW

---

**最重要的三点：**
1. ✅ 确认 4 个服务器在同一网络里，互相 ping 通
2. ✅ 修改 `inventory` 和 `group_vars/all.yml` 中的 IP 地址
3. ✅ 配置防火墙允许必要的端口通信
