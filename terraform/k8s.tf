############################
# Namespace
############################
resource "kubernetes_namespace_v1" "training" {
  metadata {
    name = "training"
  }
}

############################
# Service Accounts (IRSA)
############################
resource "kubernetes_service_account_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.backend.arn
    }
  }
}

resource "kubernetes_service_account_v1" "worker" {
  metadata {
    name      = "onboarding-worker"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.worker.arn
    }
  }
}

############################
# ConfigMap
############################
resource "kubernetes_config_map_v1" "app" {
  metadata {
    name      = "app-config"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
  }

  data = {
    REGION      = var.region
    DB_HOST     = aws_db_instance.this.address
    DB_PORT     = "5432"
    DB_NAME     = "training"
    DB_USER     = "trainingadmin"
    DB_PASSWORD = "Training123!"

    EVENT_BUS_NAME = aws_cloudwatch_event_bus.deployments.name
    SQS_QUEUE_URL  = aws_sqs_queue.deployments.id
    SNS_TOPIC_ARN  = aws_sns_topic.deployments.arn

    EASY_INSTANCE_TYPE   = var.instance_type_easy
    MEDIUM_INSTANCE_TYPE = var.instance_type_medium
    HARD_INSTANCE_TYPE   = var.instance_type_hard

    MEDIUM_AMI_ID = "ami-09d8bff2a9b85504b"
    HARD_AMI_ID   = "ami-00b1ea19ef4fc0457"

    VM_SUBNET_ID      = local.vm_subnet_id
    VM_SECURITY_GROUP = aws_security_group.vm.id
  }
}

############################
# Backend Deployment
############################
resource "kubernetes_deployment_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    labels = { app = "backend" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "backend" }
    }

    template {
      metadata {
        labels = { app = "backend" }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.backend.metadata[0].name

        container {
          name  = "backend"
          image = "${aws_ecr_repository.backend.repository_url}:latest"

          port {
            container_port = 8080
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.app.metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}

############################
# Backend Service
############################
resource "kubernetes_service_v1" "backend" {
  metadata {
    name      = "backend"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
  }

  spec {
    selector = { app = "backend" }

    port {
      port        = 80
      target_port = 8080
    }

    type = "ClusterIP"
  }
}

############################
# Frontend Deployment
############################
resource "kubernetes_deployment_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    labels = { app = "frontend" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "frontend" }
    }

    template {
      metadata {
        labels = { app = "frontend" }
      }

      spec {
        container {
          name  = "frontend"
          image = "${aws_ecr_repository.frontend.repository_url}:latest"

          port {
            container_port = 80
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}

############################
# Frontend Service (PUBLIC)
############################
resource "kubernetes_service_v1" "frontend" {
  metadata {
    name      = "frontend"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = { app = "frontend" }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

############################
# ✅ ONBOARDING WORKER (DIT ONTBRAK)
############################
resource "kubernetes_deployment_v1" "worker" {
  metadata {
    name      = "onboarding-worker"
    namespace = kubernetes_namespace_v1.training.metadata[0].name
    labels = { app = "onboarding-worker" }
  }

  spec {
    replicas = 1

    selector {
      match_labels = { app = "onboarding-worker" }
    }

    template {
      metadata {
        labels = { app = "onboarding-worker" }
      }

      spec {
        service_account_name = kubernetes_service_account_v1.worker.metadata[0].name

        container {
          name  = "worker"
          image = "${aws_ecr_repository.worker.repository_url}:latest"

          env_from {
            config_map_ref {
              name = kubernetes_config_map_v1.app.metadata[0].name
            }
          }
        }
      }
    }
  }

  depends_on = [module.eks]
}
