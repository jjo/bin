#!/bin/bash
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
# Run a single X11 instance of a given application at cmdline
# e.g.: jjo-run1.sh chromium-browser ...

which wmctrl >/dev/null || { echo "Missing wmctrl - install it."; exit 1 ;}
wmctrl -x -R "${1:?missing cmd args ...}" || {
	cd && exec ${SHELL} -c "$@"
}
