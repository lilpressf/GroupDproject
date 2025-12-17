variable "name" {
  type        = string
  description = "Name prefix for resources."
}

variable "level" {
  type        = number
  description = "Security level: 1 (easy), 2 (medium), 3 (hard)."

  validation {
    condition     = contains([1, 2, 3], var.level)
    error_message = "level must be 1, 2, or 3."
  }
}

variable "vpc_id" {
  type        = string
  description = "VPC id."
}

variable "subnet_id" {
  type        = string
  description = "Subnet id."
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type."
  default     = "t3.micro"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair name."
  default     = null
}

variable "admin_username" {
  type        = string
  description = "Linux username."
  default     = "ubuntu"
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDRs allowed to reach SSH."
  default     = []
}

variable "http_enabled" {
  type        = bool
  description = "Expose HTTP (port 80)."
  default     = true
}

variable "ssh_port_level3" {
  type        = number
  description = "Non-standard SSH port for Level 3."
  default     = 2222
}

variable "tags" {
  type        = map(string)
  description = "Extra resource tags."
  default     = {}
}
