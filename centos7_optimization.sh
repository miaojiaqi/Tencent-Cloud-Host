#!/bin/bash
source /etc/profile

echo "-----------------------create dir-------------------------------"
[ -d  /server ]      || mkdir -p /server/{tools,scripts}  
[ -d  /application ] || mkdir -p /application 
[ -d /backup ] ||  mkdir -p /backup 
[ -d /data ]   ||  mkdir -p /data 
echo '>>> create dir is ok'
echo "-------------stop firewadll and selinux-------------------------"

grep 'SELINUX=disabled' /etc/selinux/config || sed -i '/^SELINUX=/c SELINUX=disabled' /etc/selinux/config
systemctl stop firewalld
systemctl disable firewalld

grep '* - nofile 65535' /etc/security/limits.conf  || echo '* - nofile 65535 ' >>/etc/security/limits.conf


echo "-------------------config yum repo-------------------------------"
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo  >>/dev/null 2>&1
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo           >>/dev/bull 2>&1
echo '>>>config yum repo is ok'

echo "---------------------optimization sshd ------------------------------"
sed -i  '/GSSAPIAuthentication/c GSSAPIAuthentication  no'  /etc/ssh/sshd_config  
sed -i  '/#UseDNS/c UseDNS no'   /etc/ssh/sshd_config  
systemctl restart sshd
echo '>>> optimization sshd '

echo "------------------- install Software------------------------------"
yum install net-tools vim tree htop iftop \
iotop lrzsz sl wget unzip telnet nmap nc psmisc \
dos2unix bash-completion gcc -y >>/dev/null 2>&1
echo '>>> install software is ok'
