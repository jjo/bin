#!/bin/bash -x
(( $(id -u) )) && exec sudo $0 $*
set -x
killall NetworkManager
killall ipw3945d-2.6.20-16-generic
until rmmod ipw3945;do sleep 1;done
rm -f /var/run/ipw3945d.pid 
killall -9 NetworkManager
modprobe ipw3945
NetworkManager &
