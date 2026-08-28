##############################################################################
# GitHub Actions から OIDC で S3 へデプロイするための最小構成（Terraform 版）
#
# CloudFormation 版（github-oidc-s3.yaml）と同じものを作ります。
# 普段 Terraform を使っている場合はこちらをどうぞ。
#
#   terraform init
#   terraform apply \
#     -var="github_owner=my-org" \
#     -var="github_repo=my-app" \
#     -var="bucket_name=my-app-site-20260902"
##############################################################################

terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

variable "region" {
  type        = string
  default     = "ap-northeast-1"
  description = "リソースを作るリージョン"
}

variable "github_owner" {
  type        = string
  description = "GitHub の組織名またはユーザー名"
}

variable "github_repo" {
  type        = string
  description = "リポジトリ名"
}

variable "github_environment" {
  type        = string
  default     = "production"
  description = "許可する GitHub Environment 名"
}

variable "bucket_name" {
  type        = string
  description = "作成する S3 バケット名（世界で一意）"
}

variable "create_oidc_provider" {
  type        = bool
  default     = true
  description = "OIDC プロバイダを作るか。1 アカウントに 1 つだけなので、既にあるなら false"
}

locals {
  # ★ここが最も重要★ どのリポジトリの、どの環境からかまで完全一致で縛る
  subject = "repo:${var.github_owner}/${var.github_repo}:environment:${var.github_environment}"

  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"

  tags = {
    purpose = "github-actions-workshop"
  }
}

data "aws_caller_identity" "current" {}

# ── 1. GitHub を信頼先として登録する（アカウントに 1 つだけ）
resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  tags            = local.tags
}

# ── 2. 成果物を置く場所
resource "aws_s3_bucket" "site" {
  bucket = var.bucket_name
  tags   = local.tags
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket                  = aws_s3_bucket.site.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "site" {
  bucket = aws_s3_bucket.site.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "site" {
  bucket = aws_s3_bucket.site.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ── 3. GitHub Actions が引き受けるロール
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # ワイルドカード（StringLike）ではなく完全一致で縛るのが安全です
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.subject]
    }
  }
}

data "aws_iam_policy_document" "deploy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.site.arn]
  }
}

resource "aws_iam_role" "deploy" {
  name                 = "github-actions-deploy-${var.github_repo}"
  description          = "Deploy role for ${var.github_owner}/${var.github_repo}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  max_session_duration = 3600
  tags                 = local.tags
}

resource "aws_iam_role_policy" "deploy" {
  name   = "deploy-to-site-bucket"
  role   = aws_iam_role.deploy.id
  policy = data.aws_iam_policy_document.deploy.json
}

##############################################################################
# 出力
##############################################################################

output "role_arn" {
  description = "GitHub の Variables に AWS_ROLE_ARN として設定してください"
  value       = aws_iam_role.deploy.arn
}

output "bucket_name" {
  description = "GitHub の Variables に AWS_S3_BUCKET として設定してください"
  value       = aws_s3_bucket.site.id
}

output "subject_condition" {
  description = "信頼ポリシーで許可している条件"
  value       = local.subject
}
