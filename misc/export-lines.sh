#!/bin/bash
#
# For exporting log lines from LogDNA's useful API, caters for V1 and V2 API, see: 
# https://docs.logdna.com/docs/export-lines
# https://docs.logdna.com/reference#export-v1

function usage {
    echo
    echo "Usage: $0 <service_key> <v1|v2>"
    echo
    exit
}

function feedback {
    echo "lines: $1 next start/page: $2"
}

function get_lines_v2 {
    # First line - no page id
    curl -s "$URL_V2?from=${TS_START}000&to=${TS_END}000" -u $KEY: > $TMP_FILE
    jq -c '.lines[]' $TMP_FILE | tee -a $EXPORT_FILE > /dev/null 2>&1
    pageid=$(jq .pagination_id exportTemp.json | sed 's/"//g')
    count=$(jq '.lines[] | ._account' $TMP_FILE | wc -l)
    feedback $count $pageid
    
    while [ $count -gt 9999 ]
    do
        curl -s "$URL?from=${TS_START}000&to=${TS_END}000&pagination_id=$pageid" -u $KEY: > $TMP_FILE
        jq -c '.lines[]' $TMP_FILE | tee -a $EXPORT_FILE > /dev/null 2>&1
        pageid=$(jq .pagination_id exportTemp.json | sed 's/"//g')
        count=$(jq '.lines[] | ._account' $TMP_FILE | wc -l)
        feedback $count $pageid
    done
}

function get_lines_v1 {
    # Calc each segment
    while [ $TS_START -lt $TS_END ]
    do
        TS_WINDOW=$(($TS_START + $TS_PARTITION)) # Sets the upper window size
        curl -s "$URL_V1?from=${TS_START}000&to=${TS_WINDOW}000" -u $KEY: > $TMP_FILE
        jq . $TMP_FILE | tee -a $EXPORT_FILE > /dev/null 2>&1
        count=$(cat $TMP_FILE | wc -l )
        feedback $count $TS_WINDOW # $TS_WINDOW is essentially the same value as the next $TS_START
        TS_START=$(($TS_START + $TS_PARTITION)) # We update the start here as we dont want to on the first run through
    done
}

# Check usage
if [ $# -ne 2 ]; then
   usage
fi

# Setup 
TMP_FILE=exportTemp.json
EXPORT_FILE=export.json
OFFSET=86400 # The total range you want to export (seconds)
TS_START=$(($(date +%s)-$OFFSET))
TS_END=$(date +%s) # Uses current date
TS_PARTITION=30 # Size of each window retrieved (v1 exports)
KEY=$1
URL_V1="https://api.logdna.com/v1/export"
URL_V2="https://api.logdna.com/v2/export"
APIVER=$2

# Run
cat /dev/null > $EXPORT_FILE
cat /dev/null > $TMP_FILE
if [ $APIVER = "v1" ]; then 
   echo -e "\nStarting V1 export for $URL_V1 for timestamp range $TS_START to $TS_END\n"
   get_lines_v1
elif [ $APIVER = "v2" ]; then
   echo -e "\nStarting V2 export for $URL_V2 for timestamp range $TS_START to $TS_END\n"
   get_lines_v2
else
   usage
fi
