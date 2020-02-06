#!/usr/bin/env bash

dosay() { echo "--- $(date '+%T') ---> ${1}"; }
doget() { local dogetres; read -e -p "$(dosay "${1}") " -i "${2}" dogetres; echo "${dogetres}"; }
doask() { local doaskres=$(doget "${1}" "${2}"); [ "${doaskres}" == "${3}" ] && { return '0'; } || { return '1'; } }

dodistrocheck() {
 dosay "System check started";
 [[ -f '/etc/debian_version' ]] && { distro='debian'; }
 [[ -f '/etc/redhat-release' ]] && { distro='redhat'; }
}

doappscheck() {
 dodistrocheck;
 local initapps=("echo" "cat" "cp" "grep" "cut" "head" "fdisk" "sfdisk" "sgdisk" "date" "dd" "partclone.ntfs" "ntfsclone" "fsarchiver" "gzip" "blkid" "lsblk");
 for app in ${initapps[@]}; do
  if [ -z "$(command -v ${app})" ]; then
   dosay "Warning: missing ${app}";
   askpkgsinstall=true;
  fi;
 done;
 if [[ "${askpkgsinstall}" == "true" ]]; then doask 'Run initial packages check [Y/N]:' 'YN' 'Y' &&  { dopkginstall; } fi;
 dosay "System check completed";
}

dopkginstall() {
 [[ ! "${distro}" == "debian" ]] && { dosay 'Sorry debian based distribution only'; return 1; }
 local initpkgs=("gzip" "coreutils" "util-linux" "cifs-utils" "gdisk" "partclone" "fsarchiver" "ntfs-3g" "screen");
 for pkg in ${initpkgs[@]}; do
   dpkg -s "${pkg}" &>>/dev/null || {
    dosay "Warning: ${pkg} is not installed";
    doask "Install ${pkg} now [Y/N]:" 'YN' 'Y' && { echo apt-get install "${pkg}"; }
   }
 done;
}

dosetsrcid() {
if [[ ! "$(blkid -s PTTYPE -o value ${appin})" == "" ]]; then
 diskpart='disk';
 partype="$(blkid -s PTTYPE -o value ${appin})";
else
 diskpart='part';
 partype=$(blkid -s TYPE -o value "${appin}");
 [[ "${partype}" == "" ]] && { partype='none'; };
fi;

if [[ -z "${diskpart}" ]]; then dosay "Error: unknown source ${diskpart}"; exit 1; fi;
if [[ -z "${partype}" ]]; then dosay "Error: unknown source type ${partype}"; exit 1; fi;
}

dosetfileid() {
readonly fidel='-';
readonly fiend='.dci';
appout="${appin##/}${fidel}${diskpart}${fidel}${partype}${fidel}";
appout="${appout//\//${fidel}}";
}

dosetappsio() {
lsblk -o +LABEL,FSTYPE; defdevice="$(blkid -o device | head -n 1)";
while [ -z "${appin}" ]; do appin=$(doget "Input source drive or partition:" "${defdevice}"); done;
### appin=$(doget "Input source drive or partition:" "${defdevice}");
if [[ "$(blkid -o device ${appin})" == "" ]]; then dosay "Error: ${appin} is no good"; exit 1; fi;

dosetsrcid;
dosay "Info: ${appin} identified as ${diskpart} with ${partype}";
dosetfileid;
}

dosetapps() {
dosetappsio;

cappname[1]="dd";
cappfile[1]="ddump";
cappsave[1]="dd status=progress conv=sync,noerror if=${appin} of=${appout}${cappfile[1]}${fiend}";
capprest[1]="dd status=progress conv=sync,noerror if=${appout}${cappfile[1]}${fiend} of=${appin}";

cappname[2]="ntfsclone";
cappfile[2]="ntfscr";
cappsave[2]="ntfsclone -s -O ${appout}${cappfile[2]}${fiend} ${appin}";
capprest[2]="ntfsclone -r -O ${appout}${cappfile[2]}${fiend} ${appin}";

cappname[3]="fsarchiver";
cappfile[3]="fsar";
cappsave[3]="fsarchiver savefs -x -Z 1 ${appout}${cappfile[3]}${fiend} ${appin}";
capprest[3]="fsarchiver restfs ${appin} id=0,dest=${appout}${cappfile[3]}${fiend}";

cappname[4]="partclone.dd";
cappfile[4]="pcldd";
cappsave[4]="partclone.dd -c -s ${appin} -O ${appout}${cappfile[4]}${fiend}";
capprest[4]="partclone.dd -r -s ${appout}${cappfile[4]}${fiend} -O ${appin}";

cappname[5]="partclone";
cappfile[5]="pcl";
cappsave[5]="partclone.${partype} -C -c -s ${appin} -O ${appout}${cappfile[5]}${fiend}";
capprest[5]="partclone.${partype} -C -r -s ${appout}${cappfile[5]}${fiend} -O ${appin}";

cappname[6]="ddgz";
cappfile[6]="ddgz";
cappsave[6]="dd status=progress if=${appin} bs=10M conv=sync,noerror | gzip -c > ${appout}${cappfile[6]}${fiend}";
capprest[6]="gunzip -c ${appout}${cappfile[6]}${fiend} | dd status=progress of=${appin}";

cappscount=6;
}

dorun() {
dosay "--- Running apps in ${1} mode ---";
for (( c=1; c <= ${cappscount}; c++ )); do
 case "${1}" in
  name) dosay "${cappname[$c]}: ${cappname[$c]}"; ;;
  file) dosay "${cappname[$c]}: ${cappfile[$c]}"; ;;
  saveorg) dosay "${cappname[$c]}: ${cappsave[$c]}"; ;;
  save) doask "Run ${cappname[$c]} [Y/N]:" 'YN' 'Y' && { dosay "Running: ${cappsave[$c]}"; ${cappsave[$c]}; } ;;
  rest) dosay "${cappname[$c]}: ${capprest[$c]}"; ;;
  *) dosay "Warning: invalid argument received by dorun"; exit 1; ;;
 esac
done;
}

dorunapps() {
dosetapps;

[[ "${diskpart}" == "part" ]] && dorun 'save'; dorun 'rest';
### dorun 'name'; dorun 'file'; dorun 'save'; dorun 'rest';
}

main() {
### Initial System Checks
doappscheck;

### Core Apps Run
dorunapps;
}
main "$@";

