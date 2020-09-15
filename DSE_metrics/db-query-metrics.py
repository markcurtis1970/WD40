#!/usr/bin/env python
from cassandra.cluster import Cluster
from cassandra.auth import PlainTextAuthProvider
import sys
import json
import time
import datetime
from progress.bar import Bar
from six.moves import queue
#db_name = "ASTRA"
db_name = "CLOUD"

# Check arguments
def usage():
    # (note 2 includes arg 0 which is this script!)
    if len(sys.argv) != 4:
        print "\n***",sys.argv[0], "***\n"
        print 'Incorrect number of arguments, please run script as follows:'
        print '\n'+str(sys.argv[0])+' <file> <node ip or name> <test run>'
        sys.exit(0)

# Check which DB
def connect():
  if db_name == "ASTRA":
      connect_to_astra()
  if db_name == "CLOUD":
      connect_to_cloud()

# Connect to Astra
def connect_to_astra():
    global cluster, session
    cloud_config= {
            'secure_connect_bundle': './secure-connect-metrics.zip'
    }
    auth_provider = PlainTextAuthProvider('user', 'password')
    cluster = Cluster(cloud=cloud_config, auth_provider=auth_provider)
    session = cluster.connect()

# Connect to Cloud
def connect_to_cloud():
    global cluster, session
    cluster = Cluster(['10.101.34.110', '10.101.36.134','10.101.35.186'])
    session = cluster.connect()

# Disconnect from DB
def disconnect():
    cluster.shutdown()

# Check json
def check_json(source_file):
  try:
    data = json.load(source_file)
  except ValueError as e:
    print('File does not seem to be correct json format')
    print e
    sys.exit(1)
  return data

# Setup vars / read files etc
def setup_env():
    global source, node_ip, test_run, data, futures, phases
    source = open (sys.argv[1],'r')
    data = check_json(source)
    node_ip = sys.argv[2]
    test_run = sys.argv[3]
    futures = queue.Queue(maxsize=300)
    phases = {}

# Update test summary
def update_test_name(node, test):
   for phase in phases:
       session.execute("INSERT INTO \"DSE\".query_metrics_test_summary (node, test_run, phase) VALUES (%s, %s, %s)", [node, test, str(phase)]) 

# Update test results
def update_test_results():
    # List of samples to iterate over
    samples = data.keys()
    # Counts
    sample_total = len(samples)
    sample_count = 0
    row_count = 0
    # Progress bar
    p_count = 0
    prog_bar = Bar('Uploading metric data...', max=sample_total)
    # Loop over sample times
    for sample in samples:
        prog_bar.next()
        row = {}
        metrics = data[sample]['beans']
        # Loop over metrics for each phase
        for metric in metrics:
            type = str(metric['modelerType']).split('$')[1]
            name = str(metric['name']).split(',')[4].split('=')[1]
            row["sample_time"]=sample
            row["node"] = node_ip
            row["phase"] = name
            phases[name] = 1 # used to keep track of metrics phase names
            row["test_run"] = test_run
            # Histograms have more values
            if type == 'JmxHistogram':
                row["count"] = metric['Count']
                row["min"] = metric['Min']
                row["max"] = metric['Max']
                row["recentvalues"] = metric['RecentValues']
                row["mean"] = metric['Mean']
                row["stddev"] = metric['StdDev']
                row["p50"] = metric['50thPercentile']
                row["p75"] = metric['75thPercentile']
                row["p95"] = metric['95thPercentile']
                row["p98"] = metric['98thPercentile']
                row["p99"] = metric['99thPercentile']
                row["p999"] = metric['999thPercentile']
            if type == 'JmxGauge':
                row["value"] = metric['Value']
            # Each row is a set of metrics for a given phase
            rows = json.dumps(row)
            insert = "INSERT INTO \"DSE\".query_metrics_by_test JSON '" + rows + "'"
            # Passes off to the async queue
            async_insert(insert)
            #time.sleep(0.005)
    prog_bar.finish()

# Allows a pause to the queue to clear
def clear_queue():
    while True:
        try:
            futures.get_nowait().result()
        except queue.Empty:
            break

# Adds inserts to the queue
def async_insert(insert):
    future = session.execute_async(insert)
    try:
        futures.put_nowait(future)
    except queue.Full:
        clear_queue()
        futures.put_nowait(future)

def main():
    usage()
    print('Reading metrics file and input args...')
    setup_env()
    print('Connecting to db...')
    connect()
    print('Updating test data in db...')
    update_test_results()
    print('Updating test summary in db...')
    update_test_name(node_ip, test_run)
    print('Clearing queue...')
    clear_queue()
    print('Closing connection...')
    disconnect()

if __name__ == "__main__":
    main()
