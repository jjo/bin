#!/bin/sh
# Wayland wrappers for browsers to get pinch-to-zoom
# Issue: only works on main screen, for (multi-screen setups) (?)
# Issue: fails to share screen in g/meet
case ${XDG_SESSION_TYPE:?} in
    wayland) export MOZ_ENABLE_WAYLAND=1 MOZ_USE_XINPUT2=1;;
esac
exec firefox "${@}"
