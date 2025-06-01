Setup & Deployment Guide

This project demonstrates automated deployment of a frontend and backend "clock" application using Ansible and Docker.

The whole process is launches by bash deploy.sh

1. VM Setup 

setup_vm.sh

The setup_vm.sh script handles initialization of a Debian 10 virtual machine with SSH access.

This script:

    Creates a Debian VM using a downloaded image.

    Boots the VM and waits for it to receive an IP.

    Verifies SSH connectivity and scans the host key.

    Stores the VM IP and SSH info in assets/.

2. Running Ansible Playbooks (Deployment)

deploy.sh

Use the deploy.sh script to run the complete provisioning and deployment process.

This script:

    Calls setup_vm.sh to setup VM.

    Builds a Docker image with Ansible and SSH support.

    Starts an Ansible container and runs playbook.yaml from inside.

    Deploys backend frontend containers.

    Uses SSH agent forwarding to connect securely to the VM.
