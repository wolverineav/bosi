#!/bin/bash

yum remove -y openstack-neutron-bigswitch-agent
yum remove -y openstack-neutron-bigswitch-lldp
yum remove -y python-networking-bigswitch

rpm -ivh --force /root/python-networking-bigswitch-${bsnstacklib_version}-1.el7.centos.noarch.rpm
rpm -ivh --force /root/openstack-neutron-bigswitch-agent-${bsnstacklib_version}-1.el7.centos.noarch.rpm
rpm -ivh --force /root/openstack-neutron-bigswitch-lldp-${bsnstacklib_version}-1.el7.centos.noarch.rpm
rpm -ivh --force /root/python-horizon-bsn-${horizon_bsn_version}-1.el7.centos.noarch.rpm

systemctl enable neutron-bsn-lldp.service
systemctl restart neutron-bsn-lldp.service

if [[ $(hostname) == *compute* ]]; then
    rpm -ivh --force /root/nfvswitch-0.1.0-1.el7.centos.x86_64.rpm
    rpm -ivh --force /root/nfvswitch-debuginfo-0.1.0-1.el7.centos.x86_64.rpm
    rpm -ivh --force /root/qemu-system-x86-2.5.0-4bsn1.el7.centos.x86_64.rpm
    rpm -ivh --force /root/qemu-common-2.5.0-4bsn1.el7.centos.x86_64.rpm
    rpm -ivh --force /root/qemu-img-2.5.0-4bsn1.el7.centos.x86_64.rpm

    grubby --update-kernel=ALL --args="isolcpus=2-23 nohz_full=2-23 hugepagesz=1G hugepages=24058 iommu=pt intel_iommu=on"
    reboot
fi
