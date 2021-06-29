#!/bin/bash


install_packages() {
  echo "Install useful packages:"
  yum -y install glibc-devel.i686 glibc-devel
  yum -y install gcc-c++
  yum -y install make
  yum -y install ncurses-devel
  dnf -y update kernel rpm libsolv
  yum -y install net-tools
  yum -y install virt-manager
  yum -y install bison
  yum -y install flex
  yum -y install ncurses
  yum -y install elfutils-libelf-devel
  yum -y install libcap-devel
  yum -y install openssl-devel
  yum -y install fuse-devel
  dnf -y install libcap-ng-devel
  dnf -y install numactl-devel
  yum -y install rpm-build rpmdevtools
  yum -y install glibc-devel.i686 glibc-devel
  yum -y install patch
  yum -y install automake
  yum -y install libstdc++-devel
  yum -y install libstdc++-static
  yum -y install alsa-lib-devel
  yum -y install cmake
  dnf -y install libusbx-devel
  dnf -y install python2-devel
  dnf -y install python3-devel
  yum -y install make automake gcc gcc-c++ kernel-devel
  yum -y install yum-utils
  yum -y install perl-Digest-SHA.x86_64
  yum -y install git-email
  yum -y install libtool
  yum -y install glib2
  yum -y install glib2-devel
  yum -y install pixman-devel.x86_64
  yum -y install gtk3-devel.x86_64
  yum -y install libvirt-client.x86_64
  yum -y install libvirt-daemon.x86_64
  yum -y install ncurses-devel.x86_64
  yum -y install  elfutils-libelf-devel.x86_64
  yum -y install glibc-static.i686
  yum -y groupinstall "Development Tools" "Development Libraries"
  yum -y install autoconf-archive
  dnf -y install dpkg
  dnf -y install console-setup
  yum -y install dpkg-dev
  yum -y install ninja-build.x86_64
  yum -y install SDL2-devel.x86_64
  yum -y install  bridge-utils.x86_64
  yum -y install debootstrap.noarch
}

setup_qemu() {
  local qemu=""

  qemu=$(which qemu-system-x86_64)
  [[ -z "$qemu" ]] || {
    echo "$qemu exist"
    return 0
  }

  cd /root/
  git clone https://github.com/qemu/qemu.git
  cd qemu
  mkdir build
  cd build
  yum install -y ninja-build.x86_64
  ../configure --target-list=x86_64-softmmu --enable-kvm --enable-vnc --enable-gtk --enable-sdl
  make
  make install
}

get_image() {
  img=""

  img=$(ls /root/image 2>/dev/null)
  [[ -z "$img" ]] || {
    echo "$img exist"
    return 0
  }

  echo "Get the image"
  cd /root/
  wget http://xpf-desktop.sh.intel.com/syzkaller/image.tar.gz
  tar -xvf image.tar.gz
}

install_syzkaller() {
  check_syz=""
  check_env=""
  bashrc="/root/.bashrc"

  check_syz=$(which syz-manager)
  [[ -z "$check_syz" ]] || {
    echo "$check_syz exist"
    return 0
  }
  cd /root/
  yum -y install go
  git clone https://github.com/google/syzkaller.git
  cd syzkaller
  mkdir workdir
  make
  check_env=$(cat /root/.bashrc | grep syzkaller)
  [[ -n "$check_env" ]] || {
    echo "export PATH=/root/syzkaller/bin:$PATH" >> $bashrc
    echo "export PATH=/root/syzkaller/bin/linux_amd64:$PATH" >> $bashrc
    echo "export PATH=/usr/local/bin:$PATH" >> $bachrc
    sudo bash
  }
}

next_to_do() {
  echo "cd /root/image"
  echo "syz-manager --config my.cfg"
}

main() {
  install_packages
  setup_qemu
  get_image
  install_syzkaller
  next_to_do
}

main
