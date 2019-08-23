#!/bin/bash
App_Dir=/application
Server_Dir=/server/tools
IP=$(hostname -I)
[ -d ${App_Dir}    ] || mkdir -p ${App_Dir}
[ -d ${Server_Dir} ] || mkdir -p ${Server_Dir}
echo '----------------------------install GoAccess------------------------------'
cd ${Server_Dir}/  && wget https://tar.goaccess.io/goaccess-1.3.tar.gz
tar xf goaccess-1.3.tar.gz  -C ${App_Dir}
cd ${App_Dir}/goaccess-1.3/  &&  yum install -y gcc c++   GeoIP-devel && ./configure --enable-utf8 --enable-geoip=legacy
make && make install 

if [  $? -eq 0 ];then
   echo '>>>install GoAccess is ok'
fi

echo '---------------------------config goaccess.conf---------------------------'
cat >>/usr/local/etc/goaccess/goaccess.conf<<'EOF'
time-format %H:%M:%S
date-format %d/%b/%Y
log-format %h %^[%d:%t %^] "%r" %s %b "%R" "%u"
EOF

goaccess -a -d -f  /var/log/nginx/access.log  -p  /usr/local/etc/goaccess/goaccess.conf -o ${App_Dir}/index.html
if [ $? -eq 0 ];then
    echo '>>>config goaccess.conf is ok'
fi

echo '----------------------------config_nginx start_GoAccess--------------------'

cat >/etc/nginx/conf.d/goaccess.conf<<'EOF'
server {
       listen 8999;
	   server_name host_ip;
	   root code_dir/;
	   
	   location / {
	     index index.html;
	   }
}

EOF

sed -i  "s#host_ip#${IP}#g" /etc/nginx/conf.d/goaccess.conf
sed -i  "s#code_dir#${App_Dir}#g" /etc/nginx/conf.d/goaccess.conf

nginx -s reload
