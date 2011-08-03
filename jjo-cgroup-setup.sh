#!/bin/bash -xe
U=${SUDO_USER:-$USER}
CG=${U?}_browsers
cgcreate -t $U:root -g blkio,cpu:/$CG
cgset -r blkio.weight=100 $CG
cgset -r    cpu.shares=10 $CG
(cgclassify  -g blkio,cpu:/$CG $( lsof -u $U -a -c '/chrom|npviewer/' -t );exit 0)

CG=${U?}_dropbox
cgcreate -t $U:root -g blkio,cpu:/$CG
cgset -r blkio.weight=1  $CG
cgset -r    cpu.shares=2 $CG
(cgclassify  -g blkio,cpu:/$CG $( lsof -u $U -a -c '/dropbox/' -t ); exit 0)
