#!/bin/bash
for f in "$@";do
	i=auto #?
	case "$f" in
		*.[Gg][Pp][Xx]) i=gpx;;
		*.[Gg][Pp][Ii]) i=garmin_gpi;;
		*.[Oo][Vv]2) i=tomtom;;
	esac
	echo "=== file=$f ==="
	gpsbabel -i $i -f "$f" -o csv -F -
done | less
