#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
shell_run_start=`date "+%Y-%m-%d %H:%M:%S"`   #shell run start time
# Check if user is root
function rootness(){
    if [[ $EUID -ne 0 ]]; then
       echo "Error:This script must be run as root!" 1>&2
       exit 1
    fi
}

get_char()
{
	SAVEDSTTY=`stty -g`
	stty -echo
	stty cbreak
	dd if=/dev/tty bs=1 count=1 2> /dev/null
	stty -raw
	stty echo
	stty $SAVEDSTTY
}

function fun_clangcn.com(){
echo ""
echo "#############################################################"
echo "# One click Install Ngrok"
echo "# Intro: http://clang.cn/blog/"
echo "#"
echo "# Author: Clang <admin@clangcn.com>"
echo "# version:1.0"
echo "#############################################################"
echo ""
}

# Check OS
function checkos(){
    if [ ! -z "`cat /etc/issue | grep bian`" ];then
        OS=Debian
    elif [ ! -z "`cat /etc/issue | grep Ubuntu`" ];then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Disable selinux
function disable_selinux(){
	if [ -s /etc/selinux/config ] && grep 'SELINUX=enforcing' /etc/selinux/config; then
	    sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
	    setenforce 0
	fi
}



function fun_set_ngrok_domain(){
	# Set ngrok domain
	NGROK_DOMAIN=""
    read -p "Please input domain for Ngrok(e.g.:ngrok.clang.cn):" NGROK_DOMAIN
	check_input
}

function fun_set_ngrok_pass(){
	# Set ngrok pass
	ngrok_pass=""
    read -p "Please input password for Ngrok:" ngrok_pass
}

function check_input(){
	# check ngrok domain
    if [ "$NGROK_DOMAIN" = "" ]; then
    	echo -e "Your input is empty,please input again..."
    	fun_set_ngrok_domain
    else
    	echo -e "Your domain: \033[41;37m "${NGROK_DOMAIN}" \033[0m."
    	fun_set_ngrok_pass
	fi
	# check ngrok pass
    if [ "$ngrok_pass" = "" ]; then
    	echo -e "Your input is empty,please input again..."
    	fun_set_ngrok_pass
    else
    	echo -e "Your ngrok pass: \033[41;37m "${ngrok_pass}" \033[0m."
    	echo -e "\033[32m \033[05mPress any key to start...\033[0m"
    	char=`get_char`
    	pre_install
	fi
}

function config_runshell_ngrok(){
cat > /root/.ngrok_config.sh <<EOF
#!/bin/bash
# -------------config START-------------
dns="${NGROK_DOMAIN}"
pass="${ngrok_pass}"
http_port=80
https_port=443
remote_port=4443
srtCRT=server.crt
strKey=server.key
# -------------config END-------------
EOF
wget http://soft.clang.cn/ngrok/ngrok.sh -O /root/ngrok.sh
chmod 500 /root/ngrok.sh /root/.ngrok_config.sh
}

function fun_install_ngrok(){
	clear
	fun_clangcn.com
	checkos
    rootness
    disable_selinux
    fun_set_ngrok_domain
}

function pre_install(){
	echo "install ngrok,please wait..."
	apt-get update -y
	apt-get install -y build-essential mercurial git nano screen curl openssl libcurl4-openssl-dev
	cd /root
	# Download shadowsocks chkconfig file
	if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        if [ ! -s /root/go1.6.linux-amd64.tar.gz ]; then
		    if ! wget http://www.golangtc.com/static/go/1.6/go1.6.linux-amd64.tar.gz; then
		        echo "Failed to download go1.6.linux-386.tar.gz file!"
		        exit 1
		    fi
		fi
		tar zxvf go1.6.linux-amd64.tar.gz
	else
        if [ ! -s /root/go1.6.linux-386.tar.gz ]; then
		    if ! wget http://www.golangtc.com/static/go/1.6/go1.6.linux-386.tar.gz; then
		        echo "Failed to download go1.6.linux-386.tar.gz file!"
		        exit 1
		    fi
		fi
		tar zxvf go1.6.linux-386.tar.gz
	fi
	mv go/ /usr/local/
	rm -f /usr/bin/go /usr/bin/godoc /usr/bin/gofmt
	ln -s /usr/local/go/bin/* /usr/bin/
	cd /usr/local/
	git clone https://github.com/koolshare/ngrok-1.7.git ngrok
	export GOPATH=/usr/local/ngrok/
	cd ngrok
	sed -i 's;code.google.com\/p\/log4go;github.com\/keepeye\/log4go;g' src/ngrok/log/logger.go
	openssl genrsa -out rootCA.key 2048
	openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
	openssl genrsa -out server.key 2048
	openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
	openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000
	rm -f assets/client/tls/ngrokroot.crt assets/server/tls/snakeoil.crt assets/server/tls/snakeoil.key
	cp rootCA.pem assets/client/tls/ngrokroot.crt
	cp server.crt assets/server/tls/snakeoil.crt
	cp server.key assets/server/tls/snakeoil.key
	cd /usr/local/ngrok/src/github.com/gorilla
	git clone https://github.com/gorilla/mux.git
	git clone https://github.com/gorilla/context.git
	cd /usr/local/ngrok/src/github.com/peterbourgon
	git clone https://github.com/peterbourgon/diskv.git
	cd /usr/local/ngrok/src/github.com/petar
	git clone https://github.com/petar/GoLLRB.git
	if [ `getconf WORD_BIT` = '32' ] && [ `getconf LONG_BIT` = '64' ] ; then
        cd /usr/local/go/src
		GOOS=linux GOARCH=amd64 ./make.bash
		cd /usr/local/ngrok/
        GOOS=linux GOARCH=amd64 make release-server
	else
        cd /usr/local/go/src
		GOOS=linux GOARCH=386 ./make.bash
		cd /usr/local/ngrok/
        GOOS=linux GOARCH=386 make release-server
	fi
    if [ -s /usr/local/ngrok/bin/ngrokd ]; then
		config_runshell_ngrok
		clear
		fun_clangcn.com
		echo "Congratulations, Ngrok install completed!"
		echo -e "Please run script \033[32m\033[01m/root/ngrok.sh\033[0m start ngrok."
        echo -e "Your Domain: \033[32m\033[01m${NGROK_DOMAIN}\033[0m"
        echo -e "Your Ngrok password: \033[32m\033[01m${ngrok_pass}\033[0m"
        echo -e "Default http_port:\033[32m\033[01m80\033[0m,https_port:\033[32m\033[01m443\033[0m,remote_port:\033[32m\033[01m4443\033[0m"
		echo "Welcome to visit:http://clang.cn/blog/"
	    echo "Enjoy it!"
	else
        echo ""
        echo "Shadowsocks install failed! please view $HOME/ngrok_install.log."
        exit 1
    fi

	shell_run_end=`date "+%Y-%m-%d %H:%M:%S"`   #shell run end time
	time_distance=$(expr $(date +%s -d "$shell_run_end") - $(date +%s -d "$shell_run_start"));
	hour_distance=$(expr ${time_distance} / 3600) ;
	hour_remainder=$(expr ${time_distance} % 3600) ;
	min_distance=$(expr ${hour_remainder} / 60) ;
	min_remainder=$(expr ${hour_remainder} % 60) ;
	echo -e "Shell run time is \033[32m \033[01m${hour_distance} hour ${min_distance} min ${min_remainder} sec\033[0m"
}
rm -f $HOME/ngrok_install.log
fun_install_ngrok 2>&1 | tee $HOME/ngrok_install.log
exit 0
