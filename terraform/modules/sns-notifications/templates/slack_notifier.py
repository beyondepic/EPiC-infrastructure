"""
Lambda function to send SNS notifications to Slack webhook
"""
import json
import urllib3
import os
from typing import Dict, Any

# Initialize HTTP client
http = urllib3.PoolManager()

def handler(event: Dict[str, Any], context: Any) -> Dict[str, Any]:
    """
    Lambda handler function to process SNS messages and send to Slack

    Args:
        event: Lambda event containing SNS message
        context: Lambda context (unused)

    Returns:
        Response dictionary with status
    """
    try:
        # Get Slack webhook URL from environment
        webhook_url = os.environ.get('SLACK_WEBHOOK_URL')
        if not webhook_url:
            print("ERROR: SLACK_WEBHOOK_URL environment variable not set")
            return {
                'statusCode': 500,
                'body': json.dumps('Webhook URL not configured')
            }

        # Process each SNS record
        for record in event['Records']:
            sns_message = record['Sns']

            # Extract message details
            subject = sns_message.get('Subject', 'EPiC Infrastructure Notification')
            message = sns_message.get('Message', '')
            topic_arn = sns_message.get('TopicArn', '')
            timestamp = sns_message.get('Timestamp', '')

            # Determine notification type from topic ARN
            if 'app-notifications' in topic_arn:
                notification_type = 'Application'
                color = '#36a64f'  # Green for application notifications
            else:
                notification_type = 'Infrastructure'
                color = '#ff9900'  # Orange for infrastructure notifications

            # Prepare Slack message
            slack_message = {
                "attachments": [
                    {
                        "color": color,
                        "title": f"🚨 {notification_type} Alert: {subject}",
                        "text": message,
                        "fields": [
                            {
                                "title": "Topic",
                                "value": topic_arn.split(':')[-1],  # Extract topic name
                                "short": True
                            },
                            {
                                "title": "Timestamp",
                                "value": timestamp,
                                "short": True
                            },
                            {
                                "title": "Type",
                                "value": notification_type,
                                "short": True
                            }
                        ],
                        "footer": "EPiC Infrastructure Monitoring",
                        "footer_icon": "https://platform.slack-edge.com/img/default_application_icon.png"
                    }
                ]
            }

            # Send to Slack
            encoded_msg = json.dumps(slack_message).encode('utf-8')
            resp = http.request(
                'POST',
                webhook_url,
                body=encoded_msg,
                headers={'Content-Type': 'application/json'}
            )

            if resp.status != 200:
                print(f"ERROR: Failed to send Slack notification. Status: {resp.status}, Response: {resp.data}")
                return {
                    'statusCode': 500,
                    'body': json.dumps(f'Failed to send Slack notification: {resp.status}')
                }
            else:
                print(f"SUCCESS: Sent Slack notification for topic: {topic_arn}")

        return {
            'statusCode': 200,
            'body': json.dumps('Notifications sent successfully')
        }

    except Exception as e:
        print(f"ERROR: Exception in Lambda function: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps(f'Error processing notification: {str(e)}')
        }