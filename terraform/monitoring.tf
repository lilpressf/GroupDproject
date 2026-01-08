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
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { stat = "Average", label = "Web1 CPU" }],
            ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { stat = "Average", label = "Web2 CPU" }]
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
      
# EC2 Instance metrics - Network (gesplitst in 2 widgets)
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web1.id, { stat = "Sum", label = "Web1 Network In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web1.id, { stat = "Sum", label = "Web1 Network Out" }]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Web1 Network Traffic"
          view = "timeSeries"
          stacked = false
        }
      },
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web2.id, { stat = "Sum", label = "Web2 Network In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web2.id, { stat = "Sum", label = "Web2 Network Out" }]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "Web2 Network Traffic"
          view = "timeSeries"
          stacked = false
        }
      },
      
# EC2 Instance metrics - Disk usage
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.web1.id, "path", "/", { stat = "Average", label = "Web1 Disk %" }],
            ["CWAgent", "disk_used_percent", "InstanceId", aws_instance.web2.id, "path", "/", { stat = "Average", label = "Web2 Disk %" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "WebServer Disk Usage (%)"
          view = "timeSeries"
          stacked = false
          yAxis = {
            left = { min = 0, max = 100 }
          }
        }
      },
      
# Database metrics - CPU
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { stat = "Average", label = "Database CPU" }]
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
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { stat = "Average", label = "Database Connections" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Connections"
          view = "singleValue"
          stacked = false
        }
      },
      
# Database metrics - Free Storage in GB
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { stat = "Average", label = "Free Storage (GB)", unit = "Gigabytes" }]
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