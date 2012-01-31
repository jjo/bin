#!/bin/bash
test $UID -ne 0 && echo 'Needs root' && exit 1
set -vx
echo 5 > /proc/sys/vm/laptop_mode
echo 1 > /sys/devices/system/cpu/sched_mc_power_savings
echo ondemand > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
echo 1 > /sys/module/snd_hda_intel/parameters/power_save
echo min_power > /sys/class/scsi_host/host0/link_power_management_policy
iwconfig wlan0 power on
iwconfig wlan0 power timeout 500ms
for i in /sys/bus/usb/devices/*/power/autosuspend; do echo 1 > $i; done
/etc/init.d/bluetooth stop
for i in rfcomm bnep btusb bluetooth;do modprobe -r $i;done
for i in i2400m_usb i2400m wimax;do modprobe -r $i;done

