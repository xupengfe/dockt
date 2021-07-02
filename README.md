# dockt
It's for docker tests

echo "docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest"
docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest

echo "docker run --privileged -it -p 5000:56741 -v `pwd`:/root/image ccr-registry.caas.intel.com/simicsaas/syzkaller bash"

echo "docker exec -it pensive_pike bash"

https://github.com/xupengfe/dockt/blob/main/setup_syzkaller.sh with dock.

It's only supported for Cent OS environment:
https://github.com/xupengfe/dockt/blob/main/setup_syz.sh  without dock.
