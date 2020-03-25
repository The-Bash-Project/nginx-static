#!/bin/bash
DOMAIN=$(dig +short $1 A | sort -n )
AWS_SERVICE=$(curl -s https://checkip.amazonaws.com)

if [ "$DOMAIN" == "$AWS_SERVICE" ]
then
echo 
echo " ✔  A record validated for $1"
echo

DOMAIN_WWW=$(dig +short www.$1 CNAME | sort -n )

if [ "$DOMAIN_WWW" == "$1." ]
then
echo " ✔  WWW CNAME Validated for $1" 
echo
fi
fi