output "cluster_name" {
  value = aws_eks_cluster.main.name
}

output "node_group_name" {
  value = aws_eks_node_group.default.node_group_name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_ca" {
  value = aws_eks_cluster.main.certificate_authority[0].data
}
