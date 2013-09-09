#!/bin/sh
mkdir mnt
mount -t nfs4 10.0.0.1:/images mnt

HOSTNAME_SERVER="10.0.0.1"

MACADDR=`ifconfig | grep "eth0" | tr -s ' ' | cut -d ' ' -f5`
wget -O hostname http://$HOSTNAME_SERVER/getHostname.php?mac=$MACADDR 2> /dev/null
HOSTNAME="`cat hostname`"

echo "I am $HOSTNAME with MAC address $MACADDR"

echo "Imaging sda1"
partclone.extfs -r -s /mnt/sda1.v2.ubuntu.img -o /dev/sda1 -L /partclone.log

# Setup mnt enviorment for chroots
mount /dev/sda1 mnt

chroot /mnt sh -c "chage -d 0 user"

# Set hostname
echo "$HOSTNAME" > /mnt/etc/hostname

#Rebuild /etc/hosts
echo "127.0.0.1 localhost" > /mnt/etc/hosts
echo "127.0.1.1 $HOSTNAME" >> /mnt/etc/hosts
echo "" >> /mnt/etc/hosts
echo "::1 ip6-localhost" >> /mnt/etc/hosts
echo "fe00::0 ip6-localnet" >> /mnt/etc/hosts
echo "ff00::0 ip6-mcastprefix" >> /mnt/etc/hosts
echo "ff02::1 ip6-allnodes" >> /mnt/etc/hosts
echo "ff02::1 ip6-allrouters" >> /mnt/etc/hosts

# Disable network control panel (proxy settings)
rm -f /mnt/usr/lib/control-center-1/panels/libnetwork.so
rm -f /mnt/usr/share/applications/gnome-network-panel.desktop

# Reset network rules
rm -f /mnt/etc/udev/rules.d/70-persistent-net.rules

umount /mnt

echo "Done imaging"
