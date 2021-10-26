import boto3
import json


def lambda_handler(event, context):

    # Get the service resource.
    dynamodb = boto3.resource('dynamodb')

    # Set the query. This was generated with NoSQL Workbench
    input = {
        "TableName": "CloudChallengeDev",
        "Key": {
            "id": {"S": "visitorCount"}
        },
        "UpdateExpression": "SET #cc = #cc + :inc",
        "ExpressionAttributeNames": {"#cc": "currentCount"},
        "ExpressionAttributeValues": {":inc": {"N": "1"}}
    }

    table = dynamodb.table('CloudChallengeProd')
    returntable.update_item(**input)
