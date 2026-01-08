resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Narrekappe-Monitoring"
  
  dashboard_body = jsonencode({
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
      
# Database metrics - Connections
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