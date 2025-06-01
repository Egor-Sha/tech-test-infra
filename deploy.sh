#!/usr/bin/env bash

set -euo pipefail

IMAGE_NAME="ansible-runner"
CONTAINER_WORKDIR="/ansible"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEY_PATH="$SCRIPT_DIR/assets/rsa"

echo "Running setup_vm.sh to prepare VM..."
chmod +x "$SCRIPT_DIR/setup_vm.sh"
"$SCRIPT_DIR/setup_vm.sh"

echo "[INFO] Building Docker image..."
docker build -t "$IMAGE_NAME" "$SCRIPT_DIR"

if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "[INFO] Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

if ! ssh-add -l | grep -q "$KEY_PATH"; then
    echo "[INFO] Adding $KEY_PATH to ssh-agent..."
    ssh-add "$KEY_PATH"
fi

echo "[INFO] Running Ansible in Docker..."
docker run -it --rm \
    --network=host \
    -v "$SCRIPT_DIR/ansible:${CONTAINER_WORKDIR}" \
    -v "$SCRIPT_DIR/assets:${CONTAINER_WORKDIR}/assets" \
    -v "$SSH_AUTH_SOCK:/ssh-agent" \
    -e SSH_AUTH_SOCK=/ssh-agent \
    -v "$SCRIPT_DIR/assets/known_hosts:/etc/ssh/ssh_known_hosts:ro" \
    "$IMAGE_NAME" \
    ansible-playbook -i ${CONTAINER_WORKDIR}/inventory.ini ${CONTAINER_WORKDIR}/playbook.yaml

echo "[INFO] Cleaning up ssh-agent..."
ssh-add -d "$KEY_PATH" 2>/dev/null || true
