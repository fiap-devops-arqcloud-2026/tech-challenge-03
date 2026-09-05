"""Verify events written by the running analytics worker, not by the test."""
import json
import os
import sys
import time

import boto3

expected = json.loads(sys.argv[1])
db = boto3.client("dynamodb", region_name=os.environ["AWS_REGION"],
                  endpoint_url=os.environ["DYNAMODB_ENDPOINT"])
sqs = boto3.client("sqs", region_name=os.environ["AWS_REGION"],
                   endpoint_url=os.environ["SQS_ENDPOINT"])
deadline = time.monotonic() + 90
while time.monotonic() < deadline:
    items = []
    options = {"TableName": os.environ["AWS_DYNAMODB_TABLE"], "ConsistentRead": True}
    while True:
        page = db.scan(**options)
        items.extend(page["Items"])
        if "LastEvaluatedKey" not in page:
            break
        options["ExclusiveStartKey"] = page["LastEvaluatedKey"]
    actual = {
        (item["flag_name"]["S"], item["user_id"]["S"], item["result"]["BOOL"])
        for item in items if item.get("timestamp", {}).get("S")
    }
    missing = [event for event in expected
               if (event["flag_name"], event["user_id"], event["result"]) not in actual]
    attributes = sqs.get_queue_attributes(
        QueueUrl=os.environ["AWS_SQS_URL"],
        AttributeNames=["ApproximateNumberOfMessages", "ApproximateNumberOfMessagesNotVisible"],
    )["Attributes"]
    if not missing and all(int(value) == 0 for value in attributes.values()):
        print(f"PASS: {len(expected)} evaluation events persisted by analytics; SQS drained")
        break
    time.sleep(2)
else:
    raise AssertionError(f"Analytics events missing: {missing}; queue: {attributes}")
