#!/usr/bin/env bash

ifeth=eno1;
ifwifi=wlp3s0;
wifipass=InsertPassword;

#systemctl stop NetworkManager.service;
#ip link set dev $ifeth up;
#ip address add 10.10.10.11/24 dev $ifeth;
#ip route add default via 10.10.10.1;
#echo "nameserver 8.8.4.4" >> /etc/resolv.conf;
#echo "nameserver 8.8.8.8" >> /etc/resolv.conf;

apt-get install -y hostapd dnsmasq wireless-tools iw wvdial;

sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|g' '/etc/default/hostapd';
cat <<EOF > /etc/hostapd/hostapd.conf
interface=$ifwifi
driver=nl80211
channel=1
ssid=testap
wpa=2
wpa_passphrase=$wifipass
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
# Change the broadcasted/multicasted keys after this many seconds
wpa_group_rekey=600
# Change the master key after this many seconds
wpa_gmk_rekey=86400
EOF

cat <<EOF > /etc/dnsmasq.conf
domain-needed
log-facility=/var/log/dnsmasq.log
log-queries
log-dhcp
dnssec-check-unsigned
no-resolv
no-poll
no-hosts
#server=/local.lan/10.0.0.1
server=8.8.4.4
server=8.8.8.8
server=208.67.220.220
local=/local.lan/
address=/doubleclick.net/127.0.0.1
#addn-hosts=/etc/dnsmasq_static_hosts.conf
expand-hosts
domain=local.lan
dhcp-range=10.0.0.30,10.0.0.230,72h
dhcp-host=mylaptop,10.0.0.111,36h
dhcp-option=option:router,10.0.0.1
dhcp-option=6,8.8.4.4,8.8.8.8,1.1.1.1
dhcp-option=option:ntp-server,143.210.16.201
dhcp-option=19,1 # ip-forwarding on
##interface=$ifwifi
##dhcp-range=10.0.0.10,10.0.0.250,12h
##dhcp-option=3,10.0.0.1
##dhcp-option=6,10.0.0.1
####no-resolv
##log-queries
# Send RFC-3442 classless static routes
#dhcp-option=121,10.0.0.0/24,1.2.3.4,local.lan.0/8,5.6.7.8
#As above, but use custom tftp-server instead local dnsmasq
#dhcp-boot=pxelinux,server.name,10.0.0.100
# Boot for iPXE. The idea is to send two different
# filenames, the first loads iPXE, and the second tells iPXE what to
# load. The dhcp-match sets the ipxe tag for requests from iPXE.
#dhcp-boot=undionly.kpxe
#dhcp-match=set:ipxe,175 # iPXE sends a 175 option.
#dhcp-boot=tag:ipxe,http://boot.ipxe.org/demo/boot.php
dnssec
trust-anchor=.,19036,8,2,49AAC11D7B6F6446702E54A1607371607A1A41855200FD2CE1CDDE32F24E8FB5
trust-anchor=.,20326,8,2,E06D44B80B8F1D39A95C0B0D7C65D08458E880409BBC683457104237C7F8EC8D
dnssec
dnssec-check-unsigned
EOF

echo '1' > /proc/sys/net/ipv4/ip_forward

ip link set $ifwifi up;
ip address add 10.0.0.1/24 dev $ifwifi;

iptables -t nat -F; iptables -F;
iptables -t nat -A POSTROUTING -o $ifeth -j MASQUERADE
iptables -A FORWARD -i $ifwifi -o $ifeth -j ACCEPT

systemctl stop systemd-resolved.service; systemctl disable systemd-resolved.service;

# Start
systemctl start dnsmasq.service; systemctl start hostapd.service;

# Stop
#systemctl stop hostapd.service; systemctl stop dnsmasq.service;
#echo '0' > /proc/sys/net/ipv4/ip_forward
