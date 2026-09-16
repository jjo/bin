#!/bin/bash
# jjo-powersave-x220.sh  —  ThinkPad X220.
# Usage: $0 on|off
#   on  -> max battery: powersave governor, HDD link_power min_power, wlan psm on,
#          stop bluetooth + wimax i2400m, audio power_save.
#   off -> max performance: performance governor, HDD full_power, wlan psm off,
#          start bluetooth, audio power_save 0.
#
# Improved 2026-08 to match jjo-powersave-t14s.sh structure:
#   * required on|off argument (previous version was one-way).
#   * set -euo pipefail + guarded write helper (no abort, no missing-path noise).
#   * `iw dev set power_save` instead of deprecated iwconfig.
#   * Bluetooth toggled via systemctl service, not modprobe -r.
#   * Intel-specific knobs kept: scsi_host link_power_management_policy (SATA),
#     wimax/i2400m cleanup (X220-era). EPP set only if the knob exists.
set -euo pipefail

[ "$#" -ne 1 ] && { echo "usage: $0 on|off" >&2; exit 2; }
[ "$(id -u)" -ne 0 ] && { echo "needs root" >&2; exit 1; }

MODE="$1"
case "$MODE" in
  on|off) ;;
  *) echo "usage: $0 on|off (got '$MODE')" >&2; exit 2 ;;
esac

w() { # w <value> <path...>  (only if path exists+writable)
  local v="$1"; shift
  local p
  for p in "$@"; do
    if [ -w "$p" ]; then echo "$v" > "$p" 2>/dev/null || true
    else echo "  warn: $p not writable, skipped" >&2; fi
  done
}

gov_apply() { # governor (+ EPP if supported) for every CPU
  local val="$1" ep="$2"
  local c
  for c in /sys/devices/system/cpu/cpu*/cpufreq; do
    [ -w "$c/scaling_governor" ] && w "$val" "$c/scaling_governor"
    [ -w "$c/energy_performance_preference" ] && w "$ep" "$c/energy_performance_preference"
  done
}

wlan_dev() {
  iw dev 2>/dev/null | awk '/^[[:space:]]+Interface/{print $2; exit}'
}

if [ "$MODE" = on ]; then
  GOV=powersave;   EPP=power
  HDD_LPM=min_power
  AUDIO=1
  WLAN_PSM=on
  BT_ACT=stop
  WIMAX=1          # unload wimax on battery
else
  GOV=performance; EPP=performance
  HDD_LPM=max_performance
  AUDIO=0
  WLAN_PSM=off
  BT_ACT=start
  WIMAX=0          # leave wimax alone on performance
fi

echo "== [$MODE] jjo-powersave-x220 =="
echo "  cpu governor=$GOV epp=$EPP"

# --- cpu governor (+ EPP where present) ---
gov_apply "$GOV" "$EPP"

# --- HDD link power management (SATA scsi_hosts; no-op if none) ---
w "$HDD_LPM" /sys/class/scsi_host/host*/link_power_management_policy
# Explicitly re-enable pci/usb runtime PM both ways (auto on battery, on for full perf)
if [ "$MODE" = on ]; then PWR=auto; else PWR=on; fi
for p in /sys/bus/{pci,usb}/devices/*/power/control; do w "$PWR" "$p"; done

# --- audio ---
w "$AUDIO" /sys/module/snd_hda_intel/parameters/power_save

# --- wifi ---
WL="$(wlan_dev)"
if [ -n "$WL" ] && [ -d "/sys/class/net/$WL" ]; then
  iw dev "$WL" set power_save "$WLAN_PSM" 2>/dev/null \
    && echo "  wlan: $WL power_save $WLAN_PSM" \
    || echo "warn: could not set wlan power_save on $WL" >&2
else
  echo "warn: no wifi interface found" >&2
fi

# --- bluetooth (service, reversible) ---
systemctl "$BT_ACT" bluetooth 2>/dev/null && echo "  bluetooth: $BT_ACT" \
  || echo "warn: bluetooth not $BT_ACT" >&2

# --- X220-era wimax/i2400m (only unload on battery; now best-effort) ---
if [ "$WIMAX" = 1 ]; then
  for m in i2400m_usb i2400m wimax; do modprobe -r "$m" 2>/dev/null && echo "  unloaded $m"; done
fi

echo "== done ($MODE) =="