#!/bin/bash
# Is the instance ready/deployed yet

INSTANCE_SETUP_PATH="/codedeploy.server_setup"
WAIT_TIME=180

for I in `seq $WAIT_TIME`; do
    if [ -e "$INSTANCE_SETUP_PATH" ]; then
        exit 0
    fi

    sleep 1
done

exit 1
