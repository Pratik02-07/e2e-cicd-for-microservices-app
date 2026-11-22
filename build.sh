#!/usr/bin/env bash
set -euo pipefail

# Configuration
DOCKER_USER="pratik0207"
TAG="${1:-latest}" # Pass a tag as an argument (e.g., ./build.sh v1.0), defaults to 'latest'
SERVICES=("cart-service" "frontend" "product-service")

echo "=========================================="
echo " Building Docker Images (Tag: $TAG)..."
echo "=========================================="

for SERVICE in "${SERVICES[@]}"; do
  echo "--> Building $SERVICE..."
  docker build -t "${DOCKER_USER}/${SERVICE}:${TAG}" "./services/${SERVICE}"
done

echo "=========================================="
echo " Docker Images Built Successfully!"
echo "=========================================="

# echo "Pushing images to Docker Hub..."
# for SERVICE in "${SERVICES[@]}"; do
#   docker push "${DOCKER_USER}/${SERVICE}:${TAG}"
# done
# echo "Push complete!"
