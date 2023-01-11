#!/bin/bash

IMG_NAME="ubun1"

CHECK=$(docker image ls | grep "$IMG_NAME")


if [[ -z "$CHECK" ]]; then
  echo "No docker img:$IMG_NAME, will make it."
  echo "docker build -t $IMG_NAME ."
  docker build -t "$IMG_NAME" .
  echo "docker image build ."
  docker image build .
  echo "docker image ls | grep $IMG_NAME"
  docker image ls | grep $IMG_NAME
  echo "docker run -it $IMG_NAME bash"
  docker run -it "$IMG_NAME" bash
else
  echo "docker run -it $IMG_NAME bash"
  docker run -it "$IMG_NAME" bash
fi
