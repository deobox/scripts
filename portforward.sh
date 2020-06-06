#!/usr/bin/env bash
function validateip() { if [[ ${1} =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then echo "-> ip ${1} accepted"; else echo "-> ip ${1} is invalid"; exit 1; fi }
function validateport() { if (( ${1} >= 1 &&  ${1} <= 65535)); then  echo "-> port ${1} accepted"; else echo "-> ${1} is invalid port"; exit 1; fi }

read -e -p "-> Enter Local IP: " -i "$(ip route get 8.8.8.8 |  awk '/src/{print $7}')" ipmy; validateip "${ipmy}";
read -e -p "-> Enter Local Port: " -i "443" lport; validateport "${lport}";
read -e -p "-> Enter Remote IP: " ipdst; validateip "${ipdst}";
read -e -p "-> Enter Remote Port: " -i "${lport}" rport; validateport "${rport}";
read -e -p "-> Enter protocol tcp or udp: " -i "tcp" proto;
if [ ! "${proto}" == "tcp" ] && [ ! "${proto}" == "udp" ]; then echo "-> Invalid protocol ${proto}"; exit 1; fi
echo "-> Forwarding ${proto} ${ipmy}:${lport} from ${ipsrc} to ${ipdst}:${rport}";

echo "-> Generating firewall rules";
echo "
sysctl -w net.ipv4.ip_forward=1;
iptables -A INPUT -p ${proto} --dport ${lport} -j ACCEPT;
iptables -A FORWARD -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT;
iptables -A FORWARD -p ${proto} -s ${ipdst} --sport ${rport} -j ACCEPT;
iptables -A OUTPUT -p ${proto} --sport ${lport} -j ACCEPT;
iptables -A OUTPUT -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT;
iptables -t nat -A PREROUTING -p ${proto} --dport ${lport} -j DNAT --to ${ipdst}:${rport};
iptables -t nat -A POSTROUTING -p ${proto} -d ${ipdst} --dport ${rport} -j SNAT --to-source ${ipmy};
";

read -e -p "-> Proceed with forwarding [y/N]: " -i "N" dorun;
if [ ! "${dorun}" == "y" ];  then echo "-> Leaving"; exit 1; fi
echo "-> Setting up port forwarding";
sysctl -w net.ipv4.ip_forward=1;
iptables -C INPUT -p ${proto} --dport ${lport} -j ACCEPT &>/dev/null || iptables -A INPUT -p ${proto} --dport ${lport} -j ACCEPT;
iptables -C FORWARD -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT &>/dev/null || iptables -A FORWARD -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT;
iptables -C FORWARD -p ${proto} -s ${ipdst} --sport ${rport} -j ACCEPT &>/dev/null || iptables -A FORWARD -p ${proto} -s ${ipdst} --sport ${rport} -j ACCEPT;
iptables -C OUTPUT -p ${proto} --sport ${lport} -j ACCEPT &>/dev/null || iptables -A OUTPUT -p ${proto} --sport ${lport} -j ACCEPT;
iptables -C OUTPUT -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT &>/dev/null || iptables -A OUTPUT -p ${proto} --dport ${rport} -d ${ipdst} -j ACCEPT;
iptables -t nat -C PREROUTING -p ${proto} --dport ${lport} -j DNAT --to ${ipdst}:${rport} &>/dev/null || iptables -t nat -A PREROUTING -p ${proto} --dport ${lport} -j DNAT --to ${ipdst}:${rport};
iptables -t nat -C POSTROUTING -p ${proto} -d ${ipdst} --dport ${rport} -j SNAT --to-source ${ipmy} &>/dev/null || iptables -t nat -A POSTROUTING -p ${proto} -d ${ipdst} --dport ${rport} -j SNAT --to-source ${ipmy};

iptables -vnL; iptables -vnL -t nat;
echo "-> Done";
exit 0;

