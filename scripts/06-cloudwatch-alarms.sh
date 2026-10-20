#!/usr/bin/env bash
# CloudWatch alarms (no agent, no instance role) wired to an SNS email topic.
# Run from a workstation with the AWS CLI configured.
# Usage: bash 06-cloudwatch-alarms.sh <INSTANCE_ID> <EMAIL> [REGION]
set -euo pipefail
IID="${1:?usage: $0 <instance-id> <email> [region]}"
EMAIL="${2:?email required}"
REGION="${3:-us-west-2}"

TOPIC_ARN="$(aws sns create-topic --name web01-alerts --region "$REGION" --query TopicArn --output text)"
aws sns subscribe --topic-arn "$TOPIC_ARN" --protocol email --notification-endpoint "$EMAIL" --region "$REGION" >/dev/null
echo "Confirm the subscription email sent to $EMAIL."

aws cloudwatch put-metric-alarm --region "$REGION" \
  --alarm-name web01-cpu-high --namespace AWS/EC2 --metric-name CPUUtilization \
  --dimensions Name=InstanceId,Value="$IID" --statistic Average --period 300 \
  --evaluation-periods 3 --datapoints-to-alarm 2 --threshold 70 \
  --comparison-operator GreaterThanThreshold --alarm-actions "$TOPIC_ARN"

aws cloudwatch put-metric-alarm --region "$REGION" \
  --alarm-name web01-status-check --namespace AWS/EC2 --metric-name StatusCheckFailed \
  --dimensions Name=InstanceId,Value="$IID" --statistic Maximum --period 60 \
  --evaluation-periods 2 --datapoints-to-alarm 2 --threshold 1 \
  --comparison-operator GreaterThanOrEqualToThreshold --alarm-actions "$TOPIC_ARN"

aws cloudwatch describe-alarms --alarm-names web01-cpu-high web01-status-check \
  --region "$REGION" --query 'MetricAlarms[].[AlarmName,StateValue]' --output table
