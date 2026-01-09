# security_monitoring.tf

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "narrekappe-cloudtrail-logs"
  force_destroy = false

  tags = {
    Name = "CloudTrail-Logs"
  }
}

#S3 bucket policy for CloudTrail access
resource "aws_s3_bucket_policy" "cloudtrail_bucket_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.cloudtrail_logs.arn}/prefix/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

#CloudTrail Trail for AWS Console Logins (Required)
resource "aws_cloudtrail" "security_monitoring_trail" {
  name           = "narrekappe-security-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail_logs.id
  s3_key_prefix  = "prefix"
  include_global_service_events = true
  is_multi_region_trail         = true

  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.cloudtrail_security.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_to_cloudwatch.arn

  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket_policy]
}

#CloudWatch Log Group for CloudTrail Events
resource "aws_cloudwatch_log_group" "cloudtrail_security" {
  name              = "CloudTrail/NarrekappeSecurity"
  retention_in_days = 30
}

#IAM Role for CloudTrail to write to CloudWatch Logs
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

#IAM Policy for the role
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

#Metric Filter for Failed Console Logins
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

#CloudWatch Alarm for Failed Logins
resource "aws_cloudwatch_metric_alarm" "failed_login_alarm" {
  alarm_name          = "narrekappe-console-failed-logins"
  alarm_description   = "Alerts on multiple failed AWS console login attempts"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "3"
  period              = "300" # 5 minutes in seconds
  statistic           = "Sum"
  metric_name         = "ConsoleLoginFailureCount"
  namespace           = "Narrekappe/Security"
  alarm_actions       = []

  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

#Security Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "Narrekappe-Security"

  dashboard_body = jsonencode({
    timezone = "LOCAL"
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

      {
        type = "metric"
        width = 24
        height = 6
        properties = {
          metrics = [
            ["Narrekappe/Security", "ConsoleLoginFailureCount", { "stat": "Sum", "label": "Failed Logins" }]
          ]
          period = 300
          stat   = "Sum"
          region = "eu-central-1"
          title  = "Security Activity - Failed Console Logins"
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

output "cloudtrail_s3_bucket_name" {
  value       = aws_s3_bucket.cloudtrail_logs.id
  description = "Name of the S3 bucket for CloudTrail logs"
}

output "cloudwatch_log_group_name" {
  value       = aws_cloudwatch_log_group.cloudtrail_security.name
  description = "Name of the CloudWatch Log Group for security events"
}