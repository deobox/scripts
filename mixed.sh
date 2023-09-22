alias arial='aria2c --all-proxy="$http_proxy" --http-proxy="$http_proxy" --https-proxy="$http_proxy" -d "$HOME/Downloads" --max-overall-upload-limit=8K --max-upload-limit=8K --max-download-limit=900K --no-conf=true --disable-ipv6=true --enable-dht6=false --summary-interval=0 --bt-request-peer-speed-limit=500K --bt-stop-timeout=180 --bt-tracker-connect-timeout=30 --bt-tracker-timeout=30 --bt-enable-lpd=true --bt-external-ip=127.0.0.1 --enable-peer-exchange=true --always-resume=true --human-readable=true --enable-dht --dht-listen-port=6886 --seed-time=0 --seed-ratio=1.0';
alias winkey='hexdump -s 56 -e '\''"Windows BIOS key: " /29 "%s\n"'\'' /sys/firmware/acpi/tables/MSDM;'
alias ifconfig='ip -co -st -h a';

unshare --mount --uts --ipc --net --pid --fork --user --map-root-user /bin/bash;
unshare -miupfrR /home/user/rootfs --mount-proc;

brctl addbr br0; ip addr add 10.0.0.2/24 dev br0; ip link set dev br0 up; brctl addif eth0; ip tuntap add vn0 mode tap; brctl addif br0 vn0;

nmap -sn 10.0.0.0/24; nmap -T4 -v -A -sV -sS -Pn -O -sC 127.0.0.1;

wget 'https://yt-dl.org/downloads/latest/youtube-dl' -O 'youtube-dl' && chmod 0700 'youtube-dl' && sed -i '1 s|env python|env python3|g' 'youtube-dl';
youtube-dl {-F -f 251} "file.mp4"; ffprobe "file.mp4";
ffmpeg -i file.mp4 -b:a 320K -vn file.mp3; ffmpeg -i file.flac -ab 320k file.mp3;
for file in *.webm; do ffmpeg -i "${file}" -b:a 160K -vn "${file%.*}".mp3; done;
ffmpeg -i "concat:file1.mp3|file2.mp3" -acodec copy output.mp3
sed '1,10s|#!/bin/bash|& +x|' backup.sh;

ffmpeg -f x11grab -s 1600x900 -i :0.0 -framerate 25 -preset ultrafast -f alsa -ac 2 -i hw:0 out.mp4;

apt install dnsmasq; nmcli dev wifi hotspot ifname wless0 ssid "WiFiName" password "WiFiPass";
nmcli r wifi on && nmcli d wifi connect "WiFiName" password "WiFiPass";
nmcli d w c AA:BB:CC:DD:EE:FF password "WiFiPass";

certbot certonly --manual --register-unsafely-without-email -d mydomain.com;

dd if=/dev/sda of=file.img bs=$(($(blockdev --getbsz /dev/sda)*2048)) conv=sync,noerror status=progress oflag=direct;

curl --silent "http://ipinfo.io/8.8.8.8" |  python3 -c "import sys, json; print(json.load(sys.stdin)['region'])";

socat TCP4-LISTEN:8080,fork,su=nobody TCP6:[IPv6:Adress]:80;
6tunnel -f -4 8080 IPv6:Adress 80;

sed -rne '/10\/Oct\/2020/,/09\/Nov\/2020/ p' file.log;

lsof -n -P -p "$pid";

exec &> >(nc stream.ht 1337);

while [ "${pswd}" == "" ]; do read -s -e -p "-> Enter pswd: " pswd; done; echo -e "${pswd}\n${pswd}" | passwd root; unset pswd;

adduser username && echo -e "Match User username\nChrootDirectory /home/username\nForceCommand internal-sftp -d username\nPermitTTY no\nPermitEmptyPasswords no\nX11Forwarding no" >> /etc/ssh/sshd_config && mkdir -p /home/username/username; chown root.root /home/username; chown username.username /home/username/username; chmod 0750 /home/username/username; service sshd restart;

$(which rsync) --archive --update --verbose --owner --group --links --recursive --delete-before --stats --human-readable --exclude="dir1/" --exclude="dir2/*.txt" --ipv4 -e "ssh -i /path/to/key -p 2222" user@1.1.1.1:/var/www/html/ /var/www/html/ >> sync.log 2>&1

syslinux -i /dev/sdX1; dd conv=notrunc bs=440 count=1 if=/bios/mbr/mbr.bin of=/dev/sdX; parted /dev/sdX set 1 boot on (or use fdisk /dev/sdX and A)

curl --silent "http://ipinfo.io/8.8.8.8"; curl --silent "https://ipvigilante.com/8.8.8.8"

tar --selinux --acls --xattrs -czvf file.tgz file-dir;
semanage port -a -t ssh_port_t -p tcp 11; semanage port -l | grep ssh; systemctl restart sshd.service;
semanage fcontext -a -t samba_share_t /etc/file1; restorecon -R -v /etc/file1; semanage fcontext -d /test;

apt install alsa-utils; amixer set Master unmute; amixer sset 'Master' 60%; amixer -q sset Master 3%+;

gio mount -li; gio mount mtp://[usb:XXX,YYY];
apt install jmtpfs; mkdir -p mtpdevice; chown $USER:$USER mtpdevice; jmtpfs mtpdevice; fusermount -u mtpdevice;

udevadm info -a -n /dev/sdx | grep serial; udevadm monitor -kup |& tee /tmp/udev.log;
echo 'ACTION=="add", SUBSYSTEM=="block", ATTRS{serial}=="1122334455", RUN+="/usbplugged.sh" ' >> /etc/udev/rules.d/99-usb-plugged.rules; udevadm control --reload; tail -n 0 -f /var/log/syslog;

x11vnc -storepasswd; x11vnc -forever -loop -alwaysshared -nolookup -localhost -listen 127.0.0.1 -no6 -noipv6 -nobell -noxdamage -noscr -nowf -cursor arrow -xkb -display :0 -usepw  &> vnc.log &
x11vnc -storepasswd; x11vnc -forever -loop -alwaysshared -nolookup -localhost -listen 127.0.0.1 -no6 -noipv6 -nobell -noxdamage -noscr -nowf -cursor arrow -xkb -display :0 -rfbauth ~/.vnc/passwd >> ~/vnc.log 2>&1 &
apt install tigervnc-standalone-server tigervnc-tools -- tigervncserver -localhost -autokill no -depth 16 -pixelformat rgb565

apt install lxde-core pulseaudio pavucontrol lxterminal dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install lxqt-core lxterminal pulseaudio pavucontrol-qt dbus dbus-x11 dbus-user-session xserver-xorg-core adwaita-icon-theme gnome-icon-theme-nuovo openbox xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install xfce4 xfce4-terminal pulseaudio pavucontrol dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
apt install icewm pulseaudio pavucontrol xterm dbus dbus-x11 dbus-user-session xserver-xorg-core xserver-xorg-video-all xserver-xorg-input-all x11-xserver-utils x11-xkb-utils x11-utils xinit;
