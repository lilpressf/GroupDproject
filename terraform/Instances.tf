
variable "ami_id" {
  description = "AMI ID to use"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "How many instances to create"
  type        = number
  default     = 5
}

variable "subnet_id" {
  description = "VPC subnet to place instances in 
  type        = string
  default     = null
}

# custom security groups (otherwise AWS will use default SG in default VPC)
variable "vpc_security_group_ids" {
  description = "List of SG IDs (optional)"
  type        = list(string)
  default     = null
}

# attach a key pair for SSH either daan or habib has this 
variable "key_name" {
  description = "EC2 key pair name (optional)"
  type        = string
  default     = null
}

resource "aws_instance" "nodes" {
  count         = var.instance_count
  ami           = var.ami_id
  instance_type = var.instance_type
 tags = {
    Name = "lab-node-${count.index + 1}"
  }
}

output "instance_ids" {
  value = [for i in aws_instance.nodes : i.id]
}
