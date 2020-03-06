#!/bin/bash
# Is the shared volume initialised

SHARED_PATH="/shared"
SHARED_INIT_PATH="$SHARED_PATH/initialised"

if [ ! -e "$SHARED_INIT_PATH" ]; then
    exit 1
fi
