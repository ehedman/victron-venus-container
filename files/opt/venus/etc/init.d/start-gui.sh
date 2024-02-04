#!/bin/bash

touch /data/start-gui

function startGuiVnc()
{

    cd /tmp && nohup /opt/victronenergy/gui/gui -display VNC:size=800x480:depth=32:passwordFile=/data/conf/vncpassword.txt:0 &
}

startGuiVnc

while true
do
    inotifywait -e modify /data/start-gui

    if [ "$(cat /data/start-gui)" == "start-gui-vnc" ]; then

        startGuiVnc

    elif [ "$(cat /data/start-gui)" == "start-gui" ]; then
        #export TSLIB_TSEVENTTYPE=INPUT
        export TSLIB_CONSOLEDEVICE=none
        export TSLIB_FBDEVICE=/dev/fb0
        #export TSLIB_TSDEVICE=/dev/input/event3
        export TSLIB_CALIBFILE=/etc/pointercal
        export TSLIB_CONFFILE=/etc/ts.conf
        export TSLIB_PLUGINDIR=/usr/lib/ts
        #export QWS_MOUSE_PROTO=tslib:/dev/input/event3

        cd /tmp && nohup /opt/victronenergy/gui/gui -display LinuxFb:
        echo "done" > /data/start-gui

        if ! pidof -q gui; then
            startGuiVnc
        fi
    fi

done
