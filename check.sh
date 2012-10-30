#nslookup domain and add its ip to ...

sed -i "1i#$1\
' known_gfw_domains
echo "added $1 to known_gfw_domains"

IP=$(nslookup $1 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
echo "Current DNS returns: $IP"

TRUEIP=$(nslookup $1 8.8.4.4 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
echo "Google DNS returns:  $TRUEIP"

if [ $IP \!= $TRUEIP ]; then
	echo "[!] add server=/$1/8.8.8.8 to dnsmasq"
fi

