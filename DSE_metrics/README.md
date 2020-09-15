# DSE Perf diags

## Background

We needed metrics for a performance issue. We used nodetool sjk mxdump/mx to get these.
To facilitate this we created some scripts that are copied to the node and then executed locally

`run_all_diags_script.yml` - this is the ansible playbook that copies all the files to the nodes and then executes `run_all_diags.sh`

`set_query_metrics_debug.yml` - this is the ansible playbook that switches DEBUG on for Solr Queries. Left seperate as this generates a LOT of noise in the logs, so it make more sense to split this out and generate debug for less time than you're collecting metrics.

`stop_query_metrics_debug.yml` - ansible playbook to turn off the Solr Query DEBUG

`list_of_solr_cores` - a list of solr core names you wish to collect metrics for

`fetch_all_diag_output.yml` - ansible playbook to fetch back all diag output from your nodes

`jfr.sh` - triggers a JFR on the node

`query_metrics.sh` - triggers the Query Metrics collection on the node

`tpc_backpressure_metrics.sh` - triggers the TPC Metrics collection on the node

`run_all_diags.sh` - this is the main script which runs on each node and triggers the metrics collection, normally output to /tmp. Think of this like the main wrapper script that in turn triggers all metrics collection scripts, iostats collection and the JFR script.

You might wonder why not use ansible async? - because this triggers a python task on the nodes and cuts off the async task after a given time. Because we're running most metrics scripts for 10-20mins, this might be ok, but in case we want to run something longer we didnt want to keep too many spawned sessions of scripts running on a node after. So I decided to go with a wrapper script which runs the main script with nohup.

## Example

To start diag collection

```
ansible-playbook -i ./cluster_inventory --private-key ~/ssh_key run_all_diags_script.yml
```

To fetch diag collection

```
ansible-playbook -i ../cluster_inventory --private-key ~/ssh_key fetch_all_diag_output.yml
```

## Metrics in Astra / Ctool

We was using an Astra DB to upload metrics to. This is because we wanted to look at some _specific_ metrics and phases of them. Astra was ok but it proved too slow for uploding the data (free tier). For the sake of costs we built a 3 node openstack cluster. However I've left the Astra example in here in case someone finds it useful.

You'll need to use the `schema.cql` file to create the schema first.

Depending on which you want to use, set this variable in `db-query-metrics.py`

```
#db_name = "ASTRA"
db_name = "CLOUD"
```

### Astra

For this you'll need your secure connect bundle. 

`secure-connect-metrics.zip` - The Astra connection bundle to the DB

### CLOUD

You just need to edit the IP address contract points for your AWS/Azure/GCP cluster

You'll also need to edit your contact points in the function:

```
def connect_to_cloud():
    global cluster, session
    cluster = Cluster(['10.101.34.110', '10.101.36.134','10.101.35.186'])
    session = cluster.connect()
```

### Loading results

You may find you have a bunch of files to load, so a little one-liner might help. For example:

```
for file in $(find ~/Issues/Customer/tests -name "*query-metrics.out"); do f=$(basename $file); test=$(echo $f | cut -d\- -f1-4); node=$(echo $f | cut -d\- -f6); core=$(echo $f | cut -d\- -f7); ./db-query-metrics.py $file $node $core"_"$test; done
```
