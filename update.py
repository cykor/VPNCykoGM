#!/usr/bin/env python

import urllib
import base64
import string
import dns
from dns import resolver
import re

gfwlist = 'http://autoproxy-gfwlist.googlecode.com/svn/trunk/gfwlist.txt'
oklist = ['flickr.com']
print "fetching gfwList ..."
d = urllib.urlopen(gfwlist).read()
data = base64.b64decode(d)
lines = string.split(data, "\n")
newlist = []

def isipaddr(hostname=''):
	pat = re.compile(r'[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
	if re.match(pat, hostname):
		return 0
	else:
		return -1

def getip(hostname=''):
	_ip = []
	if isipaddr(hostname) == 0:
		print hostname + " is IP address"
		_ip.append(hostname)
		return
	r = dns.resolver.get_default_resolver()
	r.nameservers=['8.8.8.8']
	try:
		answers = r.query(hostname, 'A')
		for rdata in answers:
			print rdata.address
			_ip.append(rdata.address)
	except dns.resolver.NoAnswer:
		print "no answer"

	if hostname.find("www.") != 0:
		hostname = "www."+hostname
		print "querying "+hostname
		try:
			answers = dns.resolver.query(hostname, 'A')
			for rdata in answers:
				print rdata.address
				_ip.append(rdata.address)
		except dns.resolver.NoAnswer:
			print "no answer"
		
	return list(set(_ip))

for l in lines:
		if len(l) == 0:
			continue
		if l[0] == "!":
			continue
		if l[0] == "|":
			continue
		if l[0] == "@":
			continue
		if l[0] == "[":
			continue
		if l.find('zh.wikipedia.org') == 0:
			continue
		l = string.replace(l, "||","").lstrip(".")
		# strip everything from "/" to the end
		if l.find("/") != -1:
			l = l[0:l.find("/")]
		if l.find("*") != -1:
			continue
		if l.find(".") == -1:
			continue
		if l in oklist:
			continue
		newlist.append(l)

#known_gfw_domains#
known_list = [ x.rstrip() for x in open('known_gfw_domains').readlines() ]
newlist.extend(known_list)
newlist = list(set(newlist))
newlist.sort()
ip = []
count=0
gfwdn = open('gfwdomains', 'wa')
for l in newlist:
	print l
	gfwdn.write('server=/'+l+'/8.8.8.8\n')
	try:
		myip = getip(l)
		ip+=myip
		count+=1
	except:
		continue
gfwdn.close()

iplist = list(set(ip))
iplist.sort()

subnetdir={}
for ip in iplist:
	(a,b,c,d) = string.split(ip, ".")
	subnet = a+"."+b+"."+c+".0"
	if subnetdir.has_key(subnet):
		subnetdir[subnet]+=1
	else:
		subnetdir[subnet]=1

msubnet=[]
for subnet in subnetdir.keys():
	if subnetdir[subnet]>1:
		msubnet.append(subnet)

ipaddrlist = []
for ip in iplist:
	(a,b,c,d) = string.split(ip, ".")
	_subnet = a+"."+b+"."+c+".0"
	if _subnet in msubnet:
		print "%s is in subnet %s" % (ip, _subnet)
	else:
		print "%s has no subnet available" % (ip)
		ipaddrlist.append(ip)

ipaddrlist.sort()
msubnet.sort()

print "[INFO] generating vpnup.sh ..."
upfile = open('vpnup.sh','wa')
# write head of vpnup.sh
upfile.write('#!/bin/sh\nVPNGATEWAY=$(ifconfig $(ifconfig |grep tun | grep -Eo "tun([0-9.]+)" | cut -d: -f2) | grep -Eo "P-t-P:([0-9.]+)" | cut -d: -f2)\necho "adding routes to " $VPNGATEWAY\nip -force -batch - <<EOF\n')
print "[INFO] generating routes ..."
# write ip -batch routes
cnt=0
for i in ipaddrlist:
	buff = "route add %s via $VPNGATEWAY metric 5" % i
	print buff
	upfile.write(buff+'\n')
	cnt+=1
for m in msubnet:
	buff = "route add %s/24 via $VPNGATEWAY metric 5" % m
	print buff
	upfile.write(buff+'\n')
	cnt+=1
print "[INFO] total %i routes generated" % cnt
# write 'EOF'
upfile.write('EOF\n')
upfile.close()
print "[INFO] ALL DONE"
