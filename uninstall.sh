#!/bin/bash

#check root privileges
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    echo "Not running as root"
    exit
fi

export DEBIAN_FRONTEND=noninteractive

echo 

echo "NGINX SIMPLE UNINSTALL SCRIPT" 

echo 

read -p 'ENTER DOMAIN NAME WITHOUT WWW PREFIX (eg: mm.example.com) : ' DOMAIN

echo

read -p "CONTINUE UNINSTALLING NGINX ON $DOMAIN ? (TYPE 'Y' TO CONTINUE) : " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then

echo "STARTING UNINSTALLATION !"


#remove nginx

apt-get purge nginx nginx-common -y

#remove all SSL certs

rm -rf /etc/letsencrypt/live/$DOMAIN

rm -rf /etc/letsencrypt/renewal/$DOMAIN*

#remove the directory created

rm -rf /var/www/$DOMAIN

rm -- "$0"


fi




