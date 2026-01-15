terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

# Use existing VPC and subnets
data "aws_vpc" "main" {
  id = "vpc-0f159ef7a0e33559a"
}

data "aws_subnet" "public_a" {
  id = "subnet-037dbf8a81b583ed1"
}

data "aws_subnet" "public_b" {
  id = "subnet-0a66af64d8d1977a5"
}

data "aws_subnet" "private_a" {
  id = "subnet-09b453ad724b57a21"
}

data "aws_subnet" "private_b" {
  id = "subnet-0ea07d5cbea4950a0"
}

data "aws_subnet" "database_a" {
  id = "subnet-0701e2ec2275de53e"
}

data "aws_subnet" "database_b" {
  id = "subnet-04b1cab2b0522cf68"
}

# Security group for RDS (restrict to VPC CIDR by default)
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "RDS SG for ${var.project_name}"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-rds-sg"
    Project = var.project_name
  }
}

## --- DynamoDB in place of RDS ---
resource "aws_dynamodb_table" "employees" {
  name         = "${var.project_name}-employees"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "employeeId"

  attribute {
    name = "employeeId"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

resource "aws_dynamodb_table" "employee_passwords" {
  name         = "${var.project_name}-employee-passwords"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "employeeId"

  attribute {
    name = "employeeId"
    type = "S"
  }

  tags = {
    Project = var.project_name
  }
}

## --- SQS + EventBridge to feed the job-controller ---
resource "aws_sqs_queue" "onboarding" {
  name                       = "${var.project_name}-onboarding-queue"
  visibility_timeout_seconds = 120
  message_retention_seconds  = 1209600
}

resource "aws_cloudwatch_event_rule" "employee_created" {
  name        = "${var.project_name}-employee-created"
  description = "Route employeeCreated events to SQS"

  event_pattern = jsonencode({
    source       = ["eks.backend"]
    "detail-type" = ["employeeCreated"]
  })
}

resource "aws_cloudwatch_event_target" "employee_created_to_sqs" {
  rule      = aws_cloudwatch_event_rule.employee_created.name
  target_id = "sqs-onboarding"
  arn       = aws_sqs_queue.onboarding.arn
}

data "aws_iam_policy_document" "sqs_eventbridge" {
  statement {
    sid    = "AllowEventBridgeSendMessage"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.onboarding.arn]
  }
}

resource "aws_sqs_queue_policy" "onboarding" {
  queue_url = aws_sqs_queue.onboarding.id
  policy    = data.aws_iam_policy_document.sqs_eventbridge.json
}

output "db_endpoint" {
  value = null
}

output "db_port" {
  value = null
}

output "db_name" {
  value = "cs3ncadb"
}

output "db_user" {
  value = "dbadmin"
}

output "dynamodb_employees_table" {
  value = aws_dynamodb_table.employees.name
}

output "dynamodb_passwords_table" {
  value = aws_dynamodb_table.employee_passwords.name
}

output "sqs_queue_url" {
  value = aws_sqs_queue.onboarding.url
}

output "sqs_queue_arn" {
  value = aws_sqs_queue.onboarding.arn
}

# -------------------------
# EKS cluster (minimal)
# -------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Allow nodes to talk to DynamoDB, SQS, and put events (for backend/job-controller workloads)
resource "aws_iam_policy" "app_data_access" {
  name   = "${var.project_name}-app-data-access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.employees.arn,
          aws_dynamodb_table.employee_passwords.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.onboarding.arn
      },
      {
        Effect = "Allow"
        Action = [
          "events:PutEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "node_app_data_access" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = aws_iam_policy.app_data_access.arn
}

resource "aws_security_group" "eks_cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-cluster-sg"
    Project = var.project_name
  }
}

resource "aws_security_group" "eks_nodes" {
  name        = "${var.project_name}-eks-nodes-sg"
  description = "EKS worker nodes"
  vpc_id      = data.aws_vpc.main.id

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow workers to receive from cluster SG"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.eks_cluster.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-eks-nodes-sg"
    Project = var.project_name
  }
}

resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.32"

  vpc_config {
    subnet_ids         = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]
    security_group_ids = [aws_security_group.eks_cluster.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]

  tags = {
    Project = var.project_name
  }
}

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.project_name}-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [data.aws_subnet.public_a.id, data.aws_subnet.public_b.id]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  instance_types = [var.node_instance_type]

  depends_on = [
    aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Project = var.project_name
  }
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_ca" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}
