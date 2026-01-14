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
      
# Database metrics - Free Storage
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Free Storage"
          view = "singleValue"
          stacked = false
        }
      },
    ]
  })
}

# CloudWatch Log Group voor Monitoring logs (CPU waarschuwingen)
resource "aws_cloudwatch_log_group" "monitoring_logs" {
  name              = "Narrekappe/Monitoring"
  retention_in_days = 30
  
  tags = {
    Environment = "Test"
    Component   = "Monitoring"
    LogType     = "Application-Metrics"
  }
}

# Metric Filters en Alarms voor Monitoring Logs

# Web1 CPU High Alert
resource "aws_cloudwatch_log_metric_filter" "web1_cpu_high" {
  name           = "Web1-CPU-High"
  pattern        = "{ $.timestamp = *, $.instance = \"web1\", $.metric = \"CPUUtilization\", $.value > 80 }"
  log_group_name = aws_cloudwatch_log_group.monitoring_logs.name

  metric_transformation {
    name      = "Web1CPUHigh"
    namespace = "Narrekappe/Monitoring-Alerts"
    value     = "1"
  }
}

# Web2 CPU High Alert
resource "aws_cloudwatch_log_metric_filter" "web2_cpu_high" {
  name           = "Web2-CPU-High"
  pattern        = "{ $.timestamp = *, $.instance = \"web2\", $.metric = \"CPUUtilization\", $.value > 80 }"
  log_group_name = aws_cloudwatch_log_group.monitoring_logs.name

  metric_transformation {
    name      = "Web2CPUHigh"
    namespace = "Narrekappe/Monitoring-Alerts"
    value     = "1"
  }
}

# Database CPU High Alert
resource "aws_cloudwatch_log_metric_filter" "database_cpu_high" {
  name           = "Database-CPU-High"
  pattern        = "{ $.timestamp = *, $.service = \"RDS\", $.metric = \"CPUUtilization\", $.value > 80 }"
  log_group_name = aws_cloudwatch_log_group.monitoring_logs.name

  metric_transformation {
    name      = "DatabaseCPUHigh"
    namespace = "Narrekappe/Monitoring-Alerts"
    value     = "1"
  }
}

# CloudWatch Alarms voor CPU monitoring
resource "aws_cloudwatch_metric_alarm" "web1_cpu_alarm" {
  alarm_name          = "narrekappe-web1-cpu-high"
  alarm_description   = "CPU utilization on Web1 exceeds 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  threshold           = "80"
  period              = "60"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
  alarm_actions = []
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

resource "aws_cloudwatch_metric_alarm" "web2_cpu_alarm" {
  alarm_name          = "narrekappe-web2-cpu-high"
  alarm_description   = "CPU utilization on Web2 exceeds 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  threshold           = "80"
  period              = "60"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
  alarm_actions = []
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

resource "aws_cloudwatch_metric_alarm" "database_cpu_alarm" {
  alarm_name          = "narrekappe-database-cpu-high"
  alarm_description   = "CPU utilization on Database exceeds 80%"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  threshold           = "80"
  period              = "60"
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.narre-db.identifier
  }
  alarm_actions = []
  
  tags = {
    Environment = "Test"
    Component   = "Database"
  }
}

# Network Traffic Monitoring - No Traffic Alerts

# Metric Filter voor Web1 No Network Traffic
resource "aws_cloudwatch_log_metric_filter" "web1_no_network_traffic" {
  name           = "Web1-No-Network-Traffic"
  pattern        = "{ $.timestamp = *, $.instance = \"web1\", $.metric = \"NoNetworkTraffic\", $.status = \"ALERT\" }"
  log_group_name = aws_cloudwatch_log_group.monitoring_logs.name

  metric_transformation {
    name      = "Web1NoNetworkTraffic"
    namespace = "Narrekappe/Monitoring-Alerts"
    value     = "1"
  }
}

# Metric Filter voor Web2 No Network Traffic
resource "aws_cloudwatch_log_metric_filter" "web2_no_network_traffic" {
  name           = "Web2-No-Network-Traffic"
  pattern        = "{ $.timestamp = *, $.instance = \"web2\", $.metric = \"NoNetworkTraffic\", $.status = \"ALERT\" }"
  log_group_name = aws_cloudwatch_log_group.monitoring_logs.name

  metric_transformation {
    name      = "Web2NoNetworkTraffic"
    namespace = "Narrekappe/Monitoring-Alerts"
    value     = "1"
  }
}

# CloudWatch Alarm voor Web1 No Network Traffic
resource "aws_cloudwatch_metric_alarm" "web1_no_traffic_alarm" {
  alarm_name          = "narrekappe-web1-no-network-traffic"
  alarm_description   = "No network traffic detected on Web1 for 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  period              = "300"
  statistic           = "Sum"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# CloudWatch Alarm voor Web2 No Network Traffic
resource "aws_cloudwatch_metric_alarm" "web2_no_traffic_alarm" {
  alarm_name          = "narrekappe-web2-no-network-traffic"
  alarm_description   = "No network traffic detected on Web2 for 5 minutes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "1"
  threshold           = "1"
  period              = "300"
  statistic           = "Sum"
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

# SNS Topic voor no network traffic alerts
resource "aws_sns_topic" "no_traffic_alerts" {
  name = "narrekappe-no-network-traffic-alerts"
  
  tags = {
    Environment = "Test"
    Component   = "Monitoring"
    AlertType   = "NoNetworkTraffic"
  }
}

# SNS Subscription voor beheerder e-mail (Vervang "admin@example.com" met het juiste e-mailadres)
resource "aws_sns_topic_subscription" "admin_email_subscription" {
  topic_arn = aws_sns_topic.no_traffic_alerts.arn
  protocol  = "email"
  endpoint  = "admin@example.com"  # VERVANG DIT MET HET ECHTE E-MAILADRES
}

# Alarm Actions configureren voor no traffic alarms
resource "aws_cloudwatch_metric_alarm" "web1_no_traffic_alarm_final" {
  alarm_name          = "narrekappe-web1-no-network-traffic-final"
  alarm_description   = "No network traffic detected on Web1 - Sending notification"
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
  alarm_actions = [aws_sns_topic.no_traffic_alerts.arn]
  
  tags = {
    Environment = "Test"
    Component   = "WebServer"
  }
}

resource "aws_cloudwatch_metric_alarm" "web2_no_traffic_alarm_final" {
  alarm_name          = "narrekappe-web2-no-network-traffic-final"
  alarm_description   = "No network traffic detected on Web2 - Sending notification"
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
  alarm_actions = [aws_sns_topic.no_traffic_alerts.arn]
  
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

output "monitoring_log_group_arn" {
  value       = aws_cloudwatch_log_group.monitoring_logs.arn
  description = "ARN of the CloudWatch Log Group for monitoring alerts"
}

output "no_traffic_sns_topic_arn" {
  value       = aws_sns_topic.no_traffic_alerts.arn
  description = "ARN of the SNS topic for no network traffic alerts"
}