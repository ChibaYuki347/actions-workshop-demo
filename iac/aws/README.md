# AWS で試す（持ち帰り用）

ワークショップ当日は Azure でデモをご覧いただきますが、
**やっていることは AWS でもまったく同じ**です。

ここには、みなさんの AWS アカウントで同じことを試すための
テンプレートを置いています。CloudFormation と Terraform のどちらでも構いません。

> 作られるのは **S3 バケット 1 つと IAM ロール 1 つ**だけです。
> 長期のアクセスキー（`AKIA...`）は 1 つも作りません。

## Azure との対応

| やること | AWS | Azure |
|---|---|---|
| GitHub を信頼先として登録 | IAM OIDC プロバイダ | Entra ID アプリ登録 |
| 権限の入れ物 | IAM ロール | サービスプリンシパル |
| どこから使えるか絞る | 信頼ポリシーの `sub` 条件 | フェデレーション資格情報の `subject` |
| ログイン用の Action | `aws-actions/configure-aws-credentials` | `azure/login` |
| ワークフロー側の権限 | `id-token: write` | `id-token: write` |
| GitHub に置く秘密 | **なし** | **なし** |

**縛るための文字列は AWS も Azure もまったく同じ形式**です。

```
repo:<owner>/<repo>:environment:production
```

## CloudFormation で作る

```bash
aws cloudformation deploy \
  --template-file github-oidc-s3.yaml \
  --stack-name github-actions-demo \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides \
      GitHubOwner=<組織名> \
      GitHubRepo=<リポジトリ名> \
      BucketName=<世界で一意なバケット名>

# 出力を確認
aws cloudformation describe-stacks \
  --stack-name github-actions-demo \
  --query "Stacks[0].Outputs"
```

> すでに OIDC プロバイダを作ったことがある AWS アカウントでは
> `CreateOidcProvider=false` を追加してください。
> 1 アカウントに 1 つしか作れません。

## Terraform で作る

```bash
terraform init
terraform apply \
  -var="github_owner=<組織名>" \
  -var="github_repo=<リポジトリ名>" \
  -var="bucket_name=<世界で一意なバケット名>"
```

## 作ったあとにやること

### 1. GitHub の Variables に値を入れる

`Settings` → `Secrets and variables` → `Actions` → **Variables** タブ

| 名前 | 値 |
|---|---|
| `AWS_ROLE_ARN` | 出力された `RoleArn` |
| `AWS_S3_BUCKET` | 出力された `BucketName` |
| `AWS_REGION` | `ap-northeast-1` など |

いずれも **機密ではない**ので `Secrets` ではなく `Variables` で構いません。
ここが「シークレットが 1 つも無い」と言える理由です。

### 2. Environment を作る

`Settings` → `Environments` → `New environment` で **`production`** を作ります。

信頼ポリシーが `:environment:production` で縛られているため、
**この環境を経由しない実行はロールを引き受けられません。**

### 3. ワークフローを動かす

`.github/workflows/27-deploy-aws-s3.yml` を参考にしてください。

## うまくいかないときは

| 症状 | 原因 | 対処 |
|---|---|---|
| `Not authorized to perform sts:AssumeRoleWithWebIdentity` | `sub` が一致していない | ワークフローに `environment: production` があるか確認。組織名・リポジトリ名の大文字小文字も一致させる |
| `Credentials could not be loaded` | `id-token: write` が無い | ワークフローの `permissions` を確認 |
| `EntityAlreadyExists: OIDC provider already exists` | すでに登録済み | `CreateOidcProvider=false` を指定 |
| `AccessDenied` on `s3:PutObject` | バケット名の指定違い | Variables の `AWS_S3_BUCKET` を確認 |

## 片付ける

```bash
# CloudFormation
aws s3 rm s3://<バケット名> --recursive
aws cloudformation delete-stack --stack-name github-actions-demo

# Terraform
terraform destroy
```

## セキュリティ上の注意

信頼ポリシーの `sub` 条件は、**必ず完全一致（`StringEquals`）で書いてください。**

```json
❌ "repo:my-org/*"                              他のリポジトリからも引ける
⚠️ "repo:my-org/my-app:*"                       全ブランチから引ける
✅ "repo:my-org/my-app:environment:production"  環境で縛る（推奨）
```

ワイルドカードを使うと、組織内の**別のリポジトリから本番権限を取得できて**しまいます。
監査で最初に見られるポイントです。
