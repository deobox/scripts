#!/usr/bin/env bash
if [ "${1}" == "init" ]; then
 iptables -N AUTOBAN;
 iptables -I INPUT 1 -p tcp -m multiport --dports 25,110,143,465,587,993,995 -m comment --comment "AutoBanned" -j AUTOBAN; 
 iptables -A AUTOBAN -j RETURN;
 exit 0;
fi;
if [ "${1}" == "clear" ]; then iptables -F AUTOBAN; iptables -A AUTOBAN -j RETURN; exit 0; fi;

wfile='/var/log/maillog';
wlines='500';
wexclude="127.0.0.1\|10.0.0";
if [ ! -f "${wfile}" ]; then exit; fi;

function validateip () { if [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then return 0; else return 1; fi }
function checkiptables () { if [ "$(iptables -vnL AUTOBAN | grep -c $1)" == "0" ]; then return 0; else return 1; fi }
function addiptables () { iptables -C AUTOBAN -s "${1}/32" -j DROP &>/dev/null || iptables -I AUTOBAN 1 -s "${1}/32" -j DROP; }
function dowork () { validateip "${1}" && return 0; checkiptables "${1}" || return 0; logger -p mail.info -t autoban "Filtering ip address ${1}"; addiptables "${1}"; }

for wips in $(tail -n "${wlines}" "${wfile}" | grep 'SASL LOGIN authentication failed:' | sed -e 's/\(^.*\[\)\(.*\)\(\].*$\)/\2/' | sort | uniq | grep -v "${wexclude}"); do dowork "${wips}"; done;
for wips in $(tail -n "${wlines}" "${wfile}" | grep '(auth failed,' | sed -e 's/\(^.*rip=\)\(.*\)\(, lip=.*$\)/\2/' | sort | uniq | grep -v "${wexclude}"); do dowork "${wips}"; done;
for wips in $(tail -n "${wlines}" "${wfile}" | grep 'no auth attempts in' | sed -e 's/\(^.*rip=\)\(.*\)\(, lip=.*$\)/\2/' | sort | uniq | grep -v "${wexclude}"); do dowork "${wips}"; done;

