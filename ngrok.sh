#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
#=======================================================
#   System Required:  CentOS/Debian/Ubuntu (32bit/64bit)
#   Description:  Manager for Ngrok, Written by Clang
#   Author: Clang <admin@clangcn.com>
#   Intro:  http://clangcn.com
#=======================================================
version="v4.0"
arg1=$1
arg2=$2

clear
function clang.cn(){
    echo ""
    echo "#############################################################"
    echo "#  Manager Ngrok ${version} for CentOS/Debian/Ubuntu (32bit/64bit)"
    echo "#  Intro: http://clangcn.com"
    echo "#"
    echo "#  Author: Clang <admin@clangcn.com>"
    echo "#"
    echo "#############################################################"
}
clang.cn
echo ""
# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use root to install lnmp"
    exit 1
fi
if [ ! -s /root/.ngrok_config.sh ]; then
    echo -e "Error: Ngrok config file \033[40;32m/root/.ngrok_config.sh\033[0m not found!!!"
    exit 1
fi
if [ ! -s /usr/local/ngrok/bin/ngrokd ]; then
    echo -e "Error: Ngrokd not found!!!Ngrok not install!!"
    echo -e "Please run \033[32m\033[01mwget --no-check-certificate https://github.com/clangcn/ngrok-one-key-install/raw/master/ngrok_install.sh && bash ./ngrok_install.sh\033[0m install ngrok."
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
    manage_port="4446"
    . /root/.ngrok_config.sh
}

function stop_ngrok_clang(){
    fun_check_run
    if [ "${str_Ngrok_PID}" = "" ]; then
        echo "Ngrok is not running..."
    else
        echo "Stop Ngrok(PID:${str_Ngrok_PID})..."
        killall ngrokd
        echo "Ngrok stop success!"
    fi
}

function start_ngrok_clang(){
    fun_check_run
    if [ "${str_Ngrok_PID}" = "" ]; then
        fun_check_port
        echo "Start Ngrok..."
        fun_load_config
        cd /usr/local/ngrok
        echo $PWD
        echo ./bin/ngrokd -domain=\"$dns\" -httpAddr=\":$http_port\" -httpsAddr=\":$https_port\" -pass=\"$pass\" -tlsCrt=$srtCRT -tlsKey=$strKey -tunnelAddr=\":$remote_port\"
        nohup ./bin/ngrokd -domain="$dns" -httpAddr=":$http_port" -httpsAddr=":$https_port" -pass="$pass" -tlsCrt="$srtCRT" -tlsKey="$strKey" -tunnelAddr=":$remote_port" > ${ngrok_log} 2>&1 &
        echo -e "Ngrok is running..."
        echo "read ${ngrok_log} for log"
    else
        echo -e "Ngrok is running, ngrokd ProcessID is\033[40;32m" ${str_Ngrok_PID}"\033[0m."
        echo "read ${ngrok_log} for log"
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
        [ -n "${ddns[0]}" ] && subdns=\"${ddns[0]}\"
        [ -n "${ddns[1]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\"
        [ -n "${ddns[2]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\"
        [ -n "${ddns[3]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\"
        [ -n "${ddns[4]}" ] && subdns=\"${ddns[0]}\",\"${ddns[1]}\",\"${ddns[2]}\",\"${ddns[3]}\",\"${ddns[4]}\"
        fun_load_config
        [ -n "${ddns[0]}" ] && FQDN=\"${ddns[0]}.${dns}\"
        [ -n "${ddns[1]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\"
        [ -n "${ddns[2]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\"
        [ -n "${ddns[3]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\"
        [ -n "${ddns[4]}" ] && FQDN=\"${ddns[0]}.${dns}\",\"${ddns[1]}.${dns}\",\"${ddns[2]}.${dns}\",\"${ddns[3]}.${dns}\",\"${ddns[4]}.${dns}\"
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
    # check run
    ngrok_log="ngrok.log"
    str_Ngrok_proc=""
    array_Ngrok_PID=""
    str_Ngrok_PID=""
    str_Ngrok_proc=`netstat -apn | grep "ngrokd" | awk '{print $7}'| cut -d '/' -f 1`
    array_Ngrok_PID=(${str_Ngrok_proc})
    str_Ngrok_PID="${array_Ngrok_PID[0]}"
}

function fun_check_port(){
    fun_load_config
    strHttpPort=""
    strHttpsPort=""
    strRemotePort=""
    strManPort=""
    strHttpPort=`netstat -ntl | grep ":${http_port}"`
    strHttpsPort=`netstat -ntl | grep ":${https_port}"`
    strRemotePort=`netstat -ntl | grep ":${remote_port}"`
    strManagePort=`netstat -ntl | grep ":${manage_port}"`
    if [ -n "${strHttpPort}" ] || [ -n "${strHttpsPort}" ] || [ -n "${strRemotePort}" ] || [ -n "${strManagePort}" ]; then
        [ -n "${strHttpPort}" ] && str_http_port="${http_port}"
        [ -n "${strHttpsPort}" ] && str_https_port="${https_port}"
        [ -n "${strRemotePort}" ] && str_remote_port="${remote_port}"
        [ -n "${strManagePort}" ] && str_manage_port="${manage_port}"
        echo "Error: Port ${str_http_port} ${str_https_port} ${str_remote_port} ${str_manage_port} is used,view relevant port:"
        [ -n "${strHttpPort}" ] && netstat -apn | grep ":${http_port}"
        [ -n "${strHttpsPort}" ] && netstat -apn | grep ":${https_port}"
        [ -n "${strRemotePort}" ] && netstat -apn | grep ":${remote_port}"
        [ -n "${strManagePort}" ] && netstat -apn | grep ":${manage_port}"
        exit 1
    fi
}

function fun_adduser_command(){
    echo  curl -H \"Content-Type: application/json\" -H \"Auth:${pass}\" -X POST -d \''{'\"userId\":\"${strPassword}\",\"authId\":\"${userName}\",\"dns\":[${subdns}]'}'\' http://localhost:${manage_port}/adduser >/root/.ngrok_adduser.sh
    chmod +x /root/.ngrok_adduser.sh
    . /root/.ngrok_adduser.sh
    rm -f /root/.ngrok_adduser.sh
    clear
    clang.cn
    echo -e "\033[40;32mUser list :\033[0m"
    curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:${manage_port}/info
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
    if [ "${str_Ngrok_PID}" = "" ]; then
        echo "Ngrok is not running..."
    else
        fun_load_config
        fun_set_ngrok_subdomain
    fi
}

function userlist_ngrok_clang(){
    echo -e "\033[32mNgrok user list:\033[0m"
    ls /tmp/db-diskv/ng/ro/ |cut -d ':' -f 2
}

function deluser_ngrok_clang(){
    if [ -z "${1}" ]; then
        strWantdeluser=""
        userlist_ngrok_clang
        echo ""
        read -p "Please input del username you want:" strWantdeluser
        if [ "${strWantdeluser}" = "" ]; then
            echo "Error: You must input username!!"
            exit 1
        else
            deluser_Confirm_clang "${strWantdeluser}"
        fi
    else
        deluser_Confirm_clang "${1}"
    fi
}

function deluser_Confirm_clang(){
    if [ -z "${1}" ]; then
        echo "Error: You must input username!!"
        exit 1
    else
        strDelUser="${1}"
        echo -e "You want del \033[32m${strDelUser}\033[0m!"
        read -p "(if you want please input: y,Default [no]):" strConfirmDel
        case "$strConfirmDel" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        echo ""
        strConfirmDel="y"
        ;;
        n|N|No|NO|no|nO)
        echo ""
        strConfirmDel="n"
        ;;
        *)
        echo ""
        strConfirmDel="n"
        esac
        if [ $strConfirmDel = "y" ]; then
            if [ -s "/tmp/db-diskv/ng/ro/ngrok:${strDelUser}" ]; then
                rm -f /tmp/db-diskv/ng/ro/ngrok:${strDelUser}
                echo -e "Delete user \033[32m${strDelUser}\033[0m ok!"
            else
                echo ""
                echo -e "Error: user \033[32m${strDelUser}\033[0m not found!"
            fi
        fi
    fi
}

function info_ngrok_clang(){
    fun_check_run
    if [ "${str_Ngrok_PID}" = "" ]; then
        echo "Ngrok is not running..."
    else
        fun_load_config
        curl -H "Content-Type: application/json" -H "Auth:${pass}" -X GET http://localhost:${manage_port}/info
    fi
}

# Initialization
[  -z ${arg1} ]
case "${arg1}" in
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
deluser)
    deluser_ngrok_clang ${arg2}
    ;;
userlist)
    userlist_ngrok_clang
    ;;
info)
    info_ngrok_clang
    ;;
*)
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {start|stop|restart|config|adduser|deluser|userlist|info}"
    echo "Usage: `basename $0` deluser {username}"
    ;;
esac
