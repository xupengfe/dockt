FROM centos:8

LABEL maintainer "Xu Pengfei <Pengfei.Xu@intel.com>"
LABEL name "syzkaller_build"

RUN yum -y install glibc-devel.i686 glibc-devel
RUN yum -y install gcc-c++
RUN yum -y install make
RUN yum -y install ncurses-devel
RUN dnf -y update kernel rpm libsolv
RUN yum -y install net-tools
RUN yum -y install virt-manager
RUN yum -y install bison
RUN yum -y install flex
RUN yum -y install ncurses
RUN yum -y install elfutils-libelf-devel
RUN yum -y install libcap-devel
RUN yum -y install openssl-devel
RUN yum -y install fuse-devel
RUN dnf -y install libcap-ng-devel
RUN dnf -y install numactl-devel
RUN yum -y install rpm-build rpmdevtools
RUN yum -y install glibc-devel.i686 glibc-devel
RUN yum -y install patch
RUN yum -y install automake
RUN yum -y install libstdc++-devel
RUN yum -y install libstdc++-static 
RUN yum -y install alsa-lib-devel
RUN yum -y install cmake
RUN dnf -y install libusbx-devel
RUN dnf -y install python2-devel
RUN dnf -y install python3-devel
RUN yum -y install make automake gcc gcc-c++ kernel-devel
RUN yum -y install yum-utils
RUN yum -y install perl-Digest-SHA.x86_64
RUN yum -y install git-email
RUN yum -y install libtool
RUN yum -y install glib2
RUN yum -y install glib2-devel
RUN yum -y install pixman-devel.x86_64
RUN yum -y install gtk3-devel.x86_64
RUN yum -y install libvirt-client.x86_64
RUN yum -y install libvirt-daemon.x86_64
RUN yum -y install ncurses-devel.x86_64
RUN yum -y install elfutils-libelf-devel.x86_64

RUN mkdir /workbench
WORKDIR /
