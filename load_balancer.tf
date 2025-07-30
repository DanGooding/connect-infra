
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name               = "connect-alb"
  load_balancer_type = "application"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnets

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  listeners = {
    listener = {
      protocol = "HTTPS"
      port     = 443

      certificate_arn = var.domain_certificate_arn

      rules = {
        api = {
          conditions = [
            {
              path_pattern = {
                values = ["/api/*"]
              }
            }
          ]
          actions = [
            {
              type             = "forward"
              target_group_key = "api"
            }
          ]
        }
      }

      // default rule
      forward = {
        target_group_key = "static"
      }
    }
  }

  target_groups = {
    static = {
      target_type = "ip"

      // ECS will attach services to the group dynamically
      create_attachment = false
    }

    api = {
      target_type = "ip"

      create_attachment = false

      health_check = {
        matcher  = 200
        path     = "/api/walls/random"
        port     = "traffic-port"
        protocol = "HTTP"
      }
    }
  }
  tags = {
    project_name = var.project_name
  }
}
