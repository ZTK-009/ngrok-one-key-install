#!/bin/bash
#===============================================================================================
#   System Required:  CentOS Debian or Ubuntu (32bit/64bit)
#   Description:  Install Ngrok for CentOS Debian or Ubuntu
#   Author: Clang <admin@clangcn.com>
#   Intro:  http://clang.cn
#===============================================================================================
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
shell_run_start=`date "+%Y-%m-%d %H:%M:%S"`   #shell run start time
version="4.4"
program_download_url=https://raw.githubusercontent.com/clangcn/ngrok-one-key-install/master/latest/
x64_file=server_ngrokd_linux_amd64
x86_file=server_ngrokd_linux_386
md5sum_file=md5sum.md
program_init_download_url=https://raw.githubusercontent.com/clangcn/ngrok-one-key-install/master/ngrokd.init
str_install_shell=https://raw.githubusercontent.com/clangcn/ngrok-one-key-install/master/install_ngrok.sh
str_ngrok_dir="/usr/local/ngrok"
contact_us="http://koolshare.cn/forum-72-1.html"
function shell_update(){
    fun_clangcn "clear"
    echo "Check updates for shell..."
    remote_shell_version=`wget --no-check-certificate -qO- ${str_install_shell} | sed -n '/'^version'/p' | cut -d\" -f2`
    if [ ! -z ${remote_shell_version} ]; then
        if [[ "${version}" != "${remote_shell_version}" ]];then
            echo -e "${COLOR_GREEN}Found a new version,update now!!!${COLOR_END}"
            echo
            echo -n "Update shell ..."
            if ! wget --no-check-certificate -qO $0 ${str_install_shell}; then
                echo -e " [${COLOR_RED}failed${COLOR_END}]"
                echo
                exit 1
            else
                echo -e " [${COLOR_GREEN}OK${COLOR_END}]"
                echo
                echo -e "${COLOR_GREEN}Please Re-run${COLOR_END} ${COLOR_PINK}$0 ${action}${COLOR_END}"
                echo
                exit 1
            fi
            exit 1
        fi
    fi
}
function fun_clangcn(){
    local clear_flag=""
    clear_flag=$1
    if [[ ${clear_flag} == "clear" ]]; then
        clear
    fi
    echo ""
    echo "+------------------------------------------------------------+"
    echo "|         Ngrok for Linux Server, Written by Clang           |"
    echo "+------------------------------------------------------------+"
    echo "|     A tool to auto-compile & install Ngrok on Linux        |"
    echo "+------------------------------------------------------------+"
    echo "|         Intro: http://koolshare.cn/forum-72-1.html         |"
    echo "+------------------------------------------------------------+"
    echo ""
}
function fun_set_text_color(){
    COLOR_RED='\E[1;31m'
    COLOR_GREEN='\E[1;32m'
    COLOR_YELOW='\E[1;33m'
    COLOR_BLUE='\E[1;34m'
    COLOR_PINK='\E[1;35m'
    COLOR_PINKBACK_WHITEFONT='\033[45;37m'
    COLOR_GREEN_LIGHTNING='\033[32m \033[05m'
    COLOR_END='\E[0m'
}
# Check if user is root
function rootness(){
    if [[ $EUID -ne 0 ]]; then
        fun_clangcn
        echo "Error:This script must be run as root!" 1>&2
        exit 1
    fi
}
function get_char(){
    SAVEDSTTY=`stty -g`
    stty -echo
    stty cbreak
    dd if=/dev/tty bs=1 count=1 2> /dev/null
    stty -raw
    stty echo
    stty $SAVEDSTTY
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
function check_curl(){
    curl -V >/dev/null 2>&1
    if [[ $? -gt 1 ]] ;then
        echo " Run curl failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos curl ..."
            yum -y install curl curl-devel
        else
            echo " Install debian/ubuntu curl ..."
            apt-get update -y
            apt-get install -y curl
        fi
    fi
    echo $result
}
function check_md5sum(){
    md5sum --version >/dev/null 2>&1
    if [[ $? -gt 6 ]] ;then
        echo " Run md5sum failed"
    fi
    echo $result
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
function fun_set_ngrok_user_env(){
    str_single_user=""
    echo  -e "\033[33mSetting script environment, single-user or multi-user?\033[0m"
    read -p "(single-user please input: y,multi-user input: n,Default [Y]):" str_single_user
    case "${str_single_user}" in
    y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
    echo "You will set single-user!"
    str_single_user="y"
    ;;
    n|N|No|NO|no|nO)
    echo "You will set multi-user!"
    str_single_user="n"
    ;;
    *)
    echo "You will set single-user!"
    str_single_user="y"
    esac
    fun_set_ngrok_domain
}
function fun_set_ngrok_domain(){
    # Set ngrok domain
    NGROK_DOMAIN=""
    read -p "Please input domain for Ngrok(e.g.:ngrok.clang.cn):" NGROK_DOMAIN
    check_input
}
function fun_randstr(){
  index=0
  strRandomPass=""
  for i in {a..z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {A..Z}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {0..9}; do arr[index]=$i; index=`expr ${index} + 1`; done
  for i in {1..16}; do strRandomPass="$strRandomPass${arr[$RANDOM%$index]}"; done
  echo $strRandomPass
}
function fun_set_ngrok_pass(){
    # Set ngrok pass
    ngrokpass=`fun_randstr`
    read -p "Please input password for Ngrok(Default Password: ${ngrokpass}):" ngrok_pass
    if [ "${ngrok_pass}" = "" ]; then
        ngrok_pass="${ngrokpass}"
    fi
}
function check_input(){
    # check ngrok domain
    if [ "$NGROK_DOMAIN" = "" ]; then
        echo -e "Your input is empty,please input again..."
        fun_set_ngrok_domain
    else
        echo -e "Your domain: ${COLOR_PINKBACK_WHITEFONT} "${NGROK_DOMAIN}" ${COLOR_END}."
        fun_set_ngrok_pass
    fi
    # check ngrok pass
    if [ "$ngrok_pass" = "" ]; then
        echo -e "Your input is empty,please input again..."
        fun_set_ngrok_pass
    else
        echo -e "Your ngrok pass: ${COLOR_PINKBACK_WHITEFONT} "${ngrok_pass}" ${COLOR_END}."
        echo -e "${COLOR_GREEN_LIGHTNING}Press any key to start...or Press Ctrl+c to cancel${COLOR_END}"
        char=`get_char`
        pre_install
    fi
}
function fun_download_file(){
    [ ! -d ${str_ngrok_dir}/bin/ ] && mkdir -p ${str_ngrok_dir}/bin/
    program_file=""
    if [ "${Is_64bit}" == 'y' ] ; then
        program_file=${x64_file}
        if [ ! -s ${str_ngrok_dir}/bin/ngrokd ]; then
            if ! wget --no-check-certificate ${program_download_url}${program_file} -O ${str_ngrok_dir}/bin/ngrokd; then
                echo "Failed to download ${program_file} file!"
                exit 1
            fi
        fi
    else
        program_file=${x86_file}
        if [ ! -s ${str_ngrok_dir}/bin/ngrokd ]; then
            if ! wget --no-check-certificate ${program_download_url}${program_file} -O ${str_ngrok_dir}/bin/ngrokd; then
                echo "Failed to download ${program_file} file!"
                exit 1
            fi
        fi
    fi
    #check_curl
    #check_md5sum
    #md5_web=`curl -s ${program_download_url}${md5sum_file} | sed  -n "/${program_file}/p" | awk '{print $1}'`
    #local_md5=`md5sum ${str_ngrok_dir}/bin/ngrokd | awk '{print $1}'`
    #if [ "${local_md5}" != "${md5_web}" ]; then
    #    echo "md5sum not match,Failed to download ${program_file} file!"
    #    exit 1
    #fi
    [ ! -x ${str_ngrok_dir}/bin/ngrokd ] && chmod 755 ${str_ngrok_dir}/bin/ngrokd
}
function pre_install(){
    echo "Install ngrok,please wait..."
    echo "============== Install packs =============="
    if [ "${OS}" == 'CentOS' ]; then
        #yum -y update
        yum -y install net-tools openssl-devel psmisc wget vim curl curl-devel
    else
        apt-get update -y
        apt-get install -y wget build-essential mercurial curl vim psmisc openssl libcurl4-openssl-dev net-tools
    fi
    [ ! -d ${str_ngrok_dir}/bin/ ] && mkdir -p ${str_ngrok_dir}/bin/
    cd ${str_ngrok_dir}
    # Download ngrok file
    fun_download_file
    if [ -s ${str_ngrok_dir}/bin/ngrokd ]; then
        cd ${str_ngrok_dir}
        openssl genrsa -out rootCA.key 2048
        openssl req -x509 -new -nodes -key rootCA.key -subj "/CN=$NGROK_DOMAIN" -days 5000 -out rootCA.pem
        openssl genrsa -out server.key 2048
        openssl req -new -key server.key -subj "/CN=$NGROK_DOMAIN" -out server.csr
        openssl x509 -req -in server.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out server.crt -days 5000
        config_runshell_ngrok
        clear
        fun_clangcn
        echo "Install Ngrok completed! enjoy it."
        echo "========================================================================="
        echo "On key install Ngrok ${version} for Debian/Ubuntu/CentOS Linux Server"
        echo "========================================================================="
        echo ""
        echo "For more information please visit http://clang.cn/"
        echo ""
        echo -e "ngrok status manage: ${COLOR_PINKBACK_WHITEFONT}/etc/init.d/ngrokd${COLOR_END} {${COLOR_GREEN}start${COLOR_END}|${COLOR_PINK}stop${COLOR_END}|${COLOR_YELOW}restart${COLOR_END}|${COLOR_BLUE}config${COLOR_END}|${COLOR_RED}adduser${COLOR_END}|${COLOR_GREEN}info${COLOR_END}}"
        echo -e "Your Domain: ${COLOR_GREEN}${NGROK_DOMAIN}${COLOR_END}"
        echo -e "Ngrok password: ${COLOR_GREEN}${ngrok_pass}${COLOR_END}"
        echo -e "http_port: ${COLOR_GREEN}80${COLOR_END}"
        echo -e "https_port: ${COLOR_GREEN}443${COLOR_END}"
        echo -e "remote_port: ${COLOR_GREEN}4443${COLOR_END}"
        echo -e "Config file:   ${COLOR_GREEN}${str_ngrok_dir}/.ngrok_config.sh${COLOR_END}"
        echo ""
        /etc/init.d/ngrokd start
        echo "========================================================================="
        exit 0
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
    echo -e "Shell run time is ${COLOR_GREEN}${hour_distance} hour ${min_distance} min ${min_remainder} sec${COLOR_END}"
}
function config_runshell_ngrok(){
if [ "${str_single_user}" == 'y' ] ; then
cat > ${str_ngrok_dir}/.ngrok_config.sh <<EOF
#!/bin/bash
# -------------config START-------------
dns="${NGROK_DOMAIN}"
pass="${ngrok_pass}"
http_port=80
https_port=443
remote_port=4443
srtCRT=server.crt
strKey=server.key
loglevel="INFO"
SingleUser="y"
# -------------config END-------------
EOF
else
cat > ${str_ngrok_dir}/.ngrok_config.sh <<EOF
#!/bin/bash
# -------------config START-------------
dns="${NGROK_DOMAIN}"
pass="${ngrok_pass}"
http_port=80
https_port=443
remote_port=4443
srtCRT=server.crt
strKey=server.key
loglevel="INFO"
SingleUser="n"
# -------------config END-------------
EOF
fi 

if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/ngrokd; then
    echo "Failed to download ngrokd.init file!"
    exit 1
fi
[ ! -x ${str_ngrok_dir}/.ngrok_config.sh ] && chmod 500 ${str_ngrok_dir}/.ngrok_config.sh
[ ! -x /etc/init.d/ngrokd ] && chmod 755 /etc/init.d/ngrokd
if [ "${OS}" == 'CentOS' ]; then
    if [ -s /etc/init.d/ngrokd ]; then
        chmod +x /etc/init.d/ngrokd
        chkconfig --add ngrokd
    fi
else
    if [ -s /etc/init.d/ngrokd ]; then
        chmod +x /etc/init.d/ngrokd
        update-rc.d -f ngrokd defaults
        #sed -i 's/#TMPTIME=.*/TMPTIME=-1/' /etc/default/rcS
        #sed -i 's/TMPTIME=.*/TMPTIME=-1/' /etc/default/rcS
    fi
fi
[ -s /etc/init.d/ngrokd ] && ln -s /etc/init.d/ngrokd /usr/bin/ngrokd
}
function check_nano(){
    nano -V >/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run nano failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos nano ..."
            yum -y install nano
        else
            echo " Install debian/ubuntu nano ..."
            apt-get update -y
            apt-get install -y nano
        fi
    fi
    echo $result
}
function check_killall(){
    killall -V 2>/dev/null
    if [[ $? -gt 1 ]] ;then
        echo " Run killall failed"
        if [ "${OS}" == 'CentOS' ]; then
            echo " Install centos killall ..."
            yum -y install psmisc
        else
            echo " Install debian/ubuntu killall ..."
            apt-get update -y
            apt-get install -y psmisc
        fi
    fi
    echo $result
}
############################### uninstall function ##################################
function fun_install_ngrok(){
    fun_clangcn
    checkos
    check_centosversion
    check_os_bit
    disable_selinux
    if [ -s ${str_ngrok_dir}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "Ngrok is installed!"
    else
        fun_set_ngrok_user_env
    fi
}
function fun_configure_ngrok(){
    check_nano
    if [ -s ${str_ngrok_dir}/.ngrok_config.sh ]; then
        nano ${str_ngrok_dir}/.ngrok_config.sh
    else
        echo "Ngrok configuration file not found!"
    fi
}
function fun_uninstall_ngrok(){
    fun_clangcn
    if [ -s ${str_ngrok_dir}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "============== Uninstall Ngrok =============="
        save_config="n"
        echo  -e "\033[33mDo you want to keep the configuration file?\033[0m"
        read -p "(if you want please input: y,Default [no]):" save_config

        case "${save_config}" in
        y|Y|Yes|YES|yes|yES|yEs|YeS|yeS)
        echo ""
        echo "You will keep the configuration file!"
        save_config="y"
        ;;
        n|N|No|NO|no|nO)
        echo ""
        echo "You will NOT to keep the configuration file!"
        save_config="n"
        ;;
        *)
        echo ""
        echo "will NOT to keep the configuration file!"
        save_config="n"
        esac
        checkos
        /etc/init.d/ngrokd stop
        if [ "${OS}" == 'CentOS' ]; then
            chkconfig --del ngrokd
        else
            update-rc.d -f ngrokd remove
        fi
        rm -f /etc/init.d/ngrokd /usr/bin/ngrokd /var/run/ngrok_clang.pid /root/ngrok_install.log /root/ngrok_update.log
        if [ "${save_config}" == 'n' ]; then
            rm -fr ${str_ngrok_dir}
        else
            rm -fr ${str_ngrok_dir}/bin/ ${str_ngrok_dir}/ngrok.log ${str_ngrok_dir}/rootCA.* ${str_ngrok_dir}/server.*
        fi
        echo "Ngrok uninstall success!"
    else
        echo "Ngrok Not install!"
    fi
    echo ""
}
function fun_update_ngrok(){
    fun_clangcn
    if [ -s ${str_ngrok_dir}/bin/ngrokd ] && [ -s /etc/init.d/ngrokd ]; then
        echo "============== Update Ngrok =============="
        checkos
        check_centosversion
        check_os_bit
        remote_init_version=`wget --no-check-certificate -qO- ${program_init_download_url} | sed -n '/'^version'/p' | cut -d\" -f2`
        local_init_version=`sed -n '/'^version'/p' /etc/init.d/ngrokd | cut -d\" -f2`
        install_shell=${strPath}
        cd ${str_ngrok_dir}
        if [ ! -z ${remote_init_version} ];then
            if [[ "${local_init_version}" != "${remote_init_version}" ]];then
                echo "========== Update ngrokd /etc/init.d/ngrokd =========="
                if ! wget --no-check-certificate ${program_init_download_url} -O /etc/init.d/ngrokd; then
                    echo "Failed to download ngrokd.init file!"
                    exit 1
                else
                    echo -e "${COLOR_GREEN}/etc/init.d/ngrokd Update successfully !!!${COLOR_END}"
                fi
            fi
        fi
        [ ! -x /etc/init.d/ngrokd ] && chmod 755 /etc/init.d/ngrokd
        [ -s /etc/init.d/ngrokd ] && ln -s /etc/init.d/ngrokd /usr/bin/ngrokd
        [ ! -d ${str_ngrok_dir}/bin/ ] && mkdir -p ${str_ngrok_dir}/bin/
        ps -ef | grep -v grep | grep -i "${str_ngrok_dir}/bin/ngrokd" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            /etc/init.d/ngrokd stop
        else
            check_killall
            killall ngrokd
        fi
        rm -f ${str_ngrok_dir}/bin/ngrokd /var/run/ngrok_clang.pid /root/ngrok_install.log /root/ngrok_uninstall.log
        # Download ngrok file
        fun_download_file
        if [ "${OS}" == 'CentOS' ]; then
            if [ -s /etc/init.d/ngrokd ]; then
                chmod +x /etc/init.d/ngrokd
                chkconfig --add ngrokd
            fi
        else
            if [ -s /etc/init.d/ngrokd ]; then
                chmod +x /etc/init.d/ngrokd
                update-rc.d -f ngrokd defaults
            fi
        fi
        if [ -d /tmp/db-diskv/ng/ro/ ]; then
            mv /tmp/db-diskv/ ${str_ngrok_dir}/users/
        fi
        clear
        /etc/init.d/ngrokd start
        echo "Ngrok update success!"
    else
        echo "Ngrok Not install!"
    fi
    echo ""
}
clear
rootness
strPath=`pwd`
fun_set_text_color
action=$1
shell_update
[  -z $1 ]
case "$action" in
install)
    rm -f /root/ngrok_install.log
    fun_install_ngrok 2>&1 | tee /root/ngrok_install.log
    ;;
config)
    fun_configure_ngrok
    ;;
uninstall)
    fun_uninstall_ngrok 2>&1 | tee /root/ngrok_uninstall.log
    ;;
update)
    fun_update_ngrok 2>&1 | tee /root/ngrok_update.log
    ;;
*)
    fun_clangcn "clear"
    echo "Arguments error! [${action} ]"
    echo "Usage: `basename $0` {install|uninstall|update|config}"
    ;;
esac

