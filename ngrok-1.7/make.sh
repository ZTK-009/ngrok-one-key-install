#!/bin/bash
MD5='md5sum'
unamestr=`uname`

if [[ "$unamestr" == 'Darwin' ]]; then
        MD5='md5'
fi
function check_os_bit(){
    if [[ `getconf WORD_BIT` = '32' && `getconf LONG_BIT` = '64' ]] ; then
        Is_64bit='y'
    else
        Is_64bit='n'
    fi
}
check_os_bit
UPX=false
if hash upx 2>/dev/null; then
        UPX=true
fi
shpath=`pwd`
cd ${shpath}
OSES=(linux darwin windows freebsd)
ARCHS=(amd64 386)
for os in ${OSES[@]}; do
        for arch in ${ARCHS[@]}; do
                suffix=""
                if [ "$os" == "windows" ]
                then
                        suffix=".exe"
                fi
                env CGO_ENABLED=0 GOOS=$os GOARCH=$arch make release-server
                if [[ `getconf LONG_BIT` = '64' && "$arch" == "amd64" && "$os" == "linux" ]] ; then
                        mv ${shpath}/bin/ngrokd ${shpath}/bin/server_ngrokd_${os}_${arch}${suffix}
                elif [[ `getconf LONG_BIT` = '32' && "$arch" == "386" && "$os" == "linux" ]] ; then
                        mv ${shpath}/bin/ngrokd ${shpath}/bin/server_ngrokd_${os}_${arch}${suffix}
                else
                        mv ${shpath}/bin/${os}_${arch}/ngrokd${suffix} ${shpath}/bin/server_ngrokd_${os}_${arch}${suffix}
                fi
                env CGO_ENABLED=0 GOOS=$os GOARCH=$arch make release-client
                if [[ `getconf LONG_BIT` = '64' && "$arch" == "amd64" && "$os" == "linux" ]] ; then
                        mv ${shpath}/bin/ngrok ${shpath}/bin/client_ngrok_${os}_${arch}${suffix}
                elif [[ `getconf LONG_BIT` = '32' && "$arch" == "386" && "$os" == "linux" ]] ; then
                        mv ${shpath}/bin/ngrok ${shpath}/bin/client_ngrok_${os}_${arch}${suffix}
                else
                        mv ${shpath}/bin/${os}_${arch}/ngrok${suffix} ${shpath}/bin/client_ngrok_${os}_${arch}${suffix}
                fi
                rm -fr ${shpath}/bin/${os}_${arch}
                if $UPX; then upx -9 ${shpath}/bin/client_ngrok_${os}_${arch}${suffix} ${shpath}/bin/server_ngrokd_${os}_${arch}${suffix};fi
        done
done
# ARM
ARMS=(5 6 7)
for v in ${ARMS[@]}; do
        env GOGC=40 CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v make release-server
        mv ${shpath}/bin/linux_arm/ngrokd ${shpath}/bin/server_ngrokd_linux_arm$v
        env GOGC=40 CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=$v  make release-client
        mv ${shpath}/bin/linux_arm/ngrok ${shpath}/bin/client_ngrok_linux_arm$v
done
rm -fr ${shpath}/bin/linux_arm/
if $UPX; then upx -9 client_ngrok_linux_arm* server_ngrokd_linux_arm*;fi
rm -f ${shpath}/bin/go-bindata

