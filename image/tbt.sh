#!/bin/bash

DINFO=""

get_dinfo() {
  dinfo=$1

  DINFO=""
  did=$(lspci -Dn -s $dinfo | awk '{print $3}')
  di1=$(echo $did | cut -d ":" -f 1)
  di2=$(echo $did | cut -d ":" -f 2)
  DINFO="$di1 $di2"
  echo "$dinfo ->  $DINFO"
}

load_vfio() {
  local vfio=""

  vfio=$(lsmod | grep vfio)
  if [[ -z "$vfio" ]]; then
    echo "vfio_pci is not loaded and load it."
    modprobe vfio_pci
    vfio=$(lsmod | grep vfio)
    if [[ -z "$vfio" ]]; then
       echo "vfio_pci could not be loaded and exit"
       exit 1
    else
       echo "load vfio_pci successfully."
    fi
  else
    echo "vfio_pci is alread loaded."
  fi
}

main() {
  d0i="0000:00:0d.0"
  d2i="0000:00:0d.2"
  d3i="0000:00:0d.3"

  # Make sure vfio_pci is loaded
  load_vfio

  #d0d="8086 a71e"
  #d2d="8086 a73e"
  #d3d="8086 a76d"
  get_dinfo "$d0i"
  d0d=$DINFO

  get_dinfo "$d2i"
  d2d=$DINFO

  get_dinfo "$d3i"
  d3d=$DINFO

  # add the pci info into vfio new_id
  echo "echo $d0d >  /sys/bus/pci/drivers/vfio-pci/new_id"
  echo "$d0d" >  /sys/bus/pci/drivers/vfio-pci/new_id

  echo "echo $d2d >  /sys/bus/pci/drivers/vfio-pci/new_id"
  echo "$d2d" >  /sys/bus/pci/drivers/vfio-pci/new_id

  echo "echo $d3d >  /sys/bus/pci/drivers/vfio-pci/new_id"
  echo "$d3d" >  /sys/bus/pci/drivers/vfio-pci/new_id

  # unbind the bdf
  echo "echo $d0i  >   /sys/bus/pci/devices/$d0i/driver/unbind"
  echo "$d0i"  >   /sys/bus/pci/devices/"$d0i"/driver/unbind

  echo "echo $d2i  >   /sys/bus/pci/devices/$d2i/driver/unbind"
  echo "$d2i"  >   /sys/bus/pci/devices/"$d2i"/driver/unbind

  echo "echo $d3i  >   /sys/bus/pci/devices/$d3i/driver/unbind"
  echo "$d3i"  >   /sys/bus/pci/devices/"$d3i"/driver/unbind


  # bind the pci bdf
  echo "echo $d0i  >    /sys/bus/pci/drivers/vfio-pci/bind"
  echo "$d0i"  >    /sys/bus/pci/drivers/vfio-pci/bind

  echo "echo "$d2i"  >    /sys/bus/pci/drivers/vfio-pci/bind"
  echo "$d2i"  >    /sys/bus/pci/drivers/vfio-pci/bind

  echo"echo "$d3i"  >    /sys/bus/pci/drivers/vfio-pci/bind"
  echo "$d3i"  >    /sys/bus/pci/drivers/vfio-pci/bind
}


main
