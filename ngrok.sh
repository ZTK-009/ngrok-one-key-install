#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=======================================================
#   System Required:  Debian or Ubuntu (32bit/64bit)
#   Description:  Manager for Ngrok, Written by Clang
#   Author: Clang <admin@clangcn.com>
#   Intro:  http://clangcn.com
#=======================================================

clear
function clang.cn(){
    echo "#############################################################"
    echo "#  Manager Ngrok for Debian or Ubuntu (32bit/64bit)"
    echo "#  Intro: http://clangcn.com"
    echo "#"
    echo "#  Author: Clang <admin@clangcn.com>"
    echo "#"
    echo "#############################################################"
    echo ""
}
clang.cn
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi
if [ ! -s /root/.ngrok_config.sh ]; then
    echo -e "Error: Ngrok config file \033[40;32m/root/.ngrok_config.sh\033[0m not found!!!"
    exit 1
fi


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

function fun_load_config(){
    . /root/.ngrok_config.sh
}

function stop_ngrok_clang(){
    fun_check_run
    if [ "$strRun" = "" ]; then
        echo "Ngrok is not running..."
    else
        echo "Stop Ngrok..."
        ngrok_screen_id=""
        for ngrok_screen_id in ${ngrok_screen[@]}; do
            screen -S "${ngrok_screen_id}" -X quit
        done
        echo "ngrok stop success!"
    fi
}

function start_ngrok_clang(){
    fun_check_run
    if [ "$strRun" = "" ]; then
        echo "Start Ngrok..."
        fun_load_config
        cd /usr/local/ngrok
        echo $PWD
        echo ./bin/ngrokd -domain="$dns" -httpAddr=":$http_port" -httpsAddr=":$https_port" -pass="$pass" -tlsCrt=$srtCRT -tlsKey=$strKey -tunnelAddr=":$remote_port"
        screen -dmS ngrok_clang ./bin/ngrokd -domain="$dns" -httpAddr=":$http_port" -httpsAddr=":$https_port" -pass="$pass" -tlsCrt=$srtCRT -tlsKey=$strKey -tunnelAddr=":$remote_port"
        echo -e "Please input \033[40;32mscreen -ls\033[0m view screen list."
        echo -e "Please input \033[40;32mscreen -r ngrok_clang\033[0m restore Ngrok screen."    
        echo -e "Screen window press \033[40;32mCtrl + A + D\033[0m change status Detached."
    else
        echo -e "Ngrok is running,screen session id is \033[40;32m${ngrok_screen[0]}\033[0m,sockname \033[40;32m${ngrok_screen_name[0]}\033[0m"
        echo -e "please input \033[40;32mscreen -r \"session_id\"\033[0m or \033[40;32mscreen -r \"sockname\"\033[0m restore Ngrok."
    fi
}

function restart_ngrok_clang(){
    stop_ngrok_clang
    start_ngrok_clang
}

function configure_ngrok_clang(){
    nano /root/.ngrok_config.sh
}

function fun_set_ngrok_subdomain(){
    # Set ngrok pass
    subdomain=""
    ddns=""
    dns=""
    echo "Please input subdomain for Ngrok(e.g.:dns1 dns2 dns3 dns4 dns5):"
    read -p "(subdomain number max five:):" subdomain
    check_input "ngrok_subdomain"
}

function fun_set_ngrok_username(){
    userName=""
    read -p "Please input UserName for Ngrok(e.g.:ZhangSan):" userName
    check_input "ngrok_username"
}

function fun_set_ngrok_authId(){
    strPass=`openssl rand -base64 12`
    echo "Please input the password (more than 8) of Ngrok authId:"
    read -p "(Default password: $strPass):" strPassword
    if [ "$strPassword" = "" ]; then
        strPassword=$strPass
    fi
    check_input "ngrok_authId"
}

function check_input(){
case $1 in
ngrok_subdomain ) (
    # check ngrok subdomain
    if [ "$subdomain" = "" ]; then
        echo -e "Your input is empty,please input again..."
        fun_set_ngrok_subdomain
    else
        ddns=(${subdomain})
        [ ! -z "${ddns[0]}" ] && subdns=\"${ddns[0]}\"
        [ ! -z "${ddns[1]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\"
        [ ! -z "${ddns[2]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\"
        [ ! -z "${ddns[3]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\"
        [ ! -z "${ddns[4]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\",\"${ddns[4]}\"
        fun_load_config
        [ ! -z "${ddns[0]}" ] && FQDN=\"${ddns[0]}.${dns}\"
        [ ! -z "${ddns[1]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\"
        [ ! -z "${ddns[2]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\"
        [ ! -z "${ddns[3]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\"
        [ ! -z "${ddns[4]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\",\"${ddns[4]}.${dns}\"
        echo -e "Your subdomain: \033[40;32m"${subdns}" \033[0m."
        fun_set_ngrok_username
    fi
);;
ngrok_username ) (
    # check ngrok userName
    if [ "$userName" = "" ]; then
        echo -e "Your input is empty,please input again..."
        fun_set_ngrok_username
    else
        echo -e "Your username: \033[40;32m"${userName}" \033[0m."
        fun_set_ngrok_authId
    fi
);;
ngrok_authId ) (
    # check ngrok authId
    if [ "${strPassword}" = "" ]; then
        echo -e "Your input is empty,please input again..."
        fun_set_ngrok_authId
    else
        echo -e "Your authId: \033[40;32m"${strPassword}" \033[0m."
        fun_adduser_command
    fi
);;
*) break;;
esac
}

function fun_check_run(){
    strRun=""
    ngrok_screen=""
    strRun=`netstat -ntl | grep ':4446'`
    ngrok_screen=`screen -ls | grep 'ngrok_clang' | awk '{print $1}' | cut -d '.' -f 1`
    ngrok_screen_name=`screen -ls | grep 'ngrok_clang' | awk '{print $1}' | cut -d '.' -f 2`
}

function fun_adduser_command(){
    echo  curl -H \"Content-Type: application/json\" -H \"Auth:${pass}\" -X POST -d \''{'\"userId\":\"${strPassword}\",\"authId\":\"${userName}\",\"dns\":[${subdns}]'}'\' http://localhost:4446/adduser >/root/.ngrok_adduser.sh
    chmod +x /root/.ngrok_adduser.sh
    . /root/.ngrok_adduser.sh
    rm -f /root/.ngrok_adduser.sh
    clear
    clang.cn
    echo -e "\033[40;32mUser list :\033[0m"
    curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:4446/info
    echo "#############################################################"
    echo -e  "Server:\033[40;32m${dns}\033[0m"
    echo -e  "Server Port:\033[40;32m${remote_port}\033[0m"
    echo -e  "userId:\033[40;32m${userName}\033[0m"
    echo -e  "authId:\033[40;32m${strPassword}\033[0m"
    echo -e  "Your Subdomain:\033[40;32m${FQDN}\033[0m"
    echo "#############################################################"
}

function adduser_ngrok_clang(){
    fun_check_run
    fun_load_config
    if [ "$strRun" = "" ]; then
        echo "Ngrok is not running..."
    else
        fun_load_config
        fun_set_ngrok_subdomain
    fi
}

function info_ngrok_clang(){
    fun_check_run
    if [ "$strRun" = "" ]; then
        echo "Ngrok is not running..."
    else
        fun_load_config
        curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:4446/info
    fi
}

# Initialization
action=$1
[  -z $1 ]
case "$action" in
start)
    start_ngrok_clang
    ;;
stop)
    stop_ngrok_clang
    ;;
restart)
    restart_ngrok_clang
    ;;
config)
    configure_ngrok_clang
    ;;
adduser)
    adduser_ngrok_clang
    ;;
info)
    info_ngrok_clang
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {start|stop|restart|config|adduser|info}"
    ;;
esac
