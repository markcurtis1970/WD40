#!/usr/bin/env bash

function usage {
   echo "Usage: $0 <cluster name>"
   echo "Example: $0 cluster1"
}

# Check arguments - you can pass only 1 or 2
if [ $# -ne 1 ]; then
   usage
   exit
fi

# Setup vars etc.
HOSTNAME=$(hostname)
IP=$(hostname -i)
CLUSTER=$1
PASS="nottelling"
TEMPLATE="auto.ssl.conf.template"
WORKDIR="./$CLUSTER-ssl"
CONF="$WORKDIR/auto.$CLUSTER.ssl.conf"

# Customise conf file
mkdir -p $WORKDIR
cp $TEMPLATE $CONF
sed -i "s/HOSTNAME/${HOSTNAME}/" $CONF
sed -i "s/IP_ADDR/${IP}/" $CONF

# Configure openssl files
openssl req -config $CONF -new -x509 -sha256 -newkey rsa:2048 -nodes -keyout $WORKDIR/auto.$CLUSTER.key.pem -out $WORKDIR/auto.$CLUSTER.cert.pem -days 365 -extensions req_ext
openssl pkcs12 -export -in $WORKDIR/auto.$CLUSTER.cert.pem -inkey $WORKDIR/auto.$CLUSTER.key.pem -out $WORKDIR/auto.$CLUSTER.p12 -password pass:$PASS -name $HOSTNAME
keytool -importkeystore -srckeystore $WORKDIR/auto.$CLUSTER.p12 -destkeystore $WORKDIR/auto.$CLUSTER.jks -srcstoretype PKCS12 -alias $HOSTNAME -srcstorepass $PASS -deststorepass $PASS

# Completion message
echo -e "\n*** All files output into $WORKDIR ***"


