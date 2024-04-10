#!/bin/bash

PROXY_FILE="/etc/systemd/system/docker.service.d/http-proxy.conf"

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

set_proxy() {
  local check=""

  mkdir -p /etc/systemd/system/docker.service.d
  check=$(systemctl show --property=Environment docker | grep prc)
  if [[ -z "$check" ]]; then
    echo "No proxy for docker internal, will set docker intel proxy:"
    echo "[Service]" > "$PROXY_FILE"
    echo "Environment=\"HTTP_PROXY=http://proxy-prc.intel.com:913\"" >> "$PROXY_FILE"
    echo "Environment=\"HTTPS_PROXY=http://proxy-prc.intel.com:913\"" >> "$PROXY_FILE"
    echo "cat $PROXY_FILE"
    cat "$PROXY_FILE"
    echo "sudo systemctl daemon-reload"
    sudo systemctl daemon-reload
    echo "sudo systemctl restart docker"
    sudo systemctl restart docker
    check=""
    check=$(systemctl show --property=Environment docker | grep prc)
    if [[ -z "$check" ]]; then
      echo "Failed to set proxy for docker: $check, please double check!"
      echo "Check file:$PROXY_FILE"
      echo "systemctl show --property=Environment docker | grep prc"
    else
      echo "After install, docker proxy info: $check"
    fi
  else
    echo "Has docker proxy:$check"
  fi
}

set_proxy
