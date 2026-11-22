# End-to-End CI/CD Pipeline for a Microservices App

**Capstone Project 1** — Build a complete delivery pipeline from a GitHub commit to running containers across Dev, Staging, and Production environments, with quality gates (SonarQube + Trivy), manual production approval, Slack/email notifications, and parameterized rollback.

> **Role:** Fresher AWS DevOps Engineer | **Duration:** ~2 weeks | **Stack:** GitHub • Jenkins • Docker • Docker Compose • Ansible • SonarQube • Trivy • AWS EC2/ECR

---

## Table of Contents
1. [Architecture](#architecture)
2. [Repository Structure](#repository-structure)
3. [Prerequisites](#prerequisites)
4. [Setup — Local / AWS EC2](#setup)
5. [Jenkins Pipeline (8 Stages, 3 Gates)](#jenkins-pipeline)
6. [Ansible Multi-Environment Deployment](#ansible-multi-environment-deployment)
7. [Quality Gates & Security](#quality-gates--security)
8. [Rollback Procedure](#rollback-procedure)
9. [Demo Checklist for Interviews](#demo-checklist-for-interviews)
10. [What Broke & How We Fixed It](#what-broke--how-we-fixed-it)

---

## Architecture

```
Developer push to GitHub
        |
        v (webhook)
   Jenkins Controller
        |
   Jenkinsfile (declarative pipeline)
   ├─ Stage 1: Checkout
   ├─ Stage 2: Build (unit tests)
   ├─ Stage 3: SonarQube analysis  [GATE 1: quality gate must pass]
   ├─ Stage 4: Trivy image scan    [GATE 2: no critical CVEs]
   ├─ Stage 5: Docker build + tag (commit SHA)
   ├─ Stage 6: Push to AWS ECR / Docker Hub
   ├─ Stage 7: Deploy to Dev  (Ansible, auto)
   ├─ input: Manual approval       [GATE 3: production]
   └─ Stage 8: Deploy to Staging/Prod (Ansible)
        |
   Slack / Email notification (success or failure)
```

**Environments:** Dev, Staging, Production — each with its own Ansible inventory and variable file.

**Services:** `frontend`, `product-service`, `cart-service` (simple Flask APIs, orchestrated with Docker Compose).

---

## Repository Structure

```
End-to-End CICD for Microservices App/
├── README.md
├── ARCHITECTURE.md
├── sonar-project.properties
├── docker-compose.yml
├── .gitignore
├── services/
│   ├── frontend/
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   ├── product-service/
│   │   ├── app.py
│   │   ├── requirements.txt
│   │   └── Dockerfile
│   └── cart-service/
│       ├── app.py
│       │   └── Dockerfile
├── jenkins/
│   └── Jenkinsfile
├── ansible/
│   ├── ansible.cfg
│   ├── site.yml
│   ├── vault.yml
│   ├── vault_password.txt
│   ├── inventory/
│   │   ├── dev/hosts.yml
│   │   ├── staging/hosts.yml
│   │   └── prod/hosts.yml
│   ├── group_vars/
│   │   ├── dev.yml
│   │   ├── staging.yml
│   │   └── prod.yml
│   └── roles/
│       ├── docker/
│       │   └── tasks/main.yml
│       └── deploy_app/
│           ├── tasks/main.yml
│           ├── templates/docker-compose.j2
│           └── vars/main.yml
├── scripts/
│   └── rollback.sh
└── .github/
    └── workflows/
        └── pr-validation.yml
```

---

## Prerequisites

| Tool | Purpose | Install |
|------|---------|---------|
| Docker & Docker Compose | Containerize services | [docker.com](https://docs.docker.com/engine/install/) |
| Jenkins | CI/CD orchestrator | `docker run -p 8080:8080 jenkins/jenkins:lts` |
| SonarQube | Code quality gate | `docker run -d --name sonarqube -p 9000:9000 sonarqube:community` |
| Trivy | Container vulnerability scan | `aquasec/trivy` (Docker) or binary |
| AWS CLI | ECR push (optional) | `pip install awscli` |
| Ansible | Config mgmt & deployment | `pip install ansible` |
| Python 3.11+ | Service runtime | python.org |

> **Cost tip:** Run everything on local VMs (Vagrant/VirtualBox) or AWS Free Tier EC2 (t2.micro). Remember to `terraform destroy` / terminate instances when done.

---

## Setup

### 1. Clone / initialize the repo
```bash
cd "E:\PRATIK\Coding\AWS-DevOps\Arbor-project\End-to-End CICD for Microservices App"
git init
git add .
git commit -m "chore: initial project scaffold"
git branch develop
git checkout -b feature/cicd-pipeline
```

### 2. Create GitHub repo & protect branches
- Create a private/public repo on GitHub: `microservices-cicd-capstone`
- Push `main`, `develop`, and feature branches
- Settings → Branches → Add rule for `main`:
  - Require pull request reviews before merging
  - Require status checks to pass
  - Restrict pushes to admins

### 3. Jenkins credentials (Manage Jenkins → Credentials)
| Credential ID | Type | Value |
|---------------|------|-------|
| `dockerhub-creds` | Secret text | Docker Hub password / AWS ECR token |
| `aws-access-key-id` | Secret text | AWS access key |
| `aws-secret-access-key` | Secret text | AWS secret key |
| `slack-webhook` | Secret text | Slack incoming webhook URL |
| `ansible-vault` | Secret text | Ansible Vault password |

### 4. SonarQube token
- Log into SonarQube → My Account → Security → Generate token → add as Jenkins secret text `sonar-token`

---

## Jenkins Pipeline (8 Stages, 3 Gates)

File: `jenkins/Jenkinsfile`

The pipeline is declarative. Stages run in order; a failed gate aborts the build.

**Three gates:**
1. **SonarQube quality gate** — must pass (no bugs, vulnerabilities, code smells above threshold)
2. **Trivy scan** — must find zero `CRITICAL` or `HIGH` vulnerabilities
3. **Manual approval** — required before deploying to Production

```groovy
pipeline {
    agent any

    environment {
        REGISTRY       = 'pratik0207'          // your Docker Hub / ECR repo name
        APP_NAME       = 'microservices-app'
        SONAR_URL      = 'http://localhost:9000'
        SONAR_TOKEN    = credentials('sonar-token')
        DOCKER_CREDS   = credentials('dockerhub-creds')
        ANSIBLE_VAULT  = credentials('ansible-vault')
        SLACK_WEBHOOK  = credentials('slack-webhook')
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                }
                echo "Building image tag: ${env.IMAGE_TAG}"
            }
        }

        stage('Build & Unit Tests') {
            steps {
                sh 'pip install -r services/product-service/requirements.txt'
                sh 'pip install -r services/cart-service/requirements.txt'
                sh 'pip install pytest'
                sh 'pytest services/ --tb=short -q'
            }
        }

        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                          -Dsonar.projectKey=microservices-app \
                          -Dsonar.sources=services \
                          -Dsonar.host.url=${SONAR_URL} \
                          -Dsonar.login=${SONAR_TOKEN}
                    '''
                }
                // Gate 1: wait for quality gate
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

        stage('Docker Build') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                        def frontendImg = docker.build("${REGISTRY}/frontend:${env.IMAGE_TAG}")
                        def productImg  = docker.build("${REGISTRY}/product-service:${env.IMAGE_TAG}")
                        def cartImg     = docker.build("${REGISTRY}/cart-service:${env.IMAGE_TAG}")

                        // Tag as latest too
                        frontendImg.tag("${REGISTRY}/frontend:latest")
                        productImg.tag("${REGISTRY}/product-service:latest")
                        cartImg.tag("${REGISTRY}/cart-service:latest")

                        echo "Images built and tagged: ${env.IMAGE_TAG}"
                    }
                }
            }
        }

        stage('Trivy Vulnerability Scan') {
            steps {
                sh '''
                    trivy image --exit-code 1 --severity CRITICAL,HIGH \
                      ${REGISTRY}/product-service:${env.IMAGE_TAG}
                    trivy image --exit-code 1 --severity CRITICAL,HIGH \
                      ${REGISTRY}/cart-service:${env.IMAGE_TAG}
                    trivy image --exit-code 1 --severity CRITICAL,HIGH \
                      ${REGISTRY}/frontend:${env.IMAGE_TAG}
                '''
            }
        }

        stage('Push Images to Registry') {
            steps {
                script {
                    docker.withRegistry('https://index.docker.io/v1/', 'dockerhub-creds') {
                        docker.image("${REGISTRY}/frontend:${env.IMAGE_TAG}").push()
                        docker.image("${REGISTRY}/frontend:latest").push()
                        docker.image("${REGISTRY}/product-service:${env.IMAGE_TAG}").push()
                        docker.image("${REGISTRY}/product-service:latest").push()
                        docker.image("${REGISTRY}/cart-service:${env.IMAGE_TAG}").push()
                        docker.image("${REGISTRY}/cart-service:latest").push()
                    }
                }
            }
        }

        stage('Deploy to Dev') {
            when { branch 'develop' }
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/site.yml',
                    inventory: 'ansible/inventory/dev/hosts.yml',
                    credentialsId: 'ansible-vault',
                    extraVars: "[env=dev, image_tag=${env.IMAGE_TAG}]"
                )
            }
        }

        stage('Manual Approval — Production') {
            when { branch 'main' }
            input message: 'Approve production deployment?', ok: 'Deploy to Production'
        }

        stage('Deploy to Staging & Production') {
            when { branch 'main' }
            steps {
                ansiblePlaybook(
                    playbook: 'ansible/site.yml',
                    inventory: 'ansible/inventory/staging/hosts.yml',
                    credentialsId: 'ansible-vault',
                    extraVars: "[env=staging, image_tag=${env.IMAGE_TAG}]"
                )
                ansiblePlaybook(
                    playbook: 'ansible/site.yml',
                    inventory: 'ansible/inventory/prod/hosts.yml',
                    credentialsId: 'ansible-vault',
                    extraVars: "[env=prod, image_tag=${env.IMAGE_TAG}]"
                )
            }
            post {
                success {
                    slackSend color: 'good', message: "*SUCCESS* Microservices app deployed to Staging & Prod (tag: ${env.IMAGE_TAG})"
                }
                failure {
                    slackSend color: 'danger', message: "*FAILURE* Pipeline failed at tag ${env.IMAGE_TAG}"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            slackSend color: 'danger', message: "*PIPELINE FAILED* ${env.JOB_NAME} #${env.BUILD_NUMBER} — ${env.BUILD_URL}"
        }
    }
}
```

> If you don't have the Ansible plugin, replace `ansiblePlaybook` steps with `sh 'ansible-playbook -i ... ansible/site.yml --extra-vars ...'`.

---

## Ansible Multi-Environment Deployment

Separate inventory + variables per environment. `ansible-vault` encrypts secrets (DB passwords, API keys).

### Inventory example (`ansible/inventory/dev/hosts.yml`)
```yaml
dev_servers:
  hosts:
    dev-ec2:
      ansible_host: 3.210.x.x          # replace with your EC2 public IP
      ansible_user: ec2-user
      ansible_ssh_private_key_file: ~/.ssh/id_rsa
  vars:
    ansible_python_interpreter: /usr/bin/python3
```

### Group vars (`ansible/group_vars/dev.yml`)
```yaml
env: dev
image_tag: latest
compose_file: docker-compose.yml
services:
  - frontend
  - product-service
  - cart-service
frontend_port: 80
product_port: 5001
cart_port: 5002
```

### Vault (`ansible/vault.yml`)
```yaml
db_password: "change_me_in_prod"
api_secret: "super-secret-key"
```
Encrypt: `ansible-vault encrypt ansible/vault.yml --vault-password-file ansible/vault_password.txt`

### Role: docker (`ansible/roles/docker/tasks/main.yml`)
```yaml
- name: Install required system packages
  apt:
    name: [apt-transport-https, ca-certificates, curl, gnupg, lsb-release]
    state: present
    update_cache: yes

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
    state: present

- name: Install Docker Engine
  apt:
    name: [docker-ce, docker-ce-cli, containerd.io, docker-compose-plugin]
    state: present

- name: Start and enable Docker
  service:
    name: docker
    state: started
    enabled: yes

- name: Add deploy user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes
```

### Role: deploy_app (`ansible/roles/deploy_app/tasks/main.yml`)
```yaml
- name: Create app directory
  file:
    path: /opt/{{ app_name }}
    state: directory
    mode: '0755'

- name: Copy docker-compose template
  template:
    src: docker-compose.j2
    dest: /opt/{{ app_name }}/docker-compose.yml
    mode: '0644'

- name: Pull and start containers
  community.docker.docker_compose_v2:
    project_src: /opt/{{ app_name }}
    build: no
  register: compose_result

- name: Verify service health
  uri:
    url: "http://{{ inventory_hostname }}:{{ frontend_port }}/health"
    return_content: yes
  register: health_check
  until: health_check.status == 200
  retries: 30
  delay: 5
```

### Template (`ansible/roles/deploy_app/templates/docker-compose.j2`)
```jinja2
version: '3.8'
services:
  frontend:
    image: {{ registry }}/frontend:{{ image_tag }}
    ports:
      - "{{ frontend_port }}:80"
    environment:
      - PRODUCT_URL=http://product-service:5001
      - CART_URL=http://cart-service:5002
    depends_on:
      - product-service
      - cart-service
    networks:
      - app-net

  product-service:
    image: {{ registry }}/product-service:{{ image_tag }}
    ports:
      - "{{ product_port }}:5001"
    networks:
      - app-net

  cart-service:
    image: {{ registry }}/cart-service:{{ image_tag }}
    ports:
      - "{{ cart_port }}:5002"
    networks:
      - app-net

networks:
  app-net:
    driver: bridge
```

### Master playbook (`ansible/site.yml`)
```yaml
- name: Provision and deploy microservices app
  hosts: all
  become: yes
  vars_files:
    - ../group_vars/{{ env }}.yml
    - ../vault.yml
  roles:
    - docker
    - deploy_app
```

Run manually for testing:
```bash
ansible-playbook -i ansible/inventory/dev/hosts.yml ansible/site.yml \
  --extra-vars "env=dev image_tag=abc1234 registry=pratik0207" \
  --vault-password-file ansible/vault_password.txt
```

---

## Rollback Procedure

File: `scripts/rollback.sh`

```bash
#!/bin/bash
# Usage: ./rollback.sh <environment> <previous_image_tag>
# Example: ./rollback.sh prod abc1234

ENV=$1
PREV_TAG=$2

if [[ -z "$ENV" || -z "$PREV_TAG" ]]; then
  echo "Usage: $0 <dev|staging|prod> <previous_image_tag>"
  exit 1
fi

echo "Rolling back $ENV to image tag $PREV_TAG..."

ansible-playbook -i ansible/inventory/$ENV/hosts.yml ansible/site.yml \
  --extra-vars "env=$ENV image_tag=$PREV_TAG registry=pratik0207" \
  --vault-password-file ansible/vault_password.txt

echo "Rollback complete. Verify: curl http://<server>:80/health"
```

Jenkins parameterized rollback job:
- String param: `ENVIRONMENT` (dev/staging/prod)
- String param: `PREVIOUS_TAG`
- Build step: shell → `scripts/rollback.sh $ENVIRONMENT $PREVIOUS_TAG`

---

## Quality Gates & Security

| Gate | Tool | Fail condition |
|------|------|----------------|
| Gate 1 | SonarQube | Quality gate status = ERROR (bugs/vulnerabilities/code smells) |
| Gate 2 | Trivy | Any `CRITICAL` or `HIGH` CVE in image |
| Gate 3 | Jenkins input | No production deploy without manual approval |

**Shift-left security:** Trivy scans run on every build before images are pushed. Secrets are never in Git — they live in Jenkins credentials + Ansible Vault.

---
<!-- 
## Demo Checklist for Interviews

- [ ] GitHub repo with `main`, `develop`, feature branches and PR review
- [ ] Jenkinsfile committed (declarative pipeline, 8 stages)
- [ ] SonarQube quality gate shown passing (screenshot)
- [ ] Trivy scan blocking a build with a critical CVE (screenshot of failure)
- [ ] Versioned image tags (`<sha>`, not just `latest`) in Docker Hub/ECR
- [ ] Ansible inventories for dev / staging / prod
- [ ] Ansible Vault used for secrets
- [ ] Manual approval gate before production (screenshot of Jenkins input step)
- [ ] Slack/email notification on pipeline success/failure
- [ ] Rollback demo: deploy bad tag → rollback to previous tag → service healthy
- [ ] README with architecture diagram
- [ ] "What broke and how we fixed it" write-up (see below)

---

## What Broke & How We Fixed It

> Interviewers love this story. Keep a real example from your build.

**Example:** First production deploy failed because the `product-service` container crashed on startup — the `DATABASE_URL` env var wasn't injected in the Jinja2 template, so the app couldn't connect.

**Fix:**
1. Added `environment` block to `docker-compose.j2` for `product-service`
2. Added `depends_on` and a healthcheck with `start_period`
3. Re-ran Ansible playbook; verified `/health` returns 200
4. Documented in runbook: "Always define DB env vars + healthchecks before marking a service healthy"

**What to say in interview:** *"I learned not to trust 'container started' as healthy — I added HTTP health checks with retries so Ansible only marks a deploy successful after the app actually responds."*

---

## Stretch Goals (stand out in interviews)

- [ ] Jenkins agent: controller + worker (distributed builds)
- [ ] Jenkins Shared Library for reusable pipeline functions
- [ ] Nginx reverse proxy with blue-green deployment between two app versions
- [ ] AWS ECR instead of Docker Hub (with IAM role for EC2)
- [ ] GitHub branch protection requiring the Jenkins pipeline to pass before merge

---
 -->
