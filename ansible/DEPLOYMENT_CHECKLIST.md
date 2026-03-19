# Deployment Checklist

Complete the following steps before running the Ansible playbook:

## Pre-Deployment Setup

- [ ] Ansible installed on control machine (`pip install ansible`)
- [ ] SSH keys generated and configured
- [ ] SSH key-pair authentication tested to all target servers
- [ ] Python 3.8+ installed on all target servers
- [ ] All servers have internet access for package downloads
- [ ] GitHub repository is accessible (public or SSH key added)

## Configuration Steps

- [ ] Update `inventory` file with actual server IPs/hostnames
- [ ] Update `group_vars/all.yml` with correct values:
  - [ ] `git_repo` - Your GitHub repository URL
  - [ ] `git_branch` - Deployment branch (main/master)
  - [ ] `postgres_password` - Strong password for PostgreSQL
  - [ ] `redis_password` - Strong password for Redis
  - [ ] `secret_key` - Flask secret key
  - [ ] `server_name` - Domain name for application
  - [ ] `mail_server` - Email server configuration
  - [ ] `ms_translator_key` - Microsoft Translator API key (if needed)

- [ ] Update `group_vars/webservers.yml`:
  - [ ] `gunicorn_workers` - Based on server CPU count
  - [ ] `app_env` - Set to `production`

- [ ] Update `group_vars/dbservers.yml`:
  - [ ] `postgres_password` - Match with all.yml
  - [ ] Database parameters based on expected load

- [ ] Update `group_vars/cacheservers.yml`:
  - [ ] `redis_password` - Match with all.yml
  - [ ] `redis_max_memory` - Based on available RAM

- [ ] Update `group_vars/searchservers.yml`:
  - [ ] `elasticsearch_heap_size` - 50% of available system memory

## Pre-Flight Checks

```bash
# Test connectivity
ansible all -i inventory -m ping

# Check facts and variables
ansible all -i inventory -m setup

# Dry run
ansible-playbook site.yml -i inventory --check
```

- [ ] All servers respond to ping
- [ ] All servers have required Python modules
- [ ] Dry run completes without errors

## Deployment

```bash
# Run full deployment
ansible-playbook site.yml -i inventory

# Or deploy to specific groups
ansible-playbook site.yml -i inventory -l webservers
ansible-playbook site.yml -i inventory -l dbservers
```

- [ ] All playbooks run successfully
- [ ] No errors or failed tasks
- [ ] All services start successfully

## Post-Deployment Verification

```bash
# Run health checks
ansible-playbook health-check.yml -i inventory

# SSH to servers and verify
ssh ubuntu@web01.example.com
```

### On Web Servers:

- [ ] Flask application is running: `systemctl status gunicorn`
- [ ] Nginx is running: `systemctl status nginx`
- [ ] RQ Worker is running: `systemctl status rq-worker`
- [ ] Application accessible: `curl http://localhost:8000`

### On Database Server:

- [ ] PostgreSQL is running: `systemctl status postgresql`
- [ ] Database created: `psql -l | grep microblog_db`
- [ ] Database user exists: `psql -c "\du" | grep microblog_user`

### On Cache Server:

- [ ] Redis is running: `systemctl status redis-server`
- [ ] Redis responding: `redis-cli -a password ping`

### On Search Server:

- [ ] Elasticsearch is running: `systemctl status elasticsearch`
- [ ] Elasticsearch responding: `curl localhost:9200`

## Next Steps

1. **SSL Certificates**: Set up Let's Encrypt for HTTPS
   ```bash
   sudo apt install certbot python3-certbot-nginx
   sudo certbot certonly --standalone -d microblog.example.com
   ```

2. **Backup Configuration**: Verify backup scripts are working
   ```bash
   sudo /usr/local/bin/backup-postgres.sh
   ```

3. **Monitoring Setup**: Configure Prometheus and Grafana
4. **Domain DNS**: Point domain to Nginx server IP
5. **Initial Data**: Create admin user and test data
6. **Security Hardening**: Review firewall rules and fail2ban

## Troubleshooting

If any step fails:

1. Check the error message from Ansible
2. SSH to the server and check service logs
3. Review role/task files for the issue
4. Modify variables if needed and re-run

```bash
# Get detailed debug output
ansible-playbook site.yml -i inventory -vvv

# Check service status on target
ansible webservers -i inventory -m systemd -a "name=gunicorn state=started"

# View service logs
ansible webservers -i inventory -m shell -a "journalctl -u gunicorn -n 20"
```
