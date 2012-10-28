#!/bin/sh
#* VPNGATEWAY                   -- vpn gateway address (always present)
#* TUNDEV                       -- tunnel device (always present)
#* INTERNAL_IP4_ADDRESS         -- address (always present)
#* INTERNAL_IP4_NETMASK         -- netmask (often unset)
#* INTERNAL_IP4_NETMASKLEN      -- netmask length (often unset)
#* INTERNAL_IP4_NETADDR         -- address of network (only present if netmask is set)

# =========== script (variable) setup ====================================
OS="`uname -s`"
IPROUTE="`which ip | grep '^/' 2> /dev/null`"
FULL_SCRIPTNAME=/opt/sbin/vpnc
SCRIPTNAME=`basename $FULL_SCRIPTNAME`
ifconfig_syntax_ptp="pointopoint"
route_syntax_gw="gw"
route_syntax_del="del"
route_syntax_netmask="netmask"
if [ ! -d "/opt/var/run/vpnc" ]; then
	mkdir -p /opt/var/run/vpnc
fi

# ========= Toplevel state handling  =======================================
do_pre_init() {
	if (exec 6 <> /dev/net/tun) > /dev/null 2>&1 ; then
		:
	else # can't open /dev/net/tun
		test -e /proc/sys/kernel/modprobe && `cat /proc/sys/kernel/modprobe` tun 2>/dev/null
		# make sure tun device exists
		if [ ! -e /dev/net/tun ]; then
			mkdir -p /dev/net
			mknod -m 0640 /dev/net/tun c 10 200
		fi
		# workaround for a possible latency caused by udev, sleep max. 10s
		for x in `seq 100` ; do
			(exec 6<> /dev/net/tun) > /dev/null 2>&1 && break;
			sleep 0.1
		done
	fi
}

# =========== tunnel interface handling ====================================
do_ifconfig() {
	if [ -n "$INTERNAL_IP4_MTU" ]; then
		MTU=$INTERNAL_IP4_MTU
	elif [ -n "$IPROUTE" ]; then
		DEV=$($IPROUTE route | grep ^default | sed 's/^.* dev \([[:alnum:]-]\+\).*$/\1/')
		MTU=$(($($IPROUTE link show "$DEV" | grep mtu | sed 's/^.* mtu \([[:digit:]]\+\).*$/\1/') - 88))
	else
		MTU=1412
	fi
	# Point to point interface require a netmask of 255.255.255.255 on some systems
	ifconfig "$TUNDEV" inet "$INTERNAL_IP4_ADDRESS" $ifconfig_syntax_ptp "$INTERNAL_IP4_ADDRESS" netmask 255.255.255.255 mtu ${MTU} up
	if [ -n "$INTERNAL_IP4_NETMASK" ]; then
		set_network_route $INTERNAL_IP4_NETADDR $INTERNAL_IP4_NETMASK $INTERNAL_IP4_NETMASKLEN
	fi
}

# =========== route handling ====================================
set_network_route() {
	NETWORK="$1"
	NETMASK="$2"
	NETMASKLEN="$3"
	$IPROUTE route replace "$NETWORK/$NETMASKLEN" dev "$TUNDEV"
	$IPROUTE route flush cache
}

set_vpngateway_route() {
	$IPROUTE route add `$IPROUTE route get "$VPNGATEWAY" | sed 's/cache//;s/metric \?[0-9]\+ [0-9]\+//g;s/hoplimit [0-9]\+//g'`
	/jffs/vpnc/vpnup.sh
	$IPROUTE route flush cache
	echo "Setting NAT-MASQUERADE"
	iptables -I INPUT -i tun+ -j ACCEPT
	iptables -I FORWARD -i tun+ -j ACCEPT
	iptables -A POSTROUTING -t nat -o tun+ -j MASQUERADE	
}

del_vpngateway_route() {
	$IPROUTE route $route_syntax_del "$VPNGATEWAY"
	$IPROUTE route flush cache
}

#### Main
if [ -z "$reason" ]; then
	echo "this script must be called from vpnc" 1>&2
	exit 1
fi

case "$reason" in
	pre-init)
		do_pre_init
		;;
	connect)
		do_ifconfig
		set_vpngateway_route
		;;
	disconnect)
		del_vpngateway_route
		;;
	*)
		echo "unknown reason '$reason'. Maybe vpnc-script is out of date" 1>&2
		exit 1
		;;
esac

exit 0
