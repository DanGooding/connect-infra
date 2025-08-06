
resource "aws_ecr_repository" "static_container_repo" {
  name = "connect-static-server"
  image_scanning_configuration {
    scan_on_push = true
  }
  tags = {
    project_name = var.project_name
  }
}

module "static_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "static-service"
  cluster_arn = module.cluster.arn

  cpu                        = 256 // 0.25 vCPU
  memory                     = 512 // MB
  desired_count              = 1
  deployment_maximum_percent = 200
  enable_autoscaling         = false

  assign_public_ip = true

  // ssh in for debugging
  enable_execute_command = true

  container_definitions = {
    static_server_container = {
      cpu       = 256
      memory    = 512
      essential = true
      image     = "${aws_ecr_repository.static_container_repo.repository_url}:${var.static_service_container_image_tag}"
      portMappings = [{
        containerPort = var.static_service_port
        protocol      = "tcp"
        name          = "static-service"
      }]

      // nginx writes to /etc and /var
      readonlyRootFilesystem = false

      // seems to be creating a very high cardinality of metrics
      enable_cloudwatch_logging = false
    }
  }

  load_balancer = {
    service = {
      target_group_arn = module.alb.target_groups["static"].arn
      container_name   = "static_server_container"
      container_port   = var.static_service_port
    }
  }

  subnet_ids = module.vpc.public_subnets

  security_group_ingress_rules = {
    from_alb = {
      ip_protocol = "tcp"
      // note 'from_port/to_port' in this context define a range of allowed _destination_ ports (in this case a one-element range)
      from_port                    = var.static_service_port
      to_port                      = var.static_service_port
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
    image = var.static_service_container_image_tag
  }

  tags = {
    Name         = "static-ecs-service"
    project_name = var.project_name
  }
}
