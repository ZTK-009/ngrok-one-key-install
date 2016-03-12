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
echo "#######################################################################"
echo "# On key install Ngrok V3.0 for Debian/Ubuntu/CentOS Linux Server"
echo "# Intro: http://clang.cn/blog/"
echo "#"
echo "# Author: Clang <admin@clangcn.com>"
echo "# version:3.0"
echo "#######################################################################"
echo ""
}

# Check OS
function checkos(){
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OS=CentOS
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OS=Debian
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OS=Ubuntu
    else
        echo "Not support OS, Please reinstall OS and retry!"
        exit 1
    fi
}

# Get version
function getversion(){
    if [[ -s /etc/redhat-release ]];then
        grep -oE  "[0-9.]+" /etc/redhat-release
    else    
        grep -oE  "[0-9.]+" /etc/issue
    fi    
}

# CentOS version
function centosversion(){
    local code=$1
    local version="`getversion`"
    local main_ver=${version%%.*}
    if [ $main_ver == $code ];then
        return 0
    else
        return 1
    fi        
}

# Check OS bit
function check_os_bit(){
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}

function check_centosversion(){
if centosversion 5; then
    echo "Not support CentOS 5.x, please change to CentOS 6,7 or Debian or Ubuntu and try again."
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
        echo -e "\033[32m \033[05mPress any key to start...or Press Ctrl+c to cancel\033[0m"
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
    checkos
    check_centosversion
    check_os_bit
    disable_selinux
    fun_set_ngrok_domain
}

function pre_install(){
    echo "install ngrok,please wait..."
    if [ "${OS}" == 'CentOS' ]; then
        #yum -y update
        yum -y install unzip nano screen git net-tools zlib-devel openssl-devel perl hg cpio expat-devel gettext-devel curl curl-devel perl-ExtUtils-MakeMaker wget gcc gcc-c++
    else
        apt-get update -y
        apt-get install -y wget build-essential mercurial git nano screen curl openssl libcurl4-openssl-dev
    fi
    cd /usr/local/
    # rm -fr /usr/local/go/
    # Download shadowsocks chkconfig file
    if [ "${Is_64bit}" == 'y' ] ; then
        if [ ! -s /usr/local/go/bin/go ]; then
            git clone https://github.com/clangcn/go1.6.linux-amd64.git go
            if [ ! -s /usr/local/go/bin/go ]; then
                echo "Failed to download go1.6.linux-386 file!"
                exit 1
            fi
        fi
    else
        if [ ! -s /usr/local/go/bin/go ]; then
            git clone https://github.com/clangcn/go1.6.linux-386.git go
            if [ ! -s /usr/local/go/bin/go ]; then
                echo "Failed to download go1.6.linux-386 file!"
                exit 1
            fi
        fi
    fi
    rm -fr /usr/local/go/.git/
    rm -f /usr/bin/go /usr/bin/godoc /usr/bin/gofmt
    ln -s /usr/local/go/bin/* /usr/bin/
    go version
    cd /usr/local/
    git clone https://github.com/clangcn/ngrok-1.7.git ngrok
    export GOPATH=/usr/local/ngrok/
    cd ngrok
    openssl genrsa -out rootCA.key 2048
    openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
    openssl genrsa -out server.key 2048
    openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
    openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000
    rm -f assets/client/tls/ngrokroot.crt assets/server/tls/snakeoil.crt assets/server/tls/snakeoil.key
    cp rootCA.pem assets/client/tls/ngrokroot.crt
    cp server.crt assets/server/tls/snakeoil.crt
    cp server.key assets/server/tls/snakeoil.key
    if [ "${Is_64bit}" == 'y' ] ; then
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
        echo "Install Ngrok completed! enjoy it."
        echo "========================================================================="
        echo "On key install Ngrok V3.0 for Debian/Ubuntu/CentOS Linux Server"
        echo "========================================================================="
        echo ""
        echo "For more information please visit http://clang.cn/"
        echo ""
        echo -e "ngrok status manage: \033[45;37m/root/ngrok.sh\033[0m {\033[40;31mstart\033[0m|\033[40;32mstop\033[0m|\033[40;33mrestart\033[0m|\033[40;34mconfig\033[0m|\033[40;35madduser\033[0m|\033[40;36minfo\033[0m}"
        echo -e "Your Domain: \033[32m\033[01m${NGROK_DOMAIN}\033[0m"
        echo -e "Ngrok password: \033[32m\033[01m${ngrok_pass}\033[0m"
        echo -e "http_port: \033[32m\033[01m80\033[0m"
        echo -e "https_port: \033[32m\033[01m443\033[0m"
        echo -e "remote_port: \033[32m\033[01m4443\033[0m"
        echo -e "Config file:   \033[32m\033[01m/root/.ngrok_config.sh\033[0m"
        echo ""
        echo "========================================================================="
    else
        echo ""
        echo "Sorry,Failed to install Ngrok!"
        echo "You can download /root/ngrok_install.log from your server,and mail ngrok_install.log to me."
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
clear
fun_clangcn.com
rootness
rm -f /root/ngrok_install.log
fun_install_ngrok 2>&1 | tee /root/ngrok_install.log
exit 0
