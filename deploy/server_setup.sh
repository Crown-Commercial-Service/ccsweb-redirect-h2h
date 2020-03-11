#!/bin/bash
# System setup

echo "Starting codedeploy server_setup.sh ..."

SCRIPTDIR=$(dirname $0)
FIRST_RUN_PATH="/codedeploy.server_setup"
AWS_REGION_PATH="/aws_region"
SECRETS_BUCKET_NAME_PATH="/secrets_bucket_name"
HTTPD_CONF_PATH="/shared/httpd/conf/httpd.conf"

echo "> Updating system software..."
sudo yum update -y

if [ ! -e "$FIRST_RUN_PATH" ]; then
    echo "> Running once-only deployment tasks..."

    echo "> > Installing awslogs service..."
    sudo yum install -y awslogs

    echo "> > chown'ing awslogs config files..."
    sudo chown root:root \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf"

    echo "> > chmod'ing awslogs config files..."
    sudo chmod 640 \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf"

    echo "> > Movinging awslogs config files..."
    sudo mv -f \
        "$SCRIPTDIR/files/awscli.conf" \
        "$SCRIPTDIR/files/awslogs.conf" \
        /etc/awslogs/

    echo "> > Install package sources..."
    sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

    echo "> Updating system software..."
    sudo yum update -y

    echo "> > Installing web packages..."
    sudo yum -y install \
        httpd \
        mod_ssl \
        certbot \
        python2-certbot-apache

    echo "> Stopping/disabling httpd service..."
    sudo systemctl stop httpd.service
    sudo systemctl disable httpd.service

    echo "> > Web root initialisation..."
    sudo bash -c 'echo "" > /var/www/html/index.html'

    echo "> > Initialising system httpd config path..."
    rm -f /etc/httpd/conf/httpd.conf
    ln -s "$HTTPD_CONF_PATH" /etc/httpd/conf/httpd.conf

    echo "> > Installing jq..."
    sudo yum install -y jq

    echo "> > Determining AWS region..."
    AWS_REGION="eu-west-2"
    if [ "$DEPLOYMENT_GROUP_NAME" == "redirect-h2h-dev" ]; then
        AWS_REGION="eu-west-1"
    fi

    echo "> > Determining secrets bucket name..."
    SSM_SECRETS_BUCKET_NAME=$(aws --region "$AWS_REGION" ssm get-parameter --name "/CCS/SECRETS_BUCKET_NAME" | jq -r ".Parameter.Value")

    echo "> > Writing aws_region file..."
    sudo bash -c "echo -n $AWS_REGION > $AWS_REGION_PATH"

    echo "> > Writing secrets bucket name file..."
    sudo bash -c "echo -n $SSM_SECRETS_BUCKET_NAME > $SECRETS_BUCKET_NAME_PATH"

    echo "> > Uninstalling jq..."
    sudo yum remove -y jq

    echo "> > Syncing crontab tasks..."
    sudo aws --region "$AWS_REGION" s3 sync s3://$SSM_SECRETS_BUCKET_NAME/redirect-h2h/cron ~ec2-user/cron

    echo "> > Configuring cron..."
    sudo chown root:root ~ec2-user/cron/*.cron
    sudo chmod 644 ~ec2-user/cron/*.cron
    sudo mv -f ~ec2-user/cron/*.cron /etc/cron.d/
    sudo rm -rf ~ec2-user/cron
fi

echo "> Copying files..."
sudo cp -f \
    "$SCRIPTDIR/files/is_instance_ready.sh" \
    "$SCRIPTDIR/files/is_leader.sh" \
    "$SCRIPTDIR/files/is_shared_initialised.sh" \
    "$SCRIPTDIR/files/is_shared_mounted.sh" \
    "$SCRIPTDIR/files/is_shared_ready.sh" \
    "$SCRIPTDIR/files/keep_httpd_alive.sh" \
    "$SCRIPTDIR/files/le_cert.sh" \
    "$SCRIPTDIR/files/le_is_renewed.sh" \
    "$SCRIPTDIR/files/le_renew.sh" \
    "$SCRIPTDIR/files/setup_shared.sh" \
    ~ec2-user/

echo "> chown'ing copied files..."
sudo chown root:root ~ec2-user/*.sh
sudo chown root:root ~ec2-user/*.cron

echo "> chmod'ing script files..."
sudo chmod +x ~ec2-user/*.sh

sudo ~ec2-user/is_leader.sh
if [ $? -eq 0 ]; then
    echo "> Executing leader deployment tasks..."

    echo "> > Running shared volume setup..."
    sudo ~ec2-user/setup_shared.sh

    echo "> > Copying httpd.conf to shared volume..."
    if [ ! -f "$HTTPD_CONF_PATH" ]; then
        sudo aws --region "$AWS_REGION" s3 cp s3://$SSM_SECRETS_BUCKET_NAME/redirect-h2h/config/httpd.conf "$HTTPD_CONF_PATH"
        sudo chown root:root "$HTTPD_CONF_PATH"
    fi

    echo "> Leader deployment tasks complete."
fi

echo "> Configuring cron..."
sudo mv -f ~ec2-user/*.cron /etc/cron.d/

if [ ! -e "$FIRST_RUN_PATH" ]; then
    echo "> > Marking first deployment tasks as completed..."
    sudo touch "$FIRST_RUN_PATH"
fi

echo "Codedeploy server_setup.sh complete."
