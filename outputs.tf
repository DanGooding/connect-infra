output "alb_hostname" {
  description = "hostname of entry point load balancer"
  value       = module.alb.dns_name
}

output "github_actions_role" {
  description = "role to run github actions as"
  value       = aws_iam_role.github_actions.arn
}
