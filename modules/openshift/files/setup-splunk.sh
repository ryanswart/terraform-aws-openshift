#!/usr/bin/env bash

# This script template is expected to be populated during the setup of a
# OpenShift  node. It runs on host startup.

# Log everything we do.
set -x
exec > /var/log/user-data.log 2>&1

# Create initial logs config.
cat > ./awslogs.conf << EOF
[general]
state_file = /var/awslogs/state/agent-state

[/var/log/messages]
log_stream_name = openshift-splunk-{instance_id}
log_group_name = /var/log/messages
file = /var/log/messages
datetime_format = %b %d %H:%M:%S
buffer_duration = 5000
initial_position = start_of_file

[/var/log/user-data.log]
log_stream_name = splunk-{instance_id}
log_group_name = /var/log/user-data.log
file = /var/log/user-data.log
EOF

# Download and run the AWS logs agent.
curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -O
python ./awslogs-agent-setup.py --non-interactive --region us-east-1 -c ./awslogs.conf

# Start the awslogs service, also start on reboot.
# Note: Errors go to /var/log/awslogs.log
service awslogs start
chkconfig awslogs on

# Download splunk.
yum install docker
docker pull splunk/splunk
docker run -d -e "SPLUNK_START_ARGS=--accept-license" \
       -e "SPLUNK_ENABLE_LISTEN=9997"
       -e "SPLUNK_USER=root" -p "8000:8000" -p "9997:9997" \
       --restart unless-stopped
       --name splunk splunk/splunk
