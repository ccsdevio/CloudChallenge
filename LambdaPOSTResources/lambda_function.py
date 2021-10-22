import boto3
import json


def update_value():
    # Get the service resource.
    dynamodb = boto3.resource('dynamodb')
    # Set the table.
    table = dynamodb.Table('CloudChallengeDev')
    # Build the query.
    query = {
        "ExpressionAttributeValues": {":q": 1},
        "Key": {"id": "visitorCount"},
        "UpdateExpression": "SET currentCount = currentCount + :q"
    }
    response = table.update_item(**query)
    return response


def lambda_handler(event, context):
    data = update_value()
    return {
        'statusCode': 200,
        'body': json.dumps(data)
    }
