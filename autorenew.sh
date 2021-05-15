#!/bin/sh
random() {
  tr </dev/urandom -dc A-Za-z0-9 | head -c5
  echo
}

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
  ip64() {
    echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
  }
  echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}


gen_3proxy() {
  cat <<EOF
daemon
maxconn 1024
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
flush
auth none
users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})
$(awk -F "/" '{print "auth none\n" \
"allow " $1 "\n" \
"proxy -6 -n -a -p" $4 " -i" $3 " -e"$5"\n" \
"flush\n"}' ${WORKDATA})
EOF
}

gen_proxy_file_for_user() {
  cat >proxy.txt <<EOF
$(awk -F "/" '{print $3 ":" $4 ":" $1 ":" $2 }' ${WORKDATA})
EOF
}

upload_proxy() {
  local PASS=$(random)
  zip --password $PASS proxy.zip proxy.txt
  URL=$(curl -s --upload-file proxy.zip https://transfer.sh/proxy.zip)

  echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
  echo "Download zip archive from: ${URL}"
  echo "Password: ${PASS}"

}

install_jq() {
  wget -O jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
  chmod +x ./jq
  cp jq /usr/bin
}

upload_2file() {
  local PASS=$(random)
  JSON=$(curl -F "file=@proxy.txt" https://file.io)
  URL=$(echo "$JSON" | jq --raw-output '.link')

  echo "Proxy is ready! Format IP:PORT:LOGIN:PASS"
  echo "Download zip archive from: ${URL}"
  echo "Password: ${PASS}"
}

gen_data() {
  seq $FIRST_PORT $LAST_PORT | while read port; do
    echo "usr/pass/$IP4/$port/$(gen64 $IP6)"
  done
}

gen_iptables() {
  cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA})
EOF
}

gen_ifconfig() {
  cat <<EOF
$(awk -F "/" '{print "ifconfig eth0 inet6 add " $5 "/64"}' ${WORKDATA})
EOF
}

echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P1-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"




echo "working folder = /home/proxy-installer"
WORKDIR="/home/proxy-installer"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_


echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P2-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"

IP4=$(curl -4 -s icanhazip.com)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. Exteranl sub for ip6 = ${IP6}"


echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P3-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"


echo "Quel Port ? 10000"
read $FIRST_PORT

echo "How many proxy do you want to create? Example 500"
read COUNT



LAST_PORT=$(($FIRST_PORT + $COUNT))



echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P4-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"



gen_data >$WORKDIR/data.txt
gen_iptables >$WORKDIR/boot_iptables.sh
gen_ifconfig >$WORKDIR/boot_ifconfig.sh
chmod +x boot_*.sh /etc/rc.local



echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P5-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"



gen_3proxy >/usr/local/etc/3proxy/3proxy.cfg


rm -rf /home/proxy-installer/boot_iptables.sh
rm -rf /home/proxy-installer/boot_ifconfig.sh


echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P6-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"


cat >>/etc/rc.local <<EOF
bash ${WORKDIR}/boot_iptables.sh
bash ${WORKDIR}/boot_ifconfig.sh
ulimit -n 19048
service 3proxy start
EOF

echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P7-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"


bash /etc/rc.local



echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"
echo "----------P8-----------------"
echo "-----------------------------"
echo "-----------------------------"
echo "-----------------------------"


gen_proxy_file_for_user



