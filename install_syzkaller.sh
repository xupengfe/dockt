#!/bin/bash

echo "docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest"
docker pull ccr-registry.caas.intel.com/simicsaas/syzkaller:latest

echo "docker run --privileged -it -p 5000:56741 -v `pwd`:/root/image ccr-registry.caas.intel.com/simicsaas/syzkaller bash"

echo "docker exec -it pensive_pike bash"
