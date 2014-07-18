#!/bin/bash
# Auto-generate a grub.cfg suitable for USB Pendrive/SD
# asumes files at /boot/iso.
#
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
# vim: si sw=2 ts=2 et
shopt -s nullglob

for i in ubuntu*.iso linuxmint*;do
  case "$i" in *amd64*) k=vmlinuz.efi;; *) k=vmlinuz;; esac
cat <<EOF
menuentry "$i" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/casper/$k boot=casper iso-scan/filename=\$isofile noeject noprompt --
  initrd (loop)/casper/initrd.lz
}
EOF
done

for i in tails*.iso;do
  for j in "" 2;do
cat <<EOF
menuentry "$i $j" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz$j isoloop=\$isofile boot=live config live-media=removable nopersistent noprompt timezone=Etc/UTC block.events_dfl_poll_msecs=1000 splash noautologin module=Tails quiet
  initrd (loop)/live/initrd$j.img
}
menuentry "$i $j failsafe" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz$j isoloop=\$isofile boot=live config live-media=removable nopersistent noprompt timezone=Etc/UTC block.events_dfl_poll_msecs=1000 splash noautologin module=Tails noapic noapm nodma nomce nolapic nomodeset nosmp vga=normal
  initrd (loop)/live/initrd$j.img
}
EOF
  done
done

for i in systemrescuecd*.iso;do
  for arch in 32 64;do
cat <<EOF
menuentry "$i $arch" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/isolinux/rescue$arch isoloop=\$isofile setkmap=us docache dostartx
  initrd (loop)/isolinux/initram.igz
}
EOF
  done
done

for i in grml*.iso;do
  for arch in 32 64;do
cat <<EOF
menuentry "$i $arch" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/boot/grml${arch}full/vmlinuz findiso=\$isofile apm=power-off lang=us vga=791 boot=live nomce noeject noprompt --
  initrd (loop)/boot/grml${arch}full/initrd.img
}
EOF
  done
done

for i in clone*.iso;do
cat <<EOF
menuentry "$i" {
  set isofile="/boot/iso/$i"
  loopback loop \$isofile
  linux (loop)/live/vmlinuz boot=live live-config noswap nolocales edd=on nomodeset ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"\" ocs_live_keymap=\"\" ocs_live_batch=\"no\" ocs_lang=\"\" vga=788 ip=frommedia nosplash toram=filesystem.squashfs findiso=\$isofile
  initrd (loop)/live/initrd.img
}
EOF
done

cat <<EOF
menuentry "netbootme.iso" {
  loopback loop /boot/iso/netbootme.iso
  linux16 (loop)/GPXE.KRN
}

menuentry "memtest.bin" {
  linux16 /boot/img/memtest.bin
}

menuentry "Grub4DOS(grub.exe): Hiren BootCD" {
        search -f --set=root /grub.exe
  linux /grub.exe
}
EOF
