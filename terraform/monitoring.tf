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
      
# Database metrics
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mydb.id, { stat = "Average", label = "Database CPU" }]
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
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mydb.id, { stat = "Average", label = "Database Connections" }],
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", aws_db_instance.mydb.id, { stat = "Average", label = "Free Storage" }]
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Database Performance"
          view = "timeSeries"
          stacked = false
        }
      },
    ]
  })
}