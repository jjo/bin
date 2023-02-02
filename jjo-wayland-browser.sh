#!/bin/sh
# Wayland wrappers for browsers to get pinch-to-zoom
XTRA=""
BROWSER=""
case ${XDG_SESSION_TYPE:?} in
    wayland)
        CHROME_XTRA="--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-features=WebRTCPipeWireCapturer"
        export MOZ_ENABLE_WAYLAND=1 MOZ_USE_XINPUT2=1
        ;;
esac

case "$0" in
    *brave*) BROWSER=brave-browser; XTRA="${CHROME_XTRA}";;
    *chrome-beta*) BROWSER=google-chrome-beta; XTRA="${CHROME_XTRA}";;
    *chrome*) BROWSER=google-chrome; XTRA="${CHROME_XTRA}";;
    *chromium*) BROWSER=chromium-browser; XTRA="${CHROME_XTRA}";;
    *firefox*) BROWSER=firefox; XTRA="";;
esac
exec ${BROWSER:?} ${XTRA} "${@}"
