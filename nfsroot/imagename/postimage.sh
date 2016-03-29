#!/bin/sh


# Rewrite fstab
echo "/dev/disk/by-partlabel/root / ext4 errors=remount-ro 0 1" > /mnt/root/etc/fstab
echo "/dev/disk/by-partlabel/home /home ext4 errors=remount-ro 0 1" >> /mnt/root/etc/fstab

# Force user to change password
chroot /mnt/root /bin/bash -c "chage -d 0 user"

# Make the filesystem fill the partition
# Busybox mount does not automatically populate mtab
mount > /etc/mtab
resize2fs /dev/disk/by-partlabel/root

# Format, mount, and copy the home directory from the primary parition
mkdir /newhome
mke2fs -F -t ext4 /dev/disk/by-partlabel/home
mount -t ext4 /dev/disk/by-partlabel/home /newhome
cp -ar /mnt/root/home/* /newhome
#rm -rf /mnt/home/*
umount /newhome

rm -f /mnt/root/etc/udev/rules.d/70-persistent-net.rules

mount -t devtmpfs none /mnt/root/dev
mount -t proc proc /mnt/root/proc
mount -t sysfs sys /mnt/root/sys

chroot /mnt/root /bin/bash -c "grub-mkdevicemap"
chroot /mnt/root /bin/bash -c "grub-install /dev/sda --force"
chroot /mnt/root /bin/bash -c "update-grub"

umount /mnt/root/dev
umount /mnt/root/sys
umount /mnt/root/proc

# Set hostname
echo "$1" > /mnt/root/etc/hostname

#Rebuild /etc/hosts
echo "127.0.0.1 localhost" > /mnt/root/etc/hosts
echo "127.0.1.1 $1" >> /mnt/root/etc/hosts
echo "" >> /mnt/root/etc/hosts
echo "::1 ip6-localhost" >> /mnt/root/etc/hosts
echo "fe00::0 ip6-localnet" >> /mnt/root/etc/hosts
echo "ff00::0 ip6-mcastprefix" >> /mnt/root/etc/hosts
echo "ff02::1 ip6-allnodes" >> /mnt/root/etc/hosts
echo "ff02::1 ip6-allrouters" >> /mnt/root/etc/hosts
