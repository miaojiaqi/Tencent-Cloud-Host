#!/bin/bash
Elk_Dir=/application/elk
Es=elasticsearch
IP=$(hostname -I)
Es_Port=$(netstat -lntp|grep 19200|wc -l)
Kibana_Port=$(netstat -lntp|grep 15601|wc -l)

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


echo '------------------------install kibana-----------------------------------'
cd /server/tools  && tar xf kibana-7.2.0-linux-x86_64.tar.gz -C ${Elk_Dir}/
cd ${Elk_Dir}/  &&  mv kibana-7.2.0-linux-x86_64  kibana
chown -R elk:elk ${Elk_Dir}/

cat >/application/elk/kibana/config/kibana.yml<<'EOF'
server.port: 15601
server.host: "test"
kibana.index: ".kibana"
elasticsearch.hosts: ["http://test:19200"]
i18n.locale: "zh-CN"
EOF
sed -i "s@test@${IP}@g" /application/elk/kibana/config/kibana.yml


su - elk  <<EOF
nohup /application/elk/elasticsearch/bin/elasticsearch >>/dev/null 2>&1 &
nohup /application/elk/kibana/bin/kibana >>/dev/null 2>&1 &
EOF

if [ ${Es_Port}  -ne 0 ];then
    echo  "eastoc http://${IP}:19200"

fi

if [ ${Kibana_Port} -ne 0   ];then
   echo "kibana http://${IP}:15601
"
fi

