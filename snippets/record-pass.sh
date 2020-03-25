#!/bin/bash

f="$1"

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

echo " $FQDN does not point to server's IP $AWS_SERVICE"

exit 1
fi

if [ "$DOMAIN_WWW" == "$FQDN" ]
then
echo
echo " ✔  WWW CNAME Validated for $FQDN" 
echo

else 
echo 
echo " ✗  Cannot valiate CNAME record for $FQDN"
echo
echo "WWW CNAME does not exist for $FQDN "
exit 1
fi
