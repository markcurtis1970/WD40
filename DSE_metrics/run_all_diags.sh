#!/usr/bin/env bash
#
# wrapper script to run all metrics scripts
# 

# Echo usage
function usage {
    echo
    echo "Usage: $0 <path> <file with list of core names>"
    echo
    exit
}

# Check arguments
if [ $# -ne 2 ]; then
   usage
   exit
fi

# Set vars
export TIMESTAMP=$(date '+%Y-%m-%d_%H-%M-%S')
export DURATION=1200
export BASE_DIR="/tmp"
export NODE=$(hostname -i)
export LOCAL_DIR=$1
export CORES=$LOCAL_DIR/$2

# Launch iostat
nohup iostat -c -x -d -t 1 $DURATION > "$BASE_DIR/$TIMESTAMP-$NODE-iostat.out" &

# Launch query metrics scripts
while read CORE
do
    nohup $LOCAL_DIR/query_metrics.sh $CORE &
done < $CORES

# Launch JFR scripts
# These can grow large so
# left commented out
#
#nohup $LOCAL_DIR/jfr.sh &
