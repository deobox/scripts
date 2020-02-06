#!/bin/bash

function dnsup() { echo "1" > /proc/sys/net/ipv4/ip_forward;
iptables -A INPUT -p udp --dport 53 -m comment --comment "dns" -j ACCEPT;
iptables -A FORWARD -p udp --dport 53 -m comment --comment "dns" -j ACCEPT;
iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j DNAT --to-destination 8.8.4.4:53;
iptables -t nat -A POSTROUTING -p udp -m udp --dport 53 -j SNAT --to-source 10.0.0.1;
}
function dnsdown() { echo "0" > /proc/sys/net/ipv4/ip_forward; systemctl restart iptables.service; systemctl reload iptables.service; }
function dnsstatus() { echo "-> Listing firewall rules"; iptables -vnL -t nat; iptables -vnL; }

case "${1}" in
up) dnsup; dnsstatus; ;;
down) dnsdown; dnsstatus; ;;
status) dnsstatus; ;;
*) echo "-> Usage: $0 up/down/status"; ;;
esac
