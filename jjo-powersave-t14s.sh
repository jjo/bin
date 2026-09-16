#!/bin/bash
# jjo-powersave-t14s.sh  —  ThinkPad T14s Gen 6 (AMD Ryzen AI 7 PRO 360 / Radeon 880M)
# Usage: $0 on|off
#   on  -> max battery (powersave governor, EPP=power, wlan psm on, hda power_save, stop bt)
#   off -> max performance / revert everything to defaults
#
# Differences vs the X220 script (jjo-powersave-x220.sh):
#   * CPU is amd-pstate-epp, so EPP (energy_performance_preference) matter most;
#     scaling_governor is set too for older/problematic drivers.
#   * Uses `iw dev set power_save` (iwconfig is deprecated).
#   * No scsi_host/link_power_management_policy (NVMe box has 0 scsi_hosts).
#   * No i2400m/wimax modules on this laptop.
#   * Bluetooth toggled via systemctl service, never modprobe -r.
#   * AMD GPU/NPU runtime PM handled via pci power/control.
set -euo pipefail

[ "$#" -ne 1 ] && { echo "usage: $0 on|off" >&2; exit 2; }
[ "$(id -u)" -ne 0 ] && { echo "needs root" >&2; exit 1; }

MODE="$1"
case "$MODE" in
  on|off) ;;
  *) echo "usage: $0 on|off (got '$MODE')" >&2; exit 2 ;;
esac

# ---- helpers: write only if the knob exists; never let a missing path abort ----
w() { # w <value> <path...>   (only if path exists)
  local v="$1"; shift
  local p
  for p in "$@"; do
    [ -w "$p" ] && { echo "$v" > "$p" 2>/dev/null || true; } \
      || echo "warn: $p not writable, skipped" >&2
  done
}

gov_apply() { # governor + EPP for every online CPU
  local val="$1" ep="$2"
  local c
  for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    [ -w "$c/scaling_governor" ] && w "$val" "$c/scaling_governor"
    [ -w "$c/energy_performance_preference" ] && w "$ep" "$c/energy_performance_preference"
  done
}

wlan_dev() { # find the first wifi interface, robust to wlan0/wlan1/wlan2 churn
  iw dev 2>/dev/null | awk '/^[[:space:]]+Interface/{print $2; exit}'
}

# ---- mode-specific parameters ----
if [ "$MODE" = on ]; then
  GOV=powersave;   EPP=power
  LAPTOP=5;         WRITEBACK=1500;  NMI=0
  HDA_SAVE=1;       HDA_CTRL=Y
  PWR=auto          # pci/usb auto-suspend
  WLAN_PSM=on
  BT_ACT=stop
else
  GOV=performance;  EPP=performance
  LAPTOP=0;         WRITEBACK=500;   NMI=1
  HDA_SAVE=0;       HDA_CTRL=N
  PWR=on            # full performance (disable autosuspend)
  WLAN_PSM=off
  BT_ACT=start
fi

echo "== [$MODE] jjo-powersave-t14s =="
echo "  cpu governor=$GOV epp=$EPP  laptop_mode=$LAPTOP  writeback=$WRITEBACK"

# --- vm / kernel ---
sysctl -q -w vm.laptop_mode="$LAPTOP"
sysctl -q -w vm.dirty_writeback_centisecs="$WRITEBACK"
w "$NMI" /proc/sys/kernel/nmi_watchdog

# --- cpu governor + EPP ---
gov_apply "$GOV" "$EPP"

# --- audio: snd_hda_intel power save ---
w "$HDA_SAVE" /sys/module/snd_hda_intel/parameters/power_save
w "$HDA_CTRL" /sys/module/snd_hda_intel/parameters/power_save_controller

# --- wifi: explicit power save /\ off ---
WL="$(wlan_dev)"
if [ -n "$WL" ] && [ -d "/sys/class/net/$WL" ]; then
  iw dev "$WL" set power_save "$WLAN_PSM" 2>/dev/null \
    && echo "  wlan: $WL power_save $WLAN_PSM" \
    || echo "warn: could not set wlan power_save on $WL" >&2
else
  echo "warn: no wifi interface found" >&2
fi

# --- pci + usb runtime power control ---
for p in /sys/bus/{pci,usb}/devices/*/power/control; do
  w "$PWR" "$p"
done

# --- bluetooth service ---
systemctl "$BT_ACT" bluetooth 2>/dev/null && echo "  bluetooth: $BT_ACT" \
  || echo "warn: bluetooth not $BT_ACT (may be unmasked/uninstalled)" >&2

echo "== done ($MODE) =="