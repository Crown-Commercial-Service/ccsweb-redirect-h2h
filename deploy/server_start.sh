#!/bin/bash
# Start/enable application-related services

echo "Starting codedeploy server_start.sh ..."

SERVICES=(
    "awslogsd.service"
)

echo "> Starting services..."
for SERVICE in "${SERVICES[@]}"; do
    echo -n "> > Enabling & starting service [$SERVICE]: "

    sudo systemctl is-enabled --quiet "$SERVICE" \
        || sudo systemctl enable "$SERVICE"

    sudo systemctl is-active --quiet "$SERVICE" \
        || sudo systemctl start "$SERVICE"

    echo "done."
done

echo "> Restarting httpd..."

echo "> > Stopping httpd..."
sudo systemctl stop httpd.service

echo "> > Executing keep_httpd_alive.sh..."
sudo ~ec2-user/keep_httpd_alive.sh

echo "Codedeploy server_start.sh complete."
