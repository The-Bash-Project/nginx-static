#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive


echo deploying nginx for $1

sleep 3

apt update
apt upgrade -y

apt install nginx -y

mkdir /var/www/$1/

touch /var/www/$1/index.html

tee /etc/nginx/sites-available/$1.conf > /dev/null <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;
  root /var/www/nginx-auto;
  index index.html;
  server_name $1 www.$1;
  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

ln -s /etc/nginx/sites-available/$1.conf /etc/nginx/sites-enabled/$1.conf




