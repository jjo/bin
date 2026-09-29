#!/usr/bin/env python3
"""display-idle-guard - keep the displays off when the pointer is not in use.

Measured root cause (jjo-t14s, 2026-09-29)
------------------------------------------
The Bluetooth Logitech MX Vertical (/dev/input/event21, uhid, MAC
F1:D7:C8:12:BA:6C) emits continuous *phantom* input while untouched:
  * 70-110 REL events/s, bursts of up to 164 consecutive same-direction
    reports, |net| ~= 1000 units / 0.5 s - numerically indistinguishable from
    deliberate motion, so no shape/coherence/threshold filter can work;
  * ~3 BTN_LEFT *presses* (value 1) per 20 s, so buttons cannot be trusted as
    "the user is here" either.
Any such input re-arms the compositor's display power, which means COSMIC's lock
screen never blanks the displays and a manual `wlopm --off '*'` is undone within
~1 s. With no input arriving, the same command holds (30 s+ measured).

Design: anchor suppression to DISPLAY STATE, never to a stored lock flag
------------------------------------------------------------------------
Measured here: logind emits Session.Lock on the system bus when the session
locks (both `loginctl lock-session` and COSMIC's own UI), but it does NOT
reliably emit Session.Unlock when the greeter authenticates - and COSMIC never
sets logind's LockedHint at all (no COSMIC binary references SetLockedHint). An
earlier version stored a "locked" flag; holding it stale left the pointer
grabbed on a live desktop. So:

  * Lock signal -> one-shot: grab the pointers FIRST, then force the displays
    off (grab first: the phantom stream is ~77 ev/s, so an ungrabbed display is
    woken again within milliseconds).
  * While every connected output is dpms=Off -> keep the pointers grabbed so
    nothing can wake the displays.
  * Any key press -> power the displays on, release the grab, and stand off for
    --key-grace so the daemon never fights the user.
  * --lock-hold stops a lock-triggered grab being released before the power-off
    lands.

Every rule is evaluated from externally observable state, so no stale flag can
strand the pointer; the worst case is bounded by --lock-hold / --key-grace.

Optional: --idle-blank SECONDS forces the displays off after that much *keyboard*
quiet - "ignore the mouse for idleness" even while unlocked (pointer motion and
phantom clicks never count as activity).

No root, no /dev/uinput, no udev rule: EVIOCGRAB works as plain user (input
group), and the kernel drops the grab if this process dies.
"""
from __future__ import annotations

import argparse
import glob
import os
import signal
import subprocess
import sys
import time
from collections import Counter

try:
    import evdev
except ImportError:  # pragma: no cover
    sys.exit("display-idle-guard: python3-evdev is required (apt install python3-evdev)")

try:
    from gi.repository import GLib
except ImportError:  # pragma: no cover
    sys.exit("display-idle-guard: python3-gi is required (apt install python3-gi)")

LOGIN1_SESSION = "org.freedesktop.login1.Session"


# --------------------------------------------------------------------------- #
# small helpers
# --------------------------------------------------------------------------- #
def detect_wayland() -> str:
    wd = os.environ.get("WAYLAND_DISPLAY")
    if wd:
        return wd
    rt = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    for cand in ("wayland-1", "wayland-0"):
        if os.path.exists(os.path.join(rt, cand)):
            return cand
    found = sorted(glob.glob(os.path.join(rt, "wayland-*")))
    return os.path.basename(found[0]) if found else "wayland-1"


def read_dpms() -> dict:
    """{output-name: 'On'|'Off'} for every *connected*, non-writeback connector.

    Disconnected DP/HDMI connectors and evdi/DisplayLink virtual outputs report
    dpms=On with nothing attached, and card<N>-Writeback-1 is always On; counting
    them would make "all outputs off" never come true.
    """
    states = {}
    for path in glob.glob("/sys/class/drm/card*-*/dpms"):
        name = os.path.basename(os.path.dirname(path))
        if "Writeback" in name:
            continue
        try:
            with open(os.path.join(os.path.dirname(path), "status")) as fh:
                if fh.read().strip() != "connected":
                    continue
            with open(path) as fh:
                states[name] = fh.read().strip()
        except OSError:
            continue
    return states


def all_outputs_off(states: dict) -> bool:
    return bool(states) and all(v == "Off" for v in states.values())


class RealIO:
    """All side effects, isolated so the decision logic can be unit-tested."""

    def __init__(self, opts, log):
        self.opts = opts
        self.log = log
        self.env = dict(os.environ)
        self.env.setdefault("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
        self.env["WAYLAND_DISPLAY"] = detect_wayland()
        self.devices: dict = {}          # path -> evdev.InputDevice
        self.grabbed: dict = {}          # path -> evdev.InputDevice
        self.forced_off = False
        self.last_wlopm = 0.0

    # ---- device handling ----
    @staticmethod
    def has_rel_xy(dev) -> bool:
        rel = set(dev.capabilities(absinfo=False).get(evdev.ecodes.EV_REL, []))
        return bool(rel & {0, 1})            # REL_X / REL_Y

    @staticmethod
    def is_pointer(dev) -> bool:
        """A real pointing device: relative axes AND a mouse button."""
        keys = set(dev.capabilities(absinfo=False).get(evdev.ecodes.EV_KEY, []))
        return RealIO.has_rel_xy(dev) and bool(keys & {272, 273, 274})

    def pointer_paths(self) -> list:
        return [p for p, d in self.devices.items() if self.is_pointer(d)]

    def scan(self):
        """(Re)open every evdev device; drop nodes that disappeared."""
        seen = set()
        for path in sorted(evdev.list_devices()):
            seen.add(path)
            if path in self.devices:
                continue
            try:
                dev = evdev.InputDevice(path)
                os.set_blocking(dev.fd, False)   # evdev 1.7.0 lacks set_blocking()
                self.devices[path] = dev
            except OSError:
                continue
        for path in list(self.devices):
            if path not in seen:
                self.grabbed.pop(path, None)
                self.devices.pop(path, None)
        return seen

    def grab(self, paths):
        for path in paths:
            if path in self.grabbed:
                continue
            dev = self.devices.get(path)
            if dev is None:
                continue
            try:
                dev.grab()
                self.grabbed[path] = dev
                self.log(f"grabbed {path} ({dev.name})")
            except OSError as exc:
                self.log(f"grab failed for {path}: {exc}")

    def release(self, *_):
        for path, dev in list(self.grabbed.items()):
            try:
                dev.ungrab()
                self.log(f"released {path}")
            except OSError:
                pass
        self.grabbed.clear()

    # ---- display power ----
    def _wlopm(self, mode: str) -> bool:
        now = time.monotonic()
        if now - self.last_wlopm < 0.2:
            return False
        self.last_wlopm = now
        try:
            proc = subprocess.run(["wlopm", mode, "*"], env=self.env,
                                  capture_output=True, text=True, timeout=5)
        except (OSError, subprocess.TimeoutExpired) as exc:
            self.log(f"wlopm {mode} failed: {exc}")
            return False
        if proc.returncode != 0:
            self.log(f"wlopm {mode} rc={proc.returncode} {proc.stderr.strip()!r}")
            return False
        self.log(f"outputs {mode}")
        return True

    def outputs_off(self) -> bool:
        if self.opts.dry_run:
            self.log("DRY-RUN would power off outputs")
            return True
        ok = self._wlopm("--off")
        self.forced_off = self.forced_off or ok
        return ok

    def outputs_on(self) -> bool:
        if self.opts.dry_run:
            self.log("DRY-RUN would power on outputs")
            self.forced_off = False
            return True
        ok = self._wlopm("--on") if self.forced_off else True
        self.forced_off = False
        return ok

    @staticmethod
    def dpms() -> dict:
        return read_dpms()

    def now(self) -> float:
        return time.monotonic()


# --------------------------------------------------------------------------- #
# decision logic
# --------------------------------------------------------------------------- #
class Guard:
    """Suppress the pointer while the displays are off; one-shot off on lock."""

    def __init__(self, opts, io, log=None):
        self.opts = opts
        self.io = io
        self.log = log or (lambda *a, **k: None)
        self.grabbed = False
        self.no_grab_until = -1e9      # after a key press: hands off for a moment
        self.hold_until = -1e9         # after a lock grab: do not release instantly
        # Seeded from now(), NOT -inf: otherwise a daemon that starts with
        # --idle-blank set would treat the screen as idle since boot and blank
        # the displays the instant it comes up.
        self.last_key = self.io.now()
        self.last_force_off = -1e9
        self.stats = Counter()

    @property
    def suppressed(self) -> bool:
        """Introspection alias for tests/monitoring."""
        return self.grabbed

    def _now(self, now):
        return self.io.now() if now is None else now

    # ---- events ----
    def on_key(self, now=None):
        """A key press means a human is here: show the screen, then let go."""
        now = self._now(now)
        self.stats["keys"] += 1
        self.last_key = now
        self.no_grab_until = now + self.opts.key_grace
        if self.grabbed:
            self.io.outputs_on()
            self.release("key")

    def on_lock(self, now=None):
        """One-shot: grab first, then power off.

        Grab precedes the power-off because the phantom stream (~77 ev/s) would
        otherwise wake the display again within milliseconds.
        """
        now = self._now(now)
        self.stats["locks"] += 1
        self.grab()
        self.hold_until = now + self.opts.lock_hold
        if self.opts.power_off_on_lock:
            self.io.outputs_off()

    def on_unlock(self, now=None):
        self.stats["unlocks"] += 1
        self.release("unlock")
        self.io.outputs_on()

    # ---- transitions ----
    def grab(self):
        self.io.grab(self.io.pointer_paths())
        if not self.grabbed:
            self.grabbed = True
            self.stats["grabs"] += 1
            self.log("suppress (display-off)")

    def release(self, reason):
        if not self.grabbed:
            return
        self.grabbed = False
        self.io.release()
        self.log(f"resume ({reason})")

    # ---- periodic ----
    def tick(self, now, outputs_off):
        # Displays back on and the lock-grab has settled: the pointer belongs to
        # the user again. This self-healing rule is why no stale lock flag exists.
        if self.grabbed and not outputs_off and now >= self.hold_until:
            self.release("displays on")
        # Displays off: nothing may wake them (also re-grabs new BT nodes).
        if outputs_off and now >= self.no_grab_until and self.opts.on_display_off:
            self.grab()
        # Opt-in: ignore the pointer entirely for idleness.
        if (self.opts.idle_blank and not outputs_off
                and now - self.last_key > self.opts.idle_blank
                and now - self.last_force_off > 1.0):
            if self.io.outputs_off():
                self.last_force_off = now
                self.stats["idle_blanks"] += 1

    def cleanup(self):
        self.io.release()


# --------------------------------------------------------------------------- #
# wiring
# --------------------------------------------------------------------------- #
class Watcher:
    def __init__(self, io, guard, log, stats_interval):
        self.io = io
        self.guard = guard
        self.log = log
        self.stats_interval = stats_interval
        self.last_stats = time.monotonic()
        self.watched: dict = {}

    def rescan(self):
        self.io.scan()
        for path in list(self.watched):
            if path not in self.io.devices:
                self.watched.pop(path, None)
        for path, dev in self.io.devices.items():
            if path in self.watched:
                continue
            try:
                GLib.io_add_watch(dev.fd, GLib.IO_IN, self._read, path)
                self.watched[path] = dev
            except Exception as exc:
                self.log(f"watch failed {path}: {exc}")
        return True

    def _read(self, fd, condition, path):
        dev = self.io.devices.get(path)
        if dev is None:
            return False
        try:
            events = dev.read()
        except (OSError, BlockingIOError):
            return True
        if self.io.is_pointer(dev):
            return True          # phantom BTN presses: never a wake/presence source
        for ev in events:
            if ev.type == evdev.ecodes.EV_KEY and ev.value == 1:
                self.guard.on_key()
        return True

    def tick(self):
        now = self.io.now()
        self.guard.tick(now, all_outputs_off(self.io.dpms()))
        if self.stats_interval and now - self.last_stats >= self.stats_interval:
            self.last_stats = now
            s = self.guard.stats
            self.log(f"stats grabbed={self.guard.grabbed} keys={s['keys']} "
                     f"locks={s['locks']} unlocks={s['unlocks']} grabs={s['grabs']} "
                     f"idle_blanks={s['idle_blanks']}")
        return True


def main(argv=None):
    ap = argparse.ArgumentParser(description="keep displays off while the pointer is idle")
    ap.add_argument("--no-on-display-off", dest="on_display_off", action="store_false",
                    help="do not suppress while the displays are off")
    ap.add_argument("--no-power-off-on-lock", dest="power_off_on_lock",
                    action="store_false", help="do not force displays off on lock")
    ap.add_argument("--key-grace", type=float, default=3.0,
                    help="seconds after a key press to keep hands off the pointer (default 3)")
    ap.add_argument("--lock-hold", type=float, default=5.0,
                    help="seconds a lock-triggered grab is held even if the displays "
                         "already read On (default 5)")
    ap.add_argument("--idle-blank", type=float, default=0.0,
                    help="force displays off after N seconds of no KEYBOARD input "
                         "(pointer motion excluded; 0 = off)")
    ap.add_argument("--stats-interval", type=float, default=0.0,
                    help="log a status line every N seconds (0 = off)")
    ap.add_argument("--dry-run", action="store_true",
                    help="log decisions but never grab or change display power")
    opts = ap.parse_args(argv)

    def log(msg):
        print(f"[display-idle-guard] {msg}", flush=True)

    io = RealIO(opts, log)
    guard = Guard(opts, io, log)
    watcher = Watcher(io, guard, log, opts.stats_interval)

    io.scan()
    log(f"start: wayland={io.env['WAYLAND_DISPLAY']} pointers={len(io.pointer_paths())} "
        f"outputs={read_dpms()} idle_blanks_after={opts.idle_blank or 'off'}")

    # Lock is the only signal COSMIC emits reliably; Unlock is best-effort and is
    # never required, because display state drives everything else.
    try:
        import dbus
        import dbus.mainloop.glib
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        bus = dbus.SystemBus()
        bus.add_signal_receiver(lambda *a: guard.on_lock(),
                                signal_name="Lock", dbus_interface=LOGIN1_SESSION)
        bus.add_signal_receiver(lambda *a: guard.on_unlock(),
                                signal_name="Unlock", dbus_interface=LOGIN1_SESSION)
        log("subscribed to logind Session Lock/Unlock")
    except Exception as exc:
        log(f"WARNING: logind subscription failed ({exc}); display-off rule only")

    loop = GLib.MainLoop()

    def shutdown(*_):
        guard.cleanup()
        log("stopped")
        loop.quit()

    for sig in (signal.SIGTERM, signal.SIGINT):
        GLib.unix_signal_add(GLib.PRIORITY_DEFAULT, sig, shutdown)
    GLib.timeout_add(1000, watcher.tick)
    GLib.timeout_add(5000, watcher.rescan)
    watcher.rescan()
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
