#!/bin/bash -x
# Actually superseeded by this firefox extension:
#  https://addons.mozilla.org/en-US/firefox/addon/13878
for f in ~/.mozilla/firefox/*/*.sqlite; do
	(set -x;exec sqlite3 $f 'VACUUM;')
done
