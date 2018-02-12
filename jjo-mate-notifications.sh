#!/bin/bash
case "$1" in
    on)  sudo mv /usr/share/dbus-1/services/org.freedesktop.mate.Notifications.service{.disabled,} ;;
    off) sudo mv /usr/share/dbus-1/services/org.freedesktop.mate.Notifications.service{,.disabled} ;;
    st*) test -f /usr/share/dbus-1/services/org.freedesktop.mate.Notifications.service && echo on || echo off;;
    *) echo "Usage: $0 {on|off|st[atus]}"; exit 1;;
esac
