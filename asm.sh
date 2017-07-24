#!/bin/bash
shared_disk_number=$1
asmuser=$2
asmgroup=$3

THISFILE=$(basename "${0}")
THISDIR=${0%$THISFILE}
BASEDIR=${0%$THISFILE}

id $asmuser 2>&1 > /dev/null
if [ $? -ne 0 ]; then
  echo "user $asmuser is required"
  echo "executing $BASEDIR/grid_oracle_user.sh"
  sh  "$BASEDIR/grid_oracle_user.sh"
fi


### creating partitions
i=1
for x in {b..z} ; do 
  blkid /dev/sd$x\*
  if [ $? -ne 0 ]; then
     if [ -b /dev/sd$x\1 ]; then
       echo "ignoring sd$x, partition found on /dev/sd$x"
     else
       echo "ok: no partition on /dev/sd$x"
       parted -s /dev/sd$x mklabel msdos
       parted -s /dev/sd$x mkpart primary 0% 100%
       /sbin/partprobe /dev/sd${x}1 2>/dev/null
     fi
  else
    echo "filesystem metadata found on sd$x, ignoring"
  fi
  i=$(($i+1))
  if [ $i -gt $shared_disk_number ] ; then
	break;
  fi
done

 
echo "options=-g" > /etc/scsi_id.config

## dynamically populating  the asmdevices udev rules
rm -f /etc/udev/rules.d/99-oracle-asmdevices.rules
i=1
cmd="/usr/lib/udev/scsi_id -g -u -d"
for dl in {b..z} ; do 
         cat <<EOF >> /etc/udev/rules.d/99-oracle-asmdevices.rules
KERNEL=="sd?1", SUBSYSTEM=="block", PROGRAM=="$cmd /dev/\$parent", \
 RESULT=="`$cmd /dev/sd${dl}`", SYMLINK+="asm-disk$i", OWNER="$asmuser", GROUP="$asmgroup", MODE="0660"
EOF
         i=$(($i+1)) 
	if [ $i -gt $shared_disk_number ] ; then
		break;
	fi
done
cat /etc/udev/rules.d/99-oracle-asmdevices.rules


i=1
for dl in {b..z} ; do 
	/sbin/udevadm test /block/sd${dl}/sd${dl}1
         i=$(($i+1)) 
		 if [ $i -gt $shared_disk_number ] ; then
			break;
		fi
done

/sbin/udevadm control --reload-rules

ls -l /dev/asm*
