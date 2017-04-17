#!/usr/bin/env bash
# env variables to be supplied by BOSI
fqdn=%(fqdn)s
phy1_name=%(phy1_name)s
phy1_nics=%(phy1_nics)s
phy2_name=%(phy2_name)s
phy2_nics=%(phy2_nics)s
active_active=%(active_active)s

# constants for this job
LOG_FILE="/var/log/bcf_setup.log"
CONF_DIR="/etc/send_lldp"
CONF_FILE="$CONF_DIR/send_lldp.conf"
SERVICE_FILE='/usr/lib/systemd/system/send_lldp@.service'
SERVICE_FILE_MULTI_USER='/etc/systemd/system/multi-user.target.wants/send_lldp@test.service'

# Make sure only root can run this script
if [ "$(id -u)" != "0" ]; then
   echo -e "Please run as root" >> $LOG_FILE
   exit 1
fi

# if conf file exists, read it and stop services
if [ -f $CONF_FILE ]; then
    echo "send_lldp.conf exists. Stopping running agents."  >> $LOG_FILE
    egrep '^[a-zA-Z0-9_-\ ]+' $CONF_FILE | while read args; do
        echo "stopping send_lldp@" "$args"  >> $LOG_FILE
        systemctl stop send_lldp@"${args}" | true
    done
    echo "Done stopping previous instances of send_lldp."   >> $LOG_FILE
else
    mkdir -p $CONF_DIR
fi

# Overwrite existing file with new content
echo "
# lines starting with # are ignored. Sample args as given below:
# --system-desc 5c:16:c7:00:00:00 --system-name <hostname-physnet_name> -d -i 10 --network_interface <list_of_interfaces>
" > $CONF_FILE

# correctly populate CONF_FILE
if [[ $active_active == true ]]; then
    echo " --system-desc 5c:16:c7:00:00:00 --system-name ${fqdn}-${phy1_name} -d -i 10 --network_interface ${phy1_nics}" >> $CONF_FILE
else
    echo " --system-desc 5c:16:c7:00:00:00 --system-name ${fqdn}-${phy1_name} -d -i 10 --network_interface ${phy1_nics}" >> $CONF_FILE
    echo " --system-desc 5c:16:c7:00:00:00 --system-name ${fqdn}-${phy2_name} -d -i 10 --network_interface ${phy2_nics}" >> $CONF_FILE
fi

if [ ! -f $SERVICE_FILE ]; then
# service file doesn't exist,
# create the service file
echo "
[Unit]
Description=BSN send_lldp for %I
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/bin/send_lldp %I
Restart=always
StartLimitInterval=60s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target

" > $SERVICE_FILE

# link service file to multi user target
ln -sf $SERVICE_FILE $SERVICE_FILE_MULTI_USER

fi

# start the service as required:
egrep '^[a-zA-Z0-9_-\ ]+' $CONF_FILE | while read args; do
    echo "starting send_lldp@ ${args}"  >> $LOG_FILE
    systemctl start send_lldp@"${args}" | true
done
echo "Finished updating with SRIOV LLDP scripts."   >> $LOG_FILE
