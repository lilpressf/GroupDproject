# security_monitoring.tf

# CloudWatch Log Group voor Security logs
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "Narrekappe/Security-Alerts"
  retention_in_days = 90
  
  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

# SNS Topic voor security alerts
resource "aws_sns_topic" "security_alerts" {
  name = "narrekappe-security-alerts"
  
  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

# SNS Subscription voor beheerder e-mail
resource "aws_sns_topic_subscription" "security_email_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = "554603@student.fontys.nl"
}

# Security Monitoring Dashboard
resource "aws_cloudwatch_dashboard" "security_dashboard" {
  dashboard_name = "Narrekappe-Security"

  dashboard_body = jsonencode({
    timezone = "LOCAL"
    widgets = [
      # Database Connections
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Connections"
          view = "singleValue"
          stacked = false
        }
      }
    ]
  })
}

# CloudWatch Alarm for Failed Logins (CloudTrail)
resource "aws_cloudwatch_metric_alarm" "failed_login_alarm" {
  alarm_name          = "narrekappe-console-failed-logins"
  alarm_description   = "Failed AWS console login attempts detected"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  threshold           = "0"
  period              = "300"
  statistic           = "SampleCount"
  metric_name         = "ConsoleLoginFailures"
  namespace           = "AWS/CloudTrail"
  alarm_actions       = [aws_sns_topic.security_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

# Outputs
output "security_dashboard_url" {
  value       = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=Narrekappe-Security"
  description = "URL for the Security Monitoring Dashboard"
}

output "security_log_group_name" {
  value       = aws_cloudwatch_log_group.security_logs.name
  description = "Name of the CloudWatch Log Group for security alerts"
}

output "security_sns_topic_arn" {
  value       = aws_sns_topic.security_alerts.arn
  description = "ARN of the SNS topic for security alerts"
}