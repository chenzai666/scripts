#!/bin/bash
source /etc/init.d/functions
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
#永久关闭防火墙
disable_firewalld_selinux () {
	systemctl stop firewalld
    systemctl disable --now firewalld
    setenforce 0
    sed -i "s/^SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
}
#网卡更名为eth0
change_Centos_networkname(){
#cd /etc/sysconfig/network-scripts/
#x=0
#i=1
#for netCardName in `cat /proc/net/dev | awk '{i++; if(i>2){print$1}}' | sed 's/^[\t]*//g' | sed 's/[:]*$//g' | egrep -v "lo|docker"`;
#do
#	if [ -f ifcfg-${netCardName} ] && [ ! -f ifcfg-eth${x} ]; then
#		mv ifcfg-${netCardName} ifcfg-eth${x}
#		sed -i "s/${netCardName}/eth${x}/g" ifcfg-eth${x}
#		sed -i 's/ONBOOT=no/ONBOOT=yes/g' ifcfg-eth${x}
#	fi
#done
# 获取所有网卡接口
#interfaces=$(ip link show | awk -F':' '/^[0-9]+/{print $2}' | egrep -v "lo|docker")
# 定义接口计数器 
#count=0
# 遍历所有接口
#for interface in $interfaces; do
  # 获取接口MAC地址
#  mac=$(ip link show $interface | awk '/link\/ether/ {print $2}')  
  # 生成新的接口名  
#  new_name="eth"$count
  # 重命名接口
#  ip link set $interface name $new_name
  # 将规则写入配置文件
#  echo "SUBSYSTEM=="net", ACTION=="add", ATTR{address}=="$mac", NAME="$new_name"" >> /etc/udev/rules.d/75-network.rules
  # 计数器加1
#  count=$((count+1)) 
#done
# 重载规则
#udevadm control --reload-rules
cat >> /etc/default/grub << EOF
GRUB_CMDLINE_LINUX="crashkernel=auto rhgb quiet net.ifnames=0 biosdevname=0"
EOF
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /etc/sysconfig/network-scripts/
mv ifcfg-ens192 ifcfg-eth0
sed -i 's/ens192/eth0/g' ifcfg-eth0
systemctl restart network
}


#配置邮箱告警
set_postfix(){
source /etc/init.d/functions
rpm -q postfix mailx &> /dev/null ||yum -y install postfix mailx &> /dev/null
cat > /etc/mail.rc <<EOF
set from=18827262495@163.com
set smtp=smtp.163.com
set smtp-auth-user=18827262495@163.com
set smtp-auth-password=FNIYSDOEMBBMWXWR
EOF
systemctl restart postfix
if [ $? -eq 0 ];then
	green "postfix 服务重启成功!"
else
	red "postfix 服务重启失败!"
fi
echo  "init sucess" chenzai | mail -s " test" 18827262495@163.com
}

#设置 ssh 服务端口并开启 root 可以远程登录

set_ssh_port_rootlogin () {
	source /etc/init.d/functions
    read -p "请输入ssh端口号: " port
    cp -a /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
    echo Port $port >> /etc/ssh/sshd_config
    echo PermitRootLogin yes >> /etc/ssh/sshd_config
    systemctl restart sshd
    if [ $? -eq 0 ];then
        green "SSH 服务重启成功"
    else
        red "SSH 服务重启失败"
    fi
}

#制作光盘yum源和阿里云、epel源
#centos6配置yum源
centos6_make_yum_repo () {
cd /etc/yum.repos.d/
if [ -d /etc/yum.repos.d/bak ]; then
    red "bak 目录已存在!"
 else
    mkdir -p /etc/yum.repos.d/bak
	green "bak 目录已创建!"
fi
mv *.repo bak
curl -o /etc/yum.repos.d/CentOS-Base.repo https://mirrors.aliyun.com/repo/Centos-vault-6.10.repo
rpm -q epel-release &> /dev/null ||yum install -y epel-release &> /dev/null
#cat > local.repo << EOF
#[local]
#name=local repo
#baseurl=file:///iso
#enabled=1
#gpgcheck=0
#EOF
yum clean all
yum makecache fast
#if [ -d /iso ];then
#	echo "iso 目录已存在!"
# else
#	mkdir /iso
#	echo "iso 目录已创建!"
#fi
#mount /dev/sr0 /iso
#echo "/dev/sr0 /iso iso9660 defaults 0 0" >> /etc/fstab
}
#centos7配置yum源
centos7_make_yum_repo (){
cd /etc/yum.repos.d/
if [ -d /etc/yum.repos.d/bak ]; then
    red "bak 目录已存在!"
 else
    mkdir -p /etc/yum.repos.d/bak
	green "bak 目录已创建!"
fi
mv *.repo bak
curl -o /etc/yum.repos.d/CentOS-Base.repo https://repo.huaweicloud.com/repository/conf/CentOS-7-reg.repo 
rpm -q epel-release &> /dev/null || yum install -y epel-release &> /dev/null
#cat > local.repo << EOF
#[local]
#name=local repo
#baseurl=file:///iso
#enabled=1
#gpgcheck=0
#EOF
yum clean all
yum makecache fast
#if [ -d /iso ];then
#	echo "iso 目录已存在!"
# else
#	mkdir /iso
#	echo "iso 目录已创建!"
#fi
#mount /dev/sr0 /iso
#echo "/dev/sr0 /iso iso9660 defaults 0 0" >> /etc/fstab
}
#Rocky8配置yum源
Rocky8_make_yum_repo (){
sed -e 's|^mirrorlist=|#mirrorlist=|g' \
    -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
    -i.bak \
    /etc/yum.repos.d/Rocky-*.repo
#cat > local.repo << EOF
#[BaseOS]
#name=BaseOS
#baseurl=file:///iso/BaseOS
#enabled=1
#gpgcheck=0

#[AppStream]
#name=AppStream
#baseurl=file:///iso/AppStream
#enabled=1
#gpgcheck=0
#EOF
dnf clean all
dnf makecache fast
}
#Ubuntu18配置yum源
Ubuntu18_make_yum_repo (){
cat > /etc/apt/source.list << EOF
deb https://repo.huaweicloud.com/ubuntu/ bionic main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ bionic main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ bionic-security main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ bionic-security main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ bionic-updates main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ bionic-updates main restricted universe multiverse

# deb https://repo.huaweicloud.com/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src https://repo.huaweicloud.com/ubuntu/ bionic-proposed main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ bionic-backports main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ bionic-backports main restricted universe multiverse
EOF
}
#Ubuntu20配置yum源
Ubuntu20_make_yum_repo () {
cat > /etc/apt/source.list << EOF
deb https://repo.huaweicloud.com/ubuntu/ focal main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ focal main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ focal-security main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ focal-security main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ focal-updates main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ focal-updates main restricted universe multiverse

# deb https://repo.huaweicloud.com/ubuntu/ focal-proposed main restricted universe multiverse
# deb-src https://repo.huaweicloud.com/ubuntu/ focal-proposed main restricted universe multiverse

deb https://repo.huaweicloud.com/ubuntu/ focal-backports main restricted universe multiverse
deb-src https://repo.huaweicloud.com/ubuntu/ focal-backports main restricted universe multiverse
EOF
}

#修改提示符颜色
#cat >> /etc/profile.d/PS1.sh <<EOF
#PS1='\[\e[31;1m\][\u@\h \w]\$\[\e[0m\]'
#EOF
set_ps1 () {
    #echo "PS1='\[\e[32;1m\][\[\e[34;1m\]\u@\[\e[1;31m\]\h \[\e[1;33m\]\w \[\e[1;32m\]]\\$ \[\e[0m\]'" > /etc/profile.d/PS1.sh
    echo "PS1='\[\e[32;1m\][\[\e[34;1m\]\u@\[\e[1;31m\]\h \[\e[1;33m\]\w \[\e[1;32m\]]\\$ \[\e[0m\]'" >> /root/.bashrc
    echo "命令提示符优化完毕,请重新登录"
}
#安装常用软件
centos_install_package() {
package="vim curl lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip nfs-utils man-pages dos2unix nc telnet ntpdate bash-completion bash-completion-extras gcc make autoconf gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel htop git"
for i in $package
do
    rpm -q $i &>/dev/null || yum -q install -y $i
done
}
ubuntu_install_package() {
apt-get install -y vim curl tree net-tools wget iproute2 ntpdate tcpdump telnet traceroute nfs-kernel-server nfs-common lrzsz tree openssl libssl-dev libpcre3 libpcre3-dev zlib1g-dev gcc openssh-server iotop unzip zip bzip2 htop git
}

minimal_install() {
	OS_ID=`cat /etc/*-release | head -1 | grep -Eoi "(centos|ubuntu)"`
    if [ ${OS_ID} == "CentOS" ] &> /dev/null;then
        centos_install_package
    else
        ubuntu_install_package
    fi
}

#yum install vim lrzsz tree tmux lsof tcpdump wget net-tools iotop bc bzip2 zip unzip nfs-utils man-pages dos2unix nc telnet wget ntpdate bash-completion bash-completion-extras gcc make autoconf gcc-c++ glibc glibc-devel pcre pcre-devel openssl openssl-devel systemd-devel zlib-devel -y
#添加常用别名
set_alias(){
cat >> ~/.bashrc <<EOF
alias scandisk='echo - - - > /sys/class/scsi_host/host0/scan;echo - - - > /sys/class/scsi_host/host1/scan;echo - - - > /sys/class/scsi_host/host2/scan'
alias cdnet='cd /etc/sysconfig/network-scripts/'
alias cdrepo='cd /etc/yum.repos.d/'
EOF
}
#修改vim格式
set_vimrc(){
cat >> ~/.vimrc << EOF
set number
set ignorecase
set cursorline
set autoindent
set et
set ts=4
inoremap ( ()<ESC>i
inoremap [ []<ESC>i
inoremap { {}<ESC>i
inoremap < <><ESC>i
inoremap ' ''<ESC>i
inoremap " ""<ESC>i
autocmd BufNewFile *.sh exec ":call SetTitle()"
func SetTitle()
    if expand("%:e") == 'sh'
    call setline(1,"#!/bin/bash")
    call setline(2,"#********************************************************************")
    call setline(3,"#Name:          Bocchi")
    call setline(4,"#Date:          ".strftime("%Y-%m-%d"))
    call setline(5,"#FileName：     ".expand("%"))
    call setline(6,"#Description:   The test script")
    call setline(7,"#********************************************************************")
    call setline(8,"")
    endif
endfunc
autocmd BufNewFile * normal G
EOF
}
#配置Ubuntu的root登录
set_ubuntu_root(){
	source /etc/init.d/functions
	echo PermitRootLogin yes >> /etc/ssh/sshd_config
	/etc/init.d/ssh restart
	if [ $? -eq 0 ];then
		green "SSH 服务重启成功!"
	else
		red "SSH 服务重启失败!"
	fi
}

#禁用SWAP
set_swap(){
sed -i '/swap/s/^/#/' /etc/fstab
swapoff -a
}

#配置主机名
set_host_name(){
	read -p "请输入主机名: " name
	hostnamectl set-hostname $name
}

#centos6配置静态网络
centos6_setip(){
ipname=`ip link show | awk -F':' '/^[0-9]+/{print $2}' | egrep -v "lo|docker" | head -1`
ipdir="/etc/sysconfig/network-scripts"
cp -a $ipdir/ifcfg-$ipname $ipdir/ifcfg-$ipname.bak
read -p "请输入IP地址: " ip
read -p "请输入网关: " gateway
cat > $ipdir/ifcfg-$ipname << EOF
DEVICE=$ipname
TYPE=Ethernet
ONBOOT=yes
BOOTPROTO=static
IPADDR=$ip
PREFIX=23
GATEWAY=$gateway
DNS1=223.5.5.5
DNS2=8.8.8.8
EOF
service network restart
if [ $? -eq 0 ];then
	green "NETWORK 服务重启成功!"
else
	red "NETWORK 服务重启失败!"
fi
}

#centos7配置静态网络
centos7_setip(){
ipname=`ip link show | awk -F':' '/^[0-9]+/{print $2}' | egrep -v "lo|docker" | head -1`
ipdir="/etc/sysconfig/network-scripts"
cp -a $ipdir/ifcfg-$ipname $ipdir/ifcfg-$ipname.bak
read -p "请输入IP地址: " ip
read -p "请输入网关: " gateway
cat > $ipdir/ifcfg-$ipname << EOF
TYPE="Ethernet"
BOOTPROTO="static"
DEFROUTE="yes"
NAME="$ipname"
DEVICE="$ipname"
ONBOOT="yes"
IPADDR=$ip
PREFIX=23
GATEWAY=$gateway
DNS1=223.5.5.5
DNS2=8.8.8.8
EOF
systemctl restart network
if [ $? -eq 0 ];then
	green "NETWORK 服务重启成功!"
else
	red "NETWORK 服务重启失败!"
fi
}

#Ubuntu配置静态网络
Ubuntu_setip(){
ipname=`ip link show | awk -F':' '/^[0-9]+/{print $2}' | egrep -v "lo|docker" | head -1`
ipdir="/etc/netplan"
cp -a $ipdir/00-installer-config.yaml $ipdir/00-installer-config.yaml.bak
read -p "请输入IP地址: " ip
read -p "请输入网关: " gateway
cat > $ipdir/00-installer-config.yaml << EOF
network:
    ethernets:
        $ipname:
            addresses: [$ip/23]
            gateway4: $gateway
            dhcp4: false
            nameservers:
                    addresses: [223.6.6.6, 180.76.76.76]
                    search: [baidu.com]
            optional: true
    version: 2
EOF
netplan apply
if [ $? -eq 0 ];then
	green "NETWORK 服务重启成功!"
else
	red "NETWORK 服务重启失败!"
fi
}

Centos_neofetch(){
	#rpm -q dnf dnf-plugins-core &> /dev/null || sudo yum install -y dnf-plugins-core dnf
	#sudo dnf copr enable konimex/neofetch
    #sudo dnf install -y neofetch
    rpm -q epel-release &> /dev/null || sudo yum install epel-release
    curl -o /etc/yum.repos.d/konimex-neofetch-epel-7.repo https://copr.fedorainfracloud.org/coprs/konimex/neofetch/repo/epel-7/konimex-neofetch-epel-7.repo
    sudo yum install -y neofetch
    rpm -q ruby rubygems &> /dev/null || sudo yum install -y ruby rubygems
    wget https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip && cd  lolcat-master
    gem install lolcat && lolcat  --version
    rm -rf ~/master.zip
    rm -rf ~/lolcat-master
    grep "/usr/bin/neofetch | lolcat" /etc/profile
	if [ $? -eq 0 ];then
	  green "已添加到/etc/profile,如未成功请自行确认！"
	else
	  echo "/usr/bin/neofetch | lolcat" >> /etc/profile
	fi
}

Ubuntu_neofetch(){
    sudo apt-get update
    sudo apt-get install -y neofetch
    sudo apt-get install -y ruby gem
    wget https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip && cd  lolcat-master
    gem install lolcat && lolcat  --version
    rm -rf ~/master.zip
    rm -rf ~/lolcat-master
    grep "/usr/bin/neofetch | lolcat" /etc/profile
	if [ $? -eq 0 ];then
	  green "已添加到/etc/profile,如未成功请自行确认！"
	else
	  echo "/usr/bin/neofetch | lolcat" >> /etc/profile
	fi
}

Debian_neofetch(){
    sudo apt-get update
    sudo apt-get install -y neofetch
    sudo apt-get install -y ruby gem
    wget https://github.com/busyloop/lolcat/archive/master.zip
    unzip master.zip && cd  lolcat-master
    gem install lolcat && lolcat  --version
    rm -rf ~/master.zip
    rm -rf ~/lolcat-master
    grep "/usr/bin/neofetch | lolcat" /etc/profile
	if [ $? -eq 0 ];then
	  green "已添加到/etc/profile,如未成功请自行确认！"
	else
	  echo "/usr/bin/neofetch | lolcat" >> /etc/profile
	fi
}

Choice_change(){
    clear
     yellow " ================== "
     blue " 1.更换国内版仓库源"
     blue " 2.更换教育版仓库源"
     blue " 3.更换海外版仓库源"
	 yellow " ================== "
    echo
   read -p "请输入您的选项(1-3): " choice
clear
  case $choice in
  	1)
      Change_mirrors
      ;;
    2)
      Change_educate_mirrors
      ;;
    3)
      Change_overseas_mirrors
      ;;
    *)
      clear
	red "输入错误,请输入正确的数字!"
        start_menu
    sleep 2s
    start_menu
      ;;
  esac 
}

Change_mirrors(){
	bash <(curl -sSL https://linuxmirrors.cn/main.sh)
}

Change_educate_mirrors(){
	bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu 	
}

Change_overseas_mirrors(){
	bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
}


Install_Docker(){
	bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
}

start_menu(){
    clear
     yellow " ======================常规配置============================ "
     blue " 1.永久关闭防火墙"
     blue " 2. 网卡更名为eth0"
     blue " 3.配置邮箱告警"
     blue " 4.设置ssh服务和root远程登录"
     blue " 5.禁用SWAP"
     blue " 6.配置主机名"
	 blue " 7.修改vim格式"
	 blue " 8.修改提示符颜色"
	 blue " 9.配置Ububtu的root登录"
	 yellow " =====================修改ip和软件源相关=================== "
	 blue " 10.修改centos6静态ip "
	 blue " 11.修改centos7静态ip"
	 blue " 12.修改Ubuntu静态ip"
	 blue " 13.配置centos6的yum源仓库"
	 blue " 14.配置centos7的yum源仓库"
	 blue " 15.配置Rocky8的yum源仓库"
	 blue " 16.配置Ubuntu18的软件源仓库"
	 blue " 17.配置Ubuntu20的软件源仓库"
	 blue " 18.配置Centos的neofetch"
	 blue " 19.配置Ubuntu的neofetch"
	 blue " 20.配置Debian的neofetch"
	 blue " 21.建议安装软件包"
	 blue " 22.一键更换仓库源"
	 blue " 23.一键安装docker"
	 yellow " ========================================================== "
     red " 0. 退出脚本"
    echo
    read -p "请输入数字:" num
clear
case $num in
1)
	disable_firewalld_selinux
	green "防火墙已永久关闭!"
	;;
2)
	change_Centos_networkname
	green "网卡名已修改,请重启!"
	;;
3)
	set_postfix
	green "邮箱告警已配置!"
	;;
4)
	set_ssh_port_rootlogin
	green "SSH 端口和root远程登录已配置成功！"
	;;
5)
	set_swap
	green "swap已禁用成功!"
	;;
6)
	set_host_name
	green "主机名已设置成功!"
	;;
7)
	set_vimrc
	green "vimrc已配置成功!"
	;;
8)
	set_ps1
	green "PS1颜色已设置,请重新登录终端!"
	;;
9)
	set_ubuntu_root
	green "Ubuntu的root远程登录已配置成功!"
	;;
10)
	centos6_setip
	green "centos6静态IP已配置!"
	;;
11)
	centos7_setip
	green "centos7静态IP已配置!"
	;;
12)
	Ubuntu_setip
	green "Ubuntu静态IP已配置"
	;;
13)
	centos6_make_yum_repo
	green "centos6的yum仓库源已配置!"
	;;
14)
	centos7_make_yum_repo
	green "centos7的yum仓库源已配置!"
	;;
15)
	Rocky8_make_yum_repo
	green "Rocky8的yum仓库源已配置!"
	;;
16)
	Ubuntu18_make_yum_repo
	green "Ubuntu18的yum仓库源已配置!"
	;;
17)
	Ubuntu20_make_yum_repo
	green "Ubuntu20的yum仓库源已配置!"
	;;
18)
	Centos_neofetch
	green "Centos的neofetch已配置!"
	;;
19)
	Ubuntu_neofetch
	green "Ubuntu的neofetch已配置!"
	;;
20)
	Debian_neofetch
	green "Debian的neofetch已配置!"
	;;
21)
    minimal_install
    green "建议安装软件包已安装完成!"
    ;;
22)
    Choice_change
    ;;
23)
    Install_Docker
    ;;
0)
	exit 0
	;;
*)
    clear
	red "输入错误,请输入正确的数字!"
        start_menu
    sleep 2s
    start_menu
    ;;
esac
}
start_menu

