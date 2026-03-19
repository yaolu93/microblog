# Ansible Deployment for Microblog Application

This directory contains Ansible playbooks and roles for deploying the Microblog Flask application across multiple servers with PostgreSQL, Redis, Elasticsearch, and Nginx.

## Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory                # Host inventory file
├── site.yml                 # Main deployment playbook
├── deploy.yml               # Application update playbook
├── health-check.yml         # Health check playbook
├── group_vars/              # Group-level variables
│   ├── all.yml             # Global variables
│   ├── webservers.yml      # Web server variables
│   ├── dbservers.yml       # Database server variables
│   ├── cacheservers.yml    # Redis server variables
│   └── searchservers.yml   # Elasticsearch server variables
├── host_vars/               # Host-specific variables (add as needed)
└── roles/                   # Ansible roles
    ├── common/              # Common setup for all servers
    ├── postgres/            # PostgreSQL database setup
    ├── redis/               # Redis cache setup
    ├── elasticsearch/       # Elasticsearch search setup
    ├── app/                 # Flask application deployment
    └── nginx/               # Nginx reverse proxy setup
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

## Role Descriptions

### Common Role
- Updates system packages
- Installs basic utilities (git, curl, vim, etc.)
- Creates application user
- Configures SSH and firewall
- Enables fail2ban for security

### PostgreSQL Role
- Installs PostgreSQL 15
- Creates databases and users
- Configures database parameters
- Sets up automated backups

### Redis Role
- Installs Redis server
- Configures cache settings
- Sets up persistence (AOF)
- Requires password authentication

### Elasticsearch Role
- Installs Elasticsearch 8.x
- Configures JVM memory settings
- Sets up security
- Enables performance tuning

### Application Role
- Clones/updates application from Git
- Creates Python virtual environment
- Installs Python dependencies
- Initializes database
- Compiles translations
- Sets up Gunicorn WSGI server
- Configures systemd services

### Nginx Role
- Installs Nginx web server
- Configures SSL/TLS
- Sets up reverse proxy
- Configures gzip compression
- Adds security headers
- Sets up log rotation

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

## Security Considerations

1. **Passwords**: Change all default passwords in `group_vars/`
2. **SSH**: Use SSH keys, disable password authentication
3. **Firewall**: UFW firewall is enabled by default
4. **SSL**: Generate real certificates (Let's Encrypt recommended)
5. **Database**: PostgreSQL requires password authentication
6. **Redis**: Redis requires password authentication
7. **Elasticsearch**: X-Pack security is enabled

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
