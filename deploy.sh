#!/bin/bash

set -e

# Variables
KEY_PATH="./assets/rsa"
IMAGE_NAME="ansible-runner"
CONTAINER_WORKDIR="/ansible"

if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "[INFO] Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

if ! ssh-add -l | grep -q "$KEY_PATH"; then
    echo "[INFO] Adding $KEY_PATH to ssh-agent..."
    ssh-add "$KEY_PATH"
fi

echo "[INFO] Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "[INFO] Running Ansible in Docker..."
docker run -it --rm \
    -v "$(pwd)/ansible:${CONTAINER_WORKDIR}/ansible" \
    -v "$(pwd)/assets:${CONTAINER_WORKDIR}/assets" \
    -v "$SSH_AUTH_SOCK:/ssh-agent" \
    -e SSH_AUTH_SOCK=/ssh-agent \
    "$IMAGE_NAME" \
    ansible-playbook -i ${CONTAINER_WORKDIR}/ansible/inventory.ini ${CONTAINER_WORKDIR}/ansible/playbook.yaml

