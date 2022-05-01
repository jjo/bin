#!/bin/sh
# Wayland wrappers for browsers to get pinch-to-zoom
# Issue: only works on main screen, for (multi-screen setups) (?)
# Issue: fails to share screen in g/meet
XTRA=""
case ${XDG_SESSION_TYPE:?} in
    wayland) XTRA="--enable-features=UseOzonePlatform --ozone-platform=wayland";;
esac
exec google-chrome-stable ${XTRA} "${@}"
