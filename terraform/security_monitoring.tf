# security_monitoring.tf
# Prerequisite: Ensure you have a CloudTrail trail configured to log to CloudWatch.
# You can use the `aws_cloudtrail` resource below.

# 1. Create an S3 bucket for CloudTrail logs (Required)
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "narrekappe-cloudtrail-logs" # Unique name
  force_destroy = false # Set to true for easier cleanup in non-production

  tags = {
    Name = "CloudTrail-Logs"
  }
}

# 2. CloudTrail Trail for AWS Console Logins (Required)
resource "aws_cloudtrail" "security_monitoring_trail" {
  name           = "narrekappe-security-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix  = "prefix"
  include_global_service_events = true # Crucial for console logins
  is_multi_region_trail         = true # Best practice

  # This delivers logs to CloudWatch for real-time metric filtering
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_security.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

# 3. CloudWatch Log Group for CloudTrail Events
resource "aws_cloudwatch_log_group" "cloudtrail_security" {
  name              = "CloudTrail/NarrekappeSecurity"
  retention_in_days = 30
}

# 4. IAM Role for CloudTrail to write to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_to_cloudwatch" {
  name = "CloudTrail-CloudWatchLogs-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })
}

# 5. IAM Policy for the role (attached via `aws_iam_role_policy`)
resource "aws_iam_role_policy" "cloudtrail_to_cloudwatch_policy" {
  name = "WriteToCloudWatchLogs"
  role = aws_iam_role.cloudtrail_to_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail_security.arn}:*"
    }]
  })
}

# 6. Metric Filter for Failed Console Logins (The Core Detection)
resource "aws_cloudwatch_log_metric_filter" "failed_console_logins" {
  name           = "ConsoleLoginFailureCount"
  pattern        = "{ ($.eventName = ConsoleLogin) && ($.errorMessage = \"Failed authentication\") }"
  log_group_name = aws_cloudwatch_log_group.cloudtrail_security.name

  metric_transformation {
    name      = "ConsoleLoginFailureCount"
    namespace = "Narrekappe/Security"
    value     = "1"
  }
}

# 7. CloudWatch Alarm for Failed Logins
resource "aws_cloudwatch_metric_alarm" "failed_login_alarm" {
  alarm_name          = "narrekappe-console-failed-logins"
  alarm_description   = "Alerts on multiple failed AWS console login attempts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "3" # Common threshold: 3 failures in 5 min[citation:5][citation:9]
  period              = "300" # 5 minutes in seconds
  statistic           = "Sum"
  metric_name         = "ConsoleLoginFailureCount"
  namespace           = "Narrekappe/Security"
  alarm_actions       = [] # Add an SNS topic ARN here for notifications

  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

# 8. Security Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "Narrekappe-Security"

  dashboard_body = jsonencode({
    widgets = [
      # Failed Login Attempts (From CloudTrail Metric Filter)
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["Narrekappe/Security", "ConsoleLoginFailureCount", { "stat": "Sum", "label": "Failed Console Logins" }]
          ]
          period = 300
          stat   = "Sum"
          region = "eu-central-1"
          title  = "Failed AWS Console Login Attempts (Last 5 min)"
          view   = "singleValue"
        }
      },
      # Current RDS Database Connections[citation:2][citation:10]
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier]
          ]
          period = 60
          stat   = "Average"
          region = "eu-central-1"
          title  = "RDS Active Database Connections (narre-db)"
          view   = "singleValue"
        }
      },
      # Combined Time-Series View
      {
        type = "metric"
        width = 24
        height = 6
        properties = {
          metrics = [
            ["Narrekappe/Security", "ConsoleLoginFailureCount", { "stat": "Sum", "label": "Failed Logins" }],
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { "label": "DB Connections" }]
          ]
          period = 300
          stat   = "Sum"
          region = "eu-central-1"
          title  = "Security & Database Activity"
          view   = "timeSeries"
        }
      }
    ]
  })
}

# Outputs
output "security_dashboard_url" {
  value       = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=Narrekappe-Security"
  description = "URL for the Security Monitoring Dashboard"
}

output "failed_login_alarm_name" {
  value       = aws_cloudwatch_metric_alarm.failed_login_alarm.alarm_name
  description = "Name of the CloudWatch alarm for failed logins"
}