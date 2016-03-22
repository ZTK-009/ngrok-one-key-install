#Ngrok服务器一键安装脚本【支持用户管理】（穿透DDNS）

##在此非常感谢[koolshare](http://koolshare.cn/forum-72-1.html)的[小宝](http://koolshare.cn/space-uid-2380.html)宝大对ngrok进行的二次开发，让我等可以用上非常好用的程序，同时感谢[woaihsw](http://koolshare.cn/space-uid-13735.html)在脚本制作中提供的帮助。

脚本是业余爱好，英文属于文盲，写的不好，不要笑话我，欢迎您批评指正。
安装平台：CentOS、Debian、Ubuntu。
Server
------

### Install

Debian / Ubuntu:

    apt-get -y install screen
    screen -S ngrok_install
    wget --no-check-certificate https://github.com/clangcn/ngrok-one-key-install/raw/master/ngrok_install.sh -O ngrok_install.sh
    chmod 500 ./ngrok_install.sh
    ./ngrok_install.sh

CentOS:

    yum -y install screen
    screen -S ngrok_install
    wget --no-check-certificate https://github.com/clangcn/ngrok-one-key-install/raw/master/ngrok_install.sh -O ngrok_install.sh
    chmod 500 ./ngrok_install.sh
    ./ngrok_install.sh

### 服务器管理

	Usage: ngrok.sh {start|stop|restart|config|adduser|deluser|userlist|info}
	Usage: ngrok.sh deluser {username}

### 开机启动
想增加开机自启动的，在/etc/rc.local文件中增加：

    /root/ngrok.sh start

