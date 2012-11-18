#nslookup domain and add its ip to ...
VPNGATEWAY=$(ifconfig $(ifconfig |grep tun | grep -Eo "tun([0-9.]+)" | cut -d: -f2) | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)
IP=$(nslookup $1 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
TRUEIP=$(nslookup $1 127.0.0.1:65053 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

echo "Current DNS return: $IP"
echo "Google DNS return:  $TRUEIP"

if [ $IP \!= $TRUEIP ]; then
	echo "\n- please add server=/$1/127.0.0.1#65053 to dnsmasq\n"
fi

echo "adding $1 to known_gfw_domains for next time run update.py"
sed -i "1i$1\
" known_gfw_domains

echo "adding route append to vpnup.sh"
sed -i "s/^EOF/route append $TRUEIP via \$VPNGATEWAY metric 5\nEOF/" vpnup.sh

echo "append route to $TRUEIP immediately"
ip route append $TRUEIP via $VPNGATEWAY metric 5

echo "done."
