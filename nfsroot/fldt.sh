#!/bin/sh

echo "Starting FLDT from NFS!"

set -- $(cat /proc/cmdline)
for x in "$@"; do
	case "$x" in
	FLDT_NFS=*)
	IMAGING_SERVER="${x#FLDT_NFS=}"
	;;
	FLDT_MODE=*)
	IMAGING_MODE="${x#FLDT_MODE=}"
	;;
	FLDT_PORT=*)
	IMAGING_PORT="${x#FLDT_PORT=}"
	;;
	esac
done

ETHERNET_MAC=`cat /sys/class/net/en*/address`
WIFI_MAC=`cat /sys/class/net/wl*/address`
SERIAL=`cat /sys/class/dmi/id/chassis_serial`
HOSTNAME=`wget -O - http://$IMAGING_SERVER:$IMAGING_PORT/api/hostname?mac=$ETHERNET_MAC 2> /dev/null`
IMAGE_NAME=`wget -O - http://$IMAGING_SERVER:$IMAGING_PORT/api/currentImage 2> /dev/null`
ETHERNET_DEV=`echo /sys/class/net/en* | xargs basename`

echo "Ethernet: $ETHERNET_MAC"
echo "Wifi: $WIFI_MAC"
echo "Serial: $SERIAL"
echo "Hostname: $HOSTNAME"
echo "Image: $IMAGE_NAME"
echo "Ethernet Device: $ETHERNET_DEV"
echo "Imaging Port: $IMAGING_PORT"


for f in `find /nfs/checks/* -type f | sort -nr`
do
	. $f
done

if [ $IMAGING_MODE == "multicast" ]; then
	echo "Multicasting!"
	route add -net 224.0.0.0 netmask 240.0.0.0 dev $ETHERNET_DEV
fi

#parted -s < /nfs/$IMAGE_NAME/partitions.txt
/nfs/$IMAGE_NAME/partitions.sh
parted -l

hdparm -z /dev/sda
mdev -s

sleep 5

for f in `find /nfs/$IMAGE_NAME/disks/* -type f | sort -nr`
do
	echo "Restoring $f"
	LABEL=`basename $f`

	if [ -e "/dev/$LABEL" ]; then
		DISK="/dev/$LABEL"
	elif [ -e "/dev/disk/by-partlabel/$LABEL" ]; then
		DISK="/dev/disk/by-partlabel/$LABEL"
	fi
	
	echo "Imaging disk: $DISK"	


	if [ $IMAGING_MODE == "multicast" ]; then
		udp-receiver --mcast-rdv-address 224.0.0.1 | partclone.extfs -r -s - -o $DISK -L /partclone.log
	else
		partclone.extfs -r -s $f -o $DISK -L /partclone.log
	fi

	if [ ! -d "/mnt/$LABEL" ]; then
		mkdir /mnt/$LABEL
	fi
	
	mount -t ext4 $DISK /mnt/$LABEL

done

/nfs/$IMAGE_NAME/postimage.sh $HOSTNAME


for f in `find /nfs/$IMAGE_NAME/disks/* -type f | sort -nr`
do
	LABEL=`basename $f`
	umount /mnt/$LABEL
done

echo "Finished Imaging. Reboot"

