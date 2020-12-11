#!/usr/bin/env bash

#apt install dnscrypt-proxy;
#printf "nameserver 127.0.2.1\n#nameserver 1.0.0.1\n#nameserver 8.8.4.4\n#nameserver 8.8.8.8\n" > /etc/resolv.conf;

if [ -f '/etc/resolv.conf' ]; then mv -f '/etc/resolv.conf' '/etc/resolv.conf.org'; fi;
if [ -f '/run/systemd/resolve/stub-resolv.conf' ]; then ln -sf '/run/systemd/resolve/stub-resolv.conf' '/etc/resolv.conf'; fi;
#cat <<EOT>/etc/resolv.conf
#nameserver 127.0.0.53
#options edns0
#EOT

cat <<EOT>/etc/systemd/resolved.conf
[Resolve]
DNS=176.103.130.131 8.8.4.4 1.0.0.1 149.112.112.112
FallbackDNS=176.103.130.130 8.8.8.8 1.1.1.1 9.9.9.9
Domains=~
LLMNR=no
MulticastDNS=no
DNSSEC=true
DNSOverTLS=opportunistic
Cache=no
DNSStubListener=yes
ReadEtcHosts=yes
EOT

sed -i 's/ dns/ resolve [!UNAVAIL=return] dns/g' /etc/nsswitch.conf;
systemctl daemon-reload; systemctl start systemd-resolved.service;
if [ -f '/etc/resolv.conf' ]; then mv -f '/etc/resolv.conf' '/etc/resolv.conf.org'; fi;
if [ -f '/run/systemd/resolve/stub-resolv.conf' ]; then ln -sf '/run/systemd/resolve/stub-resolv.conf' '/etc/resolv.conf'; fi;
systemctl restart systemd-resolved.service;

systemd-resolve --interface $(ip route list default | awk '{print $5}') --revert;
systemd-resolve --interface $(ip route list default | awk '{print $5}') --set-dns 127.0.0.1 --set-domain domain.lan --set-llmnr=no;
resolvectl default-route $(ip route list default | awk '{print $5}') no;
