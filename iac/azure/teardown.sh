#!/usr/bin/env bash
#
# デモ環境の後片付け（Azure）
#
# 使い方:
#   ./teardown.sh <appName>
#
# リソースグループごと消し、Entra ID のアプリ登録も削除します。

set -euo pipefail

APP_NAME="${1:-}"

if [[ -z "$APP_NAME" ]]; then
  echo "使い方: $0 <appName>" >&2
  exit 1
fi

RG="rg-${APP_NAME}"

echo "==> リソースグループ ${RG} を削除します"
az group delete -n "$RG" --yes --no-wait

echo "==> Entra ID のアプリ登録 gha-${APP_NAME} を削除します"
APP_ID=$(az ad app list --display-name "gha-${APP_NAME}" --query "[0].appId" -o tsv)
if [[ -n "$APP_ID" && "$APP_ID" != "null" ]]; then
  az ad app delete --id "$APP_ID"
  echo "    削除しました (${APP_ID})"
else
  echo "    見つかりませんでした。すでに削除済みかもしれません"
fi

echo "完了しました。リソースグループの削除はバックグラウンドで進みます。"
