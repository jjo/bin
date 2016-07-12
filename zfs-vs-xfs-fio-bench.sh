#!/bin/bash
# zfs-vs-xfs-fio-bench.sh: compare XFS vs ZFS fio runs,
# particularly thinking on CEPH backed storage where ZFS doesn't
# seem to be able to reach XFS throughput.
#
# Author: JuanJo Ciarlante <juanjosec@gmail.com>
# License: GPLv3
#
FIO_CMD="fio --name=foo --ioengine=libaio --iodepth=2 --rw=randwrite --bs=4k --direct=0 --size=16M --numjobs=4 --runtime=60 --time_based --group_reporting"

test_zfs_fio() {
  (set -xe
    zpool create test -o ashift=$1 -O secondarycache=none -O recordsize=$2 -O compress=lz4 -O atime=off -O checksum=off -O redundant_metadata=most -f /dev/vdb
    (cd /test && $FIO)
    zpool destroy -f test
  )
}
test_xfs_fio() {
  (set -xe
    mkfs.xfs -s log=$1 /dev/vdb -f && mount /dev/vdb /mnt
    (cd /mnt && $FIO)
    umount /dev/vdb
  )
}


for ashift in {9..13};do
    #for recordsize in 4k 8k 16k 32k 64k 128k;do
    for recordsize in 64k ;do
        test_xfs_fio $ashift             |& tee /root/xfs-fio-s_log_$ashift.out
        test_zfs_fio $ashift $recordsize |& tee /root/zfs-fio-ashift_$ashift-recordsize_$recordsize.out
    done
done

# Some data samples: --jjo, 2016-05-04
#
# - VM: linux 4.4.0, ceph nova volume (10 node cluster with 1Gbps NICs)
# - host: linux 4.4.0, 1Gbps mtu=1500
#
DATA_xfs="
/root/xfs-fio-s_log_9.out:                   WRITE:  io=8200.8MB,  aggrb=139780KB/s,  minb=139780KB/s,  maxb=139780KB/s,  mint=60072msec,  maxt=60072msec
/root/xfs-fio-s_log_10.out:                  WRITE:  io=6432.6MB,  aggrb=109538KB/s,  minb=109538KB/s,  maxb=109538KB/s,  mint=60134msec,  maxt=60134msec
/root/xfs-fio-s_log_11.out:                  WRITE:  io=5733.9MB,  aggrb=97636KB/s,   minb=97636KB/s,   maxb=97636KB/s,   mint=60136msec,  maxt=60136msec
/root/xfs-fio-s_log_12.out:                  WRITE:  io=4848.2MB,  aggrb=81759KB/s,   minb=81759KB/s,   maxb=81759KB/s,   mint=60719msec,  maxt=60719msec
/root/xfs-fio-s_log_13.out:                  WRITE:  io=5504.7MB,  aggrb=93491KB/s,   minb=93491KB/s,   maxb=93491KB/s,   mint=60292msec,  maxt=60292msec
"
DATA_zfs="
/root/zfs-fio-ashift_9-recordsize_64k.out:   WRITE:  io=1700.7MB,  aggrb=25773KB/s,   minb=25773KB/s,   maxb=25773KB/s,   mint=67568msec,  maxt=67568msec
/root/zfs-fio-ashift_10-recordsize_64k.out:  WRITE:  io=70032KB,   aggrb=1099KB/s,    minb=1099KB/s,    maxb=1099KB/s,    mint=63697msec,  maxt=63697msec
/root/zfs-fio-ashift_11-recordsize_64k.out:  WRITE:  io=70276KB,   aggrb=1143KB/s,    minb=1143KB/s,    maxb=1143KB/s,    mint=61473msec,  maxt=61473msec
/root/zfs-fio-ashift_12-recordsize_64k.out:  WRITE:  io=76408KB,   aggrb=1233KB/s,    minb=1233KB/s,    maxb=1233KB/s,    mint=61939msec,  maxt=61939msec
/root/zfs-fio-ashift_13-recordsize_64k.out:  WRITE:  io=78968KB,   aggrb=1116KB/s,    minb=1116KB/s,    maxb=1116KB/s,    mint=70710msec,  maxt=70710msec
"
