# Ansible Quick Reference Guide

## Installation

```bash
# Using pip
pip install ansible

# Using apt (Ubuntu/Debian)
sudo apt-get install ansible

# Verify installation
ansible --version
```

## Directory Setup

```bash
cd /home/yao/fromGithub/microblog/ansible
```

## Initial Configuration

### 1. Update Inventory

Edit `inventory` file with your server IPs:
```ini
[webservers]
web01.example.com ansible_host=192.168.1.10

[dbservers]
db01.example.com ansible_host=192.168.1.11
```

### 2. Update Variables

Edit `group_vars/all.yml`:
```yaml
git_repo: your-repo-url
postgres_password: your-password
redis_password: your-password
secret_key: your-secret-key
server_name: your-domain.com
```

## Essential Commands

### Basic Commands

```bash
# Ping all hosts
ansible all -i inventory -m ping

# Run adhoc command
ansible all -i inventory -m shell -a "ls -la"

# Run as specific user
ansible all -i inventory -u ubuntu -m ping

# Run with sudo
ansible all -i inventory -m shell -a "whoami" -b
```

### Playbook Execution

```bash
# Full deployment
ansible-playbook site.yml -i inventory

# Update application only
ansible-playbook deploy.yml -i inventory

# Check system health
ansible-playbook health-check.yml -i inventory

# Dry run (check mode)
ansible-playbook site.yml -i inventory --check

# Show what will be changed
ansible-playbook site.yml -i inventory --check -vv
```

### Targeting Specific Hosts/Groups

```bash
# Target specific group
ansible-playbook site.yml -i inventory -l webservers

# Target specific host
ansible-playbook site.yml -i inventory -l web01.example.com

# Target multiple groups
ansible-playbook site.yml -i inventory -l "webservers,dbservers"

# Target hosts matching pattern
ansible-playbook site.yml -i inventory -l "web*"
```

### Verbosity Levels

```bash
# Normal output
ansible-playbook site.yml -i inventory

# Verbose (-v)
ansible-playbook site.yml -i inventory -v

# More verbose (-vv)
ansible-playbook site.yml -i inventory -vv

# Debug mode (-vvv)
ansible-playbook site.yml -i inventory -vvv

# Show variables
ansible-playbook site.yml -i inventory -vvv | grep vars
```

### Service Management

```bash
# Check service status
ansible webservers -i inventory -m systemd -a "name=gunicorn state=started"

# Start service
ansible webservers -i inventory -m systemd -a "name=gunicorn state=started"

# Stop service
ansible webservers -i inventory -m systemd -a "name=gunicorn state=stopped"

# Restart service
ansible webservers -i inventory -m systemd -a "name=gunicorn state=restarted"

# Reload service
ansible webservers -i inventory -m systemd -a "name=gunicorn state=reloaded"

# Enable service on boot
ansible webservers -i inventory -m systemd -a "name=gunicorn enabled=yes"
```

### Package Management

```bash
# Update package index
ansible all -i inventory -m apt -a "update_cache=yes"

# Install package
ansible all -i inventory -m apt -a "name=vim state=present"

# Update all packages
ansible all -i inventory -m apt -a "upgrade=yes update_cache=yes"

# Remove package
ansible all -i inventory -m apt -a "name=vim state=absent"
```

### File Management

```bash
# Copy file
ansible all -i inventory -m copy -a "src=/local/file dest=/remote/path"

# Create directory
ansible all -i inventory -m file -a "path=/tmp/test state=directory"

# Create file
ansible all -i inventory -m file -a "path=/tmp/test.txt state=touch"

# Change permissions
ansible all -i inventory -m file -a "path=/tmp/test mode=755"

# View file
ansible all -i inventory -m shell -a "cat /path/to/file"
```

### System Information

```bash
# Get all facts
ansible all -i inventory -m setup

# Get specific facts
ansible all -i inventory -m setup -a "filter=ansible_os_family"

# Show distribution
ansible all -i inventory -m setup -a "filter=ansible_distribution"

# Show kernel version
ansible all -i inventory -m setup -a "filter=ansible_kernel"

# Show available memory
ansible all -i inventory -m setup -a "filter=ansible_memtotal_mb"
```

### Logs and Debugging

```bash
# View task output
ansible-playbook site.yml -i inventory | head -100

# Save output to file
ansible-playbook site.yml -i inventory > deployment.log 2>&1

# View Ansible log
cat /var/log/ansible.log

# Enable debug logging
export ANSIBLE_DEBUG=1
ansible-playbook site.yml -i inventory

# Show registered variables
ansible-playbook site.yml -i inventory -v | grep "register"
```

## Special Variables

### Built-in Variables

```yaml
# Inventory hostname
{{ inventory_hostname }}

# Group names for current host
{{ group_names }}

# All groups in inventory
{{ groups }}

# All hosts in inventory
{{ groups['all'] }}

# Current host groups
{{ groups[inventory_hostname] }}

# Command output
{{ shell_output.stdout }}

# Error output
{{ shell_output.stderr }}

# Return code
{{ shell_output.rc }}
```

## Common Patterns

### Run Once Per Group

```bash
ansible-playbook site.yml -i inventory --serial 1
```

### Skip a Task

```bash
ansible-playbook site.yml -i inventory --skip-tags "tag_name"
```

### Run Only Specific Task

```bash
ansible-playbook site.yml -i inventory --tags "tag_name"
```

### Run with Extra Variables

```bash
ansible-playbook site.yml -i inventory -e "var_name=value"

# Multiple variables
ansible-playbook site.yml -i inventory \
  -e "postgres_password=pass123" \
  -e "redis_password=pass456" \
  -e "app_env=production"
```

### Ask for Become Password

```bash
ansible-playbook site.yml -i inventory -K
```

### Increase Timeout

```bash
ansible-playbook site.yml -i inventory -e "ansible_command_timeout=300"
```

## Troubleshooting

### SSH Issues

```bash
# Test SSH connection
ssh -i ~/.ssh/id_rsa ubuntu@server-ip

# Check SSH key permissions
ls -la ~/.ssh/
chmod 600 ~/.ssh/id_rsa

# Test ansible connectivity
ansible webservers -i inventory -m ping -vv
```

### Package Issues

```bash
# Check if package installed
ansible all -i inventory -m apt -a "name=nginx state=present"

# Install specific version
ansible all -i inventory -m apt -a "name=postgresql-15 state=present"
```

### Permission Issues

```bash
# Run with sudo
ansible all -i inventory -m shell -a "whoami" -b

# Run as specific user
ansible all -i inventory -u ubuntu -m shell -a "whoami" -b
```

### Display Variables

```bash
# Show all variables for a host
ansible webservers -i inventory -m debug -a "var=hostvars[inventory_hostname]"

# Show specific variable
ansible webservers -i inventory -m debug -a "var=app_path"
```

## Performance Tips

### Parallel Execution

```bash
# Run on 10 hosts in parallel (default is 5)
ansible-playbook site.yml -i inventory --forks 10
```

### Fact Caching

Ansible caches facts by default with:
```ini
fact_caching = jsonfile
fact_caching_connection = /tmp/facts_cache
fact_caching_timeout = 86400
```

### Gather Facts Optimizatios

```bash
# Use smart gathering
export ANSIBLE_GATHERING=smart

# Or disable gathering (if not needed)
export ANSIBLE_GATHERING=explicit
```

## Useful One-Liners

```bash
# List all hosts
ansible all -i inventory --list-hosts

# List hosts in group
ansible webservers -i inventory --list-hosts

# Show host details
ansible webservers -i inventory -m setup -a "filter=*ip*"

# Get IP address
ansible all -i inventory -m setup -a "filter=ansible_default_ipv4" | grep address

# Uptime of all servers
ansible all -i inventory -m shell -a "uptime"

# Disk usage
ansible all -i inventory -m shell -a "df -h"

# Memory usage
ansible all -i inventory -m shell -a "free -h"

# Check service status
ansible webservers -i inventory -m shell -a "systemctl status gunicorn"

# Restart all services
ansible webservers -i inventory -m systemd -a "name=gunicorn state=restarted"
```

## References

- **Official Docs**: https://docs.ansible.com
- **Module Index**: https://docs.ansible.com/ansible/latest/modules/
- **Best Practices**: https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html
