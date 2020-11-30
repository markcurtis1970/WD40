#!/usr/bin/env bash

# Creates a new k8s cluster
# ** Note **
# By default script will just echo out commands
# set DRY_RUN=false below to run commands

function usage {
    echo "Usage: $0 <name>"
    echo "Example: $0 my-k8s-cluster"
}

# Setup creds etc
function creds {
    export AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id)
    export AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key)
    export BUCKET_NAME="mykops-state-store"
    export KOPS_STATE_STORE="s3://$BUCKET_NAME"
    export SSH_KEY="/Users/mc/.ssh/mykops.pub"
}

# Create the s3 bucket
function create_bucket {
    if [ ${DRY_RUN} = "false" ]; then
        aws s3api create-bucket --bucket ${BUCKET_NAME} --region us-east-1
    else
       echo aws s3api create-bucket --bucket ${BUCKET_NAME} --region us-east-1
    fi
}

# Create cluster and validate
function create_cluster {
    if [ ${DRY_RUN} = "false" ]; then
        kops create cluster --ssh-public-key=${SSH_KEY} --zones ${REGION} --node-count=$NODE_COUNT --node-size=$NODE_SIZE --master-size=$NODE_SIZE ${NAME} --cloud-labels=$TAGS
        kops edit ig --name=${NAME} master-${REGION}
        kops update cluster ${NAME} --yes
        kops validate cluster --name=${NAME} --wait 10m
    else
        echo "Dry run output - these commands wouuld normally be run"
        echo kops create cluster --ssh-public-key=${SSH_KEY} --zones ${REGION} --node-count=$NODE_COUNT --node-size=$NODE_SIZE --master-size=$NODE_SIZE ${NAME} --cloud-labels=$TAGS
        echo kops edit ig --name=${NAME} master-${REGION}
        echo kops update cluster ${NAME} --yes
        echo kops validate cluster --name=${NAME} --wait 10m
   fi
}

# Check args
if [ $# -ne 1 ]; then
   usage
   exit
fi

# Setup env vars etc
NAME=$1.k8s.local
KOPS_STATE_STORE=""
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
REGION="eu-west-2a"
NODE_COUNT=3
NODE_SIZE="t2.medium"
TAGS="owner=bill.stickers,department=tech-support"
DRY_RUN=false

# Run
creds
create_bucket
create_cluster

