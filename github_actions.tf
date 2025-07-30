resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  tags = {
    project_name = var.project_name
  }
}

data "aws_iam_policy_document" "assume_github_actions_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.github.arn
      ]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name = "connect-github-actions"

  assume_role_policy = data.aws_iam_policy_document.assume_github_actions_role.json

  tags = {
    project_name = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_can_push_to_ecr_repos" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.push_to_ecr_repos.arn
}

data "aws_iam_policy_document" "push_to_ecr_repos" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:DescribeImages",
      "ecr:DescribePullThroughCacheRules",
      "ecr:ListImages",
      "ecr:BatchGetRepositoryScanningConfiguration",
      "ecr:DescribeRegistry",
      "ecr:GetImageCopyStatus",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:GetRegistryPolicy",
      "ecr:ListTagsForResource",
      "ecr:BatchDeleteImage",
      "ecr:BatchImportUpstreamImage",
      "ecr:PutImageTagMutability",
      "ecr:ReplicateImage",
      "ecr:TagResource",
      "ecr:UntagResource"
    ]
    resources = [aws_ecr_repository.api_server_container_repo.arn, aws_ecr_repository.static_container_repo.arn]
  }
}

resource "aws_iam_policy" "push_to_ecr_repos" {
  name   = "connect-push-to-ecr-repos"
  policy = data.aws_iam_policy_document.push_to_ecr_repos.json
  tags = {
    project_name = var.project_name
  }
}
