# Azure デモ環境（App Service）

GitHub Actions から **鍵を一切持たずに** デプロイする様子を見せるための、
最小構成のサンプル環境です。

## つくられるもの

| リソース | 種類 | 費用 |
|---|---|---|
| App Service プラン | Linux / **F1（無料枠）** | 0 円 |
| Web App | Node.js 20 | 0 円 |
| Entra ID アプリ登録 | フェデレーション資格情報つき | 0 円 |

無料枠のみで動くようにしてあります。

## 手順

### 1. 環境を作る

```bash
cd iac/azure
az login
az account set --subscription <サブスクリプション名または ID>

# appName は世界で一意にする必要があります
./setup.sh gha-demo-<自分の識別子> <owner>/<repo>
```

例:

```bash
./setup.sh gha-demo-chiba-0902 ChibaYuki347/actions-workshop-demo
```

スクリプトが終わると、次の 4 つが GitHub の **Variables** に入ります。

| 名前 | 中身 | 機密か |
|---|---|---|
| `AZURE_CLIENT_ID` | アプリ登録の ID | いいえ |
| `AZURE_TENANT_ID` | テナント ID | いいえ |
| `AZURE_SUBSCRIPTION_ID` | サブスクリプション ID | いいえ |
| `AZURE_WEBAPP_NAME` | Web App 名 | いいえ |

**どれも機密ではありません。** パスワードも鍵も出てきません。
これが OIDC を使う一番のメリットです。

### 2. GitHub 側で Environment を作る

`Settings` → `Environments` → `New environment` で **`production`** を作ります。

承認ゲートを見せたい場合は `Required reviewers` に自分を追加してください。

> フェデレーション資格情報は
> `repo:<owner>/<repo>:environment:production` で縛ってあります。
> つまり **`production` 環境を経由した実行からしか** Azure に入れません。
> ブランチを切り替えても、フォークから実行しても、この条件は突破できません。

### 3. デプロイする

`Actions` タブ → **26 - Deploy to Azure App Service** → `Run workflow`

承認ゲートを設定していれば、ここで一度止まります。承認すると公開 URL が更新されます。

### 4. 片付ける

```bash
./teardown.sh gha-demo-<自分の識別子>
```

## うまくいかないときは

| 症状 | 原因 | 対処 |
|---|---|---|
| `AADSTS70021: No matching federated identity record found` | subject が一致していない | ワークフローに `environment: production` があるか確認。リポジトリ名の大文字小文字も一致させる |
| `Error: Login failed with Error: Unable to get ACTIONS_ID_TOKEN_REQUEST_URL` | `id-token: write` が無い | ワークフローの `permissions` を確認 |
| `The subscription is not registered to use namespace 'Microsoft.Web'` | プロバイダ未登録 | `az provider register --namespace Microsoft.Web` |
| `Free tier quota exceeded` | 同じリージョンに F1 プランを作りすぎ | `LOCATION=eastus ./setup.sh ...` で別リージョンに作る |
| デプロイは成功するのにページが 503 | アプリの起動失敗 | `az webapp log tail -g rg-<appName> -n <appName>` で確認 |

## 手で作る場合（スクリプトを使わないとき）

<details>
<summary>クリックして展開</summary>

```bash
APP_NAME=gha-demo-xxxx
GH_REPO=owner/repo
RG=rg-$APP_NAME

# 1. リソースを作る
az group create -n $RG -l japaneast
az deployment group create -g $RG -f main.bicep -p appName=$APP_NAME

# 2. アプリ登録
APP_ID=$(az ad app create --display-name "gha-$APP_NAME" --query appId -o tsv)
az ad sp create --id $APP_ID

# 3. フェデレーション資格情報
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "gha-production",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:'"$GH_REPO"':environment:production",
  "audiences": ["api://AzureADTokenExchange"]
}'

# 4. その Web App だけに権限を与える
SITE_ID=$(az webapp show -g $RG -n $APP_NAME --query id -o tsv)
az role assignment create --assignee $APP_ID --role "Website Contributor" --scope $SITE_ID
```

</details>
