#!/bin/bash

BT="no"

if [ "$1" == "boot" ]; then

    if test -d /sys/class/net/mv-eth0; then
        # This is  for systemd-nspawn booted system
        mount /run
        mount /dev
        mount /dev/pts
        mount /data/log
        sed -i /82/s//80/ /etc/nginx/sites-enabled/default_server
        sed -i /'Port 23'/s//'Port 22'/ etc/ssh/sshd_config

        ifup eth0
        udhcpc -i eth0

    else
        # This is  for chroot/docker booted system
        mount -a
        # The lines below are only necessary if a web and/or an sshd server is already running on the 'host'
        # I.e, the remote console must be invoked with the :82 port declaration on the url line.
        sed -i /80/s//82/ /etc/nginx/sites-enabled/default_server
        sed -i /'Port 22'/s//'Port 23'/ etc/ssh/sshd_config
        BT="yes"
    fi


    if [ "$(mount | grep "lib/modules" | awk '{print $1}')" = "overlay" ]; then
        echo "Unpacking xz modules in /lib/modules. This will take a few seconds ..."    
        find /lib/modules/ -name "*.ko.xz" -exec xz -d {} \;
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
    echo 0 > /tmp/last_boot_type
    /usr/bin/csocket /run/dbus/system_bus_socket

    # Remove devices not to be touched by venus
    rm -f /dev/serial-starter/ttyACM0

    if  [ "$(ls -A /data/udev)" ] && [ ! -d /run/udev/data ] ; then
        mkdir -p /run/udev/data
        mount -B /data/udev /run/udev/data
    else
        echo "CRITICAL: $0: No population of /run/udev/data"
    fi

    cd /etc/rc5.d

    for file in S*
    do
        case $file in
            S09haveged | \
            S01networking | \
            S15mountnfs.sh | \
            S20apmd | \
            S20dnsmasq | \
            S20sshd | \
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

    if [ "$BT" = "yes" ]; then
        sh /lib/udev/bt-config hci0
    fi

    sleep 4

    {
        /opt/victronenergy/localsettings/localsettings.py &
        /opt/victronenergy/venus-platform/venus-platform &
        /opt/victronenergy/websockify-c/websockify 0.0.0.0:81 127.0.0.1:5900 &
        /opt/victronenergy/dbus-generator-starter/dbus_generator.py &
        /usr/bin/python3 -u /opt/victronenergy/localsettings/localsettings.py --path=/data/conf &
        /bin/bash /opt/victronenergy/serial-starter/serial-starter.sh &
        /opt/victronenergy/hub4control/hub4control &
        /bin/simple-upnpd --xml /var/run/simple-upnpd.xml -d &
        /usr/sbin/llmnrd -H venus -6 &
        /opt/victronenergy/service-advertiser/navico-announcement.sh 80 /app &
        /opt/victronenergy/venus-access/venus-access &
        /opt/victronenergy/dbus-qwacs/dbus-qwacs &
        /opt/victronenergy/dbus-fronius/dbus-fronius &
        /opt/victronenergy/dbus-adc/dbus-adc --banner &
        /usr/bin/python3 -u /opt/victronenergy/dbus-vebus-to-pvinverter/dbus_vebus_to_pvinverter.py &
        /usr/bin/python3 -u /opt/victronenergy/vrmlogger/vrmlogger.py &
        /bin/bash /opt/victronenergy/ssh-tunnel/setup-tunnel.sh &
        /usr/bin/python3 -u /opt/victronenergy/mqtt-rpc/mqtt-rpc.py &

        if [ "$BT" = "yes" ]; then
            svc -u /service/dbus-ble-sensors /service/vesmart-server
        else
            svc -t /service/dbus-ble-sensors /service/vesmart-server
        fi

        sleep 5

        /etc/init.d/start-gui.sh start-gui-vnc &

        bash

    } 2>&1 | tee -a /var/log/venus-manager
fi
