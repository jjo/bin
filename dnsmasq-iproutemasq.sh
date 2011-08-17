#!/bin/sh -x
IFACE=${1:?missing interface}
NET=${2:-192.168.0}
test $(id -u) -eq 0 || { echo "Must be root";exit 1;}
iptables -t nat -D POSTROUTING -s $NET.0/24 -j MASQUERADE 2>/dev/null
iptables -t nat -I POSTROUTING -s $NET.0/24 -j MASQUERADE
iptables -D FORWARD -s $NET.0/24 -i $IFACE -j ACCEPT 2>/dev/null
iptables -I FORWARD -s $NET.0/24 -i $IFACE -j ACCEPT
sysctl -w net/ipv4/ip_forward=1
ifconfig $IFACE $NET.1/24
dnsmasq -i $IFACE_I -F $NET.50,$NET.150,12h -b -f -R -S 8.8.8.8 -S 8.8.4.4 -d

