#!/bin/bash

mkdir -p /etc/pki/ca-trust/source/anchors
cd /etc/pki/ca-trust/source/anchors
wget http://owrdropbox.intel.com/dropbox/public/Ansible/certificates/IntelCA5A-base64.crt
wget http://owrdropbox.intel.com/dropbox/public/Ansible/certificates/IntelCA5B-base64.crt
wget http://owrdropbox.intel.com/dropbox/public/Ansible/certificates/IntelSHA256RootCA-base64.crt
update-ca-trust
systemctl daemon-reload
systemctl restart docker

echo "docker login   -u sys_clkv --password "CoreLinuxKernelValidation@22"  ccr-registry.caas.intel.com"
docker login   -u sys_clkv --password "CoreLinuxKernelValidation@22"  ccr-registry.caas.intel.com


