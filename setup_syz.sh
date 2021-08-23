#!/bin/bash

export PATH=${PATH}:/root/dockt
syzkaller_log="/tmp/setup_syzkaller"
IMAGE="/root/image/centos8.img"
QEMU_NEXT="https://github.com/intel-innersource/virtualization.hypervisors.server.vmm.qemu-next"
INTEL_NEXT="https://github.com/intel-innersource/os.linux.intelnext.kernel.git"
KERNEL_PATH="/root/os.linux.intelnext.kernel"
DEFAULT_PORT="10022"
HOME_PATH=$(echo $HOME)
IMAGE="/root/image/centos8_2.img"

usage() {
  cat <<__EOF
  usage: ./${0##*/} [-s o|i] [-f [0|1] [-i 0|1] [-h]
  -s  Source: o means official, i means intel-next (default i)
  -f  Force: 0 no reinstall if exist, 1 reinstall image (default 0)
  -i  Ignore:0 will fully installation, 1 ignore rpm and image installation(default 0)
  -h  Help
__EOF
  exit 2
}

check_syzkaller() {
  old_pid=""

  old_pid=$(ps -ef | grep syz-manager | grep config | awk -F " " '{print $2}')
  if [[ -z "$old_pid" ]]; then
    echo "No syzkaller pid run" >> "$syzkaller_log"
  else
    echo "Syzkaller pid $old_pid already run, no need set up, exit" >> "$syzkaller_log"
    exit 0
  fi
}

get_repo() {
  local dockt="/root/dockt"
  local dockt_git="https://github.com/xupengfe/dockt.git"
  local bz="/root/bzimage_bisect"
  local bz_git="https://github.com/xupengfe/bzimage_bisect.git"


  date +%Y-%m-%d_%H:%M:%S >> $syzkaller_log
  check_syzkaller
  yum install -y git

  if [[ -d "$dockt" ]]; then
    echo "$dockt is already exist, will update it" >> $syzkaller_log
    cd $dockt
    git pull
  else
    cd /root
    echo "git clone $dockt_git" >> $syzkaller_log
    git clone "$dockt_git"
  fi

  if [[ -d "$bz" ]]; then
    echo "$bz is already exist" >> $syzkaller_log
    cd $bz
    git pull
  else
    cd /root
    echo "git clone $bz_git" >> $syzkaller_log
    git clone "$bz_git"
  fi
}

install_packages() {
  [[ "$IGNORE" -eq 1 ]] && {
    echo "IGNORE:$IGNORE is 1, will ignore rpm installation"
    return 0
  }

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
  yum -y install glibc.i686 --allowerasing
  yum install -y ninja-build.x86_64
  yum -y install screen
}

clean_old_vm() {
  local old_vm=""

  old_vm=$(ps -ef | grep qemu | grep $DEFAULT_PORT  | awk -F " " '{print $2}')

  [[ -z "$old_vm" ]] || {
    echo "Kill old $DEFAULT_PORT qemu:$old_vm"
    echo "Kill old $DEFAULT_PORT qemu:$old_vm" >> $syzkaller_log
    kill -9 $old_vm
  }
}

setup_qemu() {
  local qemu=""
  local qemu_o="qemu"
  local qemu_i="virtualization.hypervisors.server.vmm.qemu-next"
  local result=""

  qemu=$(which qemu-system-x86_64)
  [[ -z "$qemu" ]] || {
    echo "$qemu exist"
    result=1
    if [[ "$IGNORE" -eq 1 ]]; then
      echo "$qemu exist and IGNORE:$IGNORE, will not reinstall qemu"
      echo "$qemu exist and IGNORE:$IGNORE, will not reinstall qemu" >> $syzkaller_log
    return 0
  }

  cd /root/

  if [[ "$SOURCE" == 'o' ]]; then
    [[ -d "/root/$qemu_o" ]] && [[ "$result" -eq 1 ]] && {
      echo "$qemu_o amd $qemu folder exist, no need to install"
      return 0
    }
    echo "rm -rf $qemu_o"
    rm -rf $qemu_o
    git clone https://github.com/qemu/qemu.git
    cd $qemu_o
    git checkout -f v6.0.0
    # delete intel qemu next to remind it's qemu official version
    rm -rf /root/$qemu_i
  elif [[ "$SOURCE" == 'i' ]]; then
    [[ -d "/root/$qemu_i" ]] && [[ "$result" -eq 1 ]] && {
      echo "$qemu_i amd $qemu folder exist, no need to install"
      return 0
    }
    echo "rm -rf $qemu_i"
    rm -rf $qemu_i
    git clone $QEMU_NEXT
    [[ $? -ne 0 ]] && {
      echo "Could not get $QEMU_NEXT, please 'dt setup'!!!!"
      echo "Could not get $QEMU_NEXT, please 'dt setup'!!!!" >> $syzkaller_log
      echo "Check $syzkaller_log"
      exit 1
    }
    cd $qemu_i
    git checkout -f origin/spr-beta
    # delete official to remind it's intel qemu next version
    rm -rf /root/qemu_o
  else
    echo "Invalid SOURCE:$SOURCE, do nothing for qemu"
    return 1
  fi

  mkdir build
  cd build
  yum install -y ninja-build.x86_64
  ../configure --target-list=x86_64-softmmu --enable-kvm --enable-vnc --enable-gtk --enable-sdl
  make
  make install
}

clone_intel_next_kernel() {
  rm -rf $KERNEL_PATH
  cd /root
  echo "git clone $INTEL_NEXT" >> $syzkaller_log
  git clone "$INTEL_NEXT"
}

setup_intel_next_kernel() {
  local check_git=""

  if [[ "$SOURCE" == 'i' ]]; then
    [[ -d "$KERNEL_PATH" ]] || clone_intel_next_kernel
    cd $KERNEL_PATH
    check_git=$(git log | head -n 1 2>/dev/null)
    if [[ -z "$check_git" ]]; then
      echo "$KERNEL_PATH git log is null, reinstall">> $syzkaller_log
      clone_intel_next_kernel
    else
      echo "$KERNEL_PATH git:$check_git is ready, no need reinstall"
      echo "$KERNEL_PATH git:$check_git is ready, no need reinstall" >> $syzkaller_log
      return 0
    fi
    cd $KERNEL_PATH
    check_git=$(git log | head -n 1 2>/dev/null)
    if [[ -z "$check_git" ]]; then
      echo "WARN:$KERNEL_PATH git log is null, return 1" >> $syzkaller_log
    else
      echo "$KERNEL_PATH is ready, git:$check_git" >> $syzkaller_log
    fi
  else
    echo "SROURCE:$SOURCE is not i, will not install $INTEL_NEXT"
    echo "SROURCE:$SOURCE is not i, will not install $INTEL_NEXT" >> $syzkaller_log
  fi
}

get_image() {
  img=""
  pub_content=""
  bz_file="/root/image/bzImage_5.14-rc5cet"

  [[ "$IGNORE" -eq 1 ]] && {
    echo "IGNORE:$IGNORE is 1, will ignore image installation"
    return 0
  }

  [[ "$FORCE" -eq 1 ]] && {
    echo "FORCE:$FORCE set to 1, will reinstall image"
    echo " rm -rf $IMAGE"
    rm -rf "$IMAGE"
  }

  img=$(ls "$IMAGE" 2>/dev/null)
  [[ -z "$img" ]] || {
    echo "$img exist, don't need to get image again"
    return 0
  }

  echo "Get the image"
  cd /root/
  rm -rf image.tar.gz
  wget http://xpf-desktop.sh.intel.com/syzkaller/image.tar.gz
  tar -xvf image.tar.gz

  cd /root/image
  if [[ -e "${HOME_PATH}/.ssh/id_rsa.pub" ]]; then
    echo "${HOME_PATH}/.ssh/id_rsa.pub exist, no need regenerate it"
    echo "${HOME_PATH}/.ssh/id_rsa.pub exist, no need regenerate it" >> $syzkaller_log
  else
    echo "No id_rsa.pub, will generate it"
    echo "No id_rsa.pub, will generate it" >> $syzkaller_log
    mkdir -p ${HOME_PATH}/.ssh/
    ssh-keygen -t rsa -N '' -f ${HOME_PATH}/.ssh/id_rsa -q
  fi
  pub_content=$(cat ${HOME_PATH}/.ssh/id_rsa.pub)

  echo $pub_content
  echo $pub_content >> $syzkaller_log
  clean_old_vm

  qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -kernel $bz_file \
    -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
    -drive file=${IMAGE},format=raw \
    -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:${DEFAULT_PORT}-:22 \
    -cpu host \
    -net nic,model=e1000 \
    -enable-kvm \
    -nographic \
    2>&1 | tee > /root/run_vm.log &

  sleep 20
  rm -rf /root/.ssh/known_hosts
  # could not send the variable value to remote VM, so set value directly
  echo "ssh -i /root/image/id_rsa_cent -o ConnectTimeout=1 -o 'StrictHostKeyChecking no' -p 10022 localhost 'echo \"$pub_content\" > ~/.ssh/authorized_keys'" > /root/image/pub.sh
  chmod 755 /root/image/pub.sh
  /root/image/pub.sh

  ssh -i /root/image/id_rsa_cent -o ConnectTimeout=1 -o 'StrictHostKeyChecking no' -p $DEFAULT_PORT localhost 'cat ~/.ssh/authorized_keys'
  scp -o 'StrictHostKeyChecking no' -P $DEFAULT_PORT ${HOME_PATH}/.ssh/id_rsa.pub root@localhost:/root/
  sleep 1
  clean_old_vm
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
    echo "export PATH=/root/syzkaller/bin:\$PATH" >> $bashrc
    echo "export PATH=/root/syzkaller/bin/linux_amd64:\$PATH" >> $bashrc
    echo "export PATH=/usr/local/bin:\$PATH" >> $bashrc
    sudo bash
  }
}

install_vncserver() {
  echo "systemctl stop firewalld.service"
  systemctl stop firewalld.service
  echo "systemctl disable firewalld.service"
  systemctl disable firewalld.service

  yum install -y tigervnc-server
  echo "vncpasswd"
  echo "vncserver"
}

next_to_do() {
  echo "Set up log: $syzkaller_log"
  echo "Install syzkaller environment successfully. Next follow below to run syzkaller:"
  echo "$(date): The syzkaller environment has been set up successfully" >> "$syzkaller_log"
  echo "cd /root/image"
  echo "syz-manager --config my.cfg"
  cd /root/image
  syz-manager --config my.cfg
}

main() {
  get_repo
  install_packages
  setup_qemu
  setup_intel_next_kernel
  get_image
  install_syzkaller
  install_vncserver
  next_to_do
}


# Set detault value
: "${SOURCE:=i}"
: "${IGNORE:=0}"
: "${FORCE:=0}"
while getopts :s:f:i:h arg; do
  case $arg in
    s)
      SOURCE=$OPTARG
      ;;
    f)
      FORCE=$OPTARG
      ;;
    i)
      IGNORE=$OPTARG
      ;;
    h)
      usage
      ;;
    *)
      usage
      ;;
  esac
done

main
