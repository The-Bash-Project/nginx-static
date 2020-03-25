#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive

echo

read -p 'Enter the domain name (FQDN) you want to install Nginx on: ' DOMAIN_INSTALL

echo

echo " ✓ Nginx-Auto will automatically provision SSL certificates for $DOMAIN_INSTALL and www.$DOMAIN_INSTALL"

echo

echo " ✓ Please make sure that $DOMAIN_INSTALL has an A record pointing to $(curl --silent http://checkip.amazonaws.com) "

echo 

read -p " ? Does $DOMAIN_INSTALL have an A record pointing to $(curl --silent http://checkip.amazonaws.com) and a WWW CNAME record pointing to $DOMAIN_INSTALL ? (TYPE 'Y' TO CONTINUE) : " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
f="$DOMAIN_INSTALL"

## Remove protocol part of url  ##
f="${f#http://}"
f="${f#https://}"
f="${f#ftp://}"
f="${f#scp://}"
f="${f#scp://}"
f="${f#sftp://}"
f="${f#www.}"
## Remove username and/or username:password part of URL  ##
f="${f#*:*@}"
f="${f#*@}"
## Remove rest of urls ##
f=${f%%/*}
 
FQDN=$f

DOMAIN=$(dig +short $FQDN A | sort -n )

AWS_SERVICE=$(curl -s https://checkip.amazonaws.com)

DOMAIN_WWW=$(dig +short www.$FQDN CNAME | sort -n )


if [ "$DOMAIN" == "$AWS_SERVICE" ]
then
echo 
echo " ✓  A record validated for $FQDN"
echo 

else 
echo 
echo " ✗  Cannot valiate A record for $FQDN"
echo 

echo " ✗  $FQDN does not point to current server's IP $AWS_SERVICE"

echo 

exit 1
fi

if [ "$DOMAIN_WWW" == "$FQDN" ]
then
echo
echo " ✔  WWW CNAME Validated for $FQDN" 
echo

else 
echo 
echo "   Cannot valiate CNAME record for $FQDN"
echo
echo " ✗ WWW CNAME does not exist for $FQDN "
echo

exit 1
fi


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

apt install unzip -y

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

certbot --register-unsafely-without-email --nginx certonly --agree-tos -d $DOMAIN, www.$DOMAIN

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

service nginx restart

#ADDING GZIP COMPRESSION SETTINGS

tee /etc/nginx/conf.d/gzip.conf > /dev/null <<EOT
#GZIP SETTINGS

gzip_disable "msie6";
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
EOT

nginx -t
service nginx restart

echo

echo

echo "✓ Congratulations! Installation Successfull"

echo

fi

else 
echo
echo "✗ Installation Aborted. Bye Bye !"
echo
fi

