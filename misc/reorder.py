#!/usr/bin/env python3
import os
import sys
import yaml

# Check arguments
def usage():
    # (note 2 includes arg 0 which is this script!)
    if len(sys.argv) != 2:
        print ('Incorrect number of arguments, please run script as follows:')
        print ('\n'+str(sys.argv[0])+' <file to re-order>')
        sys.exit(0)

# Parse the file with pyyaml and then dump
# This should naturally reorder the file
def reorder():
    doc = open(sys.argv[1])
    data = yaml.load(doc)
    print (yaml.dump(data))

# Main function
def main():
    usage()
    reorder()

if __name__ == "__main__":
    main()
