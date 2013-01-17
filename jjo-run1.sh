#!/bin/bash
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
# Run a single X11 instance of a given application at cmdline
# e.g.: jjo-run1.sh chromium-browser ...

[[ -x /usr/bin/wmctrl ]] || {
	echo "Missing wmctrl - install it."
	exit 1
}
cmd="${1:?missing cmd args...}"

wmctrl -x -R "${cmd}" || {
	cd
	exec bash -c "$@"
}
