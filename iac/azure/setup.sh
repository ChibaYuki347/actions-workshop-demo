#!/usr/bin/env bash
#
# GitHub Actions ワークショップ デモ環境のセットアップ（Azure）
#
# このスクリプトがやること:
#   1. リソースグループを作る
#   2. Bicep で App Service（無料枠）を作る
#   3. Entra ID にアプリを登録する（＝ GitHub の身元を受け入れる先）
#   4. フェデレーション資格情報を作る（＝ どのリポジトリ・どの環境からを許すか）
#   5. その Web App だけに権限を与える（最小権限）
#   6. GitHub 側の Variables に値を入れる
#
# 使い方:
#   ./setup.sh <appName> <githubOwner/githubRepo>
#
#   例) ./setup.sh gha-demo-chiba-0902 ChibaYuki347/actions-workshop-demo
#
# 必要なもの:
#   - Azure CLI (az) にログイン済みであること
#   - GitHub CLI (gh) にログイン済みであること（6 を自動化する場合）
#
# 後片付け:
#   ./teardown.sh <appName> を実行してください

set -euo pipefail

APP_NAME="${1:-}"
GH_REPO="${2:-}"

if [[ -z "$APP_NAME" || -z "$GH_REPO" ]]; then
  echo "使い方: $0 <appName> <owner/repo>" >&2
  echo "  例) $0 gha-demo-chiba-0902 ChibaYuki347/actions-workshop-demo" >&2
  exit 1
fi

RG="rg-${APP_NAME}"
LOCATION="${LOCATION:-japaneast}"
# 本番相当として扱う GitHub Environment 名。ここを縛るのが肝です
ENVIRONMENT="${ENVIRONMENT:-production}"

echo "==> 1/6 リソースグループ ${RG} を作ります"
az group create -n "$RG" -l "$LOCATION" -o none

echo "==> 2/6 App Service を作ります（Bicep）"
DEPLOY_OUT=$(az deployment group create \
  -g "$RG" \
  -f "$(dirname "$0")/main.bicep" \
  -p appName="$APP_NAME" \
  --query properties.outputs -o json)

SITE_URL=$(echo "$DEPLOY_OUT" | jq -r '.siteUrl.value')
SITE_ID=$(echo "$DEPLOY_OUT" | jq -r '.siteResourceId.value')
echo "    公開 URL: ${SITE_URL}"

echo "==> 3/6 Entra ID にアプリを登録します"
APP_ID=$(az ad app create --display-name "gha-${APP_NAME}" --query appId -o tsv)
az ad sp create --id "$APP_ID" -o none 2>/dev/null || true
echo "    client-id: ${APP_ID}"

echo "==> 4/6 フェデレーション資格情報を作ります"
echo "    許可する条件: repo:${GH_REPO}:environment:${ENVIRONMENT}"
az ad app federated-credential create --id "$APP_ID" --parameters "$(cat <<JSON
{
  "name": "gha-${ENVIRONMENT}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GH_REPO}:environment:${ENVIRONMENT}",
  "description": "GitHub Actions from ${GH_REPO} (${ENVIRONMENT})",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON
)" -o none

echo "==> 5/6 この Web App だけに権限を与えます（最小権限）"
# サブスクリプション全体ではなく、この 1 つのリソースにだけ割り当てるのが重要です
az role assignment create \
  --assignee "$APP_ID" \
  --role "Website Contributor" \
  --scope "$SITE_ID" -o none

TENANT_ID=$(az account show --query tenantId -o tsv)
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

echo "==> 6/6 GitHub 側の Variables を設定します"
if command -v gh >/dev/null 2>&1; then
  gh variable set AZURE_CLIENT_ID       --repo "$GH_REPO" --body "$APP_ID"
  gh variable set AZURE_TENANT_ID       --repo "$GH_REPO" --body "$TENANT_ID"
  gh variable set AZURE_SUBSCRIPTION_ID --repo "$GH_REPO" --body "$SUBSCRIPTION_ID"
  gh variable set AZURE_WEBAPP_NAME     --repo "$GH_REPO" --body "$APP_NAME"
  echo "    設定しました"
else
  echo "    gh コマンドが見つかりません。以下を手動で設定してください"
  echo "    Settings > Secrets and variables > Actions > Variables"
fi

cat <<EOF

────────────────────────────────────────────────
セットアップが終わりました。

  公開 URL              : ${SITE_URL}
  AZURE_CLIENT_ID       : ${APP_ID}
  AZURE_TENANT_ID       : ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID : ${SUBSCRIPTION_ID}
  AZURE_WEBAPP_NAME     : ${APP_NAME}

※ これらはいずれも機密情報ではないので、secrets ではなく
   variables に入れて構いません。パスワードや鍵は一切ありません。

次にやること:
  1. GitHub 側で Environment "${ENVIRONMENT}" を作る
     Settings > Environments > New environment
  2. 必要なら承認者（Required reviewers）を設定する
  3. Actions タブから "26 - Deploy to Azure App Service" を実行する
────────────────────────────────────────────────
EOF
