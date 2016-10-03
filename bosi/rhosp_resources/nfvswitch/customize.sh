#!/bin/bash

export LIBGUESTFS_BACKEND=direct

image_dir="/home/stack/images"

virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload python-networking-bigswitch-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload openstack-neutron-bigswitch-lldp-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload openstack-neutron-bigswitch-agent-${bsnstacklib_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload python-horizon-bsn-${horizon_bsn_version}-1.el7.centos.noarch.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload nfvswitch-${nfvswitch_version}-1.el7.centos.x86_64.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload nfvswitch-debuginfo-${nfvswitch_version}-1.el7.centos.x86_64.rpm:/root/

# Temp work-around to include qemu-2.5 in RHOSP9
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload qemu-system-x86-2.5.0-4bsn1.el7.centos.x86_64.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload qemu-common-2.5.0-4bsn1.el7.centos.x86_64.rpm:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload qemu-img-2.5.0-4bsn1.el7.centos.x86_64.rpm:/root/

# Temp work-around to include os-net-config patch with RHOSP9: Enable os-net-config to support and configure NFVSwitch
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/impl_ifcfg.py:/usr/lib/python2.7/site-packages/os_net_config/impl_ifcfg.py
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/__init__.py:/usr/lib/python2.7/site-packages/os_net_config/__init__.py
virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload osnet-patch/objects.py:/usr/lib/python2.7/site-packages/os_net_config/objects.py

virt-customize -a ${image_dir}/overcloud-full.qcow2 --firstboot startup.sh
