#!/bin/bash
echo=$(which echo); iptables=$(which iptables); systemctl=$(which systemctl);

function getip() { mynet='10.0.0.'; $echo -n "-> Enter IP ${mynet}"; read myip; 
if [ "${myip}" == "" ]; then echo "-> Cancelled" && exit 0; fi; myip=${mynet}${myip}; }
function fwstart() {
 echo "1" > /proc/sys/net/ipv4/ip_forward;
 $systemctl reload iptables.service;
 $iptables -I FORWARD 1 -m state --state ESTABLISHED,RELATED -j ACCEPT;
}
function openip() { $iptables -t nat -A POSTROUTING -s ${myip}/32 -p ALL -j SNAT --to-source 10.0.0.1; $iptables -I FORWARD 1 -s ${myip}/32 -p ALL -j ACCEPT; }
function fwstop() { echo "0" > /proc/sys/net/ipv4/ip_forward; $systemctl reload iptables.service; }
function fwstatus() { $echo "-> Listing firewall rules"; $iptables -vnL -t nat --line-numbers; $iptables -vnL FORWARD --line-numbers; }

case "$1" in
start) fwstart; fwstatus; ;;
stop) fwstop; fwstatus; ;;
status) fwstatus;;
add) getip; openip; fwstatus; ;;
*) $echo "-> Usage: $0 start/stop/status/add"; ;;
esac

