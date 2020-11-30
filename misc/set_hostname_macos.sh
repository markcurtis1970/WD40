#!/usr/bin/env bash

# Sets your macbook hostname

function usage {
    echo "Usage: $0 <name>"
    echo "Example: $0 my-macbook"
}

# Check args
if [ $# -ne 1 ]; then
   usage
   exit
fi

NETNAME=$1

/usr/sbin/scutil --set HostName "$NETNAME"
/usr/sbin/scutil --set LocalHostName "$NETNAME"
