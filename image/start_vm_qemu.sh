#!/bin/bash

DISPLAY=:1 qemu-system-x86_64 -enable-kvm \
    -drive if=pflash,format=raw,readonly=on,file=./OVMF_CODE.fd \
    -boot order=c,menu=on,splash-time=1 \
    -m 4G \
    -cpu host \
    -smp 4 \
    -vnc :8 \
    -netdev tap,id=nic0,br=br0,helper=/usr/local/libexec/qemu-bridge-helper,vhost=on \
    -device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
    -hda ./centos_0602.img

#    -nographic -vga none \
    #-cdrom centos-8.3.2011-embargo-installer-202106021408.iso \
#    -drive if=pflash,format=raw,readonly,file=ovmf/OVMF_CODE.fd \
#    -boot order=c,menu=off,splash-time=1 \

#-netdev tap,id=nic0,br=virbr0,helper=/usr/local/libexec/qemu-bridge-helper,vhost=on \
#-device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
    #-M q35 \
    #-device vfio-pci,host=0000:02:00.0 \

    #-vga none -nodefaults -nographic \
#    -device virtio-net-pci,netdev=nic0,mac=00:16:3e:0c:12:78 \
#    -netdev tap,id=nic0,br=virbr0,helper=/usr/local/libexec/qemu-bridge-helper,vhost=on \
