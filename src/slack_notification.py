import boto3
import json
import urllib3


def lambda_handler(event, context):

    ssm = boto3.client('ssm')
    slack_endpoint = ssm.get_parameter(
        Name='/terraform/lambda/slack-notification')['Parameter']['Value']
    http = urllib3.PoolManager()

    msg = {
        "channel": "#test",
        "text": "Hello, World!"
    }
    encoded_msg = json.dumps(msg).encode('utf-8')
    http.request('POST', slack_endpoint, body=encoded_msg)
