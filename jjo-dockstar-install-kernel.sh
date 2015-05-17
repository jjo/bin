#!/bin/bash -x
# Install kernel, initrd for dockstar u-boot, see
# http://forum.doozan.com/read.php?2,12096
set -xeu
V=${1:?missing version, eg: 4.0.0-kirkwood-tld-2}
DTS=dts/kirkwood-dockstar.dtb
ls -la zImage-$V vmlinuz-$V initrd.img-$V $DTS
cp -a zImage-$V  zImage.fdt
cat $DTS  >> zImage.fdt
mkimage -A arm -O linux -T kernel  -C none -a 0x00008000 -e 0x00008000 -n Linux-$V     -d zImage.fdt    uImage
mkimage -A arm -O linux -T ramdisk -C gzip -a 0x00000000 -e 0x00000000 -n initramfs-$V -d initrd.img-$V uInitrd
rm -f zImage.fdt
ls -la uImage uInitrd
