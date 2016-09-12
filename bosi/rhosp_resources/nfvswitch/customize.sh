#!/bin/bash

export LIBGUESTFS_BACKEND=direct

if [ "$#" -ne 2 ]; then
    echo "Usage: customize.sh <overcloud.qcow2> <compute|controller>"
    exit
fi

image=$1
image_type=$2
if [[ $image_type != "compute" && $image_type != "controller" ]]; then
    echo "Invalid type $image_type. Valid types: 'controller' or 'compute'"
    exit
fi

image_dir="/home/stack/images"
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload python-networking-bigswitch-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload openstack-neutron-bigswitch-lldp-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload openstack-neutron-bigswitch-agent-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload python-horizon-bsn-${horizon_bsn_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload nfvswitch-${nfvswitch_version}-1.el7.centos.x86_64.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload nfvswitch-debuginfo-${nfvswitch_version}-1.el7.centos.x86_64.rpm:/root/

# Temp work-around to include os-net-config patch with RHOSP9: Enable os-net-config to support and configure NFVSwitch
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/impl_ifcfg.py:/usr/lib/python2.7/site-packages/os_net_config/impl_ifcfg.py
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/__init__.py:/usr/lib/python2.7/site-packages/os_net_config/__init__.py
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/objects.py:/usr/lib/python2.7/site-packages/os_net_config/objects.py

if [ $image_type == "compute" ]; then
    virt-customize -a ${image_dir}/overcloud-full.qcow2 --firstboot startup_compute.sh
else
    virt-customize -a ${image_dir}/overcloud-full.qcow2 --firstboot startup_controller.sh
fi
