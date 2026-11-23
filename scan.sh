#!/usr/bin/env bash
# ==============================================================================
# Script Name: scan.sh
# Version:     1.0
# Description: Scans Docker images for CRITICAL and HIGH vulnerabilities using Trivy.
#              Accepts an optional tag argument (defaults to 'latest').
#              Exits with status 1 if any vulnerabilities are found.
# ==============================================================================

set -uo pipefail

TAG="${1:-latest}" # Pass a tag as an argument (e.g., ./scan.sh v1.0), defaults to 'latest'

# List of Docker images to scan
IMAGES=(
  "pratik0207/product-service:${TAG}"
  "pratik0207/frontend:${TAG}"
  "pratik0207/cart-service:${TAG}"
)

TRIVY_IMAGE="aquasec/trivy:latest"
SEVERITIES="CRITICAL,HIGH"
FAILED=0

echo "=========================================="
echo " Starting Trivy Vulnerability Scan..."
echo " Target Tag: ${TAG}"
echo "=========================================="

for IMAGE in "${IMAGES[@]}"; do
  echo ""
  echo ">>> Scanning image: ${IMAGE}"
  
  if docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    "${TRIVY_IMAGE}" image \
    --exit-code 1 \
    --severity "${SEVERITIES}" \
    "${IMAGE}"; then
    echo "PASS: No ${SEVERITIES} vulnerabilities found in ${IMAGE}"
  else
    echo "FAIL: ${SEVERITIES} vulnerabilities detected (or scan error) in ${IMAGE}"
    FAILED=1
  fi
done

echo ""
echo "=========================================="
if [ "${FAILED}" -ne 0 ]; then
  echo "Scan completed with failures for tag: ${TAG}"
  exit 1
else
  echo "All images passed the vulnerability scan for tag: ${TAG}!"
  exit 0
fi
