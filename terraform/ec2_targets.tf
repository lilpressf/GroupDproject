# Where worker should place EC2 instances (subnet + SG)
resource "aws_security_group" "vm" {
  name        = "${var.name}-vm"
  description = "VMs for training"
  vpc_id      = data.aws_vpc.vpc_narre_main.id
  tags        = local.tags
}

# Example: allow SSH only from within VPC (adjust!)
resource "aws_security_group_rule" "vm_ssh_vpc" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = [data.aws_vpc.vpc_narre_main.cidr_block]
  security_group_id = aws_security_group.vm.id
}

resource "aws_security_group_rule" "vm_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.vm.id
}

locals {
  vm_subnet_id = data.aws_subnet.sub_student_1.id
}
