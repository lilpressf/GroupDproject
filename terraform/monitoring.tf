resource "aws_cloudwatch_dashboard" "main_dashboard" {
  dashboard_name = "Narrekappe-Monitoring"
  
  dashboard_body = jsonencode({
    widgets = [

# EC2 Instance metrics
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
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web1.id, { stat = "Sum", label = "Web1 Network In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web1.id, { stat = "Sum", label = "Web1 Network Out" }],
            ["AWS/EC2", "NetworkIn", "InstanceId", aws_instance.web2.id, { stat = "Sum", label = "Web2 Network In" }],
            ["AWS/EC2", "NetworkOut", "InstanceId", aws_instance.web2.id, { stat = "Sum", label = "Web2 Network Out" }]
          ]
          period = 60
          stat = "Sum"
          region = "eu-central-1"
          title = "WebServer Network Traffic"
          view = "timeSeries"
          stacked = false
        }
      },
      
# Nieuwe metric: Disk usage voor webservers
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
      
# Database metrics - GECORRIGEERD: gebruik identifier in plaats van id
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
      
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { stat = "Average", label = "Database Connections" }],
            # Toon beschikbare GB in plaats van bytes
            [".", "FreeStorageSpace", ".", ".", { stat = "Average", label = "Free Storage (GB)", yAxis = "right", unit = "Gigabytes" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Performance"
          view = "timeSeries"
          stacked = false
        }
      },
      
# Database vrije storage in GB
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.narre-db.identifier, { stat = "Average", label = "Free Storage", unit = "Gigabytes" }]
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