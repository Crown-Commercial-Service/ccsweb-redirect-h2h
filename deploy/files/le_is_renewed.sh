#!/bin/bash
# Checks whether the LE certificate has renewed and whether the

SHARED_PATH="/shared"
SHARED_LE_PATH="$SHARED_PATH/le"
SHARED_HTTPD_PATH="$SHARED_PATH/httpd"
SHARED_HTTPD_DOCROOT_PATH="$SHARED_HTTPD_PATH/html"
SHARED_CERT_LAST_UPDATED_PATH="$SHARED_PATH/le.last_updated"
SHARED_CERT_MD5_PATH="$SHARED_PATH/le.cert_md5"
LOCAL_CERT_MD5_PATH="/le.cert_md5"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment:dev|uat|prod>"
    exit 1
fi

ENVIRONMENT=$1

case "$ENVIRONMENT" in
    "dev")
        DOMAIN="redirect.webdev.crowncommercial.gov.uk"
    ;;
    "uat")
        DOMAIN="redirect.webuat.crowncommercial.gov.uk"
    ;;
    "prod")
        DOMAIN="crowncommercial.gov.uk"
    ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        exit 1
    ;;
esac

# Leader instance does not need to run this
# (renewal process restarts apache automatically)
sudo ~ec2-user/is_leader.sh
if [ $? -eq 0 ]; then
    echo "ERROR: instance is the leader, exiting."
    exit 1
fi

CERT_PATH="$SHARED_LE_PATH/live/$DOMAIN/fullchain.pem"

if [ ! -e "$CERT_PATH" ] || [ ! -e "$SHARED_CERT_MD5_PATH" ]; then
    echo "ERROR: certificate or md5 file does not exist, exiting."
    exit 1
fi

echo "Checking whether the certificate recently renewed..."
IS_RENEWED=0

if [ ! -e "$LOCAL_CERT_MD5_PATH" ]; then
    echo "No local cert md5 file found, assuming the certificate has renewed."
    IS_RENEWED=1
else
    LOCAL_CERT_MD5=$(sudo cat "$LOCAL_CERT_MD5_PATH")
    SHARED_CERT_MD5=$(sudo cat "$SHARED_CERT_MD5_PATH")

    if [ "$LOCAL_CERT_MD5" != "$SHARED_CERT_MD5" ]; then
        echo "Local cert md5 file differs to the shared cert md5 file, certificate has renewed."
        IS_RENEWED=1
    fi
fi

if [ $IS_RENEWED -eq 1 ]; then
    echo "Reloading apache."
    sudo cp -f "$SHARED_CERT_MD5_PATH" "$LOCAL_CERT_MD5_PATH"
    sudo systemctl reload httpd.service
else
    echo "Certificate has not renewed."
fi

echo "Command complete."
