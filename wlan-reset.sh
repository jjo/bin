#!/bin/bash -x
(( $(id -u) )) && exec sudo $0 $*
set -x
killall NetworkManager
killall ipw3945d-$(uname -r)
typeset -i i=3
until rmmod ipw3945;do sleep 1 ; i=i-1; ((i))||break;done
rm -f /var/run/ipw3945d.pid 
killall -9 NetworkManager
modprobe ipw3945
NetworkManager &
