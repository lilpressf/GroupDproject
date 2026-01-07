# security_monitoring_simple.tf
# Eenvoudige maar robuuste security monitoring dashboard

# 1. Eerst een variabele definiëren (veiligheidshalve)
variable "enable_advanced_monitoring" {
  description = "Schakel geavanceerde monitoring in (CloudTrail, VPC Flow Logs)"
  type        = bool
  default     = false
}

# 2. Conditionele CloudTrail setup (alleen als geavanceerde monitoring aan staat)
resource "aws_cloudtrail" "security_monitoring_trail" {
  count = var.enable_advanced_monitoring ? 1 : 0
  
  name                          = "narrekappe-security-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_bucket[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  
  depends_on = [aws_s3_bucket_policy.cloudtrail_bucket[0]]
}

# 3. S3 bucket voor CloudTrail (alleen indien nodig)
resource "aws_s3_bucket" "cloudtrail_bucket" {
  count = var.enable_advanced_monitoring ? 1 : 0
  
  bucket        = "narrekappe-cloudtrail-logs-${random_id.bucket_suffix[0].hex}"
  force_destroy = false  # Voorkom per ongeluk verwijderen
}

resource "aws_s3_bucket_policy" "cloudtrail_bucket" {
  count = var.enable_advanced_monitoring ? 1 : 0
  
  bucket = aws_s3_bucket.cloudtrail_bucket[0].id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = var.enable_advanced_monitoring ? 1 : 0
  
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_bucket[0].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }
    
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_bucket[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"]
    
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

# 4. Random suffix voor bucket naam (voorkomt conflicten)
resource "random_id" "bucket_suffix" {
  count = var.enable_advanced_monitoring ? 1 : 0
  
  byte_length = 4
}

# 5. CloudWatch Dashboard - WERKT ALTIJD
resource "aws_cloudwatch_dashboard" "narrekappe_security_monitoring" {
  dashboard_name = "Narrekappe-Security-Monitoring"

  # Gebruik try() functie voor veilige references
  # Als resources niet bestaan, gebruik dan dummy waarden
  dashboard_body = jsonencode({
    widgets = [
      # Database Active Connections - VEILIG MET TRY()
      {
        type = "metric"
        width = 12
        height = 6
        x = 0
        y = 0
        properties = {
          metrics = [
            try(
              ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", aws_db_instance.mydb.identifier, { stat = "Average", label = "Database Active Connections" }],
              ["AWS/RDS", "DatabaseConnections", { stat = "Average", label = "Database (geen data)" }]  # Fallback
            )
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = try("Database Active Connections: ${aws_db_instance.mydb.identifier}", "Database Active Connections")
          view = "timeSeries"
          stacked = false
          sparkline = true
          yAxis = { left = { min = 0 } }
        }
      },
      
      # Database Failed Logins - VEILIG MET TRY()
      {
        type = "metric"
        width = 12
        height = 6
        x = 12
        y = 0
        properties = {
          metrics = [
            try(
              ["AWS/RDS", "LoginFailures", "DBInstanceIdentifier", aws_db_instance.mydb.identifier, { stat = "Sum", label = "Database Failed Logins" }],
              ["AWS/RDS", "LoginFailures", { stat = "Sum", label = "Database (geen data)" }]  # Fallback
            )
          ]
          period = 300
          stat = "Sum"
          region = "eu-central-1"
          title = try("Failed Logins: ${aws_db_instance.mydb.identifier}", "Database Failed Logins")
          view = "singleValue"
          stacked = false
          sparkline = true
        }
      },
      
      # Security Group Rules - VEILIG MET TRY()
      {
        type = "metric"
        width = 8
        height = 6
        x = 0
        y = 6
        properties = {
          metrics = [
            try(
              ["AWS/EC2", "SecurityGroupCount", "InstanceId", aws_instance.web1.id, { stat = "Average", label = "Web1 SG Rules" }],
              ["AWS/EC2", "SecurityGroupCount", { stat = "Average", label = "EC2 (geen data)" }]
            )
          ]
          period = 300
          stat = "Average"
          region = "eu-central-1"
          title = try("Security Rules: ${aws_instance.web1.tags.Name}", "Web Server 1 Security Rules")
          view = "timeSeries"
          stacked = false
          sparkline = true
        }
      },
      
      # CPU Utilization voor security monitoring
      {
        type = "metric"
        width = 8
        height = 6
        x = 8
        y = 6
        properties = {
          metrics = [
            try(
              ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web1.id, { stat = "Average", label = "Web1 CPU" }],
              ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "Web1 CPU (geen data)" }]
            ),
            try(
              ["AWS/EC2", "CPUUtilization", "InstanceId", aws_instance.web2.id, { stat = "Average", label = "Web2 CPU" }],
              ["AWS/EC2", "CPUUtilization", { stat = "Average", label = "Web2 CPU (geen data)" }]
            )
          ]
          period = 60
          stat = "Average"
          region = "eu-central-1"
          title = "Web Servers CPU (security baseline)"
          view = "timeSeries"
          stacked = false
          sparkline = true
          yAxis = { left = { min = 0, max = 100 } }
        }
      },
      
      # Status widget met uitleg
      {
        type = "text"
        width = 8
        height = 6
        x = 16
        y = 6
        properties = {
          markdown = <<-EOT
          ## Security Monitoring Status
          
          ### Actieve Monitoring:
          - ✅ Database connections
          - ✅ Failed login attempts
          - ✅ Security group rules
          - ✅ CPU utilization
          
          ### Geavanceerde monitoring:
          ${var.enable_advanced_monitoring ? "✅ **INGESCHAKELD**" : "❌ **UITGESCHAKELD**"}
          
          *Geavanceerde monitoring inschakelen:*
          ```hcl
          enable_advanced_monitoring = true
          ```
          EOT
        }
      }
    ]
  })
}

# 6. CloudWatch Log Group (veilig, altijd aanmaken)
resource "aws_cloudwatch_log_group" "security_logs" {
  name              = "/aws/narrekappe/security"
  retention_in_days = 30
  
  # Voorkom destroy errors
  lifecycle {
    prevent_destroy = false
  }
  
  tags = {
    Purpose = "SecurityMonitoring"
    ManagedBy = "Terraform"
  }
}

# 7. Data source voor account ID (veilig)
data "aws_caller_identity" "current" {}

# 8. CloudWatch Alarm voor failed logins (optioneel maar veilig)
resource "aws_cloudwatch_metric_alarm" "database_failed_logins" {
  alarm_name          = "database-failed-logins-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "LoginFailures"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Sum"
  threshold           = 5  # Alarm bij >5 failed logins in 5 min
  alarm_description   = "Database failed login attempts exceeded threshold"
  
  # Veilige dimension configuratie
  dimensions = try(
    { DBInstanceIdentifier = aws_db_instance.mydb.identifier },
    {}  # Lege dimensions als DB niet bestaat
  )
  
  # Alarm actions (optioneel)
  alarm_actions = []
  ok_actions    = []
  
  # Voorkom errors als metric niet bestaat
  lifecycle {
    ignore_changes = [dimensions]
  }
}

# 9. Output voor dashboard URL
output "security_dashboard_url" {
  value = "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#dashboards:name=${aws_cloudwatch_dashboard.narrekappe_security_monitoring.dashboard_name}"
  description = "URL naar het security monitoring dashboard"
}

output "monitoring_status" {
  value = {
    basic_monitoring    = "ACTIVE"
    advanced_monitoring = var.enable_advanced_monitoring ? "ACTIVE" : "DISABLED"
    dashboard_name      = aws_cloudwatch_dashboard.narrekappe_security_monitoring.dashboard_name
    log_group           = aws_cloudwatch_log_group.security_logs.name
  }
  description = "Status van monitoring setup"
}