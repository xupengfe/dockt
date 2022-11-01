#!/bin/bash

bzimage=$1
KERNEL="/root/os.linux.intelnext.kernel/"
#KERNEL="/home/intel-next-kernel"
IMAGE="/root/image"

[[ -z "$bzimage" ]] && bzimage="./bzImage_tbt_1031"

qemu-system-x86_64 \
        -m 2G \
        -smp 2 \
        -device vfio-pci,host="00:0d.0" \
        -device vfio-pci,host="00:0d.2" \
        -device vfio-pci,host="00:0d.3" \
        -kernel $bzimage \
        -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0 thunderbolt.dyndbg" \
        -drive file=./centos8_2.img,format=raw \
        -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10022-:22 \
        -cpu host \
        -net nic,model=e1000 \
        -enable-kvm \
        -nographic \
        2>&1 | tee vm.log

#	-device vfio-pci,host=00:07.0,id=hostdev1,addr=0x4 \
#       -kernel $KERNEL/arch/x86/boot/bzImage \
#       -kernel /root/image/bzImage_513rc5_thomas_0622 \
