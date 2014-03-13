#!/bin/bash
device=${1:?missing device eg: /dev/sdd}
shift
# several KVM optimizations for faster device IO, from
# http://blog.vmsplice.net/2013/03/new-in-qemu-14-high-performance-virtio.html
# ftp://public.dhe.ibm.com/linux/pdfs/KVM_Virtualized_IO_Performance_Paper.pdf
kvm -m 4096 \
	-drive if=none,id=drive0,cache=none,aio=native,format=raw,file=${device} \
	-device virtio-blk,drive=drive0,scsi=off,config-wce=off,x-data-plane=on "$@"
