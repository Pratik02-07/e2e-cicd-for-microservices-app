#!/bin/bash
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -aG docker ec2-user

# Install Amazon SSM Agent (already present on Amazon Linux, but ensure)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Write a marker file for Ansible to detect bootstrap completion
echo "bootstrap-complete-$(date +%s)" > /tmp/bootstrap-done