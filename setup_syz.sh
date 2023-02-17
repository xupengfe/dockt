#!/bin/bash

export PATH=${PATH}:/root/dockt
TAG_ORIGIN="/opt/tag_origin"
syzkaller_log="/root/setup_syzkaller.log"
IMAGE="/root/image/centos8.img"
QEMU_NEXT="https://github.com/intel-innersource/virtualization.hypervisors.server.vmm.qemu-next"
INTEL_NEXT="https://github.com/intel-innersource/os.linux.intelnext.kernel.git"
KERNEL_PATH="/root/os.linux.intelnext.kernel"
DEFAULT_PORT="10022"
HOME_PATH=$(echo $HOME)
IMAGE="/root/image/centos8_2.img"
BZ_PATH="/root/bzimage_bisect"
SCAN_SCRIPT="scan_bisect.sh"
SCAN_SRV="scansyz.service"
QEMU_LOG="/opt/install_qemu.log"
SYZ_FOLDER="/root/syzkaller"
OFFICIAL="o"
NEXT="i"
OFFICIAL_TAG="v7.1.0"
HTML_FOLDER="/var/www/html"

usage() {
  cat <<__EOF
  usage: ./${0##*/} [-s o|i][-f [0|1][-i 0|1][-t][-k][-b][-h]
  -s  Source: o means official, i means intel-next (default i)
  -f  Force: 0 no reinstall if exist, 1 reinstall image (default 0)
  -i  Ignore:0 will fully installation, 1 ignore rpm and image installation, i:2 will ignore qemu if exist(default 0)
  -t  Commit with head(End commit)
  -k  Develop Kernel path, if intel-next kernel no need set, will download in /root/os.linux.intelnext.kernel/ automatically
  -b  Based start commit from develop kernel, which means based on which main line kernel commit
  -h  Help
__EOF
  exit 2
}

check_syzkaller() {
  local old_pids=""
  local pid=""
  local end_commit_tag=""

  [[ -e "$TAG_ORIGIN" ]] && end_commit_tag=$(cat "$TAG_ORIGIN")
  # Only find the screen with setup_syz pids
  old_pids=$(ps -ef | grep SCREEN | grep setup_syz | awk -F " " '{print $2}')
  if [[ -z "$old_pid" ]]; then
    echo "No syzkaller pid run" >> "$syzkaller_log"
  elif [[ "$end_commit_tag" != "$TAG" ]]; then
    echo "Syzkaller pid $old_pid already run but tag:$end_commit_tag is not new:$TAG, reran the syzkaller"
    echo "Syzkaller pid $old_pid already run but tag:$end_commit_tag is not new:$TAG, reran the syzkaller" >> "$syzkaller_log"
    for pid in $old_pids; do
      echo "kill -9 $pid"
      echo "kill -9 $pid" >> "$syzkaller_log"
      kill -9 "$pid"
    done
  else
    echo "Syzkaller pid $old_pid already run and END commit tag is same:$TAG, no need set up, exit"
    echo "Syzkaller pid $old_pid already run and END commit tag is same:$TAG, no need set up, exit" >> "$syzkaller_log"
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
  local httpd_result=""

  [[ "$IGNORE" -eq 1 ]] && {
    echo "IGNORE:$IGNORE is 1, will ignore rpm installation"
    return 0
  }

  echo "Install useful packages:" >> $syzkaller_log
  echo "yum -y install glibc-devel.i686 glibc-devel"
  yum -y install glibc-devel.i686 glibc-devel
  echo "yum -y install gcc-c++"
  yum -y install gcc-c++
  yum -y install make
  yum -y install ncurses-devel
  dnf -y update kernel rpm libsolv
  yum -y install net-tools
  yum -y install virt-manager
  yum -y install bison
  yum -y install flex
  echo "yum -y install ncurses"
  yum -y install ncurses
  yum -y install elfutils-libelf-devel
  yum -y install libcap-devel
  yum -y install openssl-devel
  yum -y install fuse-devel
  dnf -y install libcap-ng-devel
  echo "dnf -y install numactl-devel"
  dnf -y install numactl-devel
  yum -y install rpm-build rpmdevtools
  yum -y install glibc-devel.i686 glibc-devel
  yum -y install patch
  echo "yum -y install automake"
  yum -y install automake
  yum -y install libstdc++-devel
  yum -y install libstdc++-static
  yum -y install alsa-lib-devel
  echo "yum -y install cmake"
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
  yum -y install spice-server.x86_64
  yum -y install spice-server-devel.x86_64
  yum -y install usbredir-devel.x86_64
  yum -y install screen
  # syz-prog2c need to use clang-format
  yum install -y clang-tools-extra
  httpd_result=$(which httpd 2>/dev/null)
  [[ -n "$httpd_result" ]] || {
    echo "yum install httpd -y"
    yum install httpd -y

    echo "mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf_backup"
    mv /etc/httpd/conf.d/welcome.conf /etc/httpd/conf.d/welcome.conf_backup

    mkdir -p $HTML_FOLDER
    echo "$(date +%Y-%m-%d_%H:%M:%S) created apache" >> ${HTML_FOLDER}/apache_record.txt

    echo "systemctl restart httpd"
    systemctl restart httpd

    echo "systemctl enable httpd"
    systemctl enable httpd
  }
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

qemu_version_check() {
  local qemu_ver=""
  local qemu_check=""

  echo "$(date +%Y-%m-%d_%H:%M:%S):$SOURCE (o:QEMU-official, i:QEMU-next) is ready" > $QEMU_LOG
  qemu_ver=$(qemu-system-x86_64 --version 2>/dev/null)
  if [[ -z "$qemu_ver" ]]; then
    echo "WARN: QEMU version is null:$qemu_ver, please contact with pengfei.xu@intel.com" >> $QEMU_LOG
    echo "WARN: QEMU version is null:$qemu_ver, please contact with pengfei.xu@intel.com" >> $syzkaller_log
    return 1
  else
    echo "$qemu_ver" >> $QEMU_LOG
    echo "$qemu_ver" >> $syzkaller_log
  fi
  qemu_check=$(qemu-system-x86_64 --version 2>/dev/null | grep "($OFFICIAL_TAG)")
  if [[ -n "$qemu_check" ]]; then
    # Check OFFICIAL TAG is matched with official version
    if [[ "$SOURCE" == "$OFFICIAL" ]]; then
      echo "$SOURCE mataches offical version:$OFFICIAL_TAG" >> $syzkaller_log
    else
      echo "WARN:$SOURCE should not match offical version:$OFFICIAL_TAG" >> $syzkaller_log
    fi
  else
    # Check OFFICIAL TAG is next version should not match with official version
    if [[ "$SOURCE" == "$OFFICIAL" ]]; then
      echo "WARN:$SOURCE should not matach the offical version:$OFFICIAL_TAG" >> $syzkaller_log
    else
      echo "$SOURCE mataches QEMU next version" >> $syzkaller_log
    fi
  fi
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
  #  if [[ "$IGNORE" -eq 2 ]]; then
  #    echo "$qemu exist and IGNORE:$IGNORE, will not reinstall qemu"
  #    echo "$qemu exist and IGNORE:$IGNORE, will not reinstall qemu" >> $syzkaller_log
  #  return 0
  #  fi
  }

  cd /root/

  if [[ "$SOURCE" == "$OFFICIAL" ]]; then
    [[ -d "/root/$qemu_o" ]] && [[ "$result" -eq 1 ]] && {
      echo "$qemu_o and $qemu folder exist, no need to install"
      echo "$qemu_o and $qemu folder exist, no need to install" >> $syzkaller_log
      qemu_version_check
      return 0
    }
    echo "rm -rf $qemu_o"
    echo "rm -rf $qemu_o" >> $syzkaller_log
    rm -rf $qemu_o
    if [[ -d "/root/${qemu_o}_bak" ]]; then
        echo "Folder /root/${qemu_o}_bak exist will move to /root/$qemu_o"
        echo "Folder /root/${qemu_o}_bak exist will move to /root/$qemu_o" >> $syzkaller_log
        mv /root/${qemu_o}_bak /root/$qemu_o
    else
      git clone https://github.com/qemu/qemu.git
    fi
    echo "cd /root/$qemu_o" >> $syzkaller_log
    cd /root/$qemu_o || {
      echo "cd /root/$qemu_o failed!!!"
      echo "cd /root/$qemu_o failed!!!" >> $syzkaller_log
    }
    echo "git fetch origin"
    echo "git fetch origin" >> $syzkaller_log
    git fetch origin
    echo "git checkout -f $OFFICIAL_TAG" >> $syzkaller_log
    git checkout -f $OFFICIAL_TAG
    # delete intel qemu next to remind it's qemu official version
    echo "mv /root/$qemu_i /root/${qemu_i}_bak"
    echo "mv /root/$qemu_i /root/${qemu_i}_bak" >> $syzkaller_log
    mv /root/$qemu_i /root/${qemu_i}_bak
  elif [[ "$SOURCE" == "$NEXT" ]]; then
    [[ -d "/root/$qemu_i" ]] && [[ "$result" -eq 1 ]] && {
      echo "$qemu_i amd $qemu folder exist, no need to install"
      qemu_version_check
      return 0
    }
    echo "rm -rf $qemu_i"
    rm -rf $qemu_i
    git clone $QEMU_NEXT
    [[ $? -ne 0 ]] && {
      echo "Could not get $QEMU_NEXT, please 'dt setup'!!!!"
      echo "$(date): Could not get $QEMU_NEXT, please 'dt setup'!!!!" >> $syzkaller_log
      echo "$(date): Could not get $QEMU_NEXT, please 'dt setup'!!!!" >> $QEMU_LOG
      echo "Check $syzkaller_log"
      exit 1
    }
    cd $qemu_i
    git checkout -f origin/spr-beta
    # delete official to remind it's intel qemu next version
    rm -rf /root/qemu_o
  else
    echo "Invalid SOURCE:$SOURCE, do nothing for qemu"
    echo "$(date): Invalid SOURCE:$SOURCE, do nothing for qemu" >> $syzkaller_log
    echo "$(date): Invalid SOURCE:$SOURCE, do nothing for qemu" >> $QEMU_LOG
    return 1
  fi

  echo "rm -rf build"
  echo "rm -rf build" >>  $syzkaller_log
  rm -rf build
  mkdir build
  cd build
  yum install -y ninja-build.x86_64
  ../configure --target-list=x86_64-softmmu --enable-kvm --enable-vnc --enable-gtk --enable-sdl
  make
  make install
  qemu_version_check
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
  local img=""
  local pub_content=""
  local bz_file="/root/image/bzImage_5.14-rc5cet"

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
  # centos8.img is for syzkaller
  # centos8_2.img is for issue bisect
  cp -rf /root/image/centos8.img /root/image/centos8_2.img
  # centos8_2.img is broken sometimes when reproduce issue
  # Use centos8_3.img backup one to recover centos8_2.img
  cp -rf /root/image/centos8.img /root/image/centos8_3.img
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

  # Each time set up or run, will update syzkaller to latest!
  if [[ -d "$SYZ_FOLDER" ]]; then
    echo "cd $SYZ_FOLDER; git pull; make" >> $syzkaller_log
    cd $SYZ_FOLDER
    git pull
    make
    sleep 1
  else
    echo "No $SYZ_FOLDER, will install syzkaller in first time" >> $syzkaller_log
  fi

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
  check_env=$(cat $bashrc | grep syzkaller)
  [[ -n "$check_env" ]] || {
    echo "export PATH=/root/syzkaller/bin:\$PATH" >> $bashrc
    echo "export PATH=/root/syzkaller/bin/linux_amd64:\$PATH" >> $bashrc
    echo "export PATH=/usr/local/bin:\$PATH" >> $bashrc
    source $bashrc
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

start_scan_service() {
  local scan_service="/etc/systemd/system/${SCAN_SRV}"
  local check_scan_pid=""

  [[ -e "$scan_service" ]] && [[ -e "/usr/bin/${SCAN_SCRIPT}" ]] && {
    check_scan_pid=$(ps -ef | grep scan_bisect | grep sh)
    if [[ -z "$check_scan_pid" ]];then
      echo "no $SCAN_SCRIPT pid, will reinstall"
    else
      echo "$scan_service & /usr/bin/$SCAN_SCRIPT and pid:$SCAN_SCRIPT exist, no need reinstall $SCAN_SRV service"
      echo "$scan_service & /usr/bin/$SCAN_SCRIPT and pid:$SCAN_SCRIPT exist, no need reinstall $SCAN_SRV service" >> "$syzkaller_log"
      return 0
    fi
  }

  echo "BZ_PATH:$BZ_PATH"
  [[ -d "$BZ_PATH" ]] || {
    echo "No $BZ_PATH folder!"
    exit 1
  }

  echo "ln -s ${BZ_PATH}/${SCAN_SCRIPT} /usr/bin/${SCAN_SCRIPT}"
  rm -rf /usr/bin/${SCAN_SCRIPT}
  ln -s ${BZ_PATH}/${SCAN_SCRIPT} /usr/bin/${SCAN_SCRIPT}

echo "[Service]" > $scan_service
echo "Type=simple" >> $scan_service
echo "ExecStart=${BZ_PATH}/${SCAN_SCRIPT}" >> $scan_service
echo "[Install]" >> $scan_service
echo "WantedBy=multi-user.target graphical.target" >> $scan_service

sleep 1

systemctl daemon-reload
systemctl enable $SCAN_SRV
systemctl start $SCAN_SRV

systemctl status $SCAN_SRV &
}

next_to_do() {
  echo "Set up log: $syzkaller_log"
  echo "Install syzkaller environment successfully. Next follow below to run syzkaller:"
  echo "$(date +%Y-%m-%d_%H%M%S): The syzkaller environment has been set up successfully" >> "$syzkaller_log"
  echo "cd /root/image"
  echo "syz-manager --config my.cfg"

  start_scan_service

  if [[ -n "$TAG" ]]; then
    if [[ -n "$KER_PATH" ]]; then
      if [[ -n "$START_COMMIT" ]]; then
        echo "/root/bzimage_bisect/run_syzkaller.sh $TAG $KER_PATH $START_COMMIT" >> "$syzkaller_log"
        /root/bzimage_bisect/run_syzkaller.sh "$TAG" "$KER_PATH" "$START_COMMIT"
      else
        echo  "KER:$KER_PATH contain value but no START_COMMIT:$START_COMMIT"
        echo  "KER:$KER_PATH contain value but no START_COMMIT:$START_COMMIT" >> "$syzkaller_log"
        /root/bzimage_bisect/run_syzkaller.sh "$TAG"
      fi
    else
      echo "/root/bzimage_bisect/run_syzkaller.sh $TAG" >> "$syzkaller_log"
      /root/bzimage_bisect/run_syzkaller.sh "$TAG"
    fi

  else
    echo "No TAG:$TAG, run syzkaller as default" >> "$syzkaller_log"
    cd /root/image
    syz-manager --config my.cfg
  fi
}

main() {
  echo "$(date +%Y-%m-%d_%H:%M:%S): SOURCE:$SOURCE|FORCE:$FORCE|IGNORE:$IGNORE|TAG:$TAG|KER:$KER_PATH|START_COMMIT:$START_COMMIT"
  echo "====================" >> "$syzkaller_log"
  echo "$(date +%Y-%m-%d_%H:%M:%S): SOURCE:$SOURCE|FORCE:$FORCE|IGNORE:$IGNORE|TAG:$TAG|KER:$KER_PATH|START_COMMIT:$START_COMMIT" >> "$syzkaller_log"

  if [[ -z "$KER_PATH" ]]; then
    KER_PATH=$KERNEL_PATH
    echo "KER_PATH is null, use $KERNEL_PATH as default" >> "$syzkaller_log"
  fi

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
while getopts :s:f:i:t:k:b:h arg; do
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
    t)
      # END COMMIT TAG or END COMMIT can be used, END COMMIT TAG is recommended
      TAG=$OPTARG
      ;;
    k)
      KER_PATH=$OPTARG
      ;;
    b)
      # based start commit
      START_COMMIT=$OPTARG
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
