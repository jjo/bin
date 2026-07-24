#!/usr/bin/env bash
# jjo's workaround 2026-07-24:
# jjo-gnome-wayland-redshift.sh — GNOME Wayland night light.
#
#
# GNOME Wayland's night light API is severely limited:
#   - NightLightPreview: max 120s, cannot be cancelled
#   - Schedule-based activation: non-functional on Pop!_OS 22.04 / GNOME 42
#   - No persistent on-demand API exists
#
# The loop command keeps the screen warm within the schedule window by
# re-firing NightLightPreview before the 120s cap expires.  Outside the
# schedule window the loop sleeps and lets the screen return to normal.
# When running via systemd (serve), it also re-calculates sunrise/sunset
# from GeoIP every ~4 hours so the schedule follows the seasons.
#
# Commands:
#   loop [from] [to] [temp]  — start schedule-aware preview loop
#   geoip [temp]             — auto-set schedule from GeoIP + solar calc
#   now [temp]               — one-shot 120s preview
#   off                      — stop loop, disable, reset to 6500K
#   status                   — show current state
#   install                  — install as systemd --user service
#   uninstall                — remove systemd service, disable
#
# Why not alternatives:
#   redshift: X11 only, no Wayland.
#   gammastep -m wayland: needs wlr-gamma-control, GNOME lacks it.
#   gammastep -m randr: only affects XWayland clients, not native GL.

set -euo pipefail
RUNDIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
PIDFILE="$RUNDIR/gnome-wayland-redshift-loop.pid"

usage() {
    echo "Usage: $(basename "$0") <loop|geoip|now|off|status|install|uninstall> [args]"
    echo ""
    echo "  loop [from] [to] [temp]  — start schedule-aware preview loop"
    echo "  geoip [temp]             — auto-set schedule from GeoIP + solar calc"
    echo "  now [temp]               — one-shot 120s preview"
    echo "  off                      — stop loop, disable, reset"
    echo "  status                   — show settings + loop state"
    echo "  install                  — install as systemd --user service (auto-geoip)"
    echo "  uninstall                — remove systemd service, disable"
    echo ""
    echo "Examples:"
    echo "  $(basename "$0") loop 19 6 3500"
    echo "  $(basename "$0") geoip 3500"
    echo "  $(basename "$0") install"
    echo "  $(basename "$0") off"
    echo "  $(basename "$0") status"
}

require_dbus() {
    if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]; then
        uid=$(id -u)
        export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/${uid}/bus"
        export DISPLAY="${DISPLAY:-:0}"
    fi
}

col_set() { gsettings set org.gnome.settings-daemon.plugins.color "$1" "$2"; }
col_get() { gsettings get org.gnome.settings-daemon.plugins.color "$1"; }

# ── time helpers ─────────────────────────────────────────────────

current_hour() {
    # Return current time as a decimal fraction of the day
    # e.g. 19:56 → 19 + 56/60 = 19.933
    date +"%-H.%-M" | awk '{split($1,a,"."); print a[1] + a[2]/60}'
}

# Returns 0 (ok) if current time is within the schedule window, 1 otherwise.
# Handles overnight schedules (from > to, e.g. 19→6).
in_schedule() {
    local from to now
    from=$(col_get night-light-schedule-from)
    to=$(col_get night-light-schedule-to)
    now=$(current_hour)

    if [ "$(echo "$from < $to" | bc -l)" -eq 1 ]; then
        # same-day: from <= now < to
        [ "$(echo "$now >= $from" | bc -l)" -eq 1 ] && \
        [ "$(echo "$now < $to" | bc -l)" -eq 1 ]
    else
        # overnight: now >= from OR now < to
        [ "$(echo "$now >= $from" | bc -l)" -eq 1 ] || \
        [ "$(echo "$now < $to" | bc -l)" -eq 1 ]
    fi
}

# ── GeoIP / solar calculation ────────────────────────────────────

# Fetches location from ipinfo.io, computes sunrise/sunset, updates gsettings.
# Usage: update_geoip [temp]
# Returns 0 on success, 1 on transient failure (network, parse).
update_geoip() {
    local temp="${1:-3500}"
    local_data=$(curl -s --max-time 5 https://ipinfo.io/json 2>/dev/null || echo "")
    loc=$(echo "$local_data" | python3 -c "
import sys, json
d = json.load(sys.stdin)
lat_s, lon_s = d['loc'].split(',')
tz = d['timezone']
print(f'{lat_s} {lon_s} {tz}')
" 2>/dev/null || echo "")
    [ -z "$loc" ] && return 1
    read -r lat lon tz <<< "$loc"
    schedule=$(python3 -c "
import math, datetime, pytz
lat, lon = $lat, $lon
now = datetime.datetime.now(pytz.timezone('$tz'))
offset = now.utcoffset().total_seconds() / 3600
today = now.date()
n = today.timetuple().tm_yday
decl = math.radians(23.44 * math.sin(math.radians(360/365 * (n - 81))))
cos_ha = -math.tan(math.radians(lat)) * math.tan(decl)
cos_ha = max(-1, min(1, cos_ha))
ha = math.degrees(math.acos(cos_ha))
utc_sunrise = 12 - ha/15 - lon/15
utc_sunset  = 12 + ha/15 - lon/15
local_sunrise = (utc_sunrise + offset) % 24
local_sunset  = (utc_sunset + offset) % 24
print(f'{local_sunset:.1f} {local_sunrise:.1f}')
" 2>/dev/null) || return 1
    read -r schedule_to schedule_from <<< "$schedule"
    col_set night-light-schedule-from "$(printf '%.1f' "$schedule_to")"
    col_set night-light-schedule-to "$(printf '%.1f' "$schedule_from")"
    col_set night-light-temperature "uint32 $temp"
    col_set night-light-enabled true
    return 0
}

# ── loop management ──────────────────────────────────────────────

loop_pid() {
    if [ -f "$PIDFILE" ]; then
        cat "$PIDFILE" 2>/dev/null || echo ""
    fi
}

loop_running() {
    local pid
    pid=$(loop_pid)
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

loop_stop() {
    local pid
    pid=$(loop_pid)
    if [ -n "$pid" ]; then
        kill "$pid" 2>/dev/null || true
        for _ in 1 2 3 4 5; do
            kill -0 "$pid" 2>/dev/null || break
            sleep 0.2
        done
    fi
    rm -f "$PIDFILE"
}

preview_120() {
    gdbus call --session \
        --dest org.gnome.SettingsDaemon.Color \
        --object-path /org/gnome/SettingsDaemon/Color \
        --method org.gnome.SettingsDaemon.Color.NightLightPreview 120 \
        >/dev/null 2>&1 || true
}

# ── commands ─────────────────────────────────────────────────────

cmd="${1:-}"
shift 2>/dev/null || true

case "${cmd}" in
    loop)
        require_dbus

        if [ "${1:-}" != "" ] && [ "${2:-}" != "" ]; then
            col_set night-light-schedule-from "$1"
            col_set night-light-schedule-to "$2"
            shift 2 || true
        fi
        if [ "${1:-}" != "" ]; then
            col_set night-light-temperature "uint32 $1"
            shift || true
        fi

        temp=$(col_get night-light-temperature | awk '{print $2}')
        start=$(col_get night-light-schedule-from)
        end=$(col_get night-light-schedule-to)
        col_set night-light-enabled true

        if loop_running; then
            echo "Loop already running (PID $(loop_pid))"
            echo "Run 'off' to stop."
            exit 0
        fi

        (
            export DBUS_SESSION_BUS_ADDRESS="$DBUS_SESSION_BUS_ADDRESS"
            export DISPLAY="${DISPLAY:-:0}"
            preview_120
            while true; do
                sleep 60
                if in_schedule; then
                    preview_120
                fi
            done
        ) &
        echo $! > "$PIDFILE"
        echo "Night light LOOP  (temp=${temp}K  schedule ${start}→${end}  PID $(cat "$PIDFILE"))"
        echo "  Active only during schedule window. Runs until 'off' or reboot."
        ;;

    geoip)
        require_dbus
        temp="${1:-3500}"
        case "$temp" in
            ''|*[!0-9]*) echo "Usage: $(basename "$0") geoip [temp]" >&2; exit 1 ;;
        esac
        if ! update_geoip "$temp"; then
            echo "GeoIP failed. Is network up?" >&2
            exit 1
        fi
        start=$(col_get night-light-schedule-from | python3 -c "print(f'{float(input()):.1f}')" 2>/dev/null || col_get night-light-schedule-from)
        end=$(col_get night-light-schedule-to | python3 -c "print(f'{float(input()):.1f}')" 2>/dev/null || col_get night-light-schedule-to)
        temp=$(col_get night-light-temperature | awk '{print $2}')
        echo "Location: auto-detected  Schedule: ${start}→${end}  (sunset→sunrise)  temp=${temp}K"
        preview_120
        ;;

    now)
        require_dbus
        temp="${1:-3500}"
        col_set night-light-temperature "uint32 $temp"
        col_set night-light-enabled true
        preview_120
        echo "Night light NOW  (temp=${temp}K  preview 120s)"
        ;;

    off)
        require_dbus
        loop_stop
        col_set night-light-enabled false
        col_set night-light-temperature "uint32 6500"
        echo "Night light OFF (loop stopped, temp reset to 6500K)"
        ;;

    status)
        require_dbus
        enabled=$(col_get night-light-enabled)
        gs_temp=$(col_get night-light-temperature | awk '{print $2}')
        start=$(col_get night-light-schedule-from)
        end=$(col_get night-light-schedule-to)
        now=$(current_hour)
        dbus_temp=$(gdbus call --session \
            --dest org.gnome.SettingsDaemon.Color \
            --object-path /org/gnome/SettingsDaemon/Color \
            --method org.freedesktop.DBus.Properties.Get \
            org.gnome.SettingsDaemon.Color Temperature 2>/dev/null | grep -oE '[0-9]+' | tail -1)
        if in_schedule; then
            sched_status="in window"
        else
            sched_status="outside"
        fi
        if loop_running; then
            loop_status="running (PID $(loop_pid))"
        elif systemctl --user -q is-active gnome-wayland-redshift.service 2>/dev/null; then
            loop_status="systemd service"
        else
            loop_status="stopped"
        fi
        start_fmt=$(printf '%.1f' "$start")
        end_fmt=$(printf '%.1f' "$end")
        now_display=$(date +%H:%M)
        echo "Enabled=${enabled}  GSettings=${gs_temp}K  Actual=${dbus_temp}K  Now=${now_display}  Schedule=${start_fmt}→${end_fmt}  (${sched_status})  Loop=${loop_status}"
        ;;

    serve)
        # Foreground loop for systemd --user service.
        # Uses Mutter SetCrtcGamma on ALL active CRTCs (not just primary).
        # Re-calculates sunrise/sunset via GeoIP every ~4 hours.
        require_dbus

        # ── temperature→RGB multipliers ──────────────────────
        # (inlined in apply_gamma Python code)
        # ── apply gamma to all active CRTCs ──────────────────
        apply_gamma() {
            local temp_k="$1"
            local saved="$orig_gamma"
            [ -z "$saved" ] && return 1
            python3 -c "
import subprocess, re, sys, json

def gdbus(method, *args):
    r = subprocess.run(['gdbus', 'call', '--session',
        '--dest', 'org.gnome.Mutter.DisplayConfig',
        '--object-path', '/org/gnome/Mutter/DisplayConfig',
        '--method', method] + list(args), capture_output=True, text=True, timeout=10)
    if r.returncode != 0:
        raise RuntimeError(f'gdbus failed: {r.stderr}')
    return r.stdout

# temp→RGB multipliers
t = $temp_k
pts = [(1000,1,0.19,0.01),(2000,1,0.45,0.15),(2700,1,0.6,0.3),
       (3000,1,0.66,0.36),(3500,1,0.73,0.48),(4000,1,0.8,0.6),
       (5000,1,0.9,0.8),(6500,1,1,1),(10000,0.95,0.97,1.08),
       (25000,0.9,0.94,1.12)]
c = max(1000, min(25000, t))
r_mul = g_mul = b_mul = 1.0
for i in range(len(pts)-1):
    t1,r1,g1,b1 = pts[i]; t2,r2,g2,b2 = pts[i+1]
    if t1 <= c <= t2:
        f = (c-t1)/(t2-t1)
        r_mul = r1+f*(r2-r1)
        g_mul = g1+f*(g2-g1)
        b_mul = b1+f*(b2-b1)
        break

# Use saved original gamma
orig = json.loads('''$saved''')
raw = gdbus('org.gnome.Mutter.DisplayConfig.GetResources')
serial = int(re.search(r'\(uint32 (\d+)', raw).group(1))

for cid_str, (r_orig, g_orig, b_orig) in orig.items():
    cid = int(cid_str)
    r_new = [min(65535, round(v * r_mul)) for v in r_orig]
    g_new = [min(65535, round(v * g_mul)) for v in g_orig]
    b_new = [min(65535, round(v * b_mul)) for v in b_orig]
    arr = lambda lst: '[' + ','.join(str(v) for v in lst) + ']'
    gdbus('org.gnome.Mutter.DisplayConfig.SetCrtcGamma',
          f'uint32 {serial}', f'uint32 {cid}',
          arr(r_new), arr(g_new), arr(b_new))
    print(f'CRTC {cid}: {r_mul:.3f} {g_mul:.3f} {b_mul:.3f}', flush=True)
" 2>&1 || return 1
        }

        # ── restore gamma to identity ───────────────────────
        restore_gamma() {
            local saved="$orig_gamma"
            [ -z "$saved" ] && return 1
            python3 -c "
import subprocess, re, json

def gdbus(method, *args):
    r = subprocess.run(['gdbus', 'call', '--session',
        '--dest', 'org.gnome.Mutter.DisplayConfig',
        '--object-path', '/org/gnome/Mutter/DisplayConfig',
        '--method', method] + list(args), capture_output=True, text=True, timeout=10)
    if r.returncode != 0:
        raise RuntimeError(f'gdbus failed: {r.stderr}')
    return r.stdout

orig = json.loads('''$saved''')
raw = gdbus('org.gnome.Mutter.DisplayConfig.GetResources')
serial = int(re.search(r'\(uint32 (\d+)', raw).group(1))

for cid_str, (r_orig, g_orig, b_orig) in orig.items():
    cid = int(cid_str)
    arr = lambda lst: '[' + ','.join(str(v) for v in lst) + ']'
    gdbus('org.gnome.Mutter.DisplayConfig.SetCrtcGamma',
          f'uint32 {serial}', f'uint32 {cid}',
          arr(r_orig), arr(g_orig), arr(b_orig))
    print(f'CRTC {cid}: restored', flush=True)
" 2>&1 || true
        }

        # ── main loop ───────────────────────────────────────
        col_set night-light-enabled true

        # Try geoip on first start
        update_geoip 2>/dev/null || true

        # Save original gamma LUTs for all active CRTCs at startup.
        # Subsequent apply_gamma calls multiply from these saved values,
        # avoiding cumulative multiplication every 60s.
        orig_gamma=$(python3 -c "
import subprocess, re, json

def gdbus(m, *a):
    r = subprocess.run(['gdbus','call','--session',
        '--dest','org.gnome.Mutter.DisplayConfig',
        '--object-path','/org/gnome/Mutter/DisplayConfig',
        '--method',m]+list(a), capture_output=True, text=True, timeout=10)
    return r.stdout

raw = gdbus('org.gnome.Mutter.DisplayConfig.GetResources')
serial = int(re.search(r'\(uint32 (\d+)', raw).group(1))
clean = re.sub(r'uint32 |int64 |boolean |double ','',raw)
result = {}
for m in re.finditer(r'\(\s*(\d+)\s*,\s*(\d+)\s*,\s*\d+\s*,\s*\d+\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(-?\d+)', clean):
    cid,w,h,s=int(m.group(1)),int(m.group(3)),int(m.group(4)),int(m.group(5))
    if w<=0 or h<=0 or s<0: continue
    gamraw = gdbus('org.gnome.Mutter.DisplayConfig.GetCrtcGamma', f'uint32 {serial}', f'uint32 {cid}')
    arr = re.findall(r'\[([^\]]+)\]', gamraw)
    if len(arr) < 3: continue
    rv = [int(x) for x in re.findall(r'\b(\d+)\b', arr[0])]
    gv = [int(x) for x in re.findall(r'\b(\d+)\b', arr[1])]
    bv = [int(x) for x in re.findall(r'\b(\d+)\b', arr[2])]
    result[str(cid)] = [rv, gv, bv]
print(json.dumps(result))
" 2>/dev/null) || orig_gamma=""

        # Apply gamma if currently in schedule, otherwise restore
        if in_schedule; then
            cur_temp=$(col_get night-light-temperature | grep -oP '\d+' | tail -1)
            apply_gamma "$cur_temp" 2>&1 | logger -t gnome-wayland-redshift || true
            restored=false
        else
            restore_gamma 2>&1 | logger -t gnome-wayland-redshift || true
            restored=true
        fi

        geoip_counter=0
        geoip_interval=235

        while true; do
            sleep 60
            geoip_counter=$((geoip_counter + 1))
            if [ "$geoip_counter" -ge "$geoip_interval" ]; then
                geoip_counter=0
                update_geoip 2>/dev/null || true
            fi
            if in_schedule; then
                cur_temp=$(col_get night-light-temperature | grep -oP '\d+' | tail -1)
                apply_gamma "$cur_temp" 2>&1 | logger -t gnome-wayland-redshift || true
                restored=false
            else
                # Only restore once when leaving the schedule — avoids flicker
                if ! $restored; then
                    restore_gamma 2>&1 | logger -t gnome-wayland-redshift || true
                    restored=true
                fi
            fi
        done
        ;;

    install)
        require_dbus
        unit="$HOME/.config/systemd/user/gnome-wayland-redshift.service"
        mkdir -p "$(dirname "$unit")"
        script_path="$(readlink -f "$0")"
        cat > "$unit" <<-UNITEOF
[Unit]
Description=GNOME Wayland night light (preview loop + auto-geoip)
After=graphical-session.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=${script_path} serve
Restart=on-failure
RestartSec=10
Environment=DISPLAY=:0
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/%U/bus

[Install]
WantedBy=default.target
UNITEOF
        systemctl --user daemon-reload
        systemctl --user enable --now gnome-wayland-redshift.service
        echo "Installed and started gnome-wayland-redshift.service"
        echo "  Auto-adjusts schedule via GeoIP every ~4h."
        echo "  logs: journalctl --user -u gnome-wayland-redshift -f"
        echo "  stop: systemctl --user stop gnome-wayland-redshift"
        ;;

    uninstall)
        systemctl --user stop gnome-wayland-redshift.service 2>/dev/null || true
        systemctl --user disable gnome-wayland-redshift.service 2>/dev/null || true
        rm -f "$HOME/.config/systemd/user/gnome-wayland-redshift.service"
        systemctl --user daemon-reload
        loop_stop
        col_set night-light-enabled false
        col_set night-light-temperature "uint32 6500"
        echo "Uninstalled. Night light disabled."
        ;;

    ""|-h|--help)
        usage
        ;;

    *)
        echo "Error: unknown command '${cmd}'" >&2
        usage >&2
        exit 1
        ;;
esac
