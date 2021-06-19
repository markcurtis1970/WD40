#!/usr/bin/env bash
#
# For checking endpoints connectivity

FQDN=$1
DELAY=1
PORT=443
REPEAT=10
SLEEP=0.5

ADDRS=$(nslookup $FQDN | grep "Address" | grep -v "#53" | awk '{print $2}')
echo -e "\n*** Checking $FQDN ***"
echo -e "IPs: \n$ADDRS"

for ADDR in $ADDRS
do 
    COUNT=0
    echo -e "\n*** Checking $ADDR ***"
    while [ $COUNT -lt $REPEAT ]
    do
       nc -n -v -w$DELAY -z $ADDR $PORT # Check IP
       COUNT=$(($COUNT + 1))
    done
done
