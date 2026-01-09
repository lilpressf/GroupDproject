import json
import os
import sys
import boto3
import psycopg

REGION = os.environ["REGION"]
SNS_TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]
DB_HOST = os.environ["DB_HOST"]
DB_PORT = int(os.environ.get("DB_PORT", "5432"))
DB_NAME = os.environ["DB_NAME"]
DB_USER = os.environ["DB_USER"]
DB_PASSWORD = os.environ["DB_PASSWORD"]

VM_SUBNET_ID = os.environ["VM_SUBNET_ID"]
VM_SECURITY_GROUP = os.environ["VM_SECURITY_GROUP"]

MEDIUM_AMI_ID = os.environ["MEDIUM_AMI_ID"]
HARD_AMI_ID = os.environ["HARD_AMI_ID"]

EASY_INSTANCE_TYPE = os.environ.get("EASY_INSTANCE_TYPE", "t3.micro")
MEDIUM_INSTANCE_TYPE = os.environ.get("MEDIUM_INSTANCE_TYPE", "t3.micro")
HARD_INSTANCE_TYPE = os.environ.get("HARD_INSTANCE_TYPE", "t3.micro")

ec2 = boto3.client("ec2", region_name=REGION)
sns = boto3.client("sns", region_name=REGION)

def get_easy_ami():
  # Latest Amazon Linux 2023 via SSM public parameter
  ssm = boto3.client("ssm", region_name=REGION)
  p = ssm.get_parameter(Name="/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64")
  return p["Parameter"]["Value"]

def db():
  # ✅ FIX: RDS vereist encryptie (SSL). Daarom sslmode=require.
  return psycopg.connect(
    host=DB_HOST,
    port=DB_PORT,
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    sslmode="require",
    connect_timeout=10,
  )

def ensure_table(conn):
  with conn.cursor() as cur:
    cur.execute("""
      CREATE TABLE IF NOT EXISTS deployments (
        id TEXT PRIMARY KEY,
        requested_at TIMESTAMPTZ NOT NULL,
        difficulty TEXT NOT NULL,
        instance_id TEXT,
        status TEXT NOT NULL
      );
    """)
  conn.commit()

def update_status(conn, deploy_id, status, instance_id=None):
  with conn.cursor() as cur:
    if instance_id:
      cur.execute(
        "UPDATE deployments SET status=%s, instance_id=%s WHERE id=%s",
        (status, instance_id, deploy_id)
      )
    else:
      cur.execute(
        "UPDATE deployments SET status=%s WHERE id=%s",
        (status, deploy_id)
      )
  conn.commit()

def run_instance(ami_id, instance_type, tags):
  resp = ec2.run_instances(
    ImageId=ami_id,
    InstanceType=instance_type,
    MinCount=1,
    MaxCount=1,
    NetworkInterfaces=[{
      "DeviceIndex": 0,
      "SubnetId": VM_SUBNET_ID,
      "Groups": [VM_SECURITY_GROUP],
      "AssociatePublicIpAddress": False
    }],
    TagSpecifications=[{
      "ResourceType": "instance",
      "Tags": [{"Key": k, "Value": v} for k, v in tags.items()]
    }],
  )
  return resp["Instances"][0]["InstanceId"]

def publish(msg):
  sns.publish(
    TopicArn=SNS_TOPIC_ARN,
    Subject="Training VM deployment",
    Message=msg
  )

def main():
  queue_url = os.environ["SQS_QUEUE_URL"]
  sqs = boto3.client("sqs", region_name=REGION)

  conn = db()
  ensure_table(conn)

  # Receive one message
  r = sqs.receive_message(
    QueueUrl=queue_url,
    MaxNumberOfMessages=1,
    WaitTimeSeconds=20,
    VisibilityTimeout=300
  )
  msgs = r.get("Messages", [])
  if not msgs:
    print("No messages; exiting")
    return 0

  m = msgs[0]
  receipt = m["ReceiptHandle"]

  # EventBridge → SQS wraps detail in a JSON envelope
  body = json.loads(m["Body"])
  detail = body.get("detail") or {}
  deploy_id = detail.get("id")
  difficulty = (detail.get("difficulty") or "").lower()

  if not deploy_id or difficulty not in ("easy", "medium", "hard"):
    print(f"Bad message: {detail}", file=sys.stderr)
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt)
    return 1

  try:
    update_status(conn, deploy_id, "PROVISIONING")

    if difficulty == "easy":
      ami = get_easy_ami()
      itype = EASY_INSTANCE_TYPE
    elif difficulty == "medium":
      ami = MEDIUM_AMI_ID
      itype = MEDIUM_INSTANCE_TYPE
    else:
      ami = HARD_AMI_ID
      itype = HARD_INSTANCE_TYPE

    instance_id = run_instance(ami, itype, {
      "Name": f"training-{difficulty}-{deploy_id[:8]}",
      "Project": "training-platform",
      "Difficulty": difficulty,
      "DeploymentId": deploy_id
    })

    update_status(conn, deploy_id, "RUNNING", instance_id=instance_id)
    publish(f"Deployment {deploy_id} ({difficulty}) started. EC2 instance: {instance_id}")
    sqs.delete_message(QueueUrl=queue_url, ReceiptHandle=receipt)
    print(f"OK: {deploy_id} -> {instance_id}")
    return 0

  except Exception as e:
    print(f"FAILED: {e}", file=sys.stderr)
    try:
      update_status(conn, deploy_id, "FAILED")
    except Exception:
      pass
    # Leave message for retry (visibility timeout)
    return 2

  finally:
    conn.close()

if __name__ == "__main__":
  raise SystemExit(main())
