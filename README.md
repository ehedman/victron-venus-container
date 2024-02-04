# victron-venus-container
README Feb-2024

What is Victron Venus for Rasperry Pi. Read: [Raspberry Pi running Victron’s Venus firmware](https://www.victronenergy.com/blog/2017/09/06/raspberry-pi-running-victrons-venus-firmware)

The issue (for me) is that this software is intended to be installed as wic image on a raspberry pi bootable SD card and that suggest that the venus system will own and manage the linux platform from bottom up.

In my case I already have rapserry pi running in my yacht running serveral of my other applications avaiable here on github.
I don't want to have the venus applcation running the entire platform but rather as a background service and have the Qt-gui opened up on demand from my own application  [sdlSpeedometer](https://github.com/ehedman/sdlSpeedometer) (or from a shell commnd).

This implenetatin achive this with simple means comprising just of a bunch of sctrpis and a mounted (or copied) standard venus (wic) SDcard to the host.

Typically a systemd service script will start venus as a background service using either chroot or systemd-nspawn to instantiate the system.

To use  systemd-nspawn would be the preferred method to start the system since it preovides a pretty god sanbox isolation from the host system and provides a good virtualized network domain.
Unfortunately systemd-nspawn does not today allow for wireless network address familys so we are limited to only ehternet connectivity here and that excludes the bluetooth feature of the system.

For wifi that is not a problem i my case since the host provides AP over wifi and that would in any case be a conflict with venus as it is intended to be a wifi client.

In summary the chroot:ed system gives 100% connectivity (through ethernet) to the outher world such as VRM and signalK etc.

The systemd-nspawn managed system gives the same but not bluetooth.

This is still in early developmemt and perhaps other containers will do the job better such as docker.

An interesting consequence of ths implementation is that venus now is running on a bookworm OS on a raperry pi 4 with a 6.10 Linux  kernel as opposed to the standard boot image with kernel 5.10

Please not that this stuff is still kind of experimental loosely bound to v3.20-37 a 7" hdmi display and local adaptations may be necessary.


