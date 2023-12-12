#!/bin/bash

export PATH=${PATH}:/usr/local/bin:/root/syzkaller/bin/linux_amd64:/root/syzkaller/bin:/opt/intel/bin64:/opt/intel/android_target:/usr/share/Modules/bin:/sbin:/bin:/usr/sbin:/usr/bin:/opt/bin

TAG_ORIGIN="/opt/tag_origin"
SCOM_FILE="/opt/start_commit"
syzkaller_log="/root/setup_syzkaller.log"
IMG_PATH="/root/image"
IMAGE="${IMG_PATH}/centos9.img"
QEMU_NEXT="https://github.com/intel-innersource/virtualization.hypervisors.server.vmm.qemu-next"
INTEL_NEXT="https://github.com/intel-innersource/os.linux.intelnext.kernel.git"
KERNEL_PATH="/root/os.linux.intelnext.kernel"
DEFAULT_PORT="10022"
HOME_PATH=$(echo $HOME)
#IMAGE2="${IMG_PATH}/centos8_2.img"
IMAGE9_2="${IMG_PATH}/centos9_2.img"
IMAGE9_3="${IMG_PATH}/centos9_3.img"
BZ_PATH="/root/bzimage_bisect"
SCAN_SCRIPT="scan_bisect.sh"
SCAN_SRV="scansyz.service"
QEMU_LOG="/opt/install_qemu.log"
SYZ_FOLDER="/root/syzkaller"
OFFICIAL="o"
NEXT="i"
OFFICIAL_TAG="v7.1.0"
HTML_FOLDER="/var/www/html"
# It only saved the run_syz by scan_bisect script records
RUN_SYZ_LOG="/root/run_syz_scan.log"

readonly DEFAULT_DEST="/var/www/html/bzimage"

usage() {
  cat <<__EOF
  usage: ./${0##*/} [-s o|i][-f [0|1][-i 0|1][-t][-k][-b][-h]
  -s  Source: o means official, i means intel-next (default i)
  -f  Force: 0 no reinstall if exist, 1 reinstall image, 2 reran syzkaller anyway (default 0)
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
  local start_commit=""

  [[ -e "$TAG_ORIGIN" ]] && end_commit_tag=$(cat "$TAG_ORIGIN")
  [[ -e "$SCOM_FILE" ]] && start_commit=$(cat "$SCOM_FILE")
  # New init process is also SCREEN or without SCREEN, so don't use SCREEN
  old_pids=$(ps -ef | grep syz-manager | grep config | awk -F " " '{print $2}')
  if [[ -z "$old_pids" ]]; then
    echo "No syzkaller pid run" >> "$syzkaller_log"
  elif [[ "$FORCE" -eq 2 ]]; then
    echo "pid $old_pids, tag:$end_commit_tag,new:$TAG, base commit:$start_commit,new:$START_COMMIT;FORCE:$FORCE, reran syzkaller!"
    echo "pid $old_pids, tag:$end_commit_tag,new:$TAG, base commit:$start_commit,new:$START_COMMIT;FORCE:$FORCE, reran syzkaller!" >> "$syzkaller_log"
    for pid in $old_pids; do
      echo "kill -9 $pid"
      echo "kill -9 $pid" >> "$syzkaller_log"
      kill -9 "$pid"
    done
  elif [[ "$end_commit_tag" != "$TAG" ]]; then
    echo "Syzkaller pid $old_pids already run but tag:$end_commit_tag is not new:$TAG, reran the syzkaller"
    echo "Syzkaller pid $old_pids already run but tag:$end_commit_tag is not new:$TAG, reran the syzkaller" >> "$syzkaller_log"
    for pid in $old_pids; do
      echo "kill -9 $pid"
      echo "kill -9 $pid" >> "$syzkaller_log"
      kill -9 "$pid"
    done
  else
    echo "Syzkaller pid $old_pids already run and END commit tag is same:$TAG, no need set up, exit"
    echo "Syzkaller pid $old_pids already run and END commit tag is same:$TAG, no need set up, exit" >> "$syzkaller_log"
    exit 0
  fi
}

get_repo() {
  local bz="/root/bzimage_bisect"
  local bz_git="https://github.com/intel-sandbox/bzimage_bisect.git"
  local bz_git_check=""

  date +%Y-%m-%d_%H:%M:%S >> $syzkaller_log
  # Syzkaller maybe do fuzzing more than 10days
  echo "sed -i s/10d/32d/g /usr/lib/tmpfiles.d/tmp.conf" >> "$syzkaller_log"
  sed -i s/10d/32d/g /usr/lib/tmpfiles.d/tmp.conf
  check_syzkaller
  yum install -y git

  if [[ -d "$bz" ]]; then
    bz_git_check=$(cat ${bz}/.git/config | grep intel | grep sandbox | grep bzimage_bisect)
    if [[ -z "$bz_git_check" ]]; then
      echo "$bz is not intel sandbox, will refetch repo" >> "$syzkaller_log"
      rm -rf "$bz"
      cd /root/ || {
        echo "[EORROR] cd /root/ failed!" >> $syzkaller_log
        exit 1
      }
      echo "git clone $bz_git" >> $syzkaller_log
      git clone "$bz_git"
    else
      echo "$bz intel sandbox repo:$bz_git_check is already exist, update." >> $syzkaller_log
      cd $bz
      git pull
    fi
  else
    cd /root
    echo "git clone $bz_git" >> $syzkaller_log
    git clone "$bz_git"
  fi
}

install_packages() {
  local httpd_result=""
  local check_selinux=""
  local cmdline_selinux=""

  [[ "$IGNORE" -eq 1 ]] && {
    echo "IGNORE:$IGNORE is 1, will ignore rpm installation"
    return 0
  }

  check_selinux=$(grep SELINUX=enforcing /etc/sysconfig/selinux | grep -v "^#")
  if [[ -n "$check_selinux" ]]; then
    sed -i s/SELINUX=enforcing/SELINUX=disabled/g  /etc/sysconfig/selinux
    setenforce 0
  fi
  cmdline_selinux=$(grep selinux /proc/cmdline)
  [[ -z "$cmdline_selinux" ]] && {
    echo "cmdline doesn't disable selinux! Will disable selinux!" >> $syzkaller_log
    grubby --update-kernel ALL --args selinux=0
  }

  echo "Install useful packages:" >> $syzkaller_log
  echo "yum -y install glibc-devel.i686 glibc-devel"
  yum -y install glibc-devel.i686 glibc-devel
  echo "yum -y install gcc-c++"
  yum -y install gcc-c++
  yum -y install make
  echo "yum -y install go"
  yum -y install go
  yum -y install libslirp-devel.x86_64
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
  yum -y groupinstall "Development Tools"
  yum -y install screen
  yum -y install python3.8
  local check_py=""
  check_py=$(python3 --version | grep "3\.8")
  [[ -z "$check_py" ]] && {
    [[ -e "/usr/bin/python3.8" ]] && {
      rm -rf /usr/bin/python3
      ln -s /usr/bin/python3.8 /usr/bin/python3
    }
  }
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

install_ninja() {
  local result=""

  ninja --version
  result=$?
  if [[ "$result" -ne 0 ]]; then
    echo "No ninja tool, install it" >> "$syzkaller_log"
    git clone https://github.com/ninja-build/ninja.git
    cd ninja || {
      echo "Access ninja failed"
      echo "Access ninja failed" >> "$syzkaller_log"
    }
    # Update in 2023.7
    git checkout -f 36843d387cb0621c1a288179af223d4f1410be73
    ./configure.py --bootstrap
    # Not /usr/local/bin/, use /usr/bin instead
    # sudo cp ninja /usr/local/bin/
    sudo cp ninja /usr/bin/
  else
    echo "ninja is installed, no need to reinstall." >> "$syzkaller_log"
  fi
}

install_usbredir() {
  local result=""

  pkg-config --modversion libusbredirparser-0.5
  result=$?
  if [[ "$result" -ne 0 ]]; then
    echo "No libusbredirparser-0.5 tool, install it" >> "$syzkaller_log"
    git clone https://gitlab.freedesktop.org/spice/usbredir.git
    cd usbredir || {
      echo "Access usbredir failed"
      echo "Access usbredir failed" >> "$syzkaller_log"
    }
    pip3 install meson
    # /usr/local/bin/ is not in the default PATH in CentOS9
    cp -rf /usr/local/bin/meson  /bin/
    git checkout -f usbredir-0.12.0
    meson build
    ninja -C build install
    pkg-config --modversion libusbredirparser-0.5
    result=$?
    [[ "$result" -ne 0 ]] && {
      echo "[ERROR] Install libusbredirparser-0.5 and still failed!!" >> "$syzkaller_log"
    }
  else
    echo "libusbredirparser-0.5 is installed, no need to reinstall." >> "$syzkaller_log"
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
  install_ninja
  cd - && {
    echo "pwd:$(pwd)"
    echo "After install ninja pwd:$(pwd)" >> "$syzkaller_log"
  }
  install_usbredir
  cd - && {
    echo "pwd:$(pwd)"
    echo "After install usbredir pwd:$(pwd)" >> "$syzkaller_log"
  }
  # /usr/local/bin/ is not in the default PATH in CentOS9 even in ~/.bashrc
  cp -rf /usr/local/bin/meson  /bin/
  # yum -y install libslirp-devel.x86_64    // installed in previous step
  ../configure --target-list=x86_64-softmmu --enable-kvm --enable-vnc --enable-gtk --enable-sdl --enable-usb-redir --enable-slirp
  make
  make install
  cp -rf qemu-system-x86_64  /usr/local/bin/
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

# Check some image update if image exists
check_img_update() {
  local ovmf_file="OVMF_CODE.fd"
  local check_cfg=""
  local check_start_vm=""
  local my_cfg_link="https://raw.githubusercontent.com/xupengfe/dockt/main/my.cfg"
  local cfg_no_ovmf_link="https://raw.githubusercontent.com/xupengfe/dockt/main/my.cfg_no_OVMF"
  local start_vm_path="http://xpf-desktop.sh.intel.com/syzkaller/image/"
  local ovmf_link="https://github.com/xupengfe/dockt/raw/main/OVMF_CODE.fd"

  [[ -e "${IMG_PATH}/my.cfg" ]] || {
    echo "No ${IMG_PATH}/my.cfg file, exit!"
    echo "No ${IMG_PATH}/my.cfg file, exit!" >> $syzkaller_log
    exit 1
  }

  [[ -e "${IMG_PATH}/${ovmf_file}" ]] || {
    echo "$(date): no $ovmf_file file in ${IMG_PATH}, get it!" >> $syzkaller_log
    echo "wget $ovmf_link -O ${IMG_PATH}/${ovmf_file}" >> $syzkaller_log
    wget $ovmf_link -O ${IMG_PATH}/${ovmf_file}
  }

  [[ -e "${IMG_PATH}/${ovmf_file}" ]] || {
    echo "$(date): no $ovmf_file file in ${IMG_PATH} after get $ovmf_file! Exit!" >> $syzkaller_log
    exit 1
  }

  check_cfg=$(grep "OVMF" ${IMG_PATH}/start2.sh)
  if [[ -z "$check_cfg" ]]; then
    echo "$(date): no OVMF:$check_cfg in ${IMG_PATH}/start2.sh" >> $syzkaller_log
    echo "wget ${start_vm_path}/start1.sh -O ${IMG_PATH}/start1.sh" >> $syzkaller_log
    wget ${start_vm_path}/start1.sh -O ${IMG_PATH}/start1.sh
    echo "wget ${start_vm_path}/start2.sh -O ${IMG_PATH}/start2.sh" >> $syzkaller_log
    wget ${start_vm_path}/start2.sh -O ${IMG_PATH}/start2.sh
    echo "wget ${start_vm_path}/start3.sh -O ${IMG_PATH}/start3.sh" >> $syzkaller_log
    wget ${start_vm_path}/start3.sh -O ${IMG_PATH}/start3.sh
  fi

  check_start_vm=$(grep "qemu_args" ${IMG_PATH}/my.cfg | grep -v "^#" | grep -i OVMF)
  # Below one syzkaller will fill qemu_args and cmdline for qemu 8.1.0 or later
  # Check if below qemu setting affect syzkaller finding bugs?
  #if [[ -z "$check_start_vm" ]]; then
  #  echo "$(date): no qemu_args:$check_start_vm in ${IMG_PATH}/my.cfg, will use OVMF my.cfg" >> $syzkaller_log
  #  echo "wget $my_cfg_link -O ${IMG_PATH}/my.cfg" >> $syzkaller_log
  #  wget "$my_cfg_link" -O "${IMG_PATH}/my.cfg"
  #fi

  # Below one syzkaller will not fill qemu_args and cmdline as before to try
  if [[ -n "$check_start_vm" ]]; then
    echo "$(date): Contains qemu_args & OVMF:$check_start_vm in ${IMG_PATH}/my.cfg, will use no OVMF my.cfg" >> $syzkaller_log
    echo "wget $cfg_no_ovmf_link -O ${IMG_PATH}/my.cfg" >> $syzkaller_log
    wget "$cfg_no_ovmf_link" -O "${IMG_PATH}/my.cfg"
  fi

  # In any situation, don't use quiet to boot vm to miss the dmesg in serial log
  sed -i s/quiet//g ${IMG_PATH}/my.cfg
  sed -i s/quiet//g ${IMG_PATH}/start1.sh
  sed -i s/quiet//g ${IMG_PATH}/start2.sh
  sed -i s/quiet//g ${IMG_PATH}/start3.sh
}

get_image() {
  local img=""
  local pub_content=""
  local bz_file="${IMG_PATH}/bzImage_5.14-rc5cet"

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
  local check_img=""
  # img is not NULL, so update the img folder
  [[ -z "$img" ]] || {
    # Old centos9.img is 8,5G size and it boot up slowly, will use new 8.2G one
    check_img=$(ls -ltra ${IMG_PATH}/centos9.img | grep "9126805504")
    if [[ -n "$check_img" ]]; then
      echo "Old centos9.img 8.5G:$check_img, will reinstall it." >> $syzkaller_log
    else
      echo "$img exist and not 8.5G(9126805504) old one:$check_img, don't need to reinstall image." >> $syzkaller_log
      check_img_update
      return 0
    fi
  }

  echo "Get the image"
  cd /root/
  rm -rf image.tar.gz
  # Clean the old images to save the disk space
  rm -rf ${IMG_PATH}/centos*img
  wget http://xpf-desktop.sh.intel.com/syzkaller/image.tar.gz
  tar -xvf image.tar.gz

  cd ${IMG_PATH}

  # centos8.img is for syzkaller
  # centos8_2.img is for issue bisect
  cp -rf "$IMAGE" "$IMAGE9_2"
  # centos8_2.img is broken sometimes when reproduce issue
  # Use centos8_3.img backup one to recover centos8_2.img
  cp -rf "$IMAGE" "$IMAGE9_3"
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
  echo "ssh -i ${IMG_PATH}/id_rsa_cent -o ConnectTimeout=1 -o 'StrictHostKeyChecking no' -p 10022 localhost 'echo \"$pub_content\" > ~/.ssh/authorized_keys'" > ${IMG_PATH}/pub.sh
  chmod 755 ${IMG_PATH}/pub.sh
  ${IMG_PATH}/pub.sh

  ssh -i ${IMG_PATH}/id_rsa_cent -o ConnectTimeout=1 -o 'StrictHostKeyChecking no' -p $DEFAULT_PORT localhost 'cat ~/.ssh/authorized_keys'
  scp -o 'StrictHostKeyChecking no' -P $DEFAULT_PORT ${HOME_PATH}/.ssh/id_rsa.pub root@localhost:/root/
  sleep 1
  clean_old_vm
}

install_syzkaller() {
  check_syz=""
  check_env=""
  check_run_syz=""
  bashrc="/root/.bashrc"

  # Each time set up or run, will update syzkaller to latest!
  if [[ -d "$SYZ_FOLDER" ]]; then
    echo "cd $SYZ_FOLDER; git pull; make" >> $syzkaller_log
    cd $SYZ_FOLDER || {
      echo "No $SYZ_FOLDER folder, exit"
      exit 1
    }
    git pull
    make generate
    make
    sleep 1
  else
    echo "No $SYZ_FOLDER, will install syzkaller in first time" >> $syzkaller_log
  fi

  check_run_syz=$(cat $bashrc | grep "check_run_syz")
  [[ -n "$check_run_syz" ]] || {
    echo "$(date) | Add /root/bzimage_bisect/check_run_syz.sh i in $bashrc" >> "$syzkaller_log"
    echo "/root/bzimage_bisect/check_run_syz.sh i" >> $bashrc
  }

  check_syz=$(which syz-manager)
  [[ -z "$check_syz" ]] || {
    echo "$check_syz exist"
    return 0
  }
  cd /root/ || {
    echo "No /root, exit"
    echo "No /root, exit" >> "$syzkaller_log"
    exit 1
  }
  yum -y install go
  git clone https://github.com/google/syzkaller.git
  cd syzkaller
  mkdir workdir
  make

  check_env=$(cat $bashrc | grep "syzkaller")
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
  echo "cd ${IMG_PATH}"
  echo "syz-manager --config my.cfg"

  start_scan_service

  if [[ -n "$TAG" ]]; then
    if [[ -n "$KER_PATH" ]]; then
      if [[ -n "$START_COMMIT" ]]; then
        echo "/root/bzimage_bisect/run_syzkaller.sh -e $TAG -k $KER_PATH -b $START_COMMIT -d $DEST -n $NEXT_BASE_TAG" >> "$syzkaller_log"
        /root/bzimage_bisect/run_syzkaller.sh -e "$TAG" -k "$KER_PATH" -b "$START_COMMIT" -d "$DEST" -n "$NEXT_BASE_TAG"
      else
        echo  "KER:$KER_PATH contain value but no START_COMMIT:$START_COMMIT"
        echo  "KER:$KER_PATH contain value but no START_COMMIT:$START_COMMIT" >> "$syzkaller_log"
        /root/bzimage_bisect/run_syzkaller.sh -e "$TAG"
      fi
    else
      echo "/root/bzimage_bisect/run_syzkaller.sh -e $TAG" >> "$syzkaller_log"
      /root/bzimage_bisect/run_syzkaller.sh -e "$TAG"
    fi

  else
    echo "No TAG:$TAG, run syzkaller as default" >> "$syzkaller_log"
    cd ${IMG_PATH}
    syz-manager --config my.cfg
  fi
}

main() {
  echo "$(date +%Y-%m-%d_%H:%M:%S):SRC:$SOURCE|FORCE:$FORCE|IGN:$IGNORE|TAG:$TAG|KER:$KER_PATH|base:$START_COMMIT|$DEST|$NEXT_BASE_TAG"
  echo "====================" >> "$syzkaller_log"
  echo "$(date +%Y-%m-%d_%H:%M:%S):SRC:$SOURCE|FORCE:$FORCE|IGN:$IGNORE|TAG:$TAG|KER:$KER_PATH|base:$START_COMMIT|$DEST|$NEXT_BASE_TAG" >> "$syzkaller_log"
  echo "$(date +%Y-%m-%d_%H:%M:%S): bash /root/setup_syz.sh -s $SOURCE -k $KER_PATH -t $TAG -b $START_COMMIT -n $NEXT_BASE_TAG -d $DEST" >> "$RUN_SYZ_LOG"
  echo "rm -rf /root/screenlog.0" >> "$syzkaller_log"
  rm -rf /root/screenlog.0
  cat /dev/null > /root/screenlog.0
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
: "${SOURCE:=o}"
: "${IGNORE:=0}"
: "${FORCE:=0}"
while getopts :s:f:i:t:k:b:d:n:h arg; do
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
      # based start commit or tag both is ok
      START_COMMIT=$OPTARG
      ;;
    d)
      # destination like default /var/www/html/bzimage
      DEST=$OPTARG
      [[ -z "$DEST" ]] && {
        echo "DEST:$DEST is null use default:$DEFAULT_DEST"
        echo "DEST:$DEST is null use default:$DEFAULT_DEST" >> "$syzkaller_log"
        DEST=$DEFAULT_DEST
      }
      ;;
    n)
      # If developed and mainline commit reproduced this issue both, will use
      # next base commit, for example v6.1-intel-next -> v6.1 -> v5.11(next)
      # Next base commit or next base tag is both ok.
      NEXT_BASE_TAG=$OPTARG
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
