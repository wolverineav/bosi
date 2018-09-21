#!/bin/bash
# Copyright 2018 Big Switch Networks, Inc.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

export LIBGUESTFS_BACKEND=direct

image_dir="/home/stack/images"

virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload neutron-bsn-lldp-${lldp_version}-1.el7.centos.noarch.rpm:/root/
# enabled for P+V mode
#virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload ivs-${ivs_version}.el7.centos.x86_64.rpm:/root/
#virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload ivs-debuginfo-${ivs_version}.el7.centos.x86_64.rpm:/root/

virt-customize -a ${image_dir}/overcloud-full.qcow2 --upload impl_ifcfg.py:/root/
virt-customize -a ${image_dir}/overcloud-full.qcow2 --firstboot startup.sh
