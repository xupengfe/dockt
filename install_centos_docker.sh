#!/bin/bash

echo "yum remove -y docker ..."
yum remove -y docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

echo "yum install -y yum-utils"
yum install -y yum-utils

yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

echo "yum remove -y podman.x86_64"
yum remove -y podman.x86_64

echo "yum install -y docker-ce docker-ce-cli containerd.io --allowerasing"
yum install -y docker-ce docker-ce-cli containerd.io --allowerasing

echo "systemctl restart docker"
systemctl restart docker
