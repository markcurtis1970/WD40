#!/usr/bin/env bash
#
# This script will basically take a DSE or Cassandra yaml and attempt to strip out any
# comments, but leave behind any parameters that may, or may not be commented out

function usage {
    echo ""
    echo "Usage: $0 <file to parse>"
    echo ""
    exit 1
}

function parse {
    cat $INFILE | grep -E "^ *[a-zA-Z_\-]+:|^ *\- [/a-zA-Z_:]+|^ *# +[a-zA-Z_\-]+:|^ *# +\- [/a-zA-Z_:]+" | sed -E "s/^ *#|^ *# //g" > $OUTFILE
}

if [ $# -ne 1 ]; then
    usage
fi

INFILE=$1
OUTFILE=$1.no_comments
parse
echo "Output is in $OUTFILE"
