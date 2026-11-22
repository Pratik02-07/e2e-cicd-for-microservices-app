# Architecture — End-to-End CI/CD for Microservices App

## High-level flow

```text
┌─────────────┐      ┌──────────────┐      ┌─────────────────┐
│  Developer  │─────►│   GitHub     │─────►│ Jenkins Webhook │
│  (feature   │      │  main/dev/   │      │  (push trigger) │
│   branch)   │      │  feature     │      └─────────────────┘
└─────────────┘      └──────────────┘                │
                                             ┌───────▼───────┐
                                             │   Jenkins     │
                                             │ Declarative   │
                                             │ Pipeline      │
                                             │ 8 stages      │
                                             └───────┬───────┘
                                                     │
              ┌──────────┬──────────┬──────────┐   │
              ▼          ▼          ▼          ▼   ▼
        Checkout   Build+Test  SonarQube   Trivy  Docker Build
          (gate)   (pytest)   [GATE 1]   [GATE 2]
                                                     │
              ┌──────────┬──────────┬──────────┐   │
              ▼          ▼          ▼          ▼   │
           Push     Deploy Dev  Approval   Deploy  │
         images     (auto)   [GATE 3]   Staging+Prod│
                                                    │
                              ┌───────┴─────────┐   │
                              ▼                 ▼   │
                         Slack/Email   Rollback job │
                       (notify)     (parameterized) │
```

## Components

| Layer | Tool | Purpose |
|-------|------|---------|
| Source control | GitHub | main/develop/feature branches, PR reviews, branch protection |
| CI/CD | Jenkins | Declarative pipeline, 8 stages, 3 quality gates |
| Code quality | SonarQube | Gate 1 — blocks build on quality-gate failure |
| Container scanning | Trivy | Gate 2 — blocks build on CRITICAL/HIGH CVEs |
| Registry | Docker Hub / AWS ECR | Versioned image tags (commit SHA + latest) |
| Config management | Ansible | Roles: docker + deploy_app; separate inventory per env |
| Secrets | Ansible Vault + Jenkins credentials | No secrets in Git |
| Deployment | Docker Compose | 3 services: frontend, product-service, cart-service |
| Notification | Slack / Email | Success/failure alerts |
| Rollback | Parameterized Jenkins job + rollback.sh | Re-deploy previous image tag |

## Environments

- **Dev** — auto-deploy on `develop` branch push
- **Staging** — auto-deploy on `main` merge (after approval)
- **Production** — manual approval gate, then deploy

## Networking

Each service exposes a `/health` endpoint. Ansible verifies health (`HTTP 200`) before marking a deploy successful. Services communicate over a Docker bridge network (`app-net`).
