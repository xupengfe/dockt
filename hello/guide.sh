#!/bin/bash
TAG_NAME="h1"

echo "How to install docker:https://docs.docker.com/engine/install/"
echo "Or check https://github.com/xupengfe/dockt.git setup_syzkaller.sh for CentOS"

echo "docker build -t $TAG_NAME ."
docker build -t $TAG_NAME .

echo "docker images"
docker images

echo "docker run -it --privileged $TAG_NAME"
docker run -it --privileged $TAG_NAME
