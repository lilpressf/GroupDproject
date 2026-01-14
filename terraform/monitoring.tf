resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Narrekappe-Monitoring"
  
  dashboard_body = jsonencode({
    timezone = "LOCAL"
    widgets = [
      # EC2 Instance metrics - CPU
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "WebServer CPU Usage"
          view = "timeSeries"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      # EC2 Instance metrics - Network Web1
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web1.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web1.id]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Web1 Network Traffic"
          view = "timeSeries"
          stacked = false
        }
      },
      
      # EC2 Instance metrics - Network Web2
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web2.id],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web2.id]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Web2 Network Traffic"
          view = "timeSeries"
          stacked = false
        }
      },
      
      # Database metrics - CPU
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database CPU Usage"
          view = "singleValue"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
      # Database metrics - Free Storage (GB)
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { "label": "Free Storage (GB)" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Free Storage (GB)"
          view = "singleValue"
          stacked = false
        }
      },
    ]
  })
}

# CloudWatch Log Group voor Monitoring logs
resource "aws_cloudwatch_log_group" "monitoring_logs" {
  name              = "Narrekappe/Monitoring-Alerts"
  retention_in_days = 30
  
  tags = {
    Environment = "Test"
    Component   = "Monitoring"
  }
}

# SNS Topic voor alle monitoring alerts
resource "aws_sns_topic" "monitoring_alerts" {
  name = "narrekappe-monitoring-alerts"
  
  tags = {
    Environment = "Test"
    Component   = "Monitoring"
  }
}

# SNS Subscription voor beheerder e-mail
resource "aws_sns_topic_subscription" "monitoring_email_subscription" {
  topic_arn = aws_sns_topic.monitoring_alerts.arn
  protocol  = "email"
  endpoint  = "554603@student.fontys.nl"
}

# CloudWatch Alarm voor Web1 CPU High (80% voor 1 minuut)
resource "aws_cloudwatch_metric_alarm" "web1_cpu_alarm" {
  alarm_name          = "narrekappe-web1-cpu-high"
  alarm_description   = "CPU utilization on Web1 exceeds 80% for 1 minute"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "80"
  period              = "60"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# CloudWatch Alarm voor Web2 CPU High (80% voor 1 minuut)
resource "aws_cloudwatch_metric_alarm" "web2_cpu_alarm" {
  alarm_name          = "narrekappe-web2-cpu-high"
  alarm_description   = "CPU utilization on Web2 exceeds 80% for 1 minute"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "80"
  period              = "60"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# CloudWatch Alarm voor Web1 No Network Traffic (5 minuten)
resource "aws_cloudwatch_metric_alarm" "web1_no_traffic_alarm" {
  alarm_name          = "narrekappe-web1-no-network-traffic"
  alarm_description   = "No network traffic detected on Web1 for 5 minutes"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  threshold           = "0"
  period              = "60"
  statistic           = "Sum"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# CloudWatch Alarm voor Web2 No Network Traffic (5 minuten)
resource "aws_cloudwatch_metric_alarm" "web2_no_traffic_alarm" {
  alarm_name          = "narrekappe-web2-no-network-traffic"
  alarm_description   = "No network traffic detected on Web2 for 5 minutes"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "5"
  threshold           = "0"
  period              = "60"
  statistic           = "Sum"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
  alarm_actions = [aws_sns_topic.monitoring_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# Outputs
output "monitoring_log_group_name" {
  value       = aws_cloudwatch_log_group.monitoring_logs.name
  description = "Name of the CloudWatch Log Group for monitoring alerts"
}

output "monitoring_sns_topic_arn" {
  value       = aws_sns_topic.monitoring_alerts.arn
  description = "ARN of the SNS topic for monitoring alerts"
}