#!/bin/bash

install_docker() {
  echo "***no real docker, will install real docker.***"
  export https_proxy=http://child-prc.intel.com:913
  export http_proxy=http://child-prc.intel.com:913
  export all_proxy=http://child-prc.intel.com:913

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
  systemctl start docker
  systemctl enable docker
}

check_docker() {
  local real_docker=""

  real_docker=$(docker info | grep "Docker Inc" | head -n 1)
  echo "real_docker:$real_docker"
  [[ -n "$real_docker" ]] || install_docker
}

setup_syzkaller() {
  image="image"

  [[ -f "$image" ]] || {
    echo "$image is already exist"
    return 0
  }
  echo "Get the image"
  wget http://xpf-desktop.sh.intel.com/syzkaller/image.tar.gz
  tar -xvf image.tar.gz
  cd image
  echo "docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest"
  docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest
}

next_to_do() {
  echo "docker run --privileged -it -p 5000:56741 -v `pwd`:/root/image ccr-registry.caas.intel.com/simicsaas/syzkaller bash"
  echo "cd ../image; syz-manager --config my.cfg"
  echo "Could try: docker exec -it pensive_pike bash"
}

main() {
  check_docker
  setup_syzkaller
  next_to_do
}

main
