#!/usr/bin/env bash

wfile='/var/log/secure';
wlog='/var/log/sshguard.csv';
wskip="0.0.0.0\|127.0.0.1\|10.1.1\|172.16.16.172";

if [ "${1}" == "init" ]; then
 iptables -N AUTOBAN;
 iptables -I INPUT 1 -p tcp --dport 22 -m comment --comment "AutoBanned" -j AUTOBAN;
 iptables -A AUTOBAN -j RETURN;
 exit 0;
fi;
if [ "${1}" == "clear" ]; then iptables -F AUTOBAN; iptables -A AUTOBAN -j RETURN; exit 0; fi;
if [ "${1}" == "list" ]; then iptables -vnL AUTOBAN --line-numbers; exit 0; fi;
if [ "${1}" == "add" ] && [ -n "${2}" ]; then echo "$(date '+%b %d %T') Manual Ban: ${2}" >> "${wfile}"; fi;
if [ "${1}" == "reload" ]; then
 for ips in $(cut -d ',' -f 3 "${wlog}" | sort -u);
 do echo "$(date '+%b %d %T') Reload Ban: $ips" >> "${wfile}"; done;
fi

if [ ! -f "${wfile}" ]; then exit; fi
if [ ! -s "${wfile}" ]; then exit; fi

function ipvalid() { if [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then return 0; else return 1; fi }
function ipcheck() { if [ "$(iptables -vnL AUTOBAN | grep -c "$1")" == "0" ]; then return 0; else return 1; fi }
function ipadd() { iptables -C AUTOBAN -s "${1}/32" -j DROP &>/dev/null || iptables -I AUTOBAN -s "${1}/32" -j DROP; }
function doadd() { ipvalid "${1}" && return 0; ipcheck "${1}" || return 0; echo "$(date '+%F,%T'),${1}" >> "${wlog}"; ipadd "${1}"; }

for wips in $(grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' "${wfile}" | sort -u | grep -v "${wskip}");
do doadd "${wips}"; done;

grep -v 'pam_unix(systemd-user:session): session opened for user root(uid=0)' "${wfile}" >> "${wlog%%.*}.log";
true > "${wfile}";

