#!/usr/bin/env bash

function gwstart() {
 echo "-> Starting Gateway";
 echo "1" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=1;
 if [ -f "iptables.conf" ]; then mv -f "iptables.conf" "iptables.conf.old"; fi;
 iptables-save > iptables.conf;
 read -e -p "-> Enter Interface: " -i "$(ip route get 8.8.8.8 | awk '/src/{print $5}')" interface;
 if [ -z "${interface}" ]; then echo "-> Please set local interface"; exit; fi;
 iptables -C FORWARD -i ${interface} -j ACCEPT &>/dev/null || iptables -A FORWARD -i ${interface} -j ACCEPT;
 iptables -C FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT &>/dev/null || iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;
 iptables -t nat -C POSTROUTING -o ${interface} -j MASQUERADE || iptables -t nat -A POSTROUTING -o ${interface} -j MASQUERADE;
 echo "-> done";
}

function gwstop() {
 echo "-> Stopping Gateway";
 echo "0" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=0;
 if [ -f "iptables.conf" ]; then iptables-restore < iptables.conf; fi;
 echo "-> done";
}

function gwstatus() {
 echo "-> Listing Firewall Rules";
 iptables -vnL -t nat --line-numbers; iptables -vnL FORWARD --line-numbers;
 echo "-> done";
}

case "${1}" in
start) gwstart; gwstatus; ;;
stop) gwstop; gwstatus; ;;
status) gwstatus;;
*) echo "-> Usage: $0 start/stop/status"; ;;
esac

