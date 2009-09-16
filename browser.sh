#!/bin/bash
# Author: JuanJo ( juanjosec O gmail o com  )
# $HOME/bin/browser.sh
#   if running, try: google-chrome, chromium-browser
#   else:            firefox
#
case "$(ps -oargs= -C chrome,chromium-browser)" in
  /opt/google/chrome*)
    exec /opt/google/chrome/chrome "$@";;
  /usr/lib/chromium-browser*)
    exec /usr/bin/chromium-browser "$@";;
esac
exec /usr/bin/firefox "$@"
exit $?

# Point2 me with the output from:
for p in /desktop/gnome/{applications/browser/exec,url-handlers/http{,s}/command}; do
  gconftool-2 -s $p -t string "$HOME/bin/browser.sh \"%s\""
done
