# security_monitoring.tf

# CloudWatch Dashboard voor Security Monitoring
resource "aws_cloudwatch_dashboard" "narrekappe_security_monitoring" {
  dashboard_name = "Narrekappe-Security-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # Database Active Connections
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 0
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mydb.identifier, { stat = "Average", label = "Database Active Connections" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Active Connections"
          view = "timeSeries"
          stacked = false
          sparkline = true
          yAxis = {
            left = { min = 0 }
          }
          setPeriodToTimeRange = false
          annotations = {
            horizontal = [
              {
                color = "#ff0000"
                label = "High Load"
                value = 50
                fill = "above"
              }
            ]
          }
        }
      },
      
      # Database Failed Connections (indirect via ConnectionAttemptsFailed)
      {
        type = "metric"
        width = 12
        height = 6
        x = 12
        y = 0
        properties = {
          metrics = [
            ["AWS/RDS", "LoginFailures", "DBInstanceIdentifier", aws_db_instance.mydb.identifier, { stat = "Sum", label = "Database Failed Logins" }]
          ]
          period = 300
          stat = "Sum"
          region = "eu-central-1"
          title = "Database Failed Login Attempts (last 5min)"
          view = "singleValue"
          stacked = false
          sparkline = true
          setPeriodToTimeRange = false
        }
      },
      
      # AWS Management Console Failed Logins (via CloudTrail)
      {
        type = "log"
        width = 24
        height = 8
        x = 0
        y = 6
        properties = {
          query = <<EOF
SOURCE 'CloudTrail/DefaultLogGroup' | 
  FILTER eventName IN ['ConsoleLogin'] AND errorMessage != '' |
  STATS count() by userIdentity.arn, sourceIPAddress, errorMessage |
  SORT count() DESC
EOF
          region = "eu-central-1"
          title = "AWS Console Failed Login Attempts",
          view = "table"
        }
      },
      
      # Geografische weergave van failed logins
      {
        type = "log"
        width = 24
        height = 8
        x = 0
        y = 14
        properties = {
          query = <<EOF
SOURCE 'CloudTrail/DefaultLogGroup' | 
  FILTER eventName IN ['ConsoleLogin', 'AssumeRole'] AND (errorCode != '' OR errorMessage != '') |
  STATS count() by sourceIPAddress, @timestamp |
  GEO_FIELDS sourceIPAddress, @timestamp |
  LIMIT 100
EOF
          region = "eu-central-1"
          title = "Geografische verdeling van failed logins (via IP)",
          view = "map"
        }
      },
      
      # Security Group Rule Violations
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 22
        properties = {
          metrics = [
            ["AWS/EC2", "SecurityGroupCount", "InstanceId", aws_instance.web1.id, { stat = "Average", label = "Web1 SG Rules" }],
            ["AWS/EC2", "SecurityGroupCount", "InstanceId", aws_instance.web2.id, { stat = "Average", label = "Web2 SG Rules" }]
          ]
          period = 300
          stat = "Average"
          region = "eu-central-1"
          title = "Security Group Rule Count (monitor voor wijzigingen)"
          view = "timeSeries"
          stacked = false
          sparkline = true
        }
      },
      
      # VPC Flow Logs: Failed Connection Attempts
      {
        type = "log"
        width = 12
        height = 6
        x = 12
        y = 22
        properties = {
          query = <<EOF
SOURCE 'vpc-flow-logs' |
  FILTER action = 'REJECT' |
  STATS count() by srcAddr, dstAddr, dstPort |
  SORT count() DESC |
  LIMIT 10
EOF
          region = "eu-central-1"
          title = "Top 10 Geblokkeerde Connectiepogingen (VPC Flow Logs)",
          view = "table"
        }
      }
    ]
  })
}

# CloudTrail Trail (optioneel - nodig voor console login monitoring)
resource "aws_cloudtrail" "security_monitoring_trail" {
  name                          = "narrekappe-security-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name  # Je moet een S3 bucket maken voor CloudTrail
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  # Log naar CloudWatch Logs voor real-time monitoring
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_to_cloudwatch.arn
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
    
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]  # Monitor alle S3 buckets
    }
  }
  
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# CloudWatch Log Group voor CloudTrail logs
resource "aws_cloudwatch_log_group" "cloudtrail_logs" {
  name              = "CloudTrail/DefaultLogGroup"
  retention_in_days = 90
}

# IAM Role voor CloudTrail om naar CloudWatch te schrijven
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "CloudTrailToCloudWatchRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch_policy" {
  name = "CloudTrailToCloudWatchPolicy"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.cloudtrail_logs.arn}:*"
      }
    ]
  })
}

# VPC Flow Logs (optioneel - voor network traffic monitoring)
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs.arn
  traffic_type    = "REJECT"  # Alleen geweigerde verbindingen loggen
  vpc_id          = aws_vpc.main.id  # Vervang met je VPC ID
  
  log_format = "$${version} $${account-id} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${action} $${log-status}"
}

resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "vpc-flow-logs"
  retention_in_days = 90
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "VPCFlowLogsRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "vpc_flow_logs_policy" {
  name = "VPCFlowLogsPolicy"
  role = aws_iam_role.vpc_flow_logs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}