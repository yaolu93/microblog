# Ansible Deployment for Microblog Application

This directory contains Ansible playbooks and roles for deploying the Microblog Flask application across multiple servers with PostgreSQL, Redis, Elasticsearch, and Nginx.

## Directory Structure & File Purposes

```
ansible/
├── 📋 顶层配置文件
│   ├── ansible.cfg              《 Ansible 全局配置（连接方式、权限、日志）
│   ├── inventory                《 主机清单（定义主机分组和连接方式）
│   ├── requirements.txt         《 Ansible 依赖（如需要）
│   └── *.yml                    《 Playbook 文件
│
├── 📂 group_vars/               《 群组变量（按主机分组定义变量）
│   ├── all.yml                  《 所有主机的全局变量（90+ 行：应用设置、凭证、服务配置）
│   ├── webservers.yml           《 Web 服务器的特定变量
│   ├── dbservers.yml            《 数据库服务器的特定变量
│   ├── cacheservers.yml         《 缓存服务器的特定变量
│   └── searchservers.yml        《 搜索引擎的特定变量
│
├── 📂 host_vars/                《 主机变量（针对特定主机的变量）
│   └── localhost.yml            《 localhost 的特定变量（如需要）
│
├── 📂 roles/                    《 角色（模块化部署任务）
│   ├── common/                  《 通用配置（系统包、用户、防火墙等）
│   │   ├── tasks/main.yml       《 30+ 个系统配置任务
│   │   ├── handlers/main.yml    《 定义触发的操作
│   │   ├── templates/           《 配置文件模板
│   │   └── vars/                《 角色特定变量
│   │
│   ├── postgres/                《 PostgreSQL 数据库
│   │   ├── tasks/main.yml       《 35+ 个数据库配置任务
│   │   ├── handlers/main.yml    《 PostgreSQL 重启
│   │   └── templates/           《 postgresql.conf 等模板
│   │
│   ├── redis/                   《 Redis 缓存
│   │   ├── tasks/main.yml       《 20+ 个缓存配置任务
│   │   ├── handlers/main.yml    《 Redis 重启
│   │   └── templates/           《 redis.conf 模板
│   │
│   ├── elasticsearch/           《 Elasticsearch 搜索
│   │   ├── tasks/main.yml       《 15+ 个搜索配置任务
│   │   ├── handlers/main.yml    《 Elasticsearch 重启
│   │   └── templates/           《 elasticsearch.yml 模板
│   │
│   ├── app/                     《 Flask 应用
│   │   ├── tasks/main.yml       《 40+ 个应用部署任务
│   │   ├── handlers/main.yml    《 Gunicorn 重启
│   │   ├── templates/           《 .env, gunicorn 配置
│   │   └── files/               《 静态配置文件
│   │
│   └── nginx/                   《 Nginx 反向代理
│       ├── tasks/main.yml       《 30+ 个 Nginx 配置任务
│       ├── handlers/main.yml    《 Nginx 测试和重启
│       └── templates/           《 nginx.conf, {各功能}配置模板
│
└── 📄 文档文件
    ├── README.md                《 本文件（部署说明）
    ├── MANAGEMENT_GUIDE.md      《 管理指南
    ├── QUICK_REFERENCE.md       《 快速参考
    └── 其他 *.md 文件           《 其他文档
```

## Prerequisites

1. **Ansible**: Install Ansible on your control machine
   ```bash
   pip install ansible
   ```

2. **SSH Access**: Ensure SSH key-based authentication is configured
   ```bash
   ssh-keygen -t rsa -b 4096
   ssh-copy-id -i ~/.ssh/id_rsa.pub ubuntu@target-server
   ```

3. **Python**: Python 3.8+ must be installed on all target servers

4. **Inventory Configuration**: Update the `inventory` file with your server IPs/hostnames

## Quick Start

### 1. Configure Inventory

Edit `inventory` file and update server addresses:

```ini
[webservers]
web01.example.com ansible_host=192.168.1.10

[dbservers]
db01.example.com ansible_host=192.168.1.11

[cacheservers]
cache01.example.com ansible_host=192.168.1.12

[searchservers]
search01.example.com ansible_host=192.168.1.13
```

### 2. Configure Variables

Edit `group_vars/all.yml` with your deployment settings:

```yaml
git_repo: https://github.com/yourusername/microblog.git
git_branch: main
app_env: production
postgres_password: changeme123  # Use strong password!
redis_password: changeme123
secret_key: your-flask-secret-key
server_name: microblog.example.com
```

### 3. Run Full Deployment

```bash
cd ansible
ansible-playbook site.yml -i inventory
```

### 4. Deploy Application Updates

```bash
ansible-playbook deploy.yml -i inventory
```

### 5. Check System Health

```bash
ansible-playbook health-check.yml -i inventory
```

## Core Configuration Files

### 1. ansible.cfg - Ansible 全局配置

**作用：**
- 指定 inventory 文件位置
- 配置用户权限提升（become/sudo）
- 设置日志位置
- 性能优化（缓存）
- SSH 连接方式

**关键配置：**
```ini
inventory = ./inventory        # 指向 inventory 文件
remote_user = ubuntu           # 远程用户名
become = True                  # 启用权限提升
become_method = sudo           # 使用 sudo
host_key_checking = False      # 跳过 SSH 密钥检查
log_path = /var/log/ansible.log # 记录日志
```

### 2. inventory - 主机清单

**作用：**
- 定义要部署的主机
- 分组主机（webservers, dbservers, etc.）
- 设置主机连接方式
- 定义主机级变量

**关键部分：**
```ini
[all:vars]              # 所有主机的全局连接变量
ansible_user = yao
ansible_become_method = sudo

[webservers]            # Web 服务器组
localhost ansible_connection=local

[dbservers]             # 数据库服务器组
localhost ansible_connection=local

[cacheservers]          # 缓存服务器组
localhost ansible_connection=local

[searchservers]         # 搜索服务器组
localhost ansible_connection=local
```

**说明：**
- `localhost`：在本机部署
- `ansible_connection=local`：使用本地连接（不通过 SSH）
- 不需要密钥或密码认证

### 3. group_vars/all.yml - 全局变量

**作用：**
- 定义所有主机通用的变量
- 应用设置
- 数据库凭证
- 服务配置
- 安全参数

**关键变量：**
```yaml
app_user: microblog                           # 应用运行用户
app_path: /home/microblog/microblog           # 应用代码路径
python_version: "3.11"                        # Python 版本
venv_path: /home/microblog/venv               # 虚拟环境路径
postgres_password: microblog_secure_pwd_2024  # 数据库密码
redis_password: redis_secure_pwd_2024         # Redis 密码
gunicorn_workers: 4                           # Gunicorn 工作进程数
```

### 4. Playbook 文件（*.yml）

**主要 Playbooks：**

| 文件 | 作用 | 使用场景 |
|------|------|--------|
| `site.yml` | 完整部署（所有服务） | 首次部署或完整重新部署 |
| `quick-deploy.yml` | 快速部署（跳过 Git，使用本地代码） | 快速更新代码 |
| `undeploy.yml` | 卸载应用（保留数据库） | 清理环境 |
| `restart.yml` | 快速重启所有服务 | 服务故障恢复 |
| `health-check.yml` | 验证系统状态 | 例行检查 |

## Deployment Flow (Execution Sequence)

执行 `ansible-playbook site.yml -i inventory` 后的流程：

### Phase 1: Common Setup (common 角色)
**目标主机：all | 功能：基础系统配置**
```
✓ 更新系统软件包
✓ 安装基础工具 (curl, wget, vim, git)
✓ 设置时区 (UTC)
✓ 创建应用用户 (microblog)
✓ 创建应用目录 (/home/microblog/*)
✓ 配置 SSH 密钥访问
✓ 启用防火墙（UFW）和配置规则
✓ 启用安全服务 (fail2ban)
```

### Phase 2: PostgreSQL Setup (postgres 角色)
**目标主机：dbservers (本例中是 localhost) | 功能：数据库初始化**
```
✓ 添加 PostgreSQL 官方仓库
✓ 安装 PostgreSQL 15
✓ 启动 PostgreSQL 服务
✓ 创建应用数据库 (microblog_db)
✓ 创建应用用户 (microblog_user)
✓ 设置用户访问权限
✓ 优化配置参数 (max_connections, shared_buffers)
✓ 配置连接认证 (pg_hba.conf)
✓ 创建备份脚本和定时任务
```

### Phase 3: Redis Setup (redis 角色)
**目标主机：cacheservers (本例中是 localhost) | 功能：缓存层初始化**
```
✓ 安装 Redis 7
✓ 创建 Redis 配置文件
✓ 设置 Redis 密码
✓ 配置持久化 (AOF)
✓ 设置最大内存和淘汰策略
✓ 启动 Redis 服务
✓ 测试 Redis 连接
```

### Phase 4: Elasticsearch Setup (elasticsearch 角色)
**目标主机：searchservers (本例中是 localhost) | 功能：搜索引擎初始化**
```
✓ 添加 Elasticsearch 仓库
✓ 安装 Elasticsearch 8.11
✓ 配置 JVM 内存和网络绑定
✓ 设置系统参数 (ulimits, sysctl)
✓ 启动 Elasticsearch 服务
⚠️ 注意：此步骤可能因内存不足而失败，但设置了 ignore_errors: yes 以继续部署
```

### Phase 5: Flask Application Deployment (app 角色)
**目标主机：webservers (localhost) | 功能：应用代码和运行环境**
```
✓ 复制应用代码（使用 cp 命令，修复过）
✓ 设置代码目录权限
✓ 创建 Python 虚拟环境
✓ 安装 Python 依赖 (requirements.txt)
✓ 创建 .env 文件（数据库、缓存配置等）
✓ 初始化 Flask 数据库 (flask db upgrade)「使用 /bin/bash，修复过」
✓ 编译翻译文件 (pybabel compile)
✓ 创建 Gunicorn systemd 服务
✓ 创建 RQ Worker systemd 服务
✓ 启动 Gunicorn (4 workers)
✓ 启动 RQ Worker（后台任务处理）
✓ 配置日志轮转
```

### Phase 6: Nginx Setup (nginx 角色)
**目标主机：webservers (localhost) | 功能：Web 服务器和 SSL 配置**
```
✓ 安装 Nginx
✓ 创建 Nginx 日志目录（在配置测试前，修复过）
✓ 创建主配置文件 (nginx.conf)
✓ 创建应用配置 (microblog.conf)
  ├─ 反向代理到 Gunicorn (127.0.0.1:8000)
  ├─ HTTPS 强制重定向
  └─ 安全头、性能优化
✓ 生成自签名 SSL 证书
✓ 创建性能优化配置 (gzip, 缓存)
✓ 创建安全头配置
✓ 创建代理参数配置
✓ 测试 Nginx 配置 (nginx -t)
✓ 启动 Nginx 服务
✓ 配置日志轮转
```

### 最终结果
```
✅ PostgreSQL: 运行中，数据库就绪，用户和权限已配置
✅ Redis: 运行中，缓存就绪，密码保护启用
✅ Elasticsearch: 安装完成（可能失败但不中断部署）
✅ Gunicorn: 运行中，5 个进程 (1 主进程 + 4 worker)
✅ RQ Worker: 运行中，处理后台任务
✅ Nginx: 运行中，反向代理配置完成，HTTPS 就绪
```

## Detailed Usage

### Deploy Only to Specific Group

```bash
# Deploy only web servers
ansible-playbook site.yml -i inventory --tags webservers

# Deploy only database
ansible-playbook site.yml -i inventory -l dbservers

# Deploy only cache
ansible-playbook site.yml -i inventory -l cacheservers
```

### Run with Specific Variables

```bash
ansible-playbook site.yml -i inventory \
  -e "postgres_password=newpassword" \
  -e "app_env=production"
```

### Run Specific Role

```bash
ansible-playbook site.yml -i inventory --tags "role:postgres"
```

### Run in Check Mode (Dry Run)

```bash
ansible-playbook site.yml -i inventory --check
```

### Increase Verbosity

```bash
# More verbose output
ansible-playbook site.yml -i inventory -v

# Very verbose
ansible-playbook site.yml -i inventory -vv

# Debug mode
ansible-playbook site.yml -i inventory -vvv
```

## Role Descriptions & Structure

Each role follows standard Ansible structure:
```
roles/ROLE_NAME/
├── tasks/main.yml          # 任务列表（执行什么操作）
├── handlers/main.yml       # 处理程序（服务重启等触发操作）
├── templates/              # Jinja2 模板（配置文件）
├── files/                  # 静态文件（直接复制）
├── vars/main.yml           # 变量定义（角色特定）
└── defaults/main.yml       # 默认变量（可被覆盖）
```

### ✨ Common Role
**主要功能：** 基础系统配置

**输出：**
- 系统用户创建 (microblog 用户)
- 应用目录创建
- SSH 密钥配置
- 防火墙规则 (UFW)
- 系统优化参数
- 安全加固 (fail2ban)

**关键文件：**
- `tasks/main.yml` - 30+ 个任务
- `templates/sshd_config.j2` - SSH 配置
- `handlers/main.yml` - 系统重启

### 🐘 PostgreSQL Role
**主要功能：** 数据库安装和配置

**输出：**
- PostgreSQL 15 安装
- 数据库创建 (microblog_db)
- 用户创建和权限设置 (microblog_user)
- 性能参数优化
- 自动备份脚本
- 连接认证配置

**关键文件：**
- `tasks/main.yml` - 35+ 个任务
- `templates/postgresql.conf.j2` - 性能参数
- `templates/pg_hba.conf.j2` - 连接认证
- `handlers/main.yml` - PostgreSQL 重启

**默认凭证：**
- User: `microblog_user`
- Password: `microblog_secure_pwd_2024` (改为强密码)

### 🔴 Redis Role
**主要功能：** 缓存服务配置

**输出：**
- Redis 7 安装
- 密码认证启用
- 持久化配置 (AOF)
- 内存管理和淘汰策略
- 连接测试

**关键文件：**
- `tasks/main.yml` - 20+ 个任务
- `templates/redis.conf.j2` - Redis 配置
- `handlers/main.yml` - Redis 重启

**默认配置：**
- Port: `6379`
- Password: `redis_secure_pwd_2024` (改为强密码)
- Max Memory: `512mb`

### 🔍 Elasticsearch Role
**主要功能：** 搜索引擎配置

**输出：**
- Elasticsearch 8.11 安装
- JVM 内存配置
- 系统参数优化
- 安全配置
- ulimits 设置

**关键文件：**
- `tasks/main.yml` - 15+ 个任务
- `templates/elasticsearch.yml.j2` - 主配置
- `templates/jvm.options.j2` - JVM 参数
- `handlers/main.yml` - Elasticsearch 重启

**注意：** 此角色的某些任务可能失败（如内存不足），但设置了 `ignore_errors: yes` 以允许部署继续

### 🐍 Application (Flask) Role
**主要功能：** Flask 应用部署与管理

**输出：**
- 应用代码部署（cp 命令，修复过）
- Python 虚拟环境创建
- 依赖安装 (pip install)
- Flask 数据库初始化 (flask db upgrade)
- 翻译文件编译
- Gunicorn WSGI 服务配置
- RQ Worker 后台任务配置
- systemd 服务建立
- 日志轮转配置

**关键文件：**
- `tasks/main.yml` - 40+ 个任务
  - 代码复制（cp 命令）← **我们的修复**
  - Flask db upgrade (/bin/bash) ← **我们的修复**
  - systemd 服务创建
- `templates/env.j2` - .env 文件模板
- `templates/gunicorn.service.j2` - Gunicorn systemd 服务
- `templates/rq-worker.service.j2` - RQ Worker systemd 服务
- `handlers/main.yml` - 服务重启处理

**输出服务：**
- Gunicorn: 4 workers（可配置）
- RQ Worker: 后台任务处理

### 🌐 Nginx Role
**主要功能：** Web 服务器和反向代理配置

**输出：**
- Nginx 安装
- HTTPS 证书（自签名或 Let's Encrypt）
- 反向代理配置（→ Gunicorn)
- 性能参数（gzip, 缓存）
- 安全头配置
- 日志配置和轮转

**关键文件：**
- `tasks/main.yml` - 30+ 个任务
  - 日志目录创建 ← **我们的修复**（在配置测试前）
  - 配置文件生成
  - SSL 证书生成
  - nginx -t 测试
- `templates/nginx.conf.j2` - Nginx 主配置
- `templates/microblog.conf.j2` - 应用特定配置
- `templates/gzip.conf.j2` - 压缩配置
- `templates/security-headers.conf.j2` - 安全头
- `templates/proxy-params.conf.j2` - 代理参数
- `handlers/main.yml` - 配置测试和重启

**反向代理配置：**
- Listens on: `80` (HTTP) → `443` (HTTPS)
- Proxies to: `http://127.0.0.1:8000` (Gunicorn)
- SSL: 自签名证书（可替换为真实证书）

## Variable Precedence (变量优先级)

Ansible 变量覆盖顺序（从低到高）：

```
1. defaults/main.yml         # 最低优先级（在各 role 中）
   ↓
2. vars/main.yml             # role 特定变量
   ↓
3. group_vars/all.yml        # 所有主机变量
   ↓
4. group_vars/{group}.yml    # 特定组变量（覆盖 all.yml）
   ↓
5. host_vars/{hostname}.yml  # 特定主机变量（覆盖组变量）
   ↓
6. 命令行 -e VAR=value      # 最高优先级
```

**例如：**
```yaml
# 如果 group_vars/all.yml 定义：
postgres_password: old_password

# 而 group_vars/dbservers.yml 定义：
postgres_password: new_password

# 则最终使用 new_password（更具体的定义覆盖全局定义）
```

## Environment Variables

The deployment creates `.env` file with these variables:

```bash
DATABASE_URL=postgresql://user:password@host/database
REDIS_URL=redis://:password@host:6379/0
ELASTICSEARCH_URL=http://host:9200
FLASK_ENV=production
SECRET_KEY=your-secret-key
LOG_TO_STDOUT=1
```

## Key Fixes Applied (关键修复)

Ansible 部署过程中已应用以下关键修复，确保部署顺利进行：

### 修复 1: 应用代码复制 ✅
**位置：** [roles/app/tasks/main.yml](roles/app/tasks/main.yml#L12-L16)

**问题：** 
- `synchronize` 模块在某些环境下失败时，备选方案的条件判断有逻辑错误
- 导致 `requirements.txt` 无法复制

**修复方案：**
```yaml
# 使用改进的 cp 命令确保覆盖现有文件
- name: Copy application code (fallback)
  shell: |
    mkdir -p "{{ app_path }}"
    cp -rf /home/yao/fromGithub/microblog/* "{{ app_path }}/"
  when: rsync_result.failed | default(false)
```

**影响：** 确保应用代码和依赖文件被正确复制到部署目录

---

### 修复 2: Nginx 日志目录创建顺序 ✅
**位置：** [roles/nginx/tasks/main.yml](roles/nginx/tasks/main.yml)

**问题：**
- 日志目录（`/var/log/microblog/nginx`）的创建任务在 Nginx 配置测试之后
- 导致 `nginx -t` 测试失败（日志目录不存在）
- 阻止 Nginx 服务启动

**修复方案：**
```yaml
# 将日志目录创建任务移到配置测试之前
- name: Create Nginx log directory
  file:
    path: /var/log/microblog/nginx
    state: directory
    owner: www-data
    group: www-data
    mode: '0755'
  ignore_errors: yes

# 然后才执行配置测试
- name: Test Nginx configuration
  shell: nginx -t
```

**影响：** Nginx 配置测试能够顺利执行，服务可正常启动

---

### 修复 3: Flask 命令 Shell 兼容性 ✅
**位置：**
- [roles/app/tasks/main.yml](roles/app/tasks/main.yml#L56) (flask db upgrade)
- [roles/app/tasks/main.yml](roles/app/tasks/main.yml#L68) (pybabel compile)
- [quick-deploy.yml](quick-deploy.yml#L141) (flask db upgrade)
- [quick-deploy.yml](quick-deploy.yml#L168) (pybabel compile)

**问题：**
- Flask 数据库迁移和翻译编译命令使用 `source` 指令
- Ansible 默认使用 `/bin/sh`，不支持 `source` 命令
- 导致命令执行失败

**修复方案：**
```yaml
# 明确指定使用 /bin/bash 而非 /bin/sh
- name: Run Flask database migrations
  shell: |
    source {{ venv_path }}/bin/activate
    flask db upgrade
  args:
    executable: /bin/bash  # ← 关键修复
  environment:
    FLASK_APP: microblog.py

- name: Compile translations
  shell: |
    source {{ venv_path }}/bin/activate
    pybabel compile -d app/translations
  args:
    executable: /bin/bash  # ← 关键修复
```

**影响：** Flask 数据库迁移和翻译编译命令能够正确执行

---

**总结：** 这三个修复确保了从代码复制、Nginx 配置测试、到 Flask 数据库初始化的整个部署流程的顺利进行。

## Security Considerations

1. **Passwords**: Change all default passwords in `group_vars/`
   - PostgreSQL: `microblog_secure_pwd_2024`
   - Redis: `redis_secure_pwd_2024`
   
2. **SSH**: 
   - Use SSH keys for remote servers
   - Disable password authentication
   - For localhost deployment, local connection is used
   
3. **Firewall**: UFW firewall is enabled by default
   - Opens ports: 22 (SSH), 80 (HTTP), 443 (HTTPS)
   - All other ports are blocked
   
4. **SSL/TLS**: 
   - Self-signed certificates are generated by default
   - For production, replace with real certificates (Let's Encrypt recommended)
   - Configure `server_name` in `group_vars/all.yml`
   
5. **Database**: PostgreSQL requires strong password authentication
   - User: `microblog_user`
   - Configure `pg_hba.conf` for IP-based access control
   
6. **Redis**: 
   - Password authentication is enforced
   - Bind to localhost only (no network exposure)
   - Configure `requirepass` in redis.conf
   
7. **Elasticsearch**: 
   - Not exposed to external network in default configuration
   - Consider enabling X-Pack security for production use

## Troubleshooting

### SSH Connection Issues

```bash
# Test SSH connectivity
ansible all -i inventory -m ping

# Verify SSH key permissions
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
```

### Service Not Starting

```bash
# Check logs on target server
sudo systemctl status gunicorn
sudo journalctl -u gunicorn -n 50
```

### Database Connection Issues

```bash
# Test database connection
psql -h db01.example.com -U microblog_user -d microblog_db
```

### Redis Connection Issues

```bash
# Test Redis connection
redis-cli -h cache01.example.com -a password ping
```

### Elasticsearch Issues

```bash
# Check Elasticsearch health
curl -u elastic:password http://search01.example.com:9200/_cluster/health?pretty
```

## Maintenance Tasks

### Update All Packages

```bash
ansible all -i inventory -m apt -a "update_cache=yes upgrade=yes"
```

### Restart All Services

```bash
ansible all -i inventory -m systemd -a "name=gunicorn daemon_reload=yes state=restarted"
```

### Backup Database

```bash
ssh db01.example.com /usr/local/bin/backup-postgres.sh
```

### Check Log Files

```bash
# View application logs
ssh web01.example.com tail -f /var/log/microblog/error.log

# View Nginx logs
ssh web01.example.com tail -f /var/log/microblog/nginx/access.log
```

## Advanced Configuration

### Custom Variables

Create `host_vars/<hostname>.yml` for host-specific settings:

```yaml
---
gunicorn_workers: 8
redis_max_memory: 1gb
postgres_max_connections: 200
```

### Limiting Deployment Scope

```bash
# Deploy to specific servers
ansible-playbook site.yml -i inventory -l web01.example.com

# Deploy to specific groups
ansible-playbook site.yml -i inventory -l webservers
```

### Using Vault for Secrets

```bash
# Create encrypted variables file
ansible-vault create group_vars/all/vault.yml

# Run playbook with vault password
ansible-playbook site.yml -i inventory --ask-vault-pass
```

## Performance Tuning

### Increase Gunicorn Workers

Edit `group_vars/webservers.yml`:
```yaml
gunicorn_workers: 8  # Increase from 4
```

### Increase Redis Memory

Edit `group_vars/cacheservers.yml`:
```yaml
redis_max_memory: 2gb  # Increase from 512mb
```

### Configure PostgreSQL for Production

Edit `group_vars/dbservers.yml` and increase pool settings:
```yaml
max_connections: 200
shared_buffers: 1GB
```

## Rolling Updates

```bash
# Update web servers one at a time
ansible-playbook deploy.yml -i inventory -l webservers --serial 1
```

## Monitoring Integration

The playbooks include monitoring support. After deployment:

1. Configure Prometheus to scrape metrics
2. Import Grafana dashboards
3. Set up alerting rules

## Getting Help

For issues and questions:

1. Check Ansible logs: `cat /var/log/ansible.log`
2. Review service logs: `sudo journalctl -u <service>`
3. Run in debug mode: `ansible-playbook site.yml -i inventory -vvv`

## License

Same as main Microblog project
