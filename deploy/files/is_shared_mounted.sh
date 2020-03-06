#!/bin/bash
# Is the shared volume ready/mounted yet

SHARED_PATH="/shared"
WAIT_TIME=180

for I in `seq $WAIT_TIME`; do
    if [ $(cat /proc/mounts | awk '{print $2}' | grep -qs "^$SHARED_PATH$"; echo $?) -eq 0 ]; then
        exit 0
    fi

    sleep 1
done

exit 1
