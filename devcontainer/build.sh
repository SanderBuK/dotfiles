#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="claude-sandbox"

echo "==> Building $IMAGE_NAME base image..."
docker build \
  --build-arg TZ="${TZ:-Europe/Amsterdam}" \
  --build-arg CLAUDE_CODE_VERSION="${CLAUDE_CODE_VERSION:-latest}" \
  -t "$IMAGE_NAME:latest" \
  "$SCRIPT_DIR"

echo "==> Built $IMAGE_NAME:latest"
