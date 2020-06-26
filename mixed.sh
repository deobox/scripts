alias arial='aria2c --all-proxy="$http_proxy" --http-proxy="$http_proxy" --https-proxy="$http_proxy" -d "$HOME/Downloads" --max-overall-upload-limit=8K --max-upload-limit=8K --max-download-limit=900K --no-conf=true --disable-ipv6=true --enable-dht6=false --summary-interval=0 --bt-request-peer-speed-limit=500K --bt-stop-timeout=180 --bt-tracker-connect-timeout=30 --bt-tracker-timeout=30 --bt-enable-lpd=true --bt-external-ip=127.0.0.1 --enable-peer-exchange=true --always-resume=true --human-readable=true --enable-dht --dht-listen-port=6886 --seed-time=0 --seed-ratio=1.0';
alias winkey='hexdump -s 56 -e '\''"Windows BIOS key: " /29 "%s\n"'\'' /sys/firmware/acpi/tables/MSDM;'

brctl addbr br0; ip addr add 10.0.0.2/24 dev br0; ip link set dev br0 up; brctl addif eth0; ip tuntap add vn0 mode tap; brctl addif br0 vn0;

nmap -sn 10.0.0.0/24; nmap -T4 -v -A -sV -sS -Pn -O -sC 127.0.0.1;

apt install dnsmasq; nmcli dev wifi hotspot ifname wless0 ssid "WiFiName" password "WiFiPass";
nmcli r wifi on && nmcli d wifi connect "WiFiName" password "WiFiPass";

certbot certonly --manual -d eu.dist.co.uk; certbot certonly --manual -d mydomain.com;

dd if=/dev/sda of=file.img bs=$(($(blockdev --getbsz /dev/sda)*2048)) conv=sync,noerror status=progress;

curl --silent "http://ipinfo.io/8.8.8.8" |  python3 -c "import sys, json; print(json.load(sys.stdin)['region'])";

sed -rne '/10\/Oct\/2020/,/09\/Nov\/2020/ p' file.log;

tar --selinux --acls --xattrs -czvf file.tgz file-dir;

adduser username && echo -e "Match User username\nChrootDirectory /home/username\nForceCommand internal-sftp -d username\nPermitTTY no\nPermitEmptyPasswords no\nX11Forwarding no" >> /etc/ssh/sshd_config && mkdir -p /home/username/username; chown root.root /home/username; chown username.username /home/username/username; chmod 0750 /home/username/username; service sshd restart;

syslinux -i /dev/sdX1; dd conv=notrunc bs=440 count=1 if=/bios/mbr/mbr.bin of=/dev/sdX; parted /dev/sdX set 1 boot on (or use fdisk /dev/sdX and A)

curl --silent "http://ipinfo.io/8.8.8.8"; curl --silent "https://ipvigilante.com/8.8.8.8"

semanage port -a -t ssh_port_t -p tcp 11; semanage port -l | grep ssh; systemctl restart sshd.service;
semanage fcontext -a -t samba_share_t /etc/file1; restorecon -R -v /etc/file1; semanage fcontext -d /test;

gio mount -li; gio mount mtp://[usb:XXX,YYY];
apt install jmtpfs; mkdir -p mtpdevice; chown $USER:$USER mtpdevice; jmtpfs mtpdevice; fusermount -u mtpdevice;

apt install lxde-core pulseaudio pavucontrol lxterminal dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install lxqt-core lxterminal pulseaudio pavucontrol-qt dbus dbus-x11 dbus-user-session xserver-xorg-core adwaita-icon-theme gnome-icon-theme-nuovo openbox xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install xfce4 xfce4-terminal pulseaudio pavucontrol dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install icewm pulseaudio pavucontrol xterm dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
