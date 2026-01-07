# security_monitoring_simple.tf
# Eenvoudige monitoring van gefaalde login pogingen

# CloudWatch Dashboard voor Failed Logins
resource "aws_cloudwatch_dashboard" "failed_logins_dashboard" {
  dashboard_name = "Narrekappe-Failed-Logins"

  dashboard_body = jsonencode({
    widgets = [
      # Instructie widget
      {
        type = "text"
        width = 24
        height = 4
        x = 0
        y = 0
        properties = {
          markdown = <<-EOT
          # 🔒 Failed Login Monitoring
          
          **Status:** ✅ Dashboard actief
          
          **Wat wordt gemonitord:**
          - Gefaalde AWS Console logins
          - Database failed login attempts
          
          **Dashboard naam:** Narrekappe-Failed-Logins
          EOT
        }
      },
      
      # Database Failed Logins (werkt als RDS bestaat)
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 4
        properties = {
          metrics = [
            # Deze metric werkt als je RDS database "narre-db" bestaat
            ["AWS/RDS", "LoginFailures", "DBInstanceIdentifier", "narre-db", 
             { "stat": "Sum", "label": "RDS Failed Logins" }]
          ]
          period = 300
          stat = "Sum"
          region = "eu-central-1"
          title = "Database Failed Login Attempts (last 5 minutes)"
          view = "singleValue"
          stacked = false
        }
      },
      
      # Alert Threshold widget
      {
        type = "text"
        width = 12
        height = 6
        x = 12
        y = 4
        properties = {
          markdown = <<-EOT
          ## Alert Thresholds
          
          **Database Failed Logins:**
          - ⚠️  Warning: >5 in 5 min
          - 🚨 Critical: >10 in 5 min
          
          **AWS Console Logins:**
          - Configureer CloudTrail voor monitoring
          - S3 bucket vereist voor logs
          
          **Volgende stappen:**
          1. Controleer RDS metrics
          2. CloudTrail inschakelen
          3. Alerts configureren
          EOT
        }
      }
    ]
  })
}

# CloudWatch Alarm voor database failed logins
resource "aws_cloudwatch_metric_alarm" "db_failed_logins_alarm" {
  alarm_name          = "narrekappe-db-failed-logins"
  alarm_description   = "Alarm when database has failed login attempts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 5  # Alarm bij >5 failed logins in 5 minuten
  period              = 300  # 5 minuten
  
  metric_name = "LoginFailures"
  namespace   = "AWS/RDS"
  statistic   = "Sum"
  
  # Statische identifier zoals gedefinieerd in je database.tf
  dimensions = {
    DBInstanceIdentifier = "narre-db"
  }
  
  # Geen alarm actions voor nu (kan later toegevoegd worden)
  alarm_actions = []
  
  tags = {
    Environment = "Test"
    Component   = "Security"
  }
}

# CloudWatch Log Group voor security logs (optioneel)
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/narrekappe/security"
  retention_in_days = 30
  
  tags = {
    Purpose = "SecurityMonitoring"
  }
}

# Output voor gebruiker
output "failed_logins_monitoring_info" {
  value = <<-EOT
  Failed Login Monitoring geconfigureerd!
  
  📊 Dashboard: Narrekappe-Failed-Logins
  🔔 Alarm: narrekappe-db-failed-logins (trigger bij >5 failed logins)
  
  URL: https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=Narrekappe-Failed-Logins
  
  Let op: Database moet bestaan ("narre-db") voordat metrics verschijnen.
  EOT
  
  description = "Informatie over gefaalde login monitoring"
}