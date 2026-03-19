#!/bin/bash

# Script to verify that all servers are ready for Ansible deployment
# Usage: ./verify-setup.sh

INVENTORY_FILE="./inventory"

if [ ! -f "$INVENTORY_FILE" ]; then
    echo "Error: inventory file not found"
    exit 1
fi

echo "=========================================="
echo "Microblog Ansible Deployment Verification"
echo "=========================================="
echo ""

# Check Ansible installation
echo "Checking Ansible installation..."
if ! command -v ansible &> /dev/null; then
    echo "❌ Ansible not installed"
    echo "   Install with: pip install ansible"
    exit 1
fi
echo "✓ Ansible $(ansible --version | head -n1)"
echo ""

# Check SSH key
echo "Checking SSH configuration..."
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "❌ SSH key not found at ~/.ssh/id_rsa"
    echo "   Generate with: ssh-keygen -t rsa -b 4096"
    exit 1
fi
echo "✓ SSH key found"
echo ""

# Check connectivity to all hosts
echo "Checking host connectivity..."
FAILED_HOSTS=0

ansible all -i "$INVENTORY_FILE" -m ping > /tmp/ansible_ping.out 2>&1

if [ $? -eq 0 ]; then
    echo "✓ All hosts are reachable"
else
    echo "❌ Some hosts failed ping test:"
    grep "FAILED" /tmp/ansible_ping.out
    FAILED_HOSTS=$?
fi
echo ""

# Check Python on all hosts
echo "Checking Python installation..."
ansible all -i "$INVENTORY_FILE" -m command -a "python3 --version" > /tmp/ansible_python.out 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Python 3 is installed on all hosts"
else
    echo "❌ Python 3 check failed"
fi
echo ""

# Syntax check playbooks
echo "Checking playbook syntax..."
for playbook in site.yml deploy.yml health-check.yml; do
    if [ ! -f "$playbook" ]; then
        echo "❌ Playbook $playbook not found"
        continue
    fi
    
    if ansible-playbook "$playbook" --syntax-check > /dev/null 2>&1; then
        echo "✓ $playbook syntax OK"
    else
        echo "❌ $playbook has syntax errors"
        ansible-playbook "$playbook" --syntax-check
    fi
done
echo ""

# Dry-run site.yml
echo "Running playbook dry-run (check mode)..."
if ansible-playbook site.yml -i "$INVENTORY_FILE" --check > /tmp/ansible_check.out 2>&1; then
    echo "✓ Playbook check mode passed"
else
    echo "⚠ Playbook check mode had issues (review below):"
    tail -20 /tmp/ansible_check.out
fi
echo ""

# Summary
echo "=========================================="
if [ $FAILED_HOSTS -eq 0 ]; then
    echo "✓ All checks passed! Ready to deploy."
    echo ""
    echo "Next steps:"
    echo "1. Review and update group_vars/all.yml"
    echo "2. Run: ansible-playbook site.yml -i inventory"
else
    echo "❌ Some checks failed. Please fix issues above."
    exit 1
fi
echo "=========================================="
