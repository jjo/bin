#!/bin/bash
test $UID -ne 0 && echo 'Needs root' && exit 1
set -v
sysctl -w vm.laptop_mode=5
sysctl -w vm.dirty_writeback_centisecs=1500
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo powersave > $i;done
echo '1' > /sys/module/snd_hda_intel/parameters/power_save
for i in /sys/class/scsi_host/host*/link_power_management_policy; do echo min_power > $i;done
for i in /sys/bus/{pci,usb}/devices/*/power/control;do echo auto > $i;done
echo '0' > '/proc/sys/kernel/nmi_watchdog';


iwconfig wlan0 power on
iwconfig wlan0 power timeout 500ms
#for i in /sys/bus/usb/devices/*/power/autosuspend; do echo 1 > $i; done
sudo service bluetooth stop
for i in rfcomm bnep btusb bluetooth;do modprobe -r $i;done
for i in i2400m_usb i2400m wimax;do modprobe -r $i;done
