#!/bin/bash

RO="no"

function doChroot
{
    exec chroot "$1" /etc/init.d/venus-manager.sh boot
}

function doDocker
{
    exec docker run --rm \
     --privileged \
     --hostname=venus \
     --net=host \
     -v/"$1":/opt \
     -v/run/udev/data:/opt/data/udev \
     --platform linux/arm64/v8 arm64v8/debian \
    sh -c 'chroot /opt /etc/init.d/venus-manager.sh boot'
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

if [ "$3" = "ro" ]; then
    echo "Info: (arg3) Venus root directory will be mounted read only"
    RO="yes"
fi

case "$2" in
    chroot)
        BOOTM=doChroot
    ;;
    systemd-nspawn)
        BOOTM=doNspawn
    ;;
    docker)
        BOOTM=doDocker
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

if ! mkdir -p "$ROOT"/lib/overlay/upper "$ROOT"/lib/overlay/work; then
    echo "Error: failed to create folders for overlayfs"
    exit 1
fi

mount -o,remount,rw "$ROOT" &>/dev/null

if [ "$RO" = "yes" ]; then
   if ! mount -o,remount,ro "$ROOT" &>/dev/null; then
       mount -B -o,ro "$ROOT" "$ROOT"
   fi
fi

UPPER="/tmp/venus/upper"
WORK="/tmp/venus/work"
LOWER="/lib/modules"
MERGED="$ROOT/lib/modules"

mkdir -p "$UPPER" "$WORK"

if [ -d "$ROOT"/lib/modules ]; then
    if ! mount overlay -t overlay -t overlay -o lowerdir="$LOWER",upperdir="$UPPER",workdir="$WORK" "$MERGED" &>/dev/null; then
        echo "CRITICAL: Failed to overlay-fs to $ROOT/lib/modules"
    fi
fi

if [ -d "$ROOT"/data/udev ] && [ -d /run/udev/data ]; then

    echo  "$ROOT" >/run/venus-root

    if test -e "$ROOT"/data/udev/mp; then
        mount -B /run/udev/data "$ROOT"/data/udev &>/dev/null
    fi

    "$BOOTM" "$ROOT"
fi

# Should not end up here ..
rm -f /run/venus-root
exit 1
