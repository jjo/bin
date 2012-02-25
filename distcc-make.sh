#!/bin/sh
HOSTS_AUTO="$HOSTS_AUTO localhost"
while [ $# -ge 1 ];do
	case "$1" in 
	--home) HOSTS_AUTO="$HOSTS_AUTO 10.55.14.2 cx";shift;;
	--um) HOSTS_AUTO="pitagoras pitagoras $HOSTS_AUTO";shift;;
	--google) HOSTS_AUTO="carpediem carpediem";shift;;
	*) break;;
	esac
done

set -x
export CCACHE_PREFIX="distcc"
export DISTCC_HOSTS="$(fping -a -t 50 $HOSTS_AUTO|xargs )"
echo "DISTCC_HOSTS=$DISTCC_HOSTS"
#make CC="ccache gcc" CXX="ccache g++"  "$@"
export PATH="/usr/lib/ccache:$PATH" 
make "$@"

