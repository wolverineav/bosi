#!/usr/bin/env bash
# env variables to be supplied by BOSI
fqdn={fqdn}
phy1_name={phy1_name}
phy1_nics={phy1_nics}
active_active={active_active}
system_desc={system_desc}

# constants for this job
LOG_FILE="/var/log/bcf_setup.log"
SERVICE_FILE_1='/usr/lib/systemd/system/send_lldp_1.service'
SERVICE_FILE_MULTI_USER_1='/etc/systemd/system/multi-user.target.wants/send_lldp_1.service'

# new vars with evaluated results
HOSTNAME=`cat /etc/hostname`

# Make sure only root can run this script
if [ "$(id -u)" != "0" ]; then
   echo -e "Please run as root" >> $LOG_FILE
   exit 1
fi

# if service file exists, stop the service. else, return true
systemctl stop send_lldp_1 | true

# rewrite service file
echo "
[Unit]
Description=BSN send_lldp for physnet 1
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/python /usr/lib/python2.7/site-packages/networking_bigswitch/bsnlldp/send_lldp.py --system-desc ${{system_desc}} --system-name ${{HOSTNAME}}-${{phy1_name}} -i 10 --network_interface ${{phy1_nics}}
Restart=always
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
" > $SERVICE_FILE_1

# symlink multi user file
ln -sf $SERVICE_FILE_1 $SERVICE_FILE_MULTI_USER_1

# reload service files
systemctl daemon-reload

# start services as required
systemctl restart send_lldp_1

echo "Finished updating with SRIOV LLDP scripts."   >> $LOG_FILE
