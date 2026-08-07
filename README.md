# GitHub Actions ワークショップ — デモリポジトリ

3 時間ワークショップ用の教材リポジトリです。各モジュールに対応する **実際に動くワークフロー** が入っています。

## セットアップ

```bash
# 1. このリポジトリを自分の Organization / アカウントに push する
gh repo create <OWNER>/actions-workshop-demo --private --source=. --push

# 2. ローカルで動作確認（依存パッケージはゼロなのでオフラインでも動く）
npm ci
npm test
```

> **public にするか private にするか**
> フォーク PR のデモを本気でやるなら public が必要です。ただし public リポジトリでは
> フォークからのワークフロー実行を無効化できません。演習用の空リポジトリで行い、
> self-hosted runner は絶対に接続しないでください。

## ファイル構成

```
.github/
  workflows/
    01-hello.yml               M1  いちばん小さいワークフロー
    02-basics.yml              M2  トリガー / コンテキスト / outputs / if
    03-matrix.yml              M2  マトリックス（include / exclude）
    04-dynamic-matrix.yml      M2  動的マトリックス（モノレポ）
    10-caller.yml              M3  Reusable Workflow（呼ぶ側）
    11-reusable-build.yml      M3  Reusable Workflow（本体）
    20-permissions.yml         M4  最小権限
    21-pr-safe.yml             M4  フォーク PR（ビルド側）
    22-pr-comment.yml          M4  フォーク PR（書き込み側 / workflow_run）
    23-oidc-azure.yml          M4  OIDC でクラウド接続
    24-deploy-environment.yml  M4  Environments と承認ゲート
    25-script-injection.yml    M4  スクリプトインジェクション対策
    30-cache.yml               M5  キャッシュ
    31-concurrency.yml         M5  concurrency
    99-broken.yml              演習 間違い探し（7 箇所）
  actions/
    setup-project/action.yml   M3  Composite Action
  dependabot.yml               M4  Action の更新自動化
  CODEOWNERS                   M6  ワークフロー変更のレビュー必須化
services/                      M2  動的マトリックスの対象
src/ test/ scripts/            アプリ本体（依存ゼロ）
SOLUTIONS.md                   演習の解答
```

## モジュール別の進め方

### M1: 全体像（25 分）

```bash
gh workflow run "01 - Hello"
```

**見るポイント**

- Actions タブに Run が現れる
- `hello` と `another` の `hostname` が違う → **ジョブは別マシン**
- 同じ結果が PR の Checks にも出る

### M2: 基礎文法（25 分）

```bash
gh workflow run "02 - Basics" -f environment=staging -f dry-run=false
gh workflow run "03 - Matrix"
gh workflow run "04 - Dynamic Matrix"
```

**見るポイント**

- `02`: `needs` で前のジョブの `outputs` を受け取っている箇所
- `03`: 2×2 から `exclude` で 1 つ減って 3 ジョブになる
- `04`: `services/` のディレクトリ数だけジョブが増える。**`services/` に新しいディレクトリを 1 つ足して再実行すると、ジョブが 1 つ増える**のが一番わかりやすい

### M3: 再利用（20 分）

```bash
gh workflow run "10 - Caller"
```

**見るポイント**

- 呼び出し側から見ると Reusable Workflow は「ジョブ 1 つ」に見える
- ログを展開すると中のステップが入れ子で見える
- `11-reusable-build.yml` は `on: workflow_call` しか持たないので単体では起動しない

### M4: セキュリティ（35 分）★最重要

```bash
gh workflow run "20 - Permissions"
gh workflow run "23 - OIDC (Azure)"
gh workflow run "24 - Deploy with Environments" -f version=1.2.3
```

**事前準備**

- `production` 環境を作り、Required reviewers に自分を追加（`24` の承認待ちデモ用）
- フォーク PR のデモをするなら、別アカウントからフォークして PR を作っておく

**見るポイント**

- `20`: 各ジョブの権限がログ冒頭の `GITHUB_TOKEN Permissions` に出る
- `23`: OIDC トークンの `sub` クレームの中身。**これがクラウド側の信頼設定と一致する**
- `24`: `production` で承認待ちになる。承認者と時刻が履歴に残る
- `21` / `22`: フォーク PR では secrets が空。書き込みは `workflow_run` 側でしか行わない

### M5: パフォーマンス（20 分）

```bash
gh workflow run "30 - Cache"     # 1 回目は miss、2 回目は hit
gh workflow run "31 - Concurrency"
```

**見るポイント**

- `30`: 1 回目と 2 回目で `cache-hit` と所要時間が変わる
- `31`: 実行中にもう一度起動すると、古い方がキャンセルされる
- キャッシュの棚卸し: `gh extension install actions/gh-actions-cache` → `gh actions-cache list`

### 演習: 間違い探し（M2 の演習枠 5 分 + M4 で回収）

`.github/workflows/99-broken.yml` を読んで、問題点を挙げてください。**7 箇所**あります。
答えは [SOLUTIONS.md](./SOLUTIONS.md)。

## 片付け

ワークショップ後にキャッシュとアーティファクトを消す場合:

```bash
gh actions-cache list
gh actions-cache delete <KEY> --confirm
gh run list --limit 50 --json databaseId --jq '.[].databaseId' | xargs -n1 gh run delete
```
