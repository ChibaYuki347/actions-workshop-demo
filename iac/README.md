# デプロイのデモ環境（IaC）

「GitHub に鍵を置かずにクラウドへデプロイする」を体感するための環境一式です。

ワークショップでは、**「動作イメージを見る」と「実際に自分で動かす」を
意図的に分けて**います。

## 3 つの段階

| | 何をするか | 必要なもの | いつ |
|---|---|---|---|
| **① 見る** | OIDC の身元証明書の中身をログに出す | **何も要りません** | 当日・全員 |
| **② 見る** | Azure App Service へ実際にデプロイする様子 | 講師の環境 | 当日・講師のデモ |
| **③ 試す** | みなさんの AWS で同じことをやる | AWS アカウント | 持ち帰り |

### ① クラウドが無くても OIDC は体験できる

`.github/workflows/23-oidc-aws.yml` / `23-oidc-azure.yml`

**AWS も Azure も要りません。** ワークフローを実行すると、
GitHub がその場で発行した身元証明書の中身がログに出ます。

```json
{
  "iss": "https://token.actions.githubusercontent.com",
  "aud": "sts.amazonaws.com",
  "sub": "repo:my-org/my-app:environment:production",
  "repository": "my-org/my-app",
  "ref": "refs/heads/main",
  "environment": "production"
}
```

この `sub` の文字列を、クラウド側に「これだけを信じます」と登録する。
**それだけ**です。鍵の受け渡しは一切ありません。

### ② Azure でのデプロイを見る

[`azure/`](./azure/) — App Service（無料枠）を Bicep で作ります。

`.github/workflows/26-deploy-azure-appservice.yml` が動く様子をご覧いただきます。

- テストが通ってからでないとデプロイされない
- 承認ボタンを押すまで本番に届かない
- 公開 URL を開くと、いま動いているコミットが表示される
- **GitHub 側に置いてあるのは機密でない ID だけ**

### ③ AWS で試す

[`aws/`](./aws/) — CloudFormation と Terraform を用意しています。

`.github/workflows/27-deploy-aws-s3.yml` がひな形です。

## 大事なこと: AWS と Azure で違うのは 2 行だけ

```diff
- - uses: azure/login@v2
+ - uses: aws-actions/configure-aws-credentials@v5

- - uses: azure/webapps-deploy@v3
+ - run: aws s3 sync ./dist s3://my-bucket --delete
```

`permissions` も `environment` も `needs` も承認ゲートも、**まったく同じ**です。

縛るための文字列すら同じ形式です。

```
repo:<owner>/<repo>:environment:production
```

つまり **今日 Azure で見ていただく内容は、そのまま AWS に読み替えられます。**
どちらのクラウドを使っていても、GitHub Actions 側の考え方は変わりません。

## 費用について

| | 構成 | 費用 |
|---|---|---|
| Azure | App Service F1（無料枠） | 0 円 |
| AWS | S3 バケット + IAM ロール | 数円/月（保管量による） |

どちらも後片付けの手順を各 README に書いてあります。
