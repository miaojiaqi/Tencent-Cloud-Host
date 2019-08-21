#!/bin/bash
Elk_Dir=/application/elk
Es=elasticsearch
IP=$(hostname -I)
echo "----------------------- install java -------------------------------------"
yum install java -y >>/dev/null 2>&1

echo "------------------------create user group-------------------------------"
groupadd -g 888 elk
useradd -u 888 -g elk elk
mkdir -p ${Elk_Dir}
mkdir -p /data/elk/${Es}
mkdir -p /var/log/elk/${Es}

echo "----------------------- install elastic ----------------------------------"
cd /server/tools
tar  xf  elasticsearch-7.2.0-linux-x86_64.tar.gz -C ${Elk_Dir}/
cd  ${Elk_Dir} && mv  elasticsearch-7.2.0   ${Es}

echo "------------------------ config elastic.yml-------------------------------"
cat >${Elk_Dir}/${Es}/config/${Es}.yml<<'EOF'
node.name: test
path.data: /data/elk/elasticsearch 
path.logs: /var/log/elk/elasticsearch
network.host: 0.0.0.0
http.port: 19200
discovery.seed_hosts: ["test"]
cluster.initial_master_nodes: ["test"]
http.cors.enabled: true
http.cors.allow-origin: "*"
EOF
sed -i "s@test@${IP}@g" ${Elk_Dir}/${Es}/config/${Es}.yml

grep 'vm.max_map_count=655360' /etc/sysctl.conf  || echo 'vm.max_map_count=655360' >>/etc/sysctl.conf  && sysctl -p


cat >>/etc/security/limits.conf <<'EOF'
*   soft        nofile  65536
*   hard        nofile  131072  
*   soft        nproc   65536
*   hard        nproc   131072
EOF

grep 'elk soft nproc 65536' /etc/security/limits.d/20-nproc.conf ||  echo 'elk soft nproc 65536' >>/etc/security/limits.d/20-nproc.conf
echo "----------------------- chown elastic ----------------------------------"
chown -R elk:elk  ${Elk_Dir}
chown -R elk:elk  /data/elk/
chown -R elk:elk  /var/log/elk

