#!/bin/bash
# Setup the shared volume

SCRIPTDIR=$(dirname $0)
SHARED_PATH="/shared"
SHARED_INIT_PATH="$SHARED_PATH/initialised"
SHARED_LE_PATH="$SHARED_PATH/le"
SHARED_HTTPD_PATH="$SHARED_PATH/httpd"
SHARED_HTTPD_DOCROOT_PATH="$SHARED_HTTPD_PATH/html"
SHARED_HTTPD_CONFIG_PATH="$SHARED_HTTPD_PATH/conf"

echo -n "Checking the shared volume is mounted: "
$SCRIPTDIR/is_shared_mounted.sh
if [ $? -ne 0 ]; then
    echo "timeout exceeded, exiting."
    exit 1
else
    echo "yes."
fi

echo -n "Is the shared volume already initialised: "
$SCRIPTDIR/is_shared_initialised.sh
if [ $? -eq 0 ]; then
    echo "yes, exiting."
    exit
else
    echo "no."
fi

echo "Initialising shared volume..."

echo "> Creating shared volume paths..."
mkdir -p \
    "$SHARED_LE_PATH" \
    "$SHARED_HTTPD_PATH" \
    "$SHARED_HTTPD_DOCROOT_PATH" \
    "$SHARED_HTTPD_CONFIG_PATH"

echo "> Initialising web-root files..."
echo "" > "$SHARED_HTTPD_DOCROOT_PATH/index.html"
mkdir -p "$SHARED_HTTPD_DOCROOT_PATH/healthcheck"
echo "HEALTHCHECK" > "$SHARED_HTTPD_DOCROOT_PATH/healthcheck/index.html"
chown -R apache:apache "$SHARED_HTTPD_DOCROOT_PATH"

echo "Initialisation complete."

echo -n "Marking shared volume as initialised: "
touch "$SHARED_INIT_PATH"
echo "done."
