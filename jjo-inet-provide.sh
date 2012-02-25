action=${1:?missing start|stop}
IFACE_I=${2:?missing IFACE_I}
IFACE_O=${3:?missing IFACE_O}
ADHOC_SSID=${4:-jjoADHOC}
KEY=${5:-off}
__() {
	echo "$@"
}
do_iptables() {
	cmd=${1:?missing -I / -D}
	__ iptables $cmd INPUT -i $IFACE_I -m state --state ESTABLISHED -j ACCEPT 
	__ iptables $cmd INPUT -i $IFACE_I -p icmp -j ACCEPT 
	__ iptables $cmd INPUT -i $IFACE_I -p tcp -m tcp --dport 53 -j ACCEPT 
	__ iptables $cmd INPUT -i $IFACE_I -p udp -m udp --dport 53 -j ACCEPT 
	__ iptables $cmd INPUT -i $IFACE_I -p udp -m udp --dport 67:69 -j ACCEPT 
	__ iptables $cmd FORWARD -i $IFACE_I -o $IFACE_O -j ACCEPT 
	__ iptables $cmd FORWARD -i $IFACE_O -o $IFACE_I -j ACCEPT 
	__ iptables $cmd OUTPUT -o $IFACE_I -j ACCEPT 
	__ iptables -t nat $cmd POSTROUTING -o $IFACE_O -j MASQUERADE
}

_stop(){
	__ killall dnsmasq
	__ ifconfig $IFACE_I down
	__ sysctl -w net/ipv4/ip_forward=0
	do_iptables -D
	#__ sed -i \"/$IFACE_I/s/^/#/\" /etc/network/interfaces
	__ killall -1 NetworkManager
}
_start(){
	do_iptables -I
	__ sysctl -w net/ipv4/ip_forward=1
	case "$IFACE_I" in wlan*)
		test -n "$ADHOC_SSID" && __ iwconfig $IFACE_I mode ad-hoc essid $ADHOC_SSID key $KEY
		;;
	esac
	__ ifconfig $IFACE_I 192.168.0.1
	__ dnsmasq -i $IFACE_I -F 192.168.0.50,192.168.0.150,12h -b -f -R -S 8.8.8.8 -S 8.8.4.4 -d \&
	#__ sed -i \"/$IFACE_I/s/^#//\" /etc/network/interfaces
	__ killall -1 NetworkManager
}

case "$action" in 
	start) _start;;
	stop)  _stop;;
	restart) _stop;_start;;
esac
