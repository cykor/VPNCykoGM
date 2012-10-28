#nslookup domain and add its ip to ...
IP=$(nslookup $1 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")
TRUEIP=$(nslookup $1 8.8.4.4 | grep "Address 1: " | tail -n 1 | sed 's/^Address 1: //g' | grep -o "^[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}")

echo "Current DNS return: $IP"
echo "Google DNS return:  $TRUEIP"

echo "add server=/$1/8.8.4.4 to known_gfw_domains"
if [ $IP \!= $TRUEIP ]; then
	echo "add server=/$1/8.8.4.4 to gfwdomains"
fi

sed -i "1i#$1" test
sed -i "2iroute add $TRUEIP via \$VPNGW Metric 5" test
sed -i '3i\
' test
echo "added route to $TRUEIP"
