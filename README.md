# Set up syzkaller by script way
```
wget https://raw.githubusercontent.com/xupengfe/dockt/main/setup_syz_sandbox.sh -O /root/setup_syz.sh
chmod 755 /root/setup_syz.sh
screen -dmSL bash /root/setup_syz.sh -s o -k /root/os.linux.intelnext.kernel -t intel-6.5-rc1-2023-07-10 -b v6.5-rc1 -n v5.11

screen -dmSL bash /root/setup_syz.sh -s o -k /root/internal-devel -t v6.5-rc1_internal-devel_hourly-20230710-100107 -b 06c2afb862f9da8dc5efa4b6076a0e48c3fbaaa5 -n f40ddce88593482919761f74910f42f4b84c004b
```

# dockt
It's for docker tests
echo "docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest"
docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest

echo "docker run --privileged -it -p 5000:56741 -v `pwd`:/root/image ccr-registry.caas.intel.com/simicsaas/syzkaller bash"

echo "docker exec -it pensive_pike bash"

https://github.com/xupengfe/dockt/blob/main/setup_syzkaller.sh with dock.

It's only supported for Cent OS environment:
https://github.com/xupengfe/dockt/blob/main/setup_syz.sh  without dock.
