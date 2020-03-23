#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive

$1 = $domain

apt update
apt upgrade -y

apt install nginx -y

mkdir /var/www/nginx-auto/

tee /etc/nginx/sites-available/n-auto.conf > /dev/null <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/nginx-auto;
  index index.html;
  server_name $domain www.$domain;
  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

ln -s /etc/nginx/sites-available/n-auto.conf /etc/nginx/sites-enabled/n-auto.conf




