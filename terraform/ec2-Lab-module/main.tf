############################
# AMI (Ubuntu 22.04 LTS)
############################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

############################
# Locals for level behavior
############################

locals {
  # Network exposure rules by level
  ssh_open_to_world = var.level == 1
  ssh_restricted    = var.level >= 2

  http_open = var.http_enabled

  ssh_port = var.level == 3 ? var.ssh_port_level3 : 22

  ssh_cidrs = local.ssh_open_to_world ? ["0.0.0.0/0"] : (
    length(var.allowed_ssh_cidrs) > 0 ? var.allowed_ssh_cidrs : ["0.0.0.0/0"]
  )

  # SSH auth posture
  password_auth = var.level == 1
  root_login    = var.level == 3 ? "no" : "prohibit-password"
}

############################
# Security Group
############################

resource "aws_security_group" "this" {
  name        = "${var.name}-lvl${var.level}-sg"
  description = "EC2 security level ${var.level}"
  vpc_id      = var.vpc_id

  # SSH
  ingress {
    description = "SSH"
    from_port   = local.ssh_port
    to_port     = local.ssh_port
    protocol    = "tcp"
    cidr_blocks = local.ssh_cidrs
  }

  # HTTP (optional)
  dynamic "ingress" {
    for_each = local.http_open ? [1] : []
    content {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  # Egress open
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-lvl${var.level}-sg"
    Level  = tostring(var.level)
    Module = "ec2_security_level"
  })
}

############################
# User data (cloud-init)
############################

locals {
  user_data = <<-CLOUDINIT
  #cloud-config
  package_update: true
  package_upgrade: ${var.level >= 2 ? "true" : "false"}

  packages:
    - nginx
    - ufw
    - fail2ban

  write_files:
    - path: /var/www/html/index.html
      permissions: "0644"
      content: |
        <html>
          <head><title>${var.name} - Level ${var.level}</title></head>
          <body style="font-family: sans-serif;">
            <h1>${var.name}</h1>
            <p>EC2 lab instance - Security Level <b>${var.level}</b></p>
          </body>
        </html>

    - path: /etc/ssh/sshd_config.d/99-${var.name}-lab.conf
      permissions: "0644"
      content: |
        Port ${local.ssh_port}
        PasswordAuthentication ${local.password_auth ? "yes" : "no"}
        KbdInteractiveAuthentication ${local.password_auth ? "yes" : "no"}
        PermitRootLogin ${local.root_login}
        X11Forwarding no
        AllowTcpForwarding ${var.level == 3 ? "no" : "yes"}

  runcmd:
    - systemctl enable nginx
    - systemctl restart nginx

    # Firewall posture
    - |
      if [ "${var.level}" = "1" ]; then
        ufw --force disable || true
      else
        ufw --force reset || true
        ufw default deny incoming
        ufw default allow outgoing
        ufw allow ${local.ssh_port}/tcp
        ${local.http_open ? "ufw allow 80/tcp" : "# http disabled"}
        ufw --force enable
      fi

    # Restart SSH
    - systemctl restart ssh || systemctl restart sshd

    # Fail2ban handling
    - |
      if [ "${var.level}" = "1" ]; then
        systemctl disable --now fail2ban || true
      else
        systemctl enable --now fail2ban || true
      fi
  CLOUDINIT
}

############################
# EC2 Instance
############################

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  user_data = local.user_data

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.tags, {
    Name   = "${var.name}-lvl${var.level}"
    Level  = tostring(var.level)
    Module = "ec2_security_level"
  })
}
