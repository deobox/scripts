#!/bin/bash

xenvm="$1"; xenserv="$(hostname)"; if [ -z "${xenserv}" ]; then xenserv='xenserver'; fi

mntdir='/media/backup';
mntdst='//10.1.1.10/backup';
mntopts='user=smbuser,pass=smbpass';

smtpserv='10.1.1.10:25';
smtpfrom="${xenserv}@yourdomain.com";
smtpto='youraccount@yourdomain.com';

function mailme() { echo -e "${mailtext}" | mailx -S "smtp=${smtpserv}" -r "${smtpfrom}" -s "${xenserv} ${xenvm} backup" "${smtpto}"; }
if [ -z "$1" ]; then mailtext="${mailtext}\n$(date +%T): Error : VM name not provided"; mailme; exit 1; fi
if [ -z "$xenvm" ]; then mailtext="${mailtext}\n$(date +%T): Error : VM name not provided"; mailme; exit 1; fi

mailtext="${mailtext}\n$(date +%T): Backing up ${xenvm} on ${xenserv}";

if [ ! -d "${mntdir}" ]; then
 if ! mkdir -p "${mntdir}" &> /dev/null; then mailtext="${mailtext}\n$(date +%T): Error : Unable to create ${mntdir}"; mailme; exit 1; fi
fi

mailtext="${mailtext}\n$(date +%T): Mounting ${mntdir}";
if [ ! "$(mount | grep -c ${mntdir})" == 0 ]; then mailtext="${mailtext}\n$(date +%T): Warning : ${mntdir} is already mounted"; else
 if ! mount.cifs "${mntdst}" "${mntdir}" -o "${mntopts}"; then mailtext="${mailtext}\n$(date +%T): Error : Unable to mount ${mntdir}"; mailme; exit 1; fi
fi
if [ ! "$(mount | grep -c ${mntdir})" ==  1 ]; then mailtext="${mailtext}\n$(date +%T): Error : Unable to mount ${mntdir}"; mailme; exit 1; fi
if [ "$(stat -c '%D' ${mntdir})" == "fd00" ]; then mailtext="${mailtext}\n$(date +%T): Error : Unable to mount ${mntdir}"; mailme; exit 1; fi

tmpfile="${mntdir}/${xenserv}-$(date '+%F-%H%I%S-%N').tmp"; sync;
if ! echo "test" > "${tmpfile}"; then mailtext="${mailtext}\n$(date +%T): Error : ${mntdir} is read only"; umount ${mntdir}; mailme; exit 1; fi
if [ ! -f "${tmpfile}" ]; then mailtext="${mailtext}\n$(date +%T): Error : ${mntdir} is read only"; umount ${mntdir}; mailme; exit 1; fi
sync; rm -f "${tmpfile}" &>/dev/null; sync;
if [ -f "${tmpfile}" ]; then mailtext="${mailtext}\n$(date +%T): Warning : Unable to delete temp file ${tmpfile}"; fi

if [ ! -d "${mntdir}/${xenserv}" ]; then sync;
 if ! mkdir -p "${mntdir}/${xenserv}" &> /dev/null; then mailtext="${mailtext}\n$(date +%T): Error : Unable to create ${mntdir}/${xenserv}"; mailme; exit 1; fi
 if [ ! -d "${mntdir}/${xenserv}" ]; then mailtext="${mailtext}\n$(date +%T): Error : Unable to create ${mntdir}/${xenserv}"; mailme; exit 1; fi
fi

if [ ! "$(xe vm-list | grep -A 1 ": ${xenvm}$" | grep -c 'running')" == "0" ]; then
 mailtext="${mailtext}\n$(date +%T): Shutting down ${xenvm}";
 if ! xe vm-shutdown name-label="${xenvm}"; then mailtext="${mailtext}\n$(date +%T): Error : Could not shut down ${xenvm}"; mailme; exit 1; else startvm=yes; fi
fi

if [ -f "${mntdir}/${xenserv}/${xenvm}.xva" ]; then
 mailtext="${mailtext}\n$(date +%T): Moving ${mntdir}/${xenserv}/${xenvm}.xva to ${mntdir}/${xenserv}/${xenvm}.xva.old"
 mv -f "${mntdir}/${xenserv}/${xenvm}.xva" "${mntdir}/${xenserv}/${xenvm}.xva.old"; sync;
fi
if [ -f "${mntdir}/${xenserv}/${xenvm}.xva" ]; then
 mailtext="${mailtext}\n$(date +%T): Error : Unale to move ${mntdir}/${xenserv}/${xenvm}.xva to ${mntdir}/${xenserv}/${xenvm}.xva.old"; mailme; exit 1;
fi

mailtext="${mailtext}\n$(date +%T): Exporting ${xenvm} to ${mntdir}/${xenserv}/${xenvm}.xva";
if ! xenexp=$(xe vm-export filename="${mntdir}/${xenserv}/${xenvm}.xva" name-label="${xenvm}");
 then mailtext="${mailtext}\n$(date +%T): Error : Exporting ${xenvm} failed";
fi
if [ ! -f "${mntdir}/${xenserv}/${xenvm}.xva" ]; then mailtext="${mailtext}\n$(date +%T): Error : Unale to create ${mntdir}/${xenserv}/${xenvm}.xva"; fi
mailtext="${mailtext}\n$(date +%T): Export completed\n$(date +%T): Export Result: ${xenexp}";

if [[ "$startvm" == "yes" ]]; then
 mailtext="${mailtext}\n$(date +%T): Starting ${xenvm}";
 if ! xe vm-start name-label="${xenvm}"; then mailtext="${mailtext}\n$(date +%T): Warning : Unable to start ${xenvm}"; fi
fi

mailtext="${mailtext}\n$(date +%T): Unmounting ${mntdir}";
if ! umount "${mntdir}"; then mailtext="${mailtext}\n$(date +%T): Error : Unable to umount ${mntdir}"; fi
if [ ! "$(mount | grep -c ${mntdir})" == 0 ]; then mailtext="${mailtext}\n$(date +%T): Error : Unable to umount ${mntdir}"; fi

mailtext="${mailtext}\n$(date +%T): Back up completed for ${xenvm} on ${xenserv}"
mailme; exit 0;

