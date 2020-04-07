#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive

if [ -z "$1" ]
then

#user based 

echo

read -p 'Enter the domain name (FQDN) you want to install Nginx on: ' DOMAIN_INSTALL

echo

echo " ✓ Nginx-Auto will automatically provision SSL certificates for $DOMAIN_INSTALL and www.$DOMAIN_INSTALL"

echo

echo " ✓ Please make sure that $DOMAIN_INSTALL has an A record pointing to $(curl --silent http://checkip.amazonaws.com) "

echo 

echo " ✓ Please make sure that $DOMAIN_INSTALL has an WWW CNAME record pointing to $DOMAIN_INSTALL "

echo 

read -p " ? Proceed with Installtion ? (TYPE 'Y' TO CONTINUE) : " -n 1 -r

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

DOMAIN_WWW=$(dig +short www.$FQDN | tail -n1 )


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

if [ "$DOMAIN_WWW" == "$AWS_SERVICE" ]
then
echo
echo " ✓ WWW CNAME Validated for $FQDN" 
echo

else 
echo 
echo "   Cannot valiate CNAME record for $FQDN"
echo
echo " ✗ WWW CNAME does not exist for $FQDN "
echo

exit 1
fi

echo

echo " ✓ Starting Installtion "

echo

sleep 2

apt update

apt upgrade -y

apt install nginx -y

rm -rf /etc/nginx/sites-enabled/default

rm -rf /etc/nginx/sites-available/default

rm -rf /var/www/html

mkdir /var/www/$FQDN/

#set up nginx welcome files

cd /var/www/$FQDN/

wget https://raw.githubusercontent.com/The-Bash-Project/nginx-auto/master/default-page/install.zip

apt install unzip -y

unzip install.zip

#set up sever blocks

tee /etc/nginx/whitelist.conf > /dev/null <<EOF
deny all;
EOF


tee /etc/nginx/sites-available/$FQDN.conf > /dev/null <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  server_name $FQDN www.$FQDN;
  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

ln -s /etc/nginx/sites-available/$FQDN.conf /etc/nginx/sites-enabled/$FQDN.conf

#restart nginx
nginx -t

service nginx restart

#install certbot

#Required for Docker Setup
apt-get install software-properties-common
apt-get install gpg

add-apt-repository ppa:certbot/certbot -y

apt update -y

apt upgrade -y

apt install certbot python-certbot-nginx -y


#issue new certs

certbot --register-unsafely-without-email --nginx certonly --agree-tos -d $FQDN,www.$FQDN

#install PHP

apt install php-fpm -y


tee /etc/nginx/sites-available/$FQDN.conf > /dev/null <<EOF
server {
     listen [::]:80;
     listen 80;

     server_name $FQDN www.$FQDN;

     include /etc/nginx/whitelist.conf;

     return 301 https://$FQDN\$request_uri;
}

server {
     listen [::]:443 ssl;
     listen 443 ssl;

     server_name www.$FQDN;

     include /etc/nginx/whitelist.conf;

     ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;

     ssl_protocols TLSv1.2 TLSv1.3 ;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

     return 301 https://$FQDN\$request_uri;
}

server {
     listen [::]:443 ssl http2;
     listen 443 ssl http2;

     server_name $FQDN;
     
    include /etc/nginx/whitelist.conf;

     ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;

     ssl_protocols TLSv1.2 TLSv1.3 ;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    root /var/www/$FQDN;
    
    index index.html;
    
     location ~ \.php$ {
        try_files $uri =404;
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
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

echo "✓ Congratulations! Installation Successfull; Nginx live at https://$FQDN "

echo

else 
echo
echo "✗ Installation Aborted. Bye Bye !"
echo
fi

else

#command line exec

f=$1

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

DOMAIN_WWW=$(dig +short www.$FQDN | tail -n1 )


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

if [ "$DOMAIN_WWW" == "$AWS_SERVICE" ]
then
echo
echo " ✓ WWW CNAME Validated for $FQDN" 
echo

else 
echo 
echo "   Cannot valiate CNAME record for $FQDN"
echo
echo " ✗ WWW CNAME does not exist for $FQDN "
echo

exit 1
fi

echo

echo " ✓ Starting Installtion "

echo

sleep 2

sudo add-apt-repository ppa:ondrej/nginx -y

apt update

apt upgrade -y

apt install nginx -y

rm -rf /etc/nginx/sites-enabled/default

rm -rf /etc/nginx/sites-available/default

rm -rf /var/www/html

mkdir /var/www/$FQDN/

#set up nginx welcome files

cd /var/www/$FQDN/

wget https://raw.githubusercontent.com/chinyasuhail/nginx-auto/master/default-page/install.zip

apt install unzip -y

unzip install.zip

#set up sever blocks

tee /etc/nginx/sites-available/$FQDN.conf > /dev/null <<EOF
server {
  listen 80 default_server;
  listen [::]:80 default_server;

  server_name $FQDN www.$FQDN;
  location / {
    try_files $uri $uri/ =404;
  }
}
EOF

ln -s /etc/nginx/sites-available/$FQDN.conf /etc/nginx/sites-enabled/$FQDN.conf

#restart nginx
nginx -t

service nginx restart

#install certbot
add-apt-repository ppa:certbot/certbot -y

apt update -y

apt upgrade -y

apt install certbot python-certbot-nginx -y


#issue new certs

certbot --register-unsafely-without-email --nginx certonly --agree-tos -d $FQDN,www.$FQDN

tee /etc/nginx/sites-available/$FQDN.conf > /dev/null <<EOF
server {
     listen [::]:80;
     listen 80;

     server_name $FQDN www.$FQDN;

     return 301 https://$FQDN\$request_uri;
}

server {
     listen [::]:443 ssl;
     listen 443 ssl;

     server_name www.$FQDN;

     ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;

     ssl_protocols TLSv1.2 ;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

     return 301 https://$FQDN\$request_uri;
}

server {
     listen [::]:443 ssl http2;
     listen 443 ssl http2;

     server_name $FQDN;

     ssl_certificate /etc/letsencrypt/live/$FQDN/fullchain.pem;
     ssl_certificate_key /etc/letsencrypt/live/$FQDN/privkey.pem;

     ssl_protocols TLSv1.2 ;

     add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

    root /var/www/$FQDN;
    
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

echo "✓ Congratulations! Installation Successfull; Nginx live at https://$FQDN"
fi

