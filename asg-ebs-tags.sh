#!/bin/bash
# Pre-requisites
yum install jq -y

# Global variables
AWS_INSTANCE_ID=$( curl http://169.254.169.254/latest/meta-data/instance-id )
AWS_HOME=/opt/aws
AWS_BIN_DIR="$AWS_HOME/bin"
export EC2_HOME="$AWS_HOME/apitools/ec2"

# Get associcated volume
ATTACHED_VOLUME=$( aws ec2 describe-volumes --filter "Name=attachment.instance-id, Values=$AWS_INSTANCE_ID" --query "Volumes[].VolumeId" --out text --region ap-southeast-2 )

# Get EC2 tags
DESCRIBE_TAGS_RESPONSE=$( aws ec2 describe-tags --filter "Name=resource-id,Values=$AWS_INSTANCE_ID" --region ap-southeast-2 )

# Loop through tags and apply them to attached volume
while read key value ; do

    if ! [[ $key =~ .*aws:* ]]; then
        CREATE_VOLUME_TAGS=$( aws ec2 create-tags --resources $ATTACHED_VOLUME --tags Key="$key",Value="$value" --region ap-southeast-2 )
    fi

done < <(echo "$DESCRIBE_TAGS_RESPONSE" | jq -r '.Tags[]|"\(.Key) \(.Value)"')
