# security_monitoring.tf
# Volledig werkende security monitoring voor Narrekappe project

# CloudWatch Dashboard voor Security Monitoring - ZONDER FOUTEN
resource "aws_cloudwatch_dashboard" "narrekappe_security_monitoring" {
  dashboard_name = "Narrekappe-Security-Monitoring"

  dashboard_body = jsonencode({
    widgets = [
      # Database Active Connections - VEILIG
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 0
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "narre-db", { stat = "Average", label = "Database Active Connections" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Active Connections: narre-db"
          view = "timeSeries"
          stacked = false
          sparkline = true
          yAxis = { left = { min = 0 } }
        }
      },
      
      # Database Failed Logins - VEILIG
      {
        type = "metric"
        width = 12
        height = 6
        x = 12
        y = 0
        properties = {
          metrics = [
            ["AWS/RDS", "LoginFailures", "DBInstanceIdentifier", "narre-db", { stat = "Sum", label = "Database Failed Logins" }]
          ]
          period = 300
          stat = "Sum"
          region = "eu-central-1"
          title = "Database Failed Login Attempts (last 5min)"
          view = "singleValue"
          stacked = false
          sparkline = true
        }
      },
      
      # Network Security - VPC Flow Logs voor REJECTED connections
      {
        type = "log"
        width = 12
        height = 6
        x = 0
        y = 6
        properties = {
          query = <<-EOT
            fields @timestamp, srcAddr, dstAddr, dstPort, action, logStatus
            | filter action = "REJECT"
            | stats count() as rejected_count by srcAddr, dstAddr, dstPort
            | sort rejected_count desc
            | limit 10
          EOT
          region = "eu-central-1"
          title = "Top 10 Geweigerde Connecties (indien Flow Logs actief)"
          view = "table"
        }
      },
      
      # Security Alert Status
      {
        type = "text"
        width = 12
        height = 6
        x = 12
        y = 6
        properties = {
          markdown = <<-EOT
          ## Security Monitoring Status
          
          ### Actieve Monitoring:
          - ✅ Database active connections
          - ✅ Database failed logins
          - 🔄 Network flow logs (indien geconfigureerd)
          
          ### Geconfigureerde Resources:
          - RDS Database: narre-db
          - VPC: vpc_narre_main
          - Web Servers: web1 & web2
          
          ### Volgende Stappen:
          1. CloudTrail inschakelen voor login auditing
          2. VPC Flow Logs configureren
          3. Alerts instellen voor failed logins
          EOT
        }
      },
      
      # CPU Utilization voor security baseline
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 12
        properties = {
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "Alle Web Servers" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Web Servers CPU Usage (Security Baseline)"
          view = "timeSeries"
          stacked = false
          sparkline = true
          yAxis = { left = { min = 0, max = 100 } }
        }
      }
    ]
  })
}

# CloudWatch Log Group voor security logs
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/narrekappe/security"
  retention_in_days = 30
  
  tags = {
    Project = "Narrekappe"
    Environment = "Test"
    ManagedBy = "Terraform"
  }
}

# CloudWatch Alarm voor failed database logins
resource "aws_cloudwatch_metric_alarm" "database_failed_logins_alarm" {
  alarm_name          = "narrekappe-database-failed-logins"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "LoginFailures"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Sum"
  threshold           = 10  # Alarm bij >10 failed logins in 5 min
  alarm_description   = "Alarm wanneer er meer dan 10 gefaalde database logins zijn in 5 minuten"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = "narre-db"
  }
  
  tags = {
    Environment = "Test"
    Severity = "High"
  }
}

# CloudWatch Alarm voor database connections (te hoog)
resource "aws_cloudwatch_metric_alarm" "database_high_connections" {
  alarm_name          = "narrekappe-database-high-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 20  # Alarm bij meer dan 20 actieve connections
  alarm_description   = "Alarm wanneer database teveel actieve verbindingen heeft"
  treat_missing_data  = "notBreaching"
  
  dimensions = {
    DBInstanceIdentifier = "narre-db"
  }
  
  tags = {
    Environment = "Test"
    Severity = "Medium"
  }
}

# Simpele VPC Flow Logs voor security monitoring
resource "aws_flow_log" "security_flow_logs" {
  log_destination_type = "cloud-watch-logs"
  traffic_type         = "REJECT"  # Alleen geweigerde verbindingen loggen
  vpc_id               = aws_vpc.vpc_narre_main.id
  log_destination      = aws_cloudwatch_log_group.security_flow_logs.arn
  max_aggregation_interval = 60
  
  tags = {
    Name = "narrekappe-security-flow-logs"
  }
}

resource "aws_cloudwatch_log_group" "security_flow_logs" {
  name              = "/aws/vpc/narrekappe/flow-logs"
  retention_in_days = 14  # Kortere retention voor security logs
  
  tags = {
    Purpose = "SecurityMonitoring"
  }
}

# IAM Role voor VPC Flow Logs
resource "aws_iam_role" "vpc_flow_logs_role" {
  name = "narrekappe-vpc-flow-logs-role"

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
  name = "narrekappe-vpc-flow-logs-policy"
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
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      }
    ]
  })
}

# Outputs voor monitoring informatie
output "security_monitoring_info" {
  value = {
    dashboard_url = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=Narrekappe-Security-Monitoring"
    alarms_configured = [
      "database-failed-logins",
      "database-high-connections"
    ]
    log_groups = [
      aws_cloudwatch_log_group.security_logs.name,
      aws_cloudwatch_log_group.security_flow_logs.name
    ]
  }
  description = "Security monitoring setup informatie"
}

output "security_alarms_info" {
  value = <<-EOT
  Security Alarms geconfigureerd:
  
  1. Database Failed Logins Alarm
     - Naam: narrekappe-database-failed-logins
     - Trigger: >10 failed logins in 5 minuten
     - Severity: High
     
  2. Database High Connections Alarm
     - Naam: narrekappe-database-high-connections
     - Trigger: >20 actieve verbindingen
     - Severity: Medium
     
  Dashboard beschikbaar via: 
  https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=Narrekappe-Security-Monitoring
  EOT
  
  description = "Informatie over geconfigureerde security alarms"
}