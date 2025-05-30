FROM python:3.10-slim

RUN apt-get update && \
    apt-get install -y \
        openssh-client \
        git \
        sudo \
        ansible && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -ms /bin/bash ansibleuser && \
    echo "ansibleuser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ansibleuser
WORKDIR /ansible

CMD [ "ansible-playbook", "--version" ]
