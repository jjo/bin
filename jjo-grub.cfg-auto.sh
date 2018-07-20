#!/bin/bash
# Auto-generate a grub.cfg suitable for USB Pendrive/SD
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
# vim: si sw=2 ts=2 et
shopt -s nullglob

submenu_begin() { echo "submenu \"${1:?} >\" --class ${2:?} {" ;}
submenu_end() { echo "}" ;}

## ubuntu {
submenu_begin Ubuntu ubuntu
for i in *ubuntu*.iso linuxmint*.iso;do
  case "$i" in
    *server*) initrd=initrd.gz; params="";;
    *) initrd=initrd.lz; params="noeject noprompt";;
  esac
  case "$i" in
    *18.04*) k=vmlinuz;;
    *amd64*) k=vmlinuz.efi;;
  esac
cat <<EOF
menuentry "$i" --class ubuntu {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/casper/$k boot=casper iso-scan/filename=\${isofile} ${params} --
  initrd (loop)/casper/$initrd
}
EOF
done
submenu_end
## }

## tails {
submenu_begin Tails tails
for i in tails*.iso;do
cat <<EOF
menuentry "$i" {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/live/vmlinuz boot=live findiso=\${isofile} config apparmor=1 security=apparmor nopersistence noprompt timezone=Etc/UTC block.events_dfl_poll_msecs=1000 splash noautologin module=Tails kaslr slab_nomerge slub_debug=FZP mce=0 vsyscall=none page_poison=1 union=aufs
  initrd (loop)/live/initrd.img
}
menuentry "$i failsafe" --class tails {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/live/vmlinuz boot=live findiso=\${isofile} config apparmor=1 security=apparmor nopersistence noprompt timezone=Etc/UTC block.events_dfl_poll_msecs=1000 noautologin module=Tails kaslr slab_nomerge slub_debug=FZP mce=0 vsyscall=none page_poison=1 union=aufs noapic noapm nodma nomce nolapic nomodeset nosmp 
  initrd (loop)/live/initrd.img
}
EOF
done
submenu_end
## }

## rescue {
submenu_begin Rescue rescue
for i in systemrescuecd*.iso;do
  for arch in 32 64;do
cat <<EOF
menuentry "$i $arch" --class rescue {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/isolinux/rescue$arch isoloop=\${isofile} setkmap=us
  initrd (loop)/isolinux/initram.igz
}
menuentry "$i $arch (to ram)" --class rescue {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/isolinux/rescue$arch isoloop=\${isofile} setkmap=us docache
  initrd (loop)/isolinux/initram.igz
}

EOF
  done
done

for i in grml*.iso;do
  for arch in 32 64;do
cat <<EOF
menuentry "$i $arch" --class rescue {
  set isofile="/boot/iso/$i"
  set bootid="cce315de-e4f4-460c-8564-12ed50cec3e2"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/boot/grml${arch}full/vmlinuz apm=power-off boot=live findiso=\${isofile} nomce net.ifnames=0 live-media-path=/live/grml${arch}-full bootid=\${bootid}
  initrd (loop)/boot/grml${arch}full/initrd.img
}
menuentry "$i $arch (to ram)" --class rescue {
  set isofile="/boot/iso/$i"
  set bootid="cce315de-e4f4-460c-8564-12ed50cec3e2"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/boot/grml${arch}full/vmlinuz apm=power-off boot=live findiso=\${isofile} nomce net.ifnames=0 live-media-path=/live/grml${arch}-full bootid=\${bootid} toram=grml${arch}-full.squashfs
  initrd (loop)/boot/grml${arch}full/initrd.img
}
EOF
  done
done
submenu_end
## }

## clone_part {
submenu_begin "Cloning and Part" clone_part
for i in clone*.iso;do
cat <<EOF
menuentry "$i" --class clone_part {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
#  linux (loop)/live/vmlinuz boot=live live-config noswap nolocales edd=on nomodeset ocs_live_run=\"ocs-live-general\" ocs_live_extra_param=\"\" ocs_live_keymap=\"\" ocs_live_batch=\"no\" ocs_lang=\"\" vga=788 ip=frommedia nosplash toram=filesystem.squashfs findiso=\${isofile}
  linux (loop)/live/vmlinuz boot=live findiso=\${isofile} union=overlay components quiet toram=live,syslinux
  initrd (loop)/live/initrd.img
}
EOF
done

for i in gparted*.iso;do
cat <<EOF
menuentry "$i" --class clone_part {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/live/vmlinuz boot=live union=overlay username=user config components quiet noswap ip= net.ifnames=0 nosplash findiso=\${isofile}
  initrd (loop)/live/initrd.img
}
menuentry "$i (to ram)" {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile} ..."
  loopback loop \${isofile}
  linux (loop)/live/vmlinuz boot=live union=overlay username=user config components quiet noswap toram=filesystem.squashfs ip= net.ifnames=0 nosplash findiso=\${isofile}
  initrd (loop)/live/initrd.img
}
EOF
done
submenu_end
## }

## netboot {
submenu_begin "Netboot" netboot
test -f ipxe.iso && cat <<EOF
menuentry "iPXE" --class netboot {
  set isofile="/boot/iso/ipxe.iso"
  echo "Using \${isofile}..."
  loopback loop \${isofile}
  linux16 (loop)/IPXE.KRN
}
EOF

test -f netboot.xyz.iso && cat <<EOF
menuentry "netboot.xyz multi-OS net installer" --class netboot {
  set isofile="/boot/iso/netboot.xyz.iso"
  echo "Using \${isofile}..."
  loopback loop \${isofile}
  linux16 (loop)/IPXE.KRN
}
EOF

test -f netbootme.iso && cat <<EOF
menuentry "netbootme.iso" --class netboot {
  set isofile="/boot/iso/netbootme.iso"
  echo "Using \${isofile}..."
  loopback loop \${isofile}
  linux16 (loop)/GPXE.KRN
}
EOF
submenu_end
## }

## bootmgr {
submenu_begin "Other Boot managers" bootmgr
# cp /usr/lib/syslinux/memdisk memdisk.bzImage
for i in sgdh*.iso super_grub2_disk*.iso; do
cat <<EOF
menuentry "Super Grub2 Disk $i" --class bootmgr {
  set isofile="/boot/iso/$i"
  echo "Using \${isofile}..."
  insmod part_gpt
  insmod memdisk
  search --set -f \${isofile}
  linux16 /boot/iso/memdisk.bzImage iso bigraw
  initrd16 \${isofile}
}
EOF
done
# Meh I have USB sticks with diff layout for grub.exe
test -f ../grub.exe -a -f ../grub/menu.lst && cat <<EOF
menuentry "Grub4Dos" --class bootmgr {
	linux /boot/grub.exe --config-file=/boot/grub/menu.lst}
EOF
test -f ../../grub.exe && cat <<EOF
menuentry "Grub4DOS(grub.exe): Hiren BootCD" {
  search -f --set=root /grub.exe
  linux /grub.exe
}
EOF

test -f ../img/plpbt && cat <<EOF
menuentry "PLoP Boot Manager" --class bootmgr {
	linux16 /boot/img/plpbt
}
EOF

test -f ../img/sbootmgr.dsk && cat <<EOF
menuentry "Smart Boot Manager" --class bootmgr {
  search --set -f /boot/img/sbootmgr.dsk
	linux16 /boot/syslinux/memdisk
	initrd16 /boot/img/sbootmgr.dsk
}
EOF

test -f ../syslinux/ldlinux.sys && cat << EOF
menuentry "Syslinux" --class bootmgr {
  search --set=root -f "/boot/syslinux/ldlinux.sys"
  drivemap -s (hd0) \${root}
  chainloader +1
}
EOF
submenu_end
## }

## tools {
submenu_begin "Misc tools" tools
test -f memtest.bin && cat <<EOF
menuentry "memtest.bin" --class tools {
  linux16 /boot/iso/memtest.bin
}
EOF

cat <<EOF
menuentry "vbeinfo" --class tools {
	vbeinfo
  read
}
menuentry "lspci" --class tools {
	lspci
  read
}
menuentry "gfxpayload 640x480" --class tools {
  set gfxpayload=640x480
  echo gfxpayload=\${gfxpayload} press enter
  read
}
menuentry "gfxpayload 800x600" --class tools {
  set gfxpayload=800x600
  echo gfxpayload=\${gfxpayload} press enter
  read
}
menuentry "gfxpayload 1024x768" --class tools {
  set gfxpayload=1024x768
  echo gfxpayload=\${gfxpayload} press enter
  read
}
menuentry "gfxpayload 1280x1024" --class tools {
  set gfxpayload=1280x1024
  echo gfxpayload=\${gfxpayload} press enter
  read
}
menuentry "Reboot" --class tools {
  insmod reboot
  reboot
}
EOF
submenu_end
## }

# Local addition
test -f grub.cfg.add && cat grub.cfg.add
# vim: et si sw=2 ts=2
