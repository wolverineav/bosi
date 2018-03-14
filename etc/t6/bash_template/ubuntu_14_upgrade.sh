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

is_controller=%(is_controller)s
is_ceph=%(is_ceph)s
is_cinder=%(is_cinder)s
is_mongo=%(is_mongo)s

install_pkg() {
    pkg=$1
    cd %(dst_dir)s/upgrade
    tar -xzf $pkg
    dir=${pkg::-7}
    cd $dir
    python setup.py build
    python setup.py install
}

controller() {

    PKGS=%(dst_dir)s/upgrade/*
    for pkg in $PKGS
    do
        if [[ $pkg == *"networking-bigswitch"* ]]; then
            install_pkg $pkg
            neutron-db-manage upgrade heads
            service neutron-server restart
        fi
        if [[ $pkg == *"horizon-bsn"* ]]; then
            install_pkg $pkg
            service apache2 restart
        fi
    done
}

compute() {

    PKGS=%(dst_dir)s/upgrade/*
    for pkg in $PKGS
    do
        if [[ $pkg == *"ivs"* ]]; then
            dpkg --force-all -i $pkg
            service ivs restart
        fi
        if [[ $pkg == *"networking-bigswitch"* ]]; then
            install_pkg $pkg
            service neutron-bsn-agent restart
        fi
    done
}

ceph() {
}

cinder() {
}

mongo() {
}


set +e

# Make sure only root can run this script
if [[ "$(id -u)" != "0" ]]; then
   echo -e "Please run as root"
   exit 1
fi

# uninstall bsnstacklib
pip uninstall -y bsnstacklib || true

if [[ $is_controller == true ]]; then
    controller
elif [[ $is_ceph == true ]]; then
    ceph
elif [[ $is_cinder == true ]]; then
    cinder
elif [[ $is_mongo == true ]]; then
    mongo
else
    compute
fi

set -e

exit 0

