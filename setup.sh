#!/usr/bin/env bash
set -e

echo "=========================================="
echo "1. Starting Jenkins Container..."
echo "=========================================="
# Remove existing container if re-running (preserves jenkins_home volume)
docker rm -f jenkins 2>/dev/null || true

docker run -d \
  --name jenkins \
  --restart unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

echo "Waiting for Jenkins to initialize..."
until docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; do
  sleep 3
done

echo "=========================================="
echo "2. Installing Jenkins Plugins..."
echo "=========================================="
# Uses Jenkins' built-in plugin installation manager CLI
docker exec -u root jenkins jenkins-plugin-cli --plugins \
  sonar \
  docker-workflow \
  ansible \
  slack \
  workflow-aggregator

echo "Restarting Jenkins to activate plugins..."
docker restart jenkins

echo "=========================================="
echo "3. Starting SonarQube Container..."
echo "=========================================="
docker rm -f sonarqube 2>/dev/null || true

docker run -d \
  --name sonarqube \
  --restart unless-stopped \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:community

echo "=========================================="
echo "4. Pulling Trivy Image..."
echo "=========================================="
docker pull aquasec/trivy:latest

# Wait for Jenkins to come back up after restart
until docker exec jenkins test -f /var/jenkins_home/secrets/initialAdminPassword 2>/dev/null; do
  sleep 2
done
ADMIN_PASS=$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "Jenkins URL:      http://localhost:8080"
echo "Initial Password: ${ADMIN_PASS}"
echo ""
echo "SonarQube URL:    http://localhost:9000 (Default login: admin / admin)"
echo ""
echo "Next Manual Steps:"
echo "1. Log into SonarQube -> My Account -> Security -> Generate a token."
echo "2. In Jenkins -> Manage Jenkins -> Credentials -> Add Secret Text with ID: 'sonar-token'."
echo "3. Run Trivy scans anytime using:"
echo "   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image <your-image>"
echo "=========================================="
