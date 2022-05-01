#!/bin/sh
# Wayland wrappers for browsers to get pinch-to-zoom
XTRA=""
case ${XDG_SESSION_TYPE:?} in
    wayland) XTRA="--enable-features=UseOzonePlatform --ozone-platform=wayland";;
esac
exec brave-browser ${XTRA} "${@}"
