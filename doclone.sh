#!/usr/bin/env bash

dosay() { echo "[ $(date '+%T') ] ${1}"; echo "[ $(date '+%F %T') ] ${1}" >> "${0}.log";}
doget() { local dogetres; read -r -e -p "$(dosay "${1}") " -i "${2}" dogetres; echo "${dogetres}"; }
doask() { local doaskres; doaskres=$(doget "${1}" "${2}"); if [ "${doaskres}" == "${3}" ]; then return '0'; else return '1'; fi; }
dobak() { if [ ! -f "$0.bak" ]; then touch "$0.bak"; fi; if [ "$(grep -c "${1}" "$0.bak")" == "0" ]; then echo "${1}" >> "$0.bak"; fi; }

doappscheck() {
 dosay "System check started"; local app; local askpkgsinstall;
 for app in 'echo' 'cat' 'cp' 'grep' 'cut' 'head' 'fdisk' 'sfdisk' 'sgdisk' 'date' 'dd' \
 'partclone.ntfs' 'ntfsclone' 'partimage' 'fsarchiver' 'du' 'gzip' 'blkid' 'lsblk'; do
  if [ -z "$(command -v ${app})" ]; then dosay "Warning: missing ${app}"; askpkgsinstall=true; fi; 
 done;
 if [[ "${askpkgsinstall}" == "true" ]]; then doask 'Run initial packages check [Y/N]:' 'YN' 'Y' &&  { dopkginstall; } fi;
 dosay "System check completed";
}

dopkginstall() {
[[ ! -f '/etc/debian_version' ]] && { dosay 'Sorry only debian based distributions are supported for now'; exit 1; }
if [ -n "$(command -v apt)" ]; then dosay 'Updating system'; apt update; fi;
 for pkg in 'gzip' 'coreutils' 'util-linux' 'gdisk' 'fdisk' 'grep' 'partclone' 'partimage' 'fsarchiver' 'ntfs-3g'; do
  dpkg -s "${pkg}" &>>/dev/null || { 
   dosay "Warning: ${pkg} is not installed";  
   doask "Install ${pkg} now [Y/N]:" 'YN' 'Y' && { apt install -y "${pkg}"; }
  }
 done;
}

dosysinfo() {
local mysyscmd; local sysfile="${0}.sys";
for mysyscmd in 'uname -a' 'ip addr' 'w' 'dpkg -l gzip coreutils util-linux gdisk partclone fsarchiver ntfs-3g' \
'df --si' 'lsblk' 'blkid' 'cat /proc/partitions' 'fdisk -l' 'parted -l' 'fdisk -x' 'mount' 'lspci'; do
 local ctoolexe; ctoolexe=$(echo "${mysyscmd}" | cut -d ' ' -f 1);
 if [ -n "$(command -v "${ctoolexe}")" ]; then echo "----- $mysyscmd -----" >> "${sysfile}"; ${mysyscmd} >> "${sysfile}"; fi;
done;
sync; if [ -f "${sysfile}" ]; then cat "${sysfile}" >> "${0}.log"; fi;
}

dodisktabset() {
ctapname[1]="dd"; ctapfile[1]="ddmbr";
ctapsave[1]="dd if=${diskname} of=${disktable}.${ctapfile[1]} bs=512 count=1 conv=sync,noerror";
ctaprest[1]="dd if=${disktable}.${ctapfile[1]} of=${diskname} bs=512 count=1";

ctapname[2]="dd"; ctapfile[2]="ddptb";
ctapsave[2]="dd if=${diskname} of=${disktable}.${ctapfile[2]} bs=512 count=63 conv=sync,noerror";
ctaprest[2]="dd if=${disktable}.${ctapfile[2]} of=${diskname} bs=512 count=63";

ctapname[3]="sgdisk"; ctapfile[3]="sgdisk";
ctapsave[3]="sgdisk --backup=${disktable}.${ctapfile[3]} ${diskname}";
ctaprest[3]="sgdisk --load-backup=${disktable}.${ctapfile[3]} ${diskname}";

ctaprestcount=3;
}

dodisktab() {
#if [ "${#appin}" -ge 11 ]; then diskname=${appin::-2}; else diskname=${appin::-1}; fi;
if [[ "${appin}" == *"nvme"* ]]; then diskname=${appin::-2}; else diskname=${appin::-1}; fi;

while [ "$(blkid -s PTTYPE -o value "${diskname}")" == "" ]; do
 dosay "Error: ${diskname} is not a device";
 diskname=$(doget "Input drive containing ${appin}:" "${diskname}"); 
done;

dosay "Info: ${appin} is located on ${diskname}";
diskpartype="$(blkid -s PTTYPE -o value "${diskname}")";
disktable="${diskname#/}"; disktable="${disktable//\//${fidel}}${fidel}disk${fidel}table-${diskpartype}";

dosay "Saving ${diskpartype} partition table for ${diskname}"; 
dobak "# Restoring ${diskname} generated $(date '+%F %H:%M:%S')"; 

dodisktabset;
for (( c=1; c <= ctaprestcount; c++ )); do 
if [ -f "${disktable}.${ctapfile[$c]}" ]; then continue; fi;
if [[ -z $(command -v "${ctapname[$c]}") ]]; then dosay "Error: ${ctapname[$c]} is missing!"; continue; fi;
dosay "Running: ${ctapsave[$c]}";
if ${ctapsave[c]} &> /dev/null;
 then dosay "Restore: ${ctaprest[c]}"; dobak "${ctaprest[c]}";
 else dosay "Error: ${ctapname[$c]} failed with code $?";
 fi
done

if [ ! -f "${disktable}.sfdisk" ] && [[ -n $(command -v sfdisk) ]]; then
dosay "Running: sfdisk -d ${diskname} > ${disktable}.sfdisk";
 if sfdisk -d "${diskname}" > "${disktable}.sfdisk";
 then dosay "Restore: sfdisk ${diskname} < ${disktable}.sfdisk"; dobak "sfdisk ${diskname} < ${disktable}.sfdisk";
 else dosay "Error: sfdisk failed with code $?";
 fi
fi

sync;
if [ -n "$(command -v smartctl)" ]; then 
 dosay "Checking ${diskname} device state"; smartctl -a "${diskname}" | grep -i "result\|sector\|uncorrect"; 
fi
}

dogenerate() { if [ -f "${0}.bak" ]; then dosay "Printing restore commands from bak file"; cat "${0}.bak"; fi; }

docmd() {
echo "[ $(date '+%T') ] Info: Here are generated commands anyway";
local diskpart; diskpart='part'; local partype; partype='ext4'; local fidel; fidel='-'; local fiend; fiend='.dci'; 
local appout; appout="${appin##/}${fidel}${diskpart}${fidel}${partype}${fidel}"; appout="${appout//\//${fidel}}";
dosetapps; for (( c=1; c <= cappscount; c++ )); do echo; echo "Save: ${cappsave[$c]}"; echo "Restore: ${capprest[$c]}"; done;

local diskname; if [[ "${appin}" == *"nvme"* ]]; then diskname=${appin::-2}; else diskname=${appin::-1}; fi;
local disktable; disktable="${diskname#/}"; disktable="${disktable//\//${fidel}}${fidel}disk${fidel}table-ddmbr";
dodisktabset; for (( c=1; c <= ctaprestcount; c++ )); do echo; echo "Save: ${ctapsave[$c]}"; echo "Restore: ${ctaprest[$c]}"; done;
}

dosetappsio() {
echo; fdisk -l | grep '/dev/'; # lsblk -o +LABEL,FSTYPE;
defdevice="$(blkid -o device | head -n 1)"; 
appin=$(doget "Input source partition or r for restore:" "${defdevice}");

if [ "${appin}" == "r" ]; then dogenerate; dosetappsio; fi;
if [[ "$(blkid -o device "${appin}")" == "" ]]; then dosay "Error: ${appin} is no good"; docmd; exit 1; fi;

if [[ ! "$(blkid -s PTTYPE -o value "${appin}")" == "" ]]; 
then diskpart='disk';  partype="$(blkid -s PTTYPE -o value "${appin}")";
else  diskpart='part';  partype=$(blkid -s TYPE -o value "${appin}"); [[ "${partype}" == "" ]] && { partype='none'; };
fi;

if [[ -z "${diskpart}" ]]; then dosay "Error: unknown source ${diskpart}"; exit 1; fi;
if [[ -z "${partype}" ]]; then dosay "Error: unknown source type ${partype}"; exit 1; fi;

dosay "Info: ${appin} identified as ${diskpart} with ${partype}";
if [ ! "${diskpart}" == "part" ]; then dosay "Please select partition to backup"; unset appin; dosetappsio; fi;

if [[ -z "${fidel}" ]]; then readonly fidel='-'; fi;
if [[ -z "${fiend}" ]]; then readonly fiend='.dci'; fi;
appout="${appin##/}${fidel}${diskpart}${fidel}${partype}${fidel}";
appout="${appout//\//${fidel}}";

dosetapps;
}

dosetapps() {
cappname[1]="partclone.dd";
cappfile[1]="partclonedd";
cappsave[1]="partclone.dd -L log-${appout}${cappfile[1]}${fiend} -C -s ${appin} -O ${appout}${cappfile[1]}${fiend}";
capprest[1]="partclone.dd -r -s ${appout}${cappfile[1]}${fiend} -O ${appin}";

cappname[2]="partclone";
cappfile[2]="partclone";
cappsave[2]="partclone.${partype} -L log-${appout}${cappfile[2]}${fiend} -C -c -s ${appin} -O ${appout}${cappfile[2]}${fiend}";
capprest[2]="partclone.${partype} -C -r -s ${appout}${cappfile[2]}${fiend} -O ${appin}";

cappname[3]="ntfsclone";
cappfile[3]="ntfsclone";
cappsave[3]="ntfsclone -s -O ${appout}${cappfile[3]}${fiend} ${appin}";
capprest[3]="ntfsclone -r -O ${appout}${cappfile[3]}${fiend} ${appin}";

cappname[4]="fsarchiver";
cappfile[4]="fsarchiver";
cappsave[4]="fsarchiver savefs -x -Z 1 ${appout}${cappfile[4]}${fiend} ${appin}";
capprest[4]="fsarchiver restfs ${appin} id=0,dest=${appout}${cappfile[4]}${fiend}";

cappname[5]="dd";
cappfile[5]="dd";
cappsave[5]="dd status=progress if=${appin} of=${appout}${cappfile[5]}${fiend} conv=sync,noerror";
capprest[5]="dd status=progress if=${appout}${cappfile[5]}${fiend} of=${appin} conv=sync,noerror";

cappname[6]="partimage";
cappfile[6]="partimage";
cappsave[6]="partimage -z1 -b -c -o -d save ${appin} ${appout}${cappfile[6]}${fiend}";
capprest[6]="partimage restore ${appin} ${appout}${cappfile[6]}${fiend}";

cappscount=6;
}

dorun() {
dodisktab; local runapp;
dobak "# Restoring ${appin} generated $(date '+%F %H:%M:%S')"; 

if [ -n "$(command -v blockdev)" ]; then 
   if [ "$(blockdev --getsize64 "${appin}")" -lt "1500000000" ]; then
    local runapp; doask "Run all apps for the small ${appin} [Y/N]:" 'YN' 'Y' && runapps=true;
   fi
fi

for (( c=1; c <= cappscount; c++ )); do 
  if [ "${runapps}" ]; then runapp=true; else doask "Run ${cappname[$c]} for ${appin} [Y/N]:" 'YN' 'Y' && runapp=true; fi
  
  if [ "${runapp}" ]; then
  { cappexe=$(echo "${cappsave[$c]}" | cut -d ' ' -f 1);
   if [[ -z $(command -v "${cappexe}") ]]; then dosay "Error: ${cappexe} is missing!"; continue; unset runapp; fi;
   dosay "Running: ${cappsave[$c]}"; 
    if ${cappsave[$c]};
     then dosay "Restore: ${capprest[$c]}"; dobak "${capprest[$c]}";
     else dosay "Error: ${cappname[$c]} failed with code $?";
    fi
   sync; unset runapp;
  }
  fi
done;

unset runapps; du --si ./*; dosetappsio; dorun;
}

main() { doappscheck; dosysinfo; dosetappsio; dorun; }
main "$@";

