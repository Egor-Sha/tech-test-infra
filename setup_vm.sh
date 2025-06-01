#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

VM_DISK_IMAGE="$SCRIPT_DIR/debian10-ssh.img"
VM_ARCHIVE_URL="https://immfly-infra-technical-test.s3-eu-west-1.amazonaws.com/debian10-ssh.img.tar.xz"
VM_ARCHIVE_NAME="$SCRIPT_DIR/debian10-ssh.img.tar.xz"
VM_XML_PATH="$SCRIPT_DIR/assets/vm.xml"
VM_XML_TMP="$SCRIPT_DIR/vm_tmp.xml"
VM_NAME="immfly-debian10"

if [ ! -f "$VM_ARCHIVE_NAME" ]; then
  echo "Downloading VM image..."
  curl -Lo "$VM_ARCHIVE_NAME" "$VM_ARCHIVE_URL"
fi

if [ ! -f "$VM_DISK_IMAGE" ]; then
  echo "Extracting VM image..."
  tar -xf "$VM_ARCHIVE_NAME" -C "$SCRIPT_DIR"
  echo "Removing VM archive to save space..."
  rm -f "$VM_ARCHIVE_NAME"  
fi

echo "Updating VM XML with disk path..."
DISK_PATH="$(realpath "$VM_DISK_IMAGE")"
sed "s|\${PATH_TO_VM_DISK_FILE}|$DISK_PATH|" "$VM_XML_PATH" > "$VM_XML_TMP"

if virsh list --all | grep -q "$VM_NAME"; then
  echo "Destroying old VM definition (if exists)..."
  virsh destroy "$VM_NAME" || true
  virsh undefine "$VM_NAME"
fi

echo "Defining and starting VM..."
virsh define "$VM_XML_TMP"
virsh start "$VM_NAME"

echo "Waiting for VM boot..."
echo "Waiting 40 seconds for VM IP assignment..."
sleep 50

VM_IP=$(virsh domifaddr "$VM_NAME" | awk '/ipv4/ {print $4}' | cut -d/ -f1)
sleep 10

if [ -z "$VM_IP" ]; then
  echo "Failed to detect VM IP. Exiting."
  exit 1
fi

echo "Detected VM IP: $VM_IP"

echo "Waiting for SSH to become available on $VM_IP..."
for i in {1..10}; do
  if nc -z "$VM_IP" 22; then
    echo "SSH is available on $VM_IP"
    break
  else
    echo "Attempt $i: SSH not available yet. Retrying in 5 seconds..."
    sleep 5
  fi
done

echo "Scanning SSH key from VM..."
if ssh-keyscan "$VM_IP" > "$SCRIPT_DIR/assets/known_hosts" 2>/dev/null; then
  echo "SSH key successfully scanned."
else
  echo "Failed to scan SSH key from $VM_IP. Exiting."
  exit 1
fi

cat > "$SCRIPT_DIR/ansible/inventory.ini" <<EOF
[debian_vm]
$VM_IP ansible_user=toor 
EOF

rm -f "$SCRIPT_DIR/vm_tmp.xml"
