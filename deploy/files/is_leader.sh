#!/bin/bash
# Whether this is the leader node or not

curl -s "http://169.254.169.254/latest/meta-data/placement/availability-zone/" | grep -q "^eu-west-.a$"
if [ $? -ne 0 ]; then
    exit 1
fi
