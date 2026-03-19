#!/bin/bash

# Script to display deployment information and usage
# Run this after successful deployment

echo "=========================================="
echo "  Microblog Ansible Deployment Complete"
echo "=========================================="
echo ""

# Read inventory and extract hosts
WEBSERVERS=$(grep -A 10 "^\[webservers\]" inventory | grep -v "^\[" | grep -v "^$" | awk '{print $1}')
DBSERVERS=$(grep -A 10 "^\[dbservers\]" inventory | grep -v "^\[" | grep -v "^$" | awk '{print $1}')
CACHESERVERS=$(grep -A 10 "^\[cacheservers\]" inventory | grep -v "^\[" | grep -v "^$" | awk '{print $1}')
SEARCHSERVERS=$(grep -A 10 "^\[searchservers\]" inventory | grep -v "^\[" | grep -v "^$" | awk '{print $1}')

echo "DEPLOYMENT SERVERS:"
echo "=================="
echo "Web Servers: $WEBSERVERS"
echo "Database Servers: $DBSERVERS"
echo "Cache Servers: $CACHESERVERS"
echo "Search Servers: $SEARCHSERVERS"
echo ""

echo "QUICK COMMANDS:"
echo "==============="
echo ""
echo "# Check application status"
echo "ansible webservers -i inventory -m systemd -a 'name=gunicorn state=started'"
echo ""
echo "# View application logs"
echo "ssh ubuntu@$WEBSERVERS tail -f /var/log/microblog/error.log"
echo ""
echo "# Check database"
echo "ansible dbservers -i inventory -m shell -a 'systemctl status postgresql'"
echo ""
echo "# Update application"
echo "ansible-playbook deploy.yml -i inventory"
echo ""
echo "# Health check"
echo "ansible-playbook health-check.yml -i inventory"
echo ""

echo "NEXT STEPS:"
echo "==========="
echo "1. Configure SSL certificates (Let's Encrypt recommended)"
echo "   sudo certbot certonly --standalone -d your-domain.com"
echo ""
echo "2. Update Nginx SSL configuration with certificate paths"
echo "   Edit: /etc/nginx/sites-available/microblog"
echo ""
echo "3. Create admin user:"
echo "   ssh ubuntu@$WEBSERVERS"
echo "   cd ~/microblog"
echo "   source venv/bin/activate"
echo "   flask shell"
echo "   >>> from app import db; from app.models import User"
echo "   >>> u = User(username='admin', email='admin@example.com')"
echo "   >>> u.set_password('admin123')"
echo "   >>> db.session.add(u)"
echo "   >>> db.session.commit()"
echo ""
echo "4. Visit your application:"
echo "   https://your-domain.com"
echo ""

echo "MONITORING:"
echo "==========="
echo "Application logs: /var/log/microblog/error.log"
echo "Access logs: /var/log/microblog/nginx/access.log"
echo "Database backups: /var/backups/postgres/"
echo ""

echo "=========================================="
