#!/usr/bin/env bash
#
# Triggers a JFR on this node

function usage {
    echo
    echo "Usage: $0 <start|dump|stop|check>"
    echo
    echo "Example: $0 start - starts a JFR for the running Cassandra process"
    echo
    exit
}

function check_java {
    JVM=$(/usr/bin/java -version 2>&1 | grep -A 1 '[openjdk|java] version' | awk 'NR==2 {print $1}') 
    echo "JVM type: $JVM"
    if [ "$JVM" == 'Java(TM)' ]; then
        echo "Oracle Java found... proceeding"
    else
        echo "Oracle java is currently the only JDK that supports JFR"
        exit
    fi
}

function check_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.check 
}

function start_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID VM.unlock_commercial_features
    sudo -u $CASSUSER $JCMD $CASSPID JFR.start name=$JFRNAME settings=profile duration="$DURATION"s
}

function stop_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.stop name=$JFRNAME
}

function dump_jfr {
    sudo -u $CASSUSER $JCMD $CASSPID JFR.dump name=$JFRNAME filename=$JFRFILE compress=true
}

if [ $# -ne 0 ]; then
    usage
    exit
fi

# Check / Set vars
if [ ! -n $TIMESTAMP ]; then
    echo "TIMESTAMP not set. Exiting"
    exit
elif [ ! -n $DURATION ]; then
    echo "DURATION not set. Exiting"
    exit
elif [ ! -n $BASE_DIR ]; then
    echo "BASE_DIR not set. Exiting"
    exit
elif [ ! -n $NODE ]; then
    echo "MODE not set. Exiting"
    exit
fi

INTERVAL=10
JFRNAME="$NODE-DSEJFR"
CASSPID=$(cat /run/dse/dse.pid)
CASSUSER="cassandra"
JFRFILE="$BASE_DIR/$TIMESTAMP-$NODE-$CASSPID.jfr"
JCMD=$(which jcmd)


# Check we have Oracle JDK
check_java
# Start JFR
start_jfr
# Wait for duration then dump / stop
sleep $DURATION
dump_jfr
stop_jfr
exit
