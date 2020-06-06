#!/usr/bin/env bash

function dnsup() { echo "1" > /proc/sys/net/ipv4/ip_forward; 
if [ -f "iptables.conf" ]; then mv -f "iptables.conf" "iptables.conf.old"; fi;
iptables-save > iptables.conf;
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;
for ipchain in 'INPUT' 'FORWARD' 'OUTPUT'; do
 for ipchport in 'tcp' 'udp'; do
  iptables -C ${ipchain} -p ${ipchport} --dport 53 -j ACCEPT &>/dev/null || iptables -A ${ipchain} -p ${ipchport} --dport 53 -j ACCEPT;
 done
done
for ipchprot in 'tcp' 'udp'; do
 iptables -C PREROUTING -t nat -p ${ipchprot} --dport 53 -j DNAT --to-destination ${ipdns}:53 &>/dev/null || iptables -A PREROUTING -t nat -p ${ipchprot} --dport 53 -j DNAT --to-destination ${ipdns}:53;
 iptables -C POSTROUTING -t nat -p ${ipchprot} --dport 53 -j SNAT --to-source ${ipmy} &>/dev/null || iptables -t nat -A POSTROUTING -p ${ipchprot} --dport 53 -j SNAT --to-source ${ipmy};
done
}

function dnsdown() { echo "0" > /proc/sys/net/ipv4/ip_forward; if [ -f "iptables.conf" ]; then iptables-restore < iptables.conf; fi; }
function dnsstatus() { echo "-> Listing firewall rules"; iptables -vnL -t nat; iptables -vnL; }

function validateip() { 
 if [[ ${1} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; 
 then echo "-> ip ${1} accepted"; 
 else echo "-> ip ${1} is invalid"; exit 1; fi 
}
function getips() {
read -e -p "-> Enter Local IP: " -i "$(ip route get 8.8.8.8 |  awk '/src/{print $7}')" ipmy; validateip "${ipmy}";
read -e -p "-> Enter Upstream DNS IP: " -i "8.8.4.4" ipdns; validateip "${ipdns}";
}

case "${1}" in
up) getips; dnsup; dnsstatus; ;;
down) dnsdown; dnsstatus; ;;
status) dnsstatus; ;;
*) echo "-> Usage: $0 up/down/status"; ;;
esac
