# victron-venus-container
README April-2024

What is Victron Venus for Rasperry Pi. Read: [Raspberry Pi running Victron’s Venus firmware](https://www.victronenergy.com/blog/2017/09/06/raspberry-pi-running-victrons-venus-firmware)

The issue (for me) is that this software is intended to be installed as a wic image on a raspberry pi bootable SDcard and that suggest that the venus system will own and manage the linux platform from bottom up.

In my case I already have a rapserry pi running in my yacht running serveral of my other applications avaiable here on github.
I don't want to have the venus applcation running the entire platform but rather as a background service and have the Qt-gui opened up on demand from my own application  [sdlSpeedometer](https://github.com/ehedman/sdlSpeedometer) (or from a shell commnd).

This implenetatin achive this with simple means comprising just of a bunch of scripts and a mounted (or copied) standard venus (wic) SDcard to the host.

Typically a systemd service script will start venus as a background service using either a docker, chroot or systemd-nspawn to instantiate the system.

To use  systemd-nspawn would be a preferred method to start the system since it preovides a pretty good sanbox isolation from the host system and provides a good virtualized network domain.
Unfortunately systemd-nspawn (macvlan interface) does not today allow for wireless network address familys so for outgoing bluethooth traffic (bluetoothd) we are limited to only ehternet connectivity and that degrades the bluetooth feature of the system.<br>
It is however, still possible to connect to Venus with bluetooth from a mobile app and then further to VRM.<br>
In this situation the outgoing traffic to sensors won't work and consequentially the I/O menu in setting won't show up.

For wifi that is not a problem i my case since the host provides AP over wifi and that would in any case be a conflict with venus as it is intended to be a wifi client.<br>
If the wifi interfaces are not in AP mode or free to use, then they can show up in the venus system as well.

### Make sure venus not hijacking your other network interfaces
As explained above, I want to have two wifi APs on the host side untouched by venus.
- Add interface names to the file /etc/connman/main.conf at line beginning with NetworkInterfaceBlacklist=

In summary the chroot:ed system and docker gives 100% connectivity to the outher world such as VRM and signalK etc.

The systemd-nspawn managed system gives the same but limited bluetooth.

An interesting consequence of ths implementation is that venus now is running on a **bookworm (minimal) 32-bit OS on a raperry pi 5 with a 6.1 64bit Linux kernel** as opposed to the standard boot image with kernel 5.10

### NOTE
- This application is currently bound to venus v3.30-2 a 7" hdmi display, Bookworm on Rasperry Pi 5 B Rev 1.0. Local adaptations may be necessary.

To start with docker, an initial container must be created:
-  docker run -it --platform linux/arm64/v8 arm64v8/debian

### Quick start for evaluation purposes
Download a ready-to-go image from:
- wget http://hedmanshome.se/venus.gz
- List content: gzip -d venus.gz -c|cpio -it
- Extract content: gzip -d venus.gz -c|cpio -imVd<br>
This image is created on a Raspberry Pi 4 OS Lite Bookworm 32-bit system (64-bit kernel)<br>
Then install the host tools from the repository:<br>
cd victron-venus-container/files<br>
cp -r etc usr /<br>
Chech the new content in /etc/udev/rules.d/99-venus-* to keep them or alter them to your needs.<br>
Then:
- /usr/local/bin/venus-boot.sh /otp/venus docker rw end0<br>
Assuming: venus-root=/opt/venus, method=docker access=ro/rw net-if=end0


### To test docker  stand-alone:
- with bash only: docker run --rm -it --privileged  --hostname=venus --net=host  -v/opt/venus:/opt  -v/run/udev/data:/opt/data/udev --platform linux/arm64/v8 arm64v8/debian  bash
- full venus os: docker run --rm -it --privileged  --hostname=venus --net=host  -v/opt/venus:/opt -v/run/udev/data:/opt/data/udev  --platform linux/arm64/v8  arm64v8/debian  sh -c 'chroot /opt /etc/init.d/venus-manager.sh boot'<br>
Assuming here that the modified venus wic image is available (mounted or copied) to /opt/venus.<br>
**Please note** that this solution is not a venus docker as such but rather a generic arm64 debian docker used to encapsulate a venus wic image residning in a folder of the host system or as a mounted partition 2 venus wic image.

For regular use the script venus-boot.sh should be used in order to have the complete run-time envirommnent right.

### From systemd
- First fix  /etc/default/venus to reflect rootfs for venus, boot method, ro/rw rootfs and network interface.
- systemctl start venus-system.service

### From shell
- /usr/local/bin/venus-boot.sh [ rootdir for venus ] [ method=chroot:systemd-nspawn:docker ] [ net-if ]
- To start the Qt-gui on the raperry-pi display: /usr/local/bin/venus-start-gui (from the host shell or from shell call from another app)
- The remote console is always active on port 80.

Eventually you have to deal with port conflicts between the host and the venus guest system (possibly for port 80 and 22), though not for the systemd-nspawn booted system.

### NOTE
- The reboot function in /opt/victronenergy/gui/qml/PageSettingsGeneral.qml is now altered to Qt.quit()

### host network interface renaming
Since the bookworm OS default network interface name (when set to predictable in raspi-config) is set to end0, then a renaming is necessary either on the host or by passing an environment variable to the venus subsystem.
You may add this rule into /etc/udev/rules.d/99-(some file)<br>
SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="e4:5f:01:9a:c1:7a", NAME="eth0"<br>
Or pass the enviromnet variabe **VRM_IFACE=ethX** to the venus system. This is a valid argument for the venus-boot.sh script.

### What about 32 and 64 bit systems
Bookworm 32-bit has still a 64 bit kernel (on rpi4-5) and it is running 32 bit binaries in user space. This implementation is tested on such a system and 64 bit bookworm is not tested.<br>
This explains why we are loading a linux/arm64/v8 docker to the system.

### More about 64-bit hosts
Check the file /opt/victronenergy/dbus-i2c/dbus-i2c.py in the Venus domain, a line reading "bus=dbus.SystemBus() if (platform.machine() ==  'xxx' ...". The xxx should be alterred to what you get from the host command "uname -m" i.e. aarch64 for the 64-bit system.

