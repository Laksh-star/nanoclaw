#!/bin/bash
# Build the BizClaw agent container image

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Read INSTANCE_NAME from .env if present, default to bizclaw
INSTANCE_NAME=$(grep -E '^INSTANCE_NAME=' "$SCRIPT_DIR/../.env" 2>/dev/null | cut -d'=' -f2 | tr -d '[:space:]' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')
INSTANCE_NAME="${INSTANCE_NAME:-bizclaw}"

IMAGE_NAME="${INSTANCE_NAME}-agent"
TAG="${1:-latest}"
CONTAINER_RUNTIME="${CONTAINER_RUNTIME:-container}"

echo "Building BizClaw agent container image..."
echo "Instance: ${INSTANCE_NAME}"
echo "Image: ${IMAGE_NAME}:${TAG}"

${CONTAINER_RUNTIME} build -t "${IMAGE_NAME}:${TAG}" .

echo ""
echo "Build complete!"
echo "Image: ${IMAGE_NAME}:${TAG}"
echo ""
echo "Test with:"
echo "  echo '{\"prompt\":\"What is 2+2?\",\"groupFolder\":\"test\",\"chatJid\":\"test@g.us\",\"isMain\":false}' | ${CONTAINER_RUNTIME} run -i ${IMAGE_NAME}:${TAG}"
