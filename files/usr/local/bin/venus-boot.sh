#!/bin/bash

function doChroot
{
    exec chroot "$1" /etc/init.d/venus-manager.sh boot
}

function doNspawn
{
    exec systemd-nspawn -D  "$1" --link-journal=no \
     --bind=/dev/tty0 \
     --bind=/dev/ttyS0 \
     --bind=/dev/ttyUSB0 \
     --bind=/dev/fb0 \
     --bind=/dev/vhci \
     --bind=/dev/input/event0 \
     --bind=/dev/input/event1 \
     --bind=/dev/input/event2 \
     --bind=/dev/input/event3 \
     --bind=/dev/input/event4 \
     --bind=/dev/input/event5 \
     --network-macvlan=eth0 \
      --private-network \
     --capability="CAP_NET_ADMIN,CAP_SYS_MODULE,CAP_SYS_RAWIO,CAP_SYS_ADMIN,CAP_SYS_PTRACE" \
    /etc/init.d/venus-manager.sh boot
}

if [ -z "$1" ]; then
    echo "Error (arg1): A venus root directory is required as an argument"
    exit 1
fi

if [ -z "$2" ]; then
    echo "Error (arg2): A venus boot method (chroot or systemd-nspawn) is required as an argument"
    exit 1
fi

case "$2" in
    chroot)
        BOOTM=doChroot
    ;;
    systemd-nspawn)
        BOOTM=doNspawn
    ;;
    *)
    echo "Error (arg2): $2 is not a vlaid boot method"
    exit 1
    ;;
esac


if [ ! -d "$1"/service ]; then
    echo "Error: $1 not a directory root for venus"
    exit 1
fi

ROOT="$1"


if [ -d "$ROOT"/run/dbus ]; then
    echo "Already running. Can't be restarted, Please reboot the system"
    exit 1
fi

rm -f /run/venus-root

umount "$ROOT"/lib/modules &>/dev/null

if [ -d "$ROOT"/lib/overlay/upper ] && [ -d "$ROOT"/lib/overlay/work  ] && [ -d "$ROOT"/lib/modules ]; then
    if ! mount overlay -t overlay -t overlay -o lowerdir=/lib/modules,upperdir="$ROOT"/lib/overlay/upper,workdir="$ROOT"/lib/overlay/work "$ROOT"/lib/modules &>/dev/null; then
        echo "CRITICAL: Failed to overlay-fs to $ROOT/lib/modules"
    fi
fi

if [ -d "$ROOT"/data/udev ] && [ -d /run/udev/data ]; then

    echo  "$ROOT" >/run/venus-root

    mount -B /run/udev/data "$ROOT"/data/udev &>/dev/null

    "$BOOTM" "$ROOT"
fi

# Should not end up here ..
rm -f /run/venus-root
exit 1
