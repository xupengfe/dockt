#!/bin/bash
IMAGE="/root/image"

port=$1

echo "ssh -i ./stretch.id_rsa -p $port -o 'StrictHostKeyChecking no' root@localhost"
ssh -i ./stretch.id_rsa -p "$port" -o "StrictHostKeyChecking no" root@localhost
