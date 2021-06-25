# LogDNA - Auto view creation

I wanted to make a way of creating a view in LogDNA based on the pods runnning in my current Kubernetes cluster

## Outline

Run a script that checks for currently running pods and then creates / updates a view based on these

We implement this as a cronjob run on the cluster itself to periodically update the view

## Scripts

`check_pods_update_view.py` - this is the main script:

   - run `kubectl` to get running pod names
   - check current views configured
   - update view if exists or create new one with names of running hosts

`logdna-pod-view.yaml` - cronjob yaml file to run the job at regular intervals in kubernetes clsuter

`role.yaml` - addrelevant role bindings to allow the pod to run `kubectl` across relevant namespaces (you might need to alter this to update for other namespaces)

`Dockerfile` - dockerfile for image

## Configuring

First build the docker file. You will probablyneed a repo so the IKS cluster can pull the image

```
docker build -t quay.io/markcurtis1970/logdna_pod_view:latest .
```

Push to repo

```
docker push quay.io/markcurtis1970/logdna_pod_view
```

Create the cronjob and role binding

```
kubectl create -f logdna_pod_view.yaml
kubectl apply -f role.yaml
```

If you change the cronjob you can use

```
kubectl replace -f logdna_pod_view.yaml
```

## Monitoring

Cronjobs run as pods and they are ephermeral. Once completed you can still inspect the logs from them, by default you'll see up to 3 as they rotate away

```
$ kubectl get pods
NAME                               READY   STATUS      RESTARTS   AGE
logdna-pod-view-1622217360-6csl4   0/1     Completed   0          2m11s
logdna-pod-view-1622217420-npj4s   0/1     Completed   0          70s
logdna-pod-view-1622217480-dvdwq   0/1     Completed   0          20s
```
