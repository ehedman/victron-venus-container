#!/bin/bash

touch /run/udev/data/start-gui

# tslib support:
# opkg update
# opkg install qt4-embedded-plugin-mousedriver-tslib
# opkg install tslib-calibrate
# opkg install tslib-tests
# run ts_calibrate and touch the screen in the right spots.
export TSLIB_TSEVENTTYPE=INPUT
export TSLIB_CONSOLEDEVICE=none
export TSLIB_FBDEVICE=/dev/fb0
export TSLIB_TSDEVICE=/dev/input/touchscreen0
export TSLIB_CALIBFILE=/etc/pointercal
export TSLIB_CONFFILE=/etc/ts.conf
export TSLIB_PLUGINDIR=/usr/lib/ts
export QWS_MOUSE_PROTO=tslib:/dev/input/touchscreen0

function startGuiVnc()
{

    cd /tmp && nohup /opt/victronenergy/gui/gui -display VNC:size=800x480:depth=32:passwordFile=/data/conf/vncpassword.txt:0 &
}

startGuiVnc

while true
do
    inotifywait -e modify /run/udev/data/start-gui

    if [ "$(cat/run/udev/data/start-gui)" == "start-gui-vnc" ]; then

        startGuiVnc

    elif [ "$(cat /run/udev/data/start-gui)" == "start-gui" ]; then

        cd /tmp && nohup /opt/victronenergy/gui/gui -display LinuxFb:
        echo "done" > /run/udev/data/start-gui

        if ! pidof -q gui; then
            startGuiVnc
        fi
    fi

done
