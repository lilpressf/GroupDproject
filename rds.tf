variable "rds_enabled" {
  description = "Enable RDS provisioning"
  type        = bool
  default     = false
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_allocated_storage" {
  description = "RDS allocated storage (GB)"
  type        = number
  default     = 20
}

variable "rds_master_username" {
  description = "RDS master username"
  type        = string
  default     = "dbadmin"
}

variable "rds_master_password" {
  description = "RDS master password (supply via tfvars or env)"
  type        = string
  default     = ""
}

resource "aws_db_subnet_group" "employees" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]

  tags = {
    Name    = "${var.project_name}-db-subnet"
    Project = var.project_name
  }
}

resource "aws_security_group" "rds" {
  count = var.rds_enabled ? 1 : 0
  name  = "${var.project_name}-rds-sg"
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

resource "aws_db_instance" "employees" {
  count                      = var.rds_enabled ? 1 : 0
  identifier                 = "${var.project_name}-employees"
  engine                     = var.rds_engine
  instance_class             = var.rds_instance_class
  allocated_storage          = var.rds_allocated_storage
  db_name                    = "${var.project_name}_db"
  username                   = var.rds_master_username
  password                   = var.rds_master_password
  db_subnet_group_name       = aws_db_subnet_group.employees.name
  vpc_security_group_ids     = var.worker_security_group_id != "" ? [var.worker_security_group_id] : (aws_security_group.rds.*.id)
  skip_final_snapshot        = true
  publicly_accessible        = false

  tags = {
    Name    = "${var.project_name}-rds"
    Project = var.project_name
  }
}
