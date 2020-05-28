#!/bin/bash
function dohelp() { echo "-> Usage: $0 encrypt/decrypt file"; }

if [ -z "${2}" ]; then dohelp; exit;  fi
if [ -f "${2}" ]; then filein="${2}"; else dohelp; exit; fi

cypher=aes-256-cbc; # List: openssl enc -cyphers
function dogetkey() { echo -n "-> Encryption key: "; read -s mykey; if [ "${mykey}" == "" ]; then echo "-> Cancelled" && exit 0; fi }
function doencrypt() { openssl enc -e -${cypher} -in "${filein}" -out "${filein}.${cypher}" -k "${mykey}"; }
function dodecrypt() { openssl enc -d -${cypher} -in "${filein}" -out "${filein%.*}" -k "${mykey}"; }

case "$1" in
encrypt) dogetkey; doencrypt; ;;
decrypt) dogetkey; dodecrypt; ;;
*) dohelp; ;;
esac
