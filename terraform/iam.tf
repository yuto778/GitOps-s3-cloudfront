# GitHubをOIDCプロバイダーとして登録
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["2b18947a6a9fc7764fd8b5fb18a863b0c6dac24f"]
}

# GitHub Actionsが引き受けるためのIAMロール
resource "aws_iam_role" "github_actions" {
  name = "github-actions-role-for-s3-deploy"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:yuto778/GitOps-s3-cloudfront:*"
          }
        }
      }
    ]
  })
}

# IAMロールにアタッチするポリシー
resource "aws_iam_policy" "s3_access" {
  name        = "s3-access-policy-for-gitops"
  description = "Allows S3 and DynamoDB access for GitOps"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3Access"
        Effect = "Allow"
        Action = "s3:*"
        Resource = [
          "arn:aws:s3:::my-gitops-test-bucket-20250803",
          "arn:aws:s3:::my-gitops-test-bucket-20250803/*",
          "arn:aws:s3:::terraform-state-215ad062",
          "arn:aws:s3:::terraform-state-215ad062/*"
        ]
      },
      {
        Sid    = "DynamoDBLockTableAccess"
        Effect = "Allow"
        Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem",
            "dynamodb:DescribeTable"
        ]
        Resource = "arn:aws:dynamodb:ap-northeast-1:048588986880:table/terraform-lock-215ad062"
      },
      {
        Sid    = "TerraformStateAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = [
          "arn:aws:s3:::terraform-state-215ad062",
          "arn:aws:s3:::terraform-state-215ad062/*"
        ]
      },
      {
        Sid    = "CloudFrontAccess"
        Effect = "Allow"
        Action = [
          "cloudfront:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMAccess"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "*"
      }
    ]
  })
}

# ロールとポリシーを紐付け
resource "aws_iam_role_policy_attachment" "attach_s3_access" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# 作成したロールのARNを出力
output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}