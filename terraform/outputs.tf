output "region" {
  value = var.region
}

output "ecr_registry" {
  value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com"
}

output "backend_ecr_repo" {
  value = aws_ecr_repository.backend.repository_url
}

output "frontend_ecr_repo" {
  value = aws_ecr_repository.frontend.repository_url
}

output "worker_ecr_repo" {
  value = aws_ecr_repository.worker.repository_url
}

output "frontend_lb_hostname" {
  description = "External LoadBalancer hostname for the frontend (available after LB is provisioned)"
  value = try(kubernetes_service_v1.frontend.status[0].load_balancer[0].ingress[0].hostname, null)
}

output "sqs_queue_url" {
  value = aws_sqs_queue.deployments.id
}

output "sns_topic_arn" {
  value = aws_sns_topic.deployments.arn
}

output "db_endpoint" {
  value = aws_db_instance.this.address
}
