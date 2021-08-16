#!/bin/bash

bzimage=$1
KERNEL="/root/os.linux.intelnext.kernel/"
#KERNEL="/home/intel-next-kernel"
IMAGE="/root/image"

[[ -z "$bzimage" ]] && bzimage="/root/image/bzImage_5.14-rc4i"

qemu-system-x86_64 \
        -m 2G \
        -smp 2 \
	-bios ./OVMF_CODE.fd \
        -hda ./centos-8-stream-embargo-coreclient-202108030826.img \
	-net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10022-:22 \
        -cpu host \
        -net nic,model=e1000 \
        -enable-kvm \
        -nographic \
        2>&1 | tee vm.log


#        -hda ./centos-8-stream-embargo-coreclient-202108030826.img \
#	-bios ./OVMF_CODE.fd \
#        -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
#        -kernel $bzimage \
#       -kernel $KERNEL/arch/x86/boot/bzImage \
#       -kernel /root/image/bzImage_513rc5_thomas_0622 \
