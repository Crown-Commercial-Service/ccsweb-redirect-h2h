#!/bin/bash
# Initial certbot certificate request

SHARED_PATH="/shared"
SHARED_LE_PATH="$SHARED_PATH/le"
SHARED_HTTPD_PATH="$SHARED_PATH/httpd"
SHARED_HTTPD_DOCROOT_PATH="$SHARED_HTTPD_PATH/html"
SHARED_CERT_LAST_UPDATED_PATH="$SHARED_PATH/le.last_updated"
SHARED_CERT_MD5_PATH="$SHARED_PATH/le.cert_md5"

if [ $# -ne 1 ]; then
    echo "Usage: $0 <environment:dev|uat|prod>"
    exit 1
fi

ENVIRONMENT=$1

EXTRA_FLAGS=
case "$ENVIRONMENT" in
    "dev")
        DOMAIN="redirect.webdev.ccsheretohelp.uk"
        EXTRA_FLAGS="--test-cert"
    ;;
    "uat")
        DOMAIN="redirect.webuat.ccsheretohelp.uk"
        EXTRA_FLAGS="--test-cert"
    ;;
    "prod")
        DOMAIN="ccsheretohelp.uk"
    ;;
    *)
        echo "Unknown environment: $ENVIRONMENT"
        exit 1
    ;;
esac

# Leader instance is responsible for the renewal process
sudo ~ec2-user/is_leader.sh
if [ $? -ne 0 ]; then
    echo "ERROR: instance is not a leader, exiting."
    exit 1
fi

CERT_PATH="$SHARED_LE_PATH/live/$DOMAIN/fullchain.pem"

if [ ! -e "$CERT_PATH" ]; then
    echo "ERROR: certificate does not exist, exiting."
    exit 1
fi

echo "Renewing existing SSL certificate..."
sudo certbot \
    renew \
    --config-dir "$SHARED_LE_PATH" \
    --webroot \
    --installer apache \
    -w "$SHARED_HTTPD_DOCROOT_PATH" \
    $EXTRA_FLAGS

if [ $? -eq 0 ]; then
    echo "Checking whether the certificate renewed or not..."

    CURRENT_CERT_MD5=
    if [ -e "$SHARED_CERT_MD5_PATH" ]; then
        CURRENT_CERT_MD5=$(sudo cat "$SHARED_CERT_MD5_PATH")
    fi

    POST_RENEWAL_CERT_MD5=
    if [ -e "$CERT_PATH" ]; then
        POST_RENEWAL_CERT_MD5=$(sudo md5sum "$CERT_PATH")
    fi

    if [ "$CURRENT_CERT_MD5" != "$POST_RENEWAL_CERT_MD5" ]; then
        echo "Certificate did renew, updating certificate last updated file."
        sudo bash -c "date > $SHARED_CERT_LAST_UPDATED_PATH"
        sudo bash -c "md5sum $CERT_PATH > $SHARED_CERT_MD5_PATH"
    fi
else
    echo "ERROR: Failed attempting certificate renewal."
fi

echo "Command complete."
