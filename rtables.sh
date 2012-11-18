#!/bin/sh
VPNGATEWAY=$(ifconfig $(ifconfig |grep tun | grep -Eo "tun([0-9.]+)" | cut -d: -f2) | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)

echo 'preparing rt_table ...'
mkdir /etc/iproute2
cp /jffs/vpnc/rt_tables /etc/iproute2/rt_tables

# echo 'routing 192.168.1.3(Xbox) for onlyvpn'
# ip rule add from 192.168.1.3 table onlyvpn
# ip route add $(nvram get wan_gateway_get) dev ppp0 proto kernel scope link src $(nvram get wan_ipaddr) table onlyvpn
# ip route add 192.168.1.0/24 dev br0 proto kernel scope link src 192.168.1.1 table onlyvpn
# ip route add default dev tun0 scope link table onlyvpn
# ip route add default via $VPNGATEWAY dev ppp0 table onlyvpn

echo 'routing 192.168.1.33(Cykor-PC) for novpn'
ip rule add from 192.168.1.33 table novpn
ip route add $(nvram get wan_gateway_get) dev ppp0 proto kernel scope link src $(nvram get wan_ipaddr) table novpn
ip route add 192.168.1.0/24 dev br0 proto kernel scope link src 192.168.1.1 table novpn
#IMDB
ip route add 72.21.206.80 dev tun0 scope link table novpn
ip route add 72.21.210.29 dev tun0 scope link table novpn
ip route add 207.171.166.22 dev tun0 scope link table novpn
#TVDB
ip route add 63.156.206.48 dev tun0 scope link table novpn
#Google
ip route add 74.125.129.0/24 dev tun0 scope link table novpn
#DropBox
ip route add 174.36.30.0/24 dev tun0 scope link table novpn
ip route add 184.73.0.0/16 dev tun0 scope link table novpn
ip route add 174.129.20/24 dev tun0 scope link table novpn
ip route add 75.101.159.0/24 dev tun0 scope link table novpn
ip route add 75.101.140.0/24 dev tun0 scope link table novpn
ip route add 174.36.51.41 dev tun0 scope link table novpn
#PirateBay
ip route add 194.71.107.15 dev tun0 scope link table novpn
#default
ip route add default via $(nvram get wan_gateway_get) dev ppp0 table novpn

echo 'route tables done.'
