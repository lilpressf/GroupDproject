# Database subnet groep
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "narre-db-subnet-group"
  subnet_ids = [aws_subnet.sub_database_2.id, aws_subnet.sub_private_1.id]

  tags = {
    Name = "narre-db-subnet-group"
  }
}

# Parameter groep voor MySQL 8.0
resource "aws_db_parameter_group" "db_params" {
  name   = "narre-mysql8-params"
  family = "mysql8.0"

  parameter {
    name  = "log_bin_trust_function_creators"
    value = "1"
  }

  parameter {
    name  = "slow_query_log"
    value = "1"
  }

  tags = {
    Name = "narre-db-params"
  }
}

# RDS MySQL database
resource "aws_db_instance" "narre-db" {
  identifier           = "narre-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  
  db_name              = "narre_db"
  username             = var.db_username
  password             = var.db_password
  
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.database_sg.id]
  
  publicly_accessible    = true
#   publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false

  enabled_cloudwatch_logs_exports = ["general", "slowquery"]
  parameter_group_name = aws_db_parameter_group.db_params.name
  
  tags = {
    Name = "narre-db"
  }
}

# Optioneel: Outputs voor gebruik elders
output "db_endpoint" {
  value       = aws_db_instance.narre-db.endpoint
  description = "Database endpoint voor connectie"
  sensitive   = false
}

output "db_address" {
  value       = aws_db_instance.narre-db.address
  description = "Database hostname"
  sensitive   = false
}

output "db_port" {
  value       = aws_db_instance.narre-db.port
  description = "Database poort"
  sensitive   = false
}