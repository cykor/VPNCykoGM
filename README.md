本项目是我对之前[VPNCyko项目](https://github.com/cykor/VPNCyko)的改写，使用VPNC连接Cisco IPSec服务器并采用[autoddvpn项目](https://code.google.com/p/autoddvpn/)提出的gracemode，另外加入了一个以前写的检查域名是否被墙及DNS污染的脚本。

本项目基于以下配置：

* 路由器：[华硕RT-N66U](http://www.asus.com/Networks/Wireless_Routers/RTN66U/)，我认为是目前可以刷Tomato的最好的路由器
* 固件：[Tomato by Shibby](http://tomato.groov.pl/)，目前使用的是[K26USB-1.28.RT-N5x-MIPSR2-102-AIO-64K.trx](http://tomato.groov.pl/download/K26RT-N/build5x-102-EN/Asus%20RT-N66u%2064k/)
* VPN：[@cosbeta](https://twitter.com/cosbeta)的[VPN服务](http://killwall.com)，60GB/月3台并发，服务器多、速度快，三年只要240元
* 宽带：我家用的是长城宽带…… 

##参考文档
* [\[BLT\]FQX的Blog](http://www.zhongguotese.net)，之前的VPNCyko项目赤裸裸抄袭了[这篇文章](http://www.zhongguotese.net/2012/a-bridge-to-home-theater-2.html)和其中的代码
* [@Paveo的blog](http://w3.owind.com)，作为一个Falcop用户，虽然买不起VIG，但是向你致敬
* [autoddvpn项目](https://code.google.com/p/autoddvpn/)，学习并改写了其中gracemode部分的代码，将gfwListGen.py修改为了本项目中的update.py，用于下载gfwlist并更新vpnup.sh
* [DNSPython](http://www.dnspython.org/)，运行update.py需要的库，本项目中的[dns目录](https://github.com/cykor/VPNCykoGM/tree/master/dns)就是DNSPython 1.10.0

##本项目实现了
* 开机自动连接Cisco IPSec服务器，效率比常见的OpenVPN高很多
* 通过修改vpnc连接配置文件，防止vpnc断线（暂时没有启用vpncwatch，昨天到今天早上12个小时没有断线）
* 抄袭[\[BLT\]FQX的Blog](http://www.zhongguotese.net)中的双路由表设置，家里的下载专用机（192.168.1.33）除了Google、IMDB等路线外不走VPN（避免耗费VPN流量和带来封账号风险）
* 使用[jimmyxu的chnroutes项目](https://github.com/jimmyxu/chnroutes)中提到的iproute2方案，几秒搞定gracemode的1000多条路由
* 使用[OpenDNS的DNSCrypt](http://www.opendns.com/technology/dnscrypt/)对抗DNS污染，仅将几个明显被DNS污染的域名用DNSCrypt解析

##通过ssh访问路由器
在Terminal中：

	ssh-keygen
	cat ~/.ssh/id_rsa.pub

将id_rsa.public中的内容拷贝到[路由器访问管理界面](http://192.168.1.1/admin-access.asp)的Authorized Keys中，之后在Terminal中：

	ssh root@192.168.1.1

就可以登陆路由器了。或者直接通过Telnet访问也可以。

##通过ssh登陆，安装opkg
	mkdir /jffs/opt
	mount -o bind /jffs/opt /opt 

将这上面这一行`mount -o bind /jffs/opt /opt`加到[路由器JFFS管理界面](http://192.168.1.1/admin-jffs2.asp)的Execute When Mounted中，这样路由器每次mount jffs的时候都会自动加载/opt

	cd /opt
	wget http://wl500g-repo.googlecode.com/svn/ipkg/entware_install.sh
	chmod +x ./entware_install.sh
	./entware_install.sh

##将本项目文件复制到路由器中
出于节省空间的考虑，这里使用curl而不是git获取项目文件：

	opkg install curl
	mkdir /jffs/vpnc
	cd /jffs/vpnc
	curl -kL https://github.com/cykor/VPNCykoGM/tarball/master | tar zx
	cd cykor-VPNCykoGM-xxxxxxx
	mv * ..
	
##安装python并更新vpnup.sh
如果路由器的Flash空间不够安装python，可以跳过本步，在OS X或者Linux下用项目中的update.py生成。根据网络速度，生成/更新一次可能要半个小时的时间。

	opkg install python
	cd /jffs/vpnc
	./update.py

本项目中的[update.py](https://github.com/cykor/VPNCykoGM/blob/master/update.py)修改自[autoddvpn项目](https://code.google.com/p/autoddvpn/)的gfwListGen.py，作用是自动下载最新版的gfwList并生成/更新vpnup.sh中的路由规则。

##安装DNSCrypt
[DNSCrypt](http://www.opendns.com/technology/dnscrypt/)原理很简单，通过建立一条到OpenDNS的SSL链路（443端口）进行域名解析，并在本地提供查询代理服务器（[entware](http://wl500g-repo.googlecode.com)中缺省配置是65053端口）。这样只要在DNSMasq中指定被污染的域名通过本地的DNSCrypt代理解析，就可以彻底摆脱53 UDP端口上的污染信息。

	opkg install dnscrypt-proxy

这样安装后DNSCrypt是会随路由器自动启动的，不过现在可以手工启动一下看看有没有问题：

	/opt/etc/init.d/S09dnscrypt-proxy start

如果有问题，首先确认与208.67.220.220链接不存在问题，另外编辑一下/opt/etc/init.d/S09dnscrypt-proxy，将ARGS这行改为这样应该就可以了：

	ARGS="--local-address=127.0.0.1:65053 --daemonize"   

##设置DNSMasq
不建议使用update.py生成的gfwdomains直接设置dnsmasq，这个文件包含了所有gfwList里面的域名，其中大多数域名并没有被污染，全部启用的话会影响CDN加速，降低DNS解析的效率。所以本项目中缺省使用运营商配置的DNS解析（观察一段如果有问题可以改用114DNS），apple相关域名通过中华电信DNS解析，只有Twiiter、Facebook等明确发现有DNS污染的网站才使用DNSCrypt解析。不过这样带来的问题是，由于OpenDNS的IP也可能被封锁，因此要待VPN链接建立后重启DNSCrypt进程才能解析，而且可能随着VPN链路的稳定性影响解析，好在dnsmasq本身有cache（本项目中设为2048条记录）。

具体需要做的就是将本项目中的[dnsmasq](https://github.com/cykor/VPNCykoGM/blob/master/dnsmasq)中的内容粘贴到[路由器DHCP/DNS管理界面](http://192.168.1.1/advanced-dhcpdns.asp)里面Dnsmasq Custom configuration中，勾选Use internal DNS和Prevent DNS-rebind attacks，保存设置即可。

##安装VPNC
首先安装vpnc：

	opkg install vpnc
	
通过opkg安装vpnc是没有vpnc-script的。本项目中的[script.sh](https://github.com/cykor/VPNCykoGM/blob/master/script.sh)是根据[nslu2的ipkg源](http://ipkg.nslu2-linux.org/feeds/optware/ddwrt/cross/stable/)里面vpnc_0.5.3-1_mipsel.ipk的vpnc-script精简和修改的，主要是去掉了与在路由器上运行无关的代码、修改resolve文件的部分，将设置缺省路由修改为调用vpnup.sh添加路由。请注意确保script.sh加上了可执行权限：

	chmod a+x script.sh

##配置IPSec VPN账号
根据本项目中的sample.conf修改新建配置文件，内容如下：

	IPSec gateway 服务器地址
	IPSec ID 服务商提供的组ID
	IPSec secret 服务商提供的组密码
	Xauth username 你的用户名
	Xauth password 你的密码
	DPD idle timeout (our side) 0		#关闭vpnc 5.x中有问题的DPD功能
	NAT Traversal Mode cisco-udp		#设置NAT穿越模式
	Script '/jffs/vpnc/script.sh'		#让vpnc调用script.sh作为vpnc-script

##最后的准备
在[路由器脚本管理界面](http://192.168.1.1/admin-scripts.asp)的WAN Up中加入

	vpnc /jffs/vpnc/sample.conf
	/opt/etc/init.d/S09dnscrypt-proxy restart

告诉路由器在外网链接建立后运行vpnc，并重启DNSCrypt进程。
虽然并不必要，但是现在 **重启路由器吧！** 享受大功告成的感觉！

##附1：关于双路由表的配置
本项目中双路由表是在script.sh中调用rtables.sh实现的，为路由器中设置了固定IP的192.168.1.33设置一张novpn的路由表。如果不需要这样的功能，在[script.sh](https://github.com/cykor/VPNCykoGM/blob/master/script.sh)中将下面这一行注释或删掉就可以了：

	-70-	/jffs/vpnc/rtables.sh

##附2：使用check.sh配置自己需要走VPN的域名
本项目中提供一个[check.sh](https://github.com/cykor/VPNCykoGM/blob/master/check.sh)脚本，使用起来很简单：

	cd /jffs/vpnc
	./check.sh xxx.com

这个脚本的作用是：

1. 通过比较缺省DNS和DNSCrypt返回的结果，检查一个无法访问的域名是否被污染。如果被污染了，则生成dnsmasq配置的建议，把这一行直接粘贴到[路由器DHCP/DNS管理界面](http://192.168.1.1/advanced-dhcpdns.asp)里面Dnsmasq Custom configuration中即可。之所以不自动添加，是因为有的时候不同DNS解析的结果不同，但都是正确的IP，这时需要肉眼判断一下再决定。

2. 根据DNSCrypt解析的结果，将访问这个域名的路由直接加入路由表，这样不需要重启路由器就可以访问了。 

3. 将访问这个域名的路由追加到vpnup.sh最后，这样下次路由器重启时也会自动添加这条路由。

4. 将域名加入[known_gfw_domains](https://github.com/cykor/VPNCykoGM/blob/master/known_gfw_domains)，下次运行[update.py](https://github.com/cykor/VPNCykoGM/blob/master/update.py)时会读取这个文件并补充路由规则。

##附3：vpnc-disconnect的问题
使用opkg安装vpnc后，在我的Tomato Shibby中是无法正常使用vpnc-disconnect的。不过只要将vpnc-disconnect脚本中的

	pid=/var/run/vpnc/pid

修改为

	pid=/var/run/vpnc.pid
	
即可。当然一般情况下是用不到vpnc-disconnect的。