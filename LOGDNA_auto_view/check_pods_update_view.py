#!/usr/bin/env python3
#
# Grab running pod names from your k8s cluster
# then create or update a view with a given name
# so the view always represents only the running
# pods
#
# Works with env vars (default in brackets):
# NAMESPACE - kubernetes namespace (default)
# VIEW_NAME - view name (logdna_support_view)

import json
import os
import sys
import requests
import subprocess

# get any env vars to setup things
def setup():
    global namespace, view_name, category_name, endpoint_url, service_key
    namespace = os.environ.get('NAMESPACE', 'default')
    view_name = os.environ.get('VIEW_NAME', 'logdna-support-view')
    category_name = os.environ.get('CATEGORY_NAME', 'logdna-support')
    endpoint_url = os.environ.get('ENDPOINT_URL', 'https://api.logdna.com/v1/config/')
    service_key = os.environ.get('SERVICE_KEY','9999')

# deal with any response errors
def response_errors(resp):
    if resp.status_code != requests.codes.ok:
        print(resp.text)
        print(resp.request.url)
        sys.exit(0)

# get the names of running pods
def get_pods():
    global pods
    command = "kubectl get pods -n " + str(namespace) + " | grep -v \"NAME\" | awk '{print $1}'"
    output = subprocess.check_output(command, shell=True).decode(sys.stdout.encoding)
    pods = str(output).split('\n')

# construct the json body of the view
def construct_json():
   global view, view_json
   view = {"name":[], "hosts":[]}
   view["name"] = view_name
   view["category"] = [category_name]
   for pod in pods:
      if pod != "":
         view["hosts"].append(pod)
   view_json = json.dumps(view)

# check to see if the view already exists
def find_view():
   global reqd_view_id 
   view_headers = { 'content-type':'application/json','servicekey': service_key}
   view_resp = requests.get(endpoint_url + "view/", headers=view_headers)
   response_errors(view_resp)
   view_json = view_resp.json()
   for ret_views in view_json:
       if ret_views['name'] == view_name:
           reqd_view_id = ret_views['viewid']
       else:
           reqd_view_id = -1
   # for debugging - comment in 
   #print(view_resp.request.headers)
   #print(view_resp.request.url)
   #print(view_resp.text)

# create or update the view
def create_update_view():
   view_headers = { 'content-type':'application/json','servicekey': service_key}
   if reqd_view_id == -1:
       print("no views with name \"{}\" found, will create a new view.".format(view_name))
       view_resp = requests.post(endpoint_url + "view/", headers=view_headers, data=view_json)
       response_errors(view_resp)
   else: 
       print("found view \"{}\" with id {}, will update this view.".format(view_name, reqd_view_id))
       view_resp = requests.put( endpoint_url + "view/" + str(reqd_view_id), headers=view_headers, data=view_json)
       response_errors(view_resp)
   # for debugging - comment in
   #print(view_resp.request.headers)
   #print(view_resp.request.url)
   #print(view_resp.text)

def main():
    setup()
    get_pods()
    construct_json()
    find_view()
    create_update_view()

if __name__ == "__main__":
    main()
