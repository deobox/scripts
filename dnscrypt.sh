#!/usr/bin/env bash

#apt install -y -f dnscrypt-proxy;
#if [ -f '/etc/resolv.conf' ]; then mv -f '/etc/resolv.conf' '/etc/resolv.conf.org' >/dev/null; fi;
#echo -e "nameserver 127.0.2.1\n#nameserver 8.8.4.4" > /etc/resolv.conf;

cat > /etc/systemd/resolved.conf << _EOF_
[Resolve]
DNS=1.0.0.1 176.103.130.131 8.8.4.4 149.112.112.112
FallbackDNS=1.1.1.1 176.103.130.130 8.8.8.8 9.9.9.9
Domains=~
LLMNR=no
MulticastDNS=no
#DNSSEC=true
DNSSEC=false
#DNSOverTLS=opportunistic
DNSOverTLS=yes
Cache=no
DNSStubListener=yes
ReadEtcHosts=yes
_EOF_

systemctl start systemd-resolved.service;
if [ -f '/etc/resolv.conf' ]; then mv -f '/etc/resolv.conf' '/etc/resolv.conf.org' >/dev/null; fi;
#echo -e "nameserver 127.0.0.53\noptions edns0 trust-ad\nsearch ." > '/etc/resolv.conf';
if [ -f '/run/systemd/resolve/stub-resolv.conf' ]; then
 ln -sf '/run/systemd/resolve/stub-resolv.conf' '/etc/resolv.conf';
fi;

sed -i 's|files dns|files resolve [!UNAVAIL=return] dns|g' /etc/nsswitch.conf; sync;
systemctl daemon-reload; systemctl restart systemd-resolved.service;

for iface in /sys/class/net/*; do
 if [ "${iface##*/}" = "lo"  ]; then continue; fi
 resolvectl revert ${iface##*/};
 resolvectl default-route ${iface##*/} no;
 resolvectl llmnr ${iface##*/} off;
 resolvectl dns ${iface##*/} 127.0.0.1;
done;
