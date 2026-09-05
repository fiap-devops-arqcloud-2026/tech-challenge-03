"""Create disposable SQS/DynamoDB resources in the Compose Moto container."""
import os

import boto3

endpoint = "http://aws-local:5000"
sqs = boto3.client("sqs", endpoint_url=endpoint)
sqs.create_queue(QueueName="evaluations")
db = boto3.client("dynamodb", endpoint_url=endpoint)
table = os.environ["AWS_DYNAMODB_TABLE"]
if table not in db.list_tables()["TableNames"]:
    db.create_table(
        TableName=table,
        KeySchema=[{"AttributeName": "event_id", "KeyType": "HASH"}],
        AttributeDefinitions=[{"AttributeName": "event_id", "AttributeType": "S"}],
        BillingMode="PAY_PER_REQUEST",
    )
db.get_waiter("table_exists").wait(TableName=table)
print("Local SQS queue and DynamoDB table ready")
