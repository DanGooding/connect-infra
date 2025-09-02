module "cluster" {
  source = "terraform-aws-modules/ecs/aws//modules/cluster"

  name = "connect-ecs-cluster"
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 100
    }
  }

  setting = [
    {
      name  = "containerInsights"
      value = "disabled"
    }
  ]

  tags = {
    project_name = var.project_name
  }
}
