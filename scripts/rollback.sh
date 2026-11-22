#!/bin/bash
# Usage: ./rollback.sh <environment> <previous_image_tag>
# Example: ./rollback.sh prod abc1234
set -euo pipefail

ENV="${1:?Usage: $0 <dev|staging|prod> <previous_image_tag>}"
PREV_TAG="${2:?Usage: $0 <dev|staging|prod> <previous_image_tag>}"
REGISTRY="${REGISTRY:-pratik0207}"

echo "Rolling back $ENV to image tag $PREV_TAG..."

ansible-playbook -i "ansible/inventory/$ENV/hosts.yml" ansible/site.yml \
  --extra-vars "env=$ENV image_tag=$PREV_TAG registry=$REGISTRY" \
  --vault-password-file ansible/vault_password.txt

echo "Rollback complete. Verify: curl http://<server>:80/health"
