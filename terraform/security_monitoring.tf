# security_monitoring.tf - Vereenvoudigde werkende versie
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
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "narre-db", { stat = "Average", label = "Database Active Connections" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Active Connections"
          view = "timeSeries"
          stacked = false
        }
      },
      
      # Database Failed Logins
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
          title = "Database Failed Login Attempts"
          view = "singleValue"
          stacked = false
        }
      },
      
      # Security Status
      {
        type = "text"
        width = 24
        height = 6
        x = 0
        y = 6
        properties = {
          markdown = "## Security Monitoring\n\n- ✅ Database connections monitoring\n- ✅ Failed login monitoring\n- 📊 Alerts configured for high activity\n\nDashboard: Narrekappe-Security-Monitoring"
        }
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/narrekappe/security"
  retention_in_days = 30
}