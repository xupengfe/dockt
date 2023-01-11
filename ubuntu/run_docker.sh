#!/bin/bash

IMG_NAME="ubuntu22"

CHECK=$(docker image ls | grep "$IMG_NAME")


if [[ -z "$CHECK" ]]; then
  echo "No docker img:$IMG_NAME, will make it."
  echo "docker build -t $IMG_NAME ."
  docker build -t "$IMG_NAME" .
  echo "docker image build ."
  docker image build .
  echo "docker image ls | grep $IMG_NAME"
  docker image ls | grep $IMG_NAME
  #echo "docker run -it $IMG_NAME bash"
  #docker run -it "$IMG_NAME" bash
else
  echo "docker image ls | grep $IMG_NAME"
  docker image ls | grep $IMG_NAME
  #echo "docker run -it $IMG_NAME bash"
  #docker run -it "$IMG_NAME" bash
fi

echo "Next please cd target folder, then run below command:"
echo "docker run -it -v `pwd`:/src $IMG_NAME bash"
