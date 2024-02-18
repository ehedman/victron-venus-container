#!/bin/bash

BT="no"

if [ "$1" == "boot" ]; then

    if test -d /sys/class/net/mv-eth0; then
        # This is  for systemd-nspawn booted system
        mount /run
        mount /dev
        mount /dev/pts
        mount /sys/fs/pstore
        mount /dev/shm 
        mount /data/log
        mount /var/volatile
        mount /var/lib
        mount /dev/mqueue

        ifup eth0
        udhcpc -i eth0

    else
        # This is  for chroot/docker booted system
        mount -a
        BT="yes"
    fi


    if [ "$(mount | grep "lib/modules" | awk '{print $1}')" = "overlay" ]; then
        echo "Unpacking xz modules in /lib/modules. This will take a few seconds ..."    
        find /lib/modules/$(uname -r) -name "*.ko.xz" -exec xz -d {} \;
        echo "Done"
    fi

    mkdir /run/dbus
    mkdir /run/lock
    mkdir -p /var/volatile/log
    mkdir -p /var/volatile/services
    mkdir -p /var/volatile/tmp
    mkdir -p /var/lock/swupdate
    mkdir -p /var/volatile/log/nginx
    mkdir /run/nginx
    mkdir /run/flashmq
    echo 0 > /tmp/last_boot_type
    /usr/bin/csocket /run/dbus/system_bus_socket

    # Remove devices not to be touched by venus
    rm -f /dev/serial-starter/ttyACM0

    if  [ "$(ls -A /udev)" ] && [ ! -d /run/udev/data ] ; then
        mkdir -p /run/udev/data
        mount -B /udev /run/udev/data
    else
        echo "CRITICAL: $0: No population of /run/udev/data"
    fi

    /etc/init.d/overlays.sh 

    cd /etc/rc5.d

    for file in S*
    do
        case $file in
            S09haveged | \
            S01networking | \
            S15mountnfs.sh | \
            S20apmd | \
            S20dnsmasq | \
            S75avahi-autoipd | \
            S82report-data-failure.sh | \
            S80resolv-watch | \
            S99rmnologin.sh | \
            S90crond | \
            S99stop-bootlogd)
                continue
            ;;
        *)
            ./$file start &
            sleep 1
        ;;
        esac                  
    done

    sleep 3

    if [ "$BT" = "yes" ]; then
        sh /lib/udev/bt-config hci0
    else
        svc -t /service/dbus-ble-sensors /service/vesmart-server
    fi

    if  [ -d /etc/init.d/custom.d ] && [ "$(ls -A /etc/init.d/custom.d)" ] && [ -e /etc/init.d/custom.d/S* ]; then
        for file in /etc/init.d/custom.d/S*; do
            $file start
       done
    fi

   {
        svc -u /service/localsettings

        /etc/init.d/start-gui.sh start-gui-vnc &

        bash

    } 2>&1 | tee -a /var/log/venus-manager
fi
