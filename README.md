# victron-venus-container
README Feb-2024

What is Victron Venus for Rasperry Pi. Read: [Raspberry Pi running Victron’s Venus firmware](https://www.victronenergy.com/blog/2017/09/06/raspberry-pi-running-victrons-venus-firmware)

The issue (for me) is that this software is intended to be installed as wic image on a raspberry pi bootable SD card and that suggest that the venus system will own and manage the linux platform from bottom up.

In my case I already have rapserry pi running in my yacht running serveral of my other applications avaiable here on github.
I don't want to have the venus applcation running the entire platform but rather as a background service and have the Qt-gui opened up on demand from my own application  [sdlSpeedometer](https://github.com/ehedman/sdlSpeedometer) (or from a shell commnd).

This implenetatin achive this with simple means comprising just of a bunch of sctrpis and a mounted (or copied) standard venus (wic) SDcard to the host.

Typically a systemd service script will start venus as a background service using either a docker, chroot or systemd-nspawn to instantiate the system.

To use  systemd-nspawn would be a preferred method to start the system since it preovides a pretty god sanbox isolation from the host system and provides a good virtualized network domain.
Unfortunately systemd-nspawn does not today allow for wireless network address familys so we are limited to only ehternet connectivity here and that excludes the bluetooth feature of the system.

For wifi that is not a problem i my case since the host provides AP over wifi and that would in any case be a conflict with venus as it is intended to be a wifi client.

In summary the chroot:ed system and docker gives 100% connectivity (through ethernet) to the outher world such as VRM and signalK etc.

The systemd-nspawn managed system gives the same but not bluetooth.

This is still in early developmemt and perhaps other containers will do the job better.

An interesting consequence of ths implementation is that venus now is running on a bookworm OS on a raperry pi 4 with a 6.10 Linux  kernel as opposed to the standard boot image with kernel 5.10

Please not that this stuff is still kind of experimental loosely bound to venus v3.20-37 a 7" hdmi display, Bookworm on rasperry pi 4 Rev 1.5 . Local adaptations may be necessary.

To start with docker, an initial container must be created:  # docker run -it --platform linux/arm64/v8 arm64v8/debian

### To test docker  stand-alone:
- with bash only: docker run --rm -it --privileged  --hostname=venus --net=host  -v/opt/venus:/opt  -v/run/udev/data:/opt/data/udev --platform linux/arm64/v8 arm64v8/debian  bash
- full venus os: docker run --rm -it --privileged  --hostname=venus --net=host  -v/opt/venus:/opt -v/run/udev/data:/opt/data/udev  --platform linux/arm64/v8  arm64v8/debian  sh -c 'chroot /opt /etc/init.d/venus-manager.sh boot'<br>
Assuming here that the modified venus wic image is available (mounted or copied) to /opt/venus

### From systemd
- First fix  /etc/default/venus to reflect rootfs for venus and boot method
- systemctl start venus-system.service

### From shell
- /usr/local/bin/venus-boot.sh [ rootdir for venus ] [ method=chroot:systemd-nspawn:docker ]
- To start the Qt-gui on the raperry-pi display: /usr/local/bin/venus-start-gui (from shell or from shell call from another app)
- The remote console is always active but may run on port 82 (if another web server uses port 80). This can be altered in /etc/init.d/venus-manager.sh as seen from the venus rootfs.

For the latter case, the remote console won't be available from VRM, but still online remotely if your firewall takes care of the redirection of port 80->82.<br>
This behaviour is valid for docker and chroot but systemd-nspawn has a virtualization of venus eth0 to make it appear as a truly bridged networked device with dhcp client features.

### What about 32 and 64 bit systems
Bookworm 32-bit has still a 64 bit kernel and it is running 32 bit binaries in user space. This implementation is tested on such a system and 64 bit bookworm is not tested.<br>
This explains why we are loading a linux/arm64/v8 docker to the system.

