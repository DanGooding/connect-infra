resource "aws_ecr_repository" "api_server_container_repo" {
  name = "connect-api-server"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    project_name = var.project_name
  }
}

resource "aws_secretsmanager_secret" "db_password" {
  name = "connect-db-pass"
  tags = {
    project_name = var.project_name
  }
}

module "api_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "api-service"
  cluster_arn = module.cluster.arn

  cpu                        = 256
  memory                     = 512
  desired_count              = 1
  deployment_maximum_percent = 200
  enable_autoscaling         = false

  assign_public_ip = true

  // ssh in for debugging
  enable_execute_command = true

  container_definitions = {
    api_service_container = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${aws_ecr_repository.api_server_container_repo.repository_url}:${var.api_service_container_image_tag}"
      portMappings = [{
        name          = "api-service"
        containerPort = var.api_service_port
        protocol      = "tcp"
      }]
      environment = [
        {
          name  = "DB_NAME"
          value = var.db_credentials.name
        },
        {
          name  = "DB_USER",
          value = var.db_credentials.user
        },
        {
          name  = "DB_URL",
          value = var.db_credentials.url
        }
      ]
      secrets = [
        {
          name      = "DB_PASS"
          valueFrom = aws_secretsmanager_secret.db_password.arn
        }
      ]
      enable_cloudwatch_logging = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["api"].arn
      container_name   = "api_service_container"
      container_port   = var.api_service_port
    }
  }

  subnet_ids = module.vpc.public_subnets

  security_group_ingress_rules = {
    from_alb = {
      ip_protocol                  = "tcp"
      from_port                    = var.api_service_port
      to_port                      = var.api_service_port
      referenced_security_group_id = module.alb.security_group_id
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  task_tags = {
    image = var.api_service_container_image_tag
  }

  tags = {
    Name         = "api-ecs-service"
    project_name = var.project_name
  }
}

data "aws_iam_policy_document" "access_secrets_for_api_service" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.db_password.arn]
  }
}

resource "aws_iam_policy" "access_secrets_for_api_service" {
  name   = "connect-access-runtime-secrets"
  policy = data.aws_iam_policy_document.access_secrets_for_api_service.json
  tags = {
    project_name = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "api_sevice_can_access_secrets" {
  role       = module.api_service.task_exec_iam_role_name
  policy_arn = aws_iam_policy.access_secrets_for_api_service.arn
}

