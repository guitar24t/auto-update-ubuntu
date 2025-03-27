#!/bin/bash

#Place the following in /etc/cron.d/auto_update_run
#0 3 * * * root sleep ${RANDOM:0:2}m && /scripts/autoupdate.sh


export DEBIAN_FRONTEND=noninteractive
mkdir -p /var/log/autoupdate
if [ ! -d /var/log/autoupdate ]; then
    logfile=/dev/null
else
    logfile=/var/log/autoupdate/lastrun.log
fi

auto_restart=true

apt update -y > $logfile
apt upgrade -o Dpkg::Options::="--force-confnew" -y | tee --append $logfile
apt upgrade -o APT::Get::Always-Include-Phased-Updates=true -y | tee --append $logfile
apt dist-upgrade -o Dpkg::Options::="--force-confnew" -y | tee --append $logfile
apt-mark auto ^linux-image- | tee --append $logfile
apt autoremove --yes | tee --append $logfile

if [ $logfile != '/dev/null' ]; then
    if [ $( grep -Po '\d+(?= (upgraded|newly installed|to remove))' /var/log/autoupdate/lastrun.log | awk '{ SUM += $1 } END { print SUM }' ) -gt 0 ]; then
        if [ $auto_restart = false ]; then
            echo "Skipping required reboot, please restart this server"
        else
            echo "Rebooting server..."
            reboot
        fi
    else
        echo "No reboot required."
    fi
fi
