#!/bin/bash
# Initial certbot certificate request
# NOTE: this is manually executed once the DNS has fully propagated

SHARED_PATH="/shared"
SHARED_LE_PATH="$SHARED_PATH/le"
SHARED_HTTPD_PATH="$SHARED_PATH/httpd"
SHARED_HTTPD_DOCROOT_PATH="$SHARED_HTTPD_PATH/html"
SHARED_CERT_LAST_UPDATED_PATH="$SHARED_PATH/le.last_updated"
SHARED_CERT_MD5_PATH="$SHARED_PATH/le.cert_md5"

if [ $# -ne 2 ]; then
    echo "Usage: $0 <environment:dev|uat|prod> <certificate email>"
    exit 1
fi

ENVIRONMENT=$1
EMAIL=$2

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

CERT_PATH="$SHARED_LE_PATH/live/$DOMAIN/fullchain.pem"

if [ -e "$CERT_PATH" ]; then
    echo "ERROR: certificate already exists, exiting."
    exit 1
fi

echo "Provisioning new SSL certificate for domain: $DOMAIN"
echo "Using registered email: $EMAIL"
sudo certbot \
    run \
    --config-dir "$SHARED_LE_PATH" \
    --webroot \
    --installer apache \
    -w "$SHARED_HTTPD_DOCROOT_PATH" \
    -d "$DOMAIN" \
    --agree-tos \
    --email "$EMAIL" \
    --no-eff-email \
    --no-redirect \
    $EXTRA_FLAGS

if [ $? -eq 0 ]; then
    echo "Certificate issued; marking certificate as updated."
    sudo bash -c "date > $SHARED_CERT_LAST_UPDATED_PATH"
    sudo bash -c "md5sum $CERT_PATH > $SHARED_CERT_MD5_PATH"
else
    echo "ERROR: Failed getting new certificate issued."
fi

echo "Command complete."
