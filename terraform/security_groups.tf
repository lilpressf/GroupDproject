# security_monitoring.tf

# CloudWatch Log Group voor Security Monitoring logs
resource "aws_cloudwatch_log_group" "security_monitoring_logs" {
  name              = "Narrekappe/Security-Monitoring"
  retention_in_days = 90  # Langer bewaren vanwege compliance
  
  tags = {
    Environment = "Test"
    Component   = "Security"
    LogType     = "Security-Events"
  }
}

# Metric Filter voor Security Triggers
resource "aws_cloudwatch_log_metric_filter" "security_trigger" {
  name           = "Security-Trigger-Activated"
  pattern        = "{ $.timestamp = *, $.event = \"SECURITY_TRIGGER_ACTIVATED\", $.details = * }"
  log_group_name = aws_cloudwatch_log_group.security_monitoring_logs.name

  metric_transformation {
    name      = "SecurityTriggerCount"
    namespace = "Narrekappe/Security-Triggers"
    value     = "1"
  }
}

# CloudWatch Alarm voor Security Triggers
resource "aws_cloudwatch_metric_alarm" "security_trigger_alarm" {
  alarm_name          = "narrekappe-security-trigger"
  alarm_description   = "Security trigger has been activated"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  period              = "60"
  statistic           = "Sum"
  metric_name         = "SecurityTriggerCount"
  namespace           = "Narrekappe/Security-Triggers"
  alarm_actions       = []
  
  tags = {
    Environment = "Test"
    Component   = "Security"
    Priority    = "High"
  }
}

# Security Monitoring Dashboard (Aangepast - alleen de widget toevoegen)
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
      },

      # Database metrics - Connections (verplaatst van monitoring.tf)
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
      },

      # Security Triggers Widget
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["Narrekappe/Security-Triggers", "SecurityTriggerCount", { "stat": "Sum", "label": "Security Triggers" }]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Security Triggers Activated"
          view = "singleValue"
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
  value       = "narrekappe-console-failed-logins"  # Directe referentie
  description = "Name of the CloudWatch alarm for failed logins"
}

output "cloudtrail_s3_bucket_name" {
  value       = "narrekappe-cloudtrail-logs"  # Directe referentie
  description = "Name of the S3 bucket for CloudTrail logs"
}

output "cloudwatch_log_group_name" {
  value       = "CloudTrail/NarrekappeSecurity"  # Directe referentie
  description = "Name of the CloudWatch Log Group for security events"
}

output "security_monitoring_log_group_name" {
  value       = aws_cloudwatch_log_group.security_monitoring_logs.name
  description = "Name of the CloudWatch Log Group for security monitoring alerts"
}

output "security_monitoring_log_group_arn" {
  value       = aws_cloudwatch_log_group.security_monitoring_logs.arn
  description = "ARN of the CloudWatch Log Group for security monitoring alerts"
}