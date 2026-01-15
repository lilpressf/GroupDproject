variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "narrekappe"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "narrekappe-eks"
}

variable "node_instance_type" {
  description = "EKS worker node instance type"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "EKS node group desired size"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "EKS node group min size"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "EKS node group max size"
  type        = number
  default     = 3
}

variable "vpc_cidr" {
  description = "VPC CIDR for RDS network"
  type        = string
  default     = "10.20.0.0/16"
}

variable "rds_engine" {
  description = "RDS engine"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "RDS engine version"
  type        = string
  default     = "16.3"
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
  description = "RDS master password"
  type        = string
  sensitive   = true
}
