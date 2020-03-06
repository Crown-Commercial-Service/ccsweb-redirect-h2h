#!/bin/bash
# Responsible for keeping httpd alive

SCRIPTDIR=$(dirname $0)

echo -n "Is httpd currently running: "
pgrep "^httpd$" 2>&1 > /dev/null
if [ $? -eq 0 ]; then
    echo "yes, exiting."
    exit
else
    echo "no."
fi

echo -n "Checking this instance is ready/setup: "
$SCRIPTDIR/is_instance_ready.sh
if [ $? -ne 0 ]; then
    echo "timeout exceeded, exiting."
    exit 1
else
    echo "ready."
fi

echo -n "Checking the shared volume is ready: "
$SCRIPTDIR/is_shared_ready.sh
if [ $? -ne 0 ]; then
    echo "timeout exceeded, exiting."
    exit 1
else
    echo "ready."
fi

echo -n "Restarting httpd: "
systemctl restart httpd.service 2>&1 > /dev/null
if [ $? -eq 0 ]; then
    echo "done."
else
    echo "error."
fi
