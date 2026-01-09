# logs.tf - CloudWatch Alarms met SNS notificaties

# SNS Topic voor e-mail notificaties
resource "aws_sns_topic" "alerts_topic" {
  name = "narrekappe-alerts"
}

# SNS Subscription voor e-mail
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.alerts_topic.arn
  protocol  = "email"
  endpoint  = "554603@student.fontys.nl"  # Email from the administrator
}

# Alarm voor Web1 CPU >= 80%
resource "aws_cloudwatch_metric_alarm" "web1_cpu_high" {
  alarm_name          = "web1-cpu-high"
  alarm_description   = "Web1 CPU usage is 80% or higher"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 60
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web1.id
  }
  alarm_actions = [aws_sns_topic.alerts_topic.arn]
}

# Alarm voor Web2 CPU >= 80%
resource "aws_cloudwatch_metric_alarm" "web2_cpu_high" {
  alarm_name          = "web2-cpu-high"
  alarm_description   = "Web2 CPU usage is 80% or higher"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 60
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  dimensions = {
    InstanceId = aws_instance.web2.id
  }
  alarm_actions = [aws_sns_topic.alerts_topic.arn]
}

# Alarm voor Database CPU >= 80%
resource "aws_cloudwatch_metric_alarm" "db_cpu_high" {
  alarm_name          = "db-cpu-high"
  alarm_description   = "Database CPU usage is 80% or higher"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 80
  period              = 60
  statistic           = "Average"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.narre-db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts_topic.arn]
}

# Alarm voor Database vrije opslag <= 5GB
resource "aws_cloudwatch_metric_alarm" "db_low_storage" {
  alarm_name          = "db-low-storage"
  alarm_description   = "Database has less than 5GB free storage"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 5 * 1024 * 1024 * 1024  # 5GB in bytes
  period              = 60
  statistic           = "Average"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  dimensions = {
    DBInstanceIdentifier = aws_db_instance.narre-db.identifier
  }
  alarm_actions = [aws_sns_topic.alerts_topic.arn]
}

# Alarm voor mislukte login pogingen
resource "aws_cloudwatch_metric_alarm" "failed_login" {
  alarm_name          = "failed-login-attempt"
  alarm_description   = "Er is een mislukte login poging in het AWS systeem"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = 1
  period              = 300
  statistic           = "Sum"
  metric_name         = "ConsoleLoginFailureCount"
  namespace           = "Narrekappe/Security"
  alarm_actions       = [aws_sns_topic.alerts_topic.arn]
}