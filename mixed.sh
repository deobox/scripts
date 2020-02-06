alias arial='aria2c --all-proxy="$http_proxy" --http-proxy="$http_proxy" --https-proxy="$http_proxy" -d "$HOME/Downloads" --max-overall-upload-limit=8K --max-upload-limit=8K --max-download-limit=900K --no-conf=true --disable-ipv6=true --enable-dht6=false --summary-interval=0 --bt-request-peer-speed-limit=500K --bt-stop-timeout=180 --bt-tracker-connect-timeout=30 --bt-tracker-timeout=30 --bt-enable-lpd=true --bt-external-ip=127.0.0.1 --enable-peer-exchange=true --always-resume=true --human-readable=true --enable-dht --dht-listen-port=6886 --seed-time=0 --seed-ratio=1.0';

addbr br0; addif br0 eth0 ; addif br0 eth1; ip link set br0 up;

echo dd if=/dev/sda of=file.img bs=$(($(blockdev --getbsz /dev/sda)*2048)) conv=sync,noerror status=progress;

curl --silent "http://ipinfo.io/8.8.8.8" |  python3 -c "import sys, json; print(json.load(sys.stdin)['region'])";

sed -rne '/10\/Oct\/2020/,/09\/Nov\/2020/ p' file.log;

adduser username && echo -e "Match User username\nChrootDirectory /home/username\nForceCommand internal-sftp -d username\nPermitTTY no\nPermitEmptyPasswords no\nX11Forwarding no" >> /etc/ssh/sshd_config && mkdir -p /home/username/username; chown root.root /home/username; chown username.username /home/username/username; chmod 0750 /home/username/username; service sshd restart;

/bios/mtools/syslinux -i /dev/sdX1; dd conv=notrunc bs=440 count=1 if=/bios/mbr/mbr.bin of=/dev/sdX; parted /dev/sdX set 1 boot on (or use fdisk /dev/sdX and A)

curl --silent "http://ipinfo.io/8.8.8.8"; curl --silent "https://ipvigilante.com/8.8.8.8"
