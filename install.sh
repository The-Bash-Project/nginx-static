#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive

echo

read -p 'ENTER DOMAIN NAME WITHOUT WWW PREFIX (eg: mm.example.com) : ' DOMAIN

echo

read -p "CONTINUE INSTALLING NGINX ON $DOMAIN ? (TYPE 'Y' TO CONTINUE) : " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    # do dangerous stuff

echo

echo "STARTING INSTALLATION !"

echo

sleep 2

apt update
apt upgrade -y

apt install nginx -y

rm -rf /etc/nginx/sites-enabled/default

rm -rf /etc/nginx/sites-available/default

mkdir /var/www/$DOMAIN/

#set up nginx welcome files

cd /var/www/$DOMAIN/

wget https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/default-page/install.zip

unzip install.zip

#set up sever blocks

tee /etc/nginx/sites-available/$DOMAIN.conf > /dev/null <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  server_name $DOMAIN www.$DOMAIN;
  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

ln -s /etc/nginx/sites-available/$DOMAIN.conf /etc/nginx/sites-enabled/$DOMAIN.conf

#restart nginx
nginx -t

service nginx restart

#install certbot
add-apt-repository ppa:certbot/certbot -y

apt update -y

apt upgrade -y

apt install python-certbot-nginx -y


#issue new certs

certbot --register-unsafely-without-email --nginx certonly --agree-tos -d $DOMAIN,www.$DOMAIN

tee /etc/nginx/sites-available/$DOMAIN.conf > /dev/null <<EOF

# mattermost default port config

server {
     listen [::]:80;
     listen 80;

     server_name $DOMAIN www.$DOMAIN;

     return 301 https://$DOMAIN\$request_uri;
}

server {
     listen [::]:443 ssl;
     listen 443 ssl;

     server_name www.$DOMAIN;

     ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

     ssl_protocols TLSv1.2 TLSv1.3;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

     return 301 https://$DOMAIN\$request_uri;
}

server {
     listen [::]:443 ssl http2;
     listen 443 ssl http2;

     server_name $DOMAIN;

     ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

     ssl_protocols TLSv1.2 TLSv1.3;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    root /var/www/$DOMAIN;
    
    index index.html;

    }

EOF

#write out current crontab
crontab -l > renewcert

#echo new cron into cron file
echo "0 0,12 * * * certbot renew >/dev/null 2>&1" >> renewcert

#install new cron file
crontab renewcert
rm renewcert



#restart nginx
nginx -t
service nginx restart

fi

