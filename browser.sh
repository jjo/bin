#!/bin/bash
# Author: JuanJo ( juanjosec O gmail o com  )
# $HOME/bin/browser.sh
#   if running, try: google-chrome, chromium-browser
#   else:            firefox
#
case "$(ps -oargs= -C chrome,chromium-browser)" in
  */opt/google/chrome*) browser=chrome;;
  /usr/lib/chromium-browser*) browser=chromium;;
  *) browser=firefox;;
esac
case "$1" in
	ed2k:*) echo ed2k-jjo
		~/bin/ml-dllink.sh "$@";exit $?;;
	*craigslist*) browser=chromium;;
esac
case "$browser" in
  chrome) exec /opt/google/chrome/chrome "$@";;
  chromium) exec /usr/bin/chromium-browser "$@";;
  firefox) exec /usr/bin/firefox "$@";;
esac
exit 255

# Point2 me with the output from:
for p in /desktop/gnome/{applications/browser/exec,url-handlers/http{,s}/command}; do
  gconftool-2 -s $p -t string "$HOME/bin/browser.sh \"%s\""
done
