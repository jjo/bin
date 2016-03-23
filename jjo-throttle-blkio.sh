#!/bin/bash
# Throttle command IO with blkio, see usage below
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
usage() {
	echo "Usage: sudo $0 mount_point blkio_name bps comand args..."
	echo "       sudo $0 /srv/ limit_foo 1048576    find /srv/some/thing"
	echo "       sudo $0 /srv/ limit_foo 1048576    sudo -Hu 'find /srv/some/thing'"
}

[ $# -gt 3 ] || {
	usage
	exit 1
}
# Checks:
[ $(id -u) = 0 ] || {
	echo "ERROR: needs root"
	exit 1
}
which cgexec || {
	echo "ERROR: missing 'cgexec' command, do: apt-get install cgroup-bin"
	exit 1
}

mount_point="${1:?missing mount_point for device to throttle, eg /srv/}"
blkio_name="${2?missing blkio name, eg limit_foo}"
bps="${3:?missing bps, eg 1048576}"
shift 3

# need major_device to throttle
major_device=$(($(stat -c '%d' ${mount_point})/256))

# do it:
trap "rmdir /sys/fs/cgroup/blkio/$blkio_name/" 0 2
mkdir -p /sys/fs/cgroup/blkio/$blkio_name/
echo "$major_device:0 $bps" > /sys/fs/cgroup/blkio/$blkio_name/blkio.throttle.write_bps_device
echo "$major_device:0 $bps" > /sys/fs/cgroup/blkio/$blkio_name/blkio.throttle.read_bps_device
cgexec -g blkio:$blkio_name $*
