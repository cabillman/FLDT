#!/bin/sh
/sbin/parted -s /dev/sda mklabel gpt
/sbin/parted -s /dev/sda mkpart primary ext2 513MiB 50%
/sbin/parted -s /dev/sda mkpart primary ext2 50% 100%
/sbin/parted -s /dev/sda name 1 root
/sbin/parted -s /dev/sda name 2 home
/sbin/parted -s /dev/sda set 1 boot on
