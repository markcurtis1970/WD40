# SSL scripts

If you need to generate SSL certs with Subject Alt Names (SAN) fields then these scripts might help you. 

## Config

Configure the `auto.ssl.conf.template` file for your SSL options. Configure the following fields in the script for general things like passwords, which template and conf file names you wish to use etc

```
PASS="datastax"
TEMPLATE="auto.ssl.conf.template"
WORKDIR="./$CLUSTER-ssl"
CONF="$WORKDIR/auto.$CLUSTER.ssl.conf"
```

## Runnning

Clone the repo and then make the necessary changes to `auto.ssl.conf.template`

Note if you leave these fields as is, the script will generate one DNS name and IP based on the local host.

```
[alt_names]
DNS.1 = HOSTNAME
IP.1 = IP_ADDR
```

If you fill them in then the literal values will be used

```
[alt_names]
DNS.1 = abc.123.com
DNS.2 = def.123.com
IP.1 = 129.168.0.1
IP.2 = 129.168.0.2
```

Run the script like so

```
$ ./auto.ssl.create.sh my_cluster
Generating a 2048 bit RSA private key
.......................................................................................................+++
............................+++
writing new private key to './my_cluster-ssl/auto.my_cluster.key.pem'
-----
Importing keystore ./my_cluster-ssl/auto.my_cluster.p12 to ./my_cluster-ssl/auto.my_cluster.jks...

Warning:
The JKS keystore uses a proprietary format. It is recommended to migrate to PKCS12 which is an industry standard format using "keytool -importkeystore -srckeystore ./my_cluster-ssl/auto.my_cluster.jks -destkeystore ./my_cluster-ssl/auto.my_cluster.jks -deststoretype pkcs12".

*** All files output into ./my_cluster-ssl ***
```

As the output mentions all output files go into the sub directory with the name of your cluster.


