#!/bin/bash -xe
U=${SUDO_USER:-$USER}
CG=${U?}_browsers
cgcreate -t $U:root -g blkio,cpu:/$CG
cgset -r blkio.weight=100 $CG
cgset -r    cpu.shares=10 $CG
cgclassify  -g blkio,cpu:/$CG $( lsof -u $U -c '/chrom|npviewer/' -t )
