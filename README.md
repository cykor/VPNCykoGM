本项目是我对之前VPNCyko项目的改写，使用VPNC连接Cisco IPSec服务器并采用[autoddvpn项目](https://code.google.com/p/autoddvpn/)提出的gracemode，另外加入了一个以前写的检查域名是否被墙及DNS污染的脚本。

本项目基于以下配置：

* 路由器：[华硕RT-N66U](http://www.asus.com/Networks/Wireless_Routers/RTN66U/)，我认为是目前可以刷Tomato的最好的路由器
* 固件：[Tomato by Shibby](http://tomato.groov.pl/)，目前使用的是[K26USB-1.28.RT-N5x-MIPSR2-102-AIO-64K.trx](http://tomato.groov.pl/download/K26RT-N/build5x-102-EN/Asus%20RT-N66u%2064k/)
* VPN：@cosbeta的[VPN服务](http://killwall.com)，60GB/月3台并发，服务器多、速度快，三年只要240元
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
* 最小化对dnsmasq配置的修改，目前仅将几个明显被DNS污染的域名用8.8.8.8解析

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

	vpnc /jffs/vpnc/sample.conf;

告诉路由器在外网链接建立后运行vpnc。
虽然并不必要，但是**现在重启路由器吧**！享受大功告成的感觉！

##附1：dnsmasq的设置
不太建议使用update.py生成的gfwdomains直接设置dnsmasq，这个文件包含了所有gfwList里面的域名，其中大多数域名并没有被污染，全部启用的话会降低DNS解析的效率。所以我缺省使用运营商配置的DNS解析（观察一段如果有问题就改用114DNS），apple相关域名通过中华电信DNS解析，只有Twiiter、Facebook等明确发现有DNS污染的网站才使用8.8.8.8解析。目前这样还没有发现什么问题，观察一段时间再决定是不是要应用[AntiDNSPoisoning](http://code.google.com/p/openwrt-gfw/wiki/AntiDNSPoisoning)。

具体设置很简单：将本项目中的[dnsmasq](https://github.com/cykor/VPNCykoGM/blob/master/dnsmasq)中的内容粘贴到[路由器DHCP/DNS管理界面](http://192.168.1.1/advanced-dhcpdns.asp)里面Dnsmasq Custom configuration中，勾选Use internal DNS和Prevent DNS-rebind attacks，保存设置即可。

##附2：vpnc-disconnect的问题
使用opkg安装vpnc后，在我的Tomato Shibby中是无法正常使用vpnc-disconnect的。不过只要将vpnc-disconnect脚本中的

	pid=/var/run/vpnc/pid

修改为

	pid=/var/run/vpnc.pid
	
即可。当然一般情况下是用不到vpnc-disconnect的。