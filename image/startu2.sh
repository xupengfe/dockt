#!/bin/bash

bzimage=$1
KERNEL="/root/os.linux.intelnext.kernel/"
#KERNEL="/home/intel-next-kernel"
IMAGE="/root/image"

[[ -z "$bzimage" ]] && bzimage="/root/image/bzImage_5.14-rc5cet"

qemu-system-x86_64 \
        -m 2G \
        -smp 2 \
        -kernel $bzimage \
        -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
        -drive file=./ubuntu_good.img,format=raw \
        -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10022-:22 \
        -cpu host \
        -net nic,model=e1000 \
        -enable-kvm \
        -nographic \
        2>&1 | tee vm.log


#       -kernel $KERNEL/arch/x86/boot/bzImage \
#       -kernel /root/image/bzImage_513rc5_thomas_0622 \
