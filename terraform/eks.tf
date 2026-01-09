module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.24.2"

  cluster_name    = var.name
  cluster_version = "1.30"

  vpc_id = data.aws_vpc.vpc_narre_main.id

  subnet_ids = [
    data.aws_subnet.sub_private_1.id,
    data.aws_subnet.sub_private_2.id
  ]

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  # 🔐 RBAC FIX — GEBRUIK DE ECHTE IAM ROLE (NIET assumed-role)
  access_entries = {
    admin = {
      principal_arn = data.aws_iam_session_context.current.issuer_arn

      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_groups = {
    default = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 4

      subnet_ids = [
        data.aws_subnet.sub_private_1.id,
        data.aws_subnet.sub_private_2.id
      ]
    }
  }
}
