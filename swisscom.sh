#!/bin/bash
(( $(id -u) )) && exec sudo $0 $*
PROVIDER=${1:-swisscom}
pon $PROVIDER updetach $X || exit $?
(
	sleep 2
	if dig +short +time=2 www.google.com >/dev/null ;then
		:
	else
		killall nload
		exit 255
	fi
) &
check_pid=$!
(sudo bash -c "/etc/init.d/debtorrent-client stop; /etc/init.d/debtorrent-tracker stop") > /dev/null 2>&1 &
nload ppp0
wait $check_pid
[ $? -eq 255 ] && echo "*** DNS resolution seems not to be working :( ***"
read -p 'Shutdown pppd link [Y/n] ? ' yesno
case "$yesno" in
[nN]*) exit 0;;
esac
poff $PROVIDER 
