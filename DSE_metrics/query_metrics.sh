#!/usr/bin/env bash
#
# Collect Query metrics

function usage {
    echo
    echo "Usage: $0 <solr core>"
    echo
    echo "Example: ./$0 wiki.solr"
    echo
    exit
}

function reset_metrics {
    #Reset mBeans
    nodetool sjk mx -b "com.datastax.bdp:type=search,index=$CORE,name=QueryMetrics" -mc -op resetLatencies --quiet
}

function collect_query_metrics {
    echo "{" >> $METRICS
    for i in $(seq $COUNT); do
        TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
        echo "\"$TIMESTAMP\":" >> $METRICS
        nodetool sjk mxdump -q "com.datastax.bdp:type=metrics,scope=search,index=$CORE,metricType=QueryMetrics,*" >> $METRICS
        # Add comma to improve json format
        if [ $i -lt $COUNT ]; then
            echo "," >> $METRICS
        fi
    sleep $INTERVAL
    done
    echo "}" >> $METRICS
}

# Check usage
if [ $# -ne 1 ]; then
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
COUNT=$(( $DURATION / $INTERVAL ))
CORE=$1
METRICS="$BASE_DIR/$TIMESTAMP-$NODE-$CORE-query-metrics.out"

# Run
reset_metrics
collect_query_metrics
