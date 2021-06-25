#!/usr/bin/env python3
#
# Example of how to pull down a containers digest values
# For comparing against a kubectl describe output to get
# version, esp useful when they have a generic tag like "stable"
#
# Uses the LogDNA agent as an example here

import json
import os
import requests

# pull each page from public dockerhub until there's no more
def pull_from_dockerhub():
    next='https://registry.hub.docker.com/v2/repositories/logdna/logdna-agent/tags/?page=1'
    while next is not None:
        raw_page = requests.get(next)
        extract_info(raw_page)
        next = raw_page.json()['next']

# extract the json info and append to a dictionary
def extract_info(raw_page):
    raw_results = raw_page.json()
    results = raw_results['results']
    for result in results:
        res_data[result['name']] = result['images'][0]['digest']

# print each element with a reasonably nice format
def print_info():
    for key,value in res_data.items():
        print('{:30}{}'.format(key,value))

def main():
    global res_data
    res_data={}
    pull_from_dockerhub()
    print_info()

if __name__ == "__main__":
    main()
