# GitHub Actions Training — 受講者ハンドアウト

> このドキュメントは、ワークショップのスライドを補完する配布資料です。
> **セッション後に単独で読み返せる密度**で書かれています。
> 当日の操作手順は別冊の **「GitHub Actions ハンズオン手順書」** を参照してください。

**構成**: 全 2 日（各 3 時間）
**対象読者**: 開発者 / システム管理者
**前提知識**: Git の基本操作（clone / commit / push / Pull Request がわかること）
**CI/CD の知識は不要です。** ゼロから説明します。
**当日の演習は Web ブラウザだけで行います。** ツールのインストールは一切不要です。

### この資料の読み方

| 部 | 内容 | いつ読むか |
|---|---|---|
| **第 I 部 Day 1 の要点** | CI/CD とは何か、Actions の全体像、書き方、失敗の読み方 | Day 1 の復習に |
| **第 II 部 Day 2 の要点** | CI パイプライン、シークレット、AWS へのデプロイ、安全な運用 | Day 2 の復習に |
| **第 III 部 発展編** | 再利用、深いセキュリティ、コスト最適化、ガバナンス | 導入が進んでから |
| **付録** | 用語集、アンチパターン、トラブルシュート、リンク集 | 困ったときに |

> **第 III 部は当日ほとんど扱いません。** 社内で本格導入するフェーズで読んでください。

---

## 目次

**第 I 部 — Day 1 の要点**
- [D1-1. なぜ CI/CD が要るのか](#d1-1-なぜ-cicd-が要るのか)
- [D1-2. GitHub Actions とは何か](#d1-2-github-actions-とは何か)
- [D1-3. ワークフローの書き方](#d1-3-ワークフローの書き方)
- [D1-4. 失敗の読み方](#d1-4-失敗の読み方)

**第 II 部 — Day 2 の要点**
- [D2-1. CI パイプラインを組み立てる](#d2-1-ci-パイプラインを組み立てる)
- [D2-2. シークレットと環境](#d2-2-シークレットと環境)
- [D2-3. AWS へデプロイする](#d2-3-aws-へデプロイする)
- [D2-4. 安全に運用する](#d2-4-安全に運用する)
- [D2-5. 導入の進め方](#d2-5-導入の進め方)

**第 III 部 — 発展編**
- [1. 全体像とアーキテクチャ](#1-全体像とアーキテクチャ)
- [2. ワークフローの基礎文法](#2-ワークフローの基礎文法)
- [3. 再利用と部品化](#3-再利用と部品化)
- [4. セキュリティ](#4-セキュリティ)
- [5. パフォーマンスとコスト最適化](#5-パフォーマンスとコスト最適化)
- [6. 運用・ガバナンス・スケール](#6-運用ガバナンススケール)
- [7. まとめ](#7-まとめ)

**付録**
- [付録 Z. 用語集](#付録-z-用語集)
- [付録 A. アンチパターン集](#付録-a-アンチパターン集)
- [付録 B. トラブルシュート早見表](#付録-b-トラブルシュート早見表)
- [付録 C. 参考リンク](#付録-c-参考リンク)

---

## デモリポジトリ

本文中のサンプルは、すべて**実際に動くワークフロー**としてデモリポジトリに入っています。

**https://github.com/ChibaYuki347/actions-workshop-demo**

| ファイル | 対応する内容 |
|---|---|
| `01-hello.yml` | D1-2 全体像（ジョブが別マシンで動くことの確認） |
| `02-basics.yml` / `03-matrix.yml` / `04-dynamic-matrix.yml` | D1-3 / D2-1 基礎文法とマトリクス |
| `23-oidc-aws.yml` | **D2-3 AWS へのデプロイ（OIDC）** |
| `24-deploy-environment.yml` | D2-2 Environment と承認ゲート |
| `20-permissions.yml` / `21-pr-safe.yml` / `25-script-injection.yml` | D2-4 安全な運用 |
| `30-cache.yml` / `31-concurrency.yml` | D2-5 / 発展 5. コスト |
| `10-caller.yml` / `11-reusable-build.yml` | 発展 3. 再利用 |
| `exercises/98-broken-lite.yml` | 演習（間違い探し・3 箇所・やさしい版） |
| `exercises/99-broken.yml` | 演習（間違い探し・7 箇所・上級版） |

依存パッケージはゼロなので、`npm ci && npm test` はオフラインでも通ります。
フォークするか自分の Organization に push すれば、そのまま全ワークフローを実行して試せます。

⚠️ `exercises/` の 2 ファイルは意図的に危険な書き方をしています。
`.github/workflows/` の外に置いてあるので実行されることはありませんが、
**中のパターンを本番のワークフローにコピーしないでください。**

---

# 第 I 部 — Day 1 の要点

## D1-1. なぜ CI/CD が要るのか

### いま起きていること

手作業でビルドやデプロイをしていると、次のことが起こります。

| 症状 | 何が起きているか |
|---|---|
| 「私の環境では動くのに」 | 人によって手順や環境がわずかに違う |
| リリース作業に半日かかる | 手順書を見ながら人が順番にコマンドを打っている |
| 手順を 1 つ飛ばして事故 | チェックリストが人の注意力に依存している |
| 誰がいつ何を出したかわからない | 記録が Excel やチャットに散っている |
| 壊れたことに翌日気づく | テストがマージ後にしか走らない |

これらはすべて **「人が毎回やっている」ことが原因**です。
CI/CD は、この繰り返し作業を**機械に固定して渡す**という考え方です。

### 用語を 3 つだけ

| 用語 | 意味 | ひとことで言うと |
|---|---|---|
| **CI**<br>Continuous Integration | コードを変更するたびに、自動でビルド・テストして壊れていないか確かめる | **壊れていないか、毎回機械が確かめる** |
| **CD**<br>Continuous Delivery / Deployment | テストを通ったものを、自動で配布・デプロイする | **通ったものを、そのまま自動で届ける** |
| **パイプライン** | 「取ってくる → 組み立てる → 試す → 配る」という一連の自動処理の流れ | **一本の流れ作業のライン** |

### 導入すると何が変わるか

| | Before（手作業） | After（CI/CD） |
|---|---|---|
| **いつ気づく** | マージした後、あるいは翌日 | **PR を出した数分後** |
| **誰がやる** | 決まった人（属人化） | 誰が変更しても同じ処理が走る |
| **手順** | 手順書 + 人の注意力 | YAML ファイル 1 本（＝コードとしてレビューできる） |
| **記録** | チャットや Excel | **実行ログが自動で全部残る** |
| **リリース** | 半日がかりのイベント | 通ったらボタン 1 つ |

### 順番が大事

いきなり全部やろうとすると失敗します。**この順番で入れてください。**

```
1. CI（テストを自動で走らせる）
      ↓  ここが安定してから
2. PR で必須チェックにする
      ↓  ここでチームが慣れてから
3. staging への自動デプロイ
      ↓  ここで自信がついてから
4. production への（承認付き）デプロイ
```

> **テストが自動で走らない状態で自動デプロイを入れると、壊れたものを速く配るだけになります。**
> 順番を飛ばさないでください。

### YAML の最低限

ワークフローは **YAML** という形式で書きます。ルールは 4 つだけです。

1. **字下げはスペース。タブは使えない**（2 個ずつが慣例）
2. **字下げの深さが構造を決める**
3. **コロンの後ろにはスペースが要る**（`name: CI`）
4. **`-` はリストの項目**

```yaml
jobs:            # 深さ 0
  build:         # 深さ 2 → jobs の中
    steps:       # 深さ 4 → build の中
      - run: ls  # 深さ 6 → steps のリスト項目
```

---

## D1-2. GitHub Actions とは何か

### ひとことで

**「リポジトリで何かが起きたら、GitHub のサーバー上で、決めた処理を自動で走らせる」仕組み**です。

- 「何かが起きたら」＝ **トリガー**（`on:`）
- 「決めた処理」＝ **ジョブとステップ**（`jobs:`）
- 「GitHub のサーバー上で」＝ **ランナー**（`runs-on:`）

### 置き場所は決まっている

```
リポジトリ/
├── .github/
│   └── workflows/        ← ここに置いたものだけが動く
│       ├── ci.yml
│       └── deploy.yml
├── src/
└── README.md
```

- `.github/workflows/` の直下に置いた `.yml` / `.yaml` **だけ**が認識されます
- サブフォルダに入れると **動きません**
- ファイル名は自由（`ci.yml` でも `build.yml` でも可）
- **1 リポジトリに複数本置けます**（用途ごとに分けるのが普通）

### 3 つの階層

```
ワークフロー (workflow)   ← YAML ファイル 1 本
  └── ジョブ (job)        ← 1 ジョブ = 1 台の仮想マシン。並列に走る
        └── ステップ (step) ← 上から順に 1 つずつ実行される
```

**ここが最重要です。**

| | 単位 | 実行のされ方 | 状態の共有 |
|---|---|---|---|
| **ジョブ同士** | 別々の仮想マシン | **並列**（何もしなければ同時に走る） | **共有されない** |
| **ステップ同士** | 同じ仮想マシンの中 | **直列**（上から順） | ファイルも環境も共有される |

> よくある誤解：「ジョブ A でビルドしたファイルを、ジョブ B で使える」
> → **使えません。** 別のマシンだからです。
> 渡したいときは **アーティファクト**（`upload-artifact` / `download-artifact`）を使います。

### ランナーとは

ワークフローを実際に動かすマシンのことです。

| 種類 | 誰が用意するか | 特徴 |
|---|---|---|
| **GitHub-hosted** | GitHub | 毎回まっさらな仮想マシンが立つ。何も残らない |
| **Self-hosted** | 自社 | 社内ネットワークに繋げる。ただし後片付けと隔離は自分の責任 |

**`runs-on:`** に何を書くかで、実行される場所が決まります。
GitHub-hosted なら `ubuntu-latest` のような**名前**を、
Self-hosted なら**ラベルの組み合わせ**（例：`[ self-hosted, Windows ]`）を書きます。

> **本日の環境では** `runs-on:` に `[self-hosted, Windows, X64]` を指定します（手順書の値が正です）。
> この本では説明の都合上ずっと `ubuntu-latest` と書いていますが、
> **実際に打ち込むときは手順書の値に読み替えてください。**

どちらの場合も、そのマシンには **最初リポジトリのコードは入っていません。**

だから `actions/checkout` が要ります（← Day 1 のハンズオン②で体験した内容）。

---

## D1-3. ワークフローの書き方

### 骨格

```yaml
name: CI                    # ① 表示名（省略可）

on:                         # ② いつ動かすか
  push:
    branches: [ main ]

jobs:                       # ③ 何をするか
  build:                    #    ジョブ名（自由）
    runs-on: ubuntu-latest  # ④ どこで動かすか
    steps:                  # ⑤ 上から順に実行される処理
      - uses: actions/checkout@v5
      - run: npm ci
      - run: npm test
```

**この 5 つがすべてです。** 残りは全部オプションです。

### `run:` と `uses:` の違い

| | `run:` | `uses:` |
|---|---|---|
| 何をする | シェルコマンドをそのまま実行 | 誰かが作った部品（Action）を呼び出す |
| 例 | `run: npm test` | `uses: actions/checkout@v5` |
| いつ使う | 自分のプロジェクト固有の処理 | セットアップなど、みんながやること |

```yaml
steps:
  # uses: 部品を呼ぶ。バージョンを @ で指定する
  - uses: actions/checkout@v5
  - uses: actions/setup-node@v4
    with:                      # 部品に渡す入力は with: で
      node-version: '22'

  # run: コマンドをそのまま実行
  - run: npm ci
  - name: テスト               # name: を付けるとログが読みやすい
    run: npm test
```

### 主なトリガー

| 書き方 | いつ動くか | よく使う場面 |
|---|---|---|
| `push:` | コードが push されたとき | main への変更を検知 |
| `pull_request:` | PR が作られた / 更新されたとき | **マージ前のチェック（最重要）** |
| `workflow_dispatch:` | 画面のボタンを押したとき | 手動デプロイ |
| `schedule:` | 決めた時刻に | 夜間バッチ、定期チェック |
| `release:` | リリースが作られたとき | 本番デプロイ |

```yaml
on:
  push:
    branches: [ main ]            # main への push だけ
  pull_request:
    branches: [ main ]            # main 宛の PR だけ
  workflow_dispatch:              # 手動実行も許可
```

> **`branches:` で絞らないと、全ブランチの全 push で動きます。**
> 実行時間（＝コスト）が無駄になるので、必ず絞ってください。

### よく使う変数（コンテキスト）

```yaml
- run: echo "${{ github.repository }}"    # owner/repo
- run: echo "${{ github.ref_name }}"      # ブランチ名
- run: echo "${{ github.sha }}"           # コミットの SHA
- run: echo "${{ github.actor }}"         # 実行した人
- run: echo "${{ github.event_name }}"    # push / pull_request など
```

⚠️ **`${{ }}` の中身は、実行前にそのまま文字列として埋め込まれます。**
PR タイトルなど**外部から来る値**を `run:` に直接埋め込むと危険です（→ D2-4 で扱います）。

---

## D1-4. 失敗の読み方

### 心構え

**失敗は異常ではありません。**
CI を入れると、失敗は毎日起きます。それが CI の役目だからです。

大事なのは、**失敗したときに自分で読み解けること**です。

### どこを見るか

```
Actions タブ
  └── 失敗した実行（❌ が付いている行）をクリック
        └── 左側のジョブ一覧で、❌ が付いているジョブをクリック
              └── 右側で、❌ が付いているステップをクリック
                    └── ここにログが出る ← 読むのはここだけ
```

**❌ が付いているステップだけを見てください。**
その上のステップは全部成功しているので、読む必要はありません。

**エラー行の「1 つ上」に本当の原因があります。**
`Process completed with exit code 1` は結果だけを言っています。理由は直前にあります。

### よくある失敗パターン

| ログに出るメッセージ | 何が起きているか | どうすればいいか |
|---|---|---|
| `No such file or directory` | リポジトリのファイルが仮想マシンに無い | **`actions/checkout` を足す** |
| `Invalid workflow file` | YAML の書き方が間違っている | エラーの行番号を見て字下げを確認 |
| `command not found` | そのコマンドが入っていない | `setup-node` などセットアップ Action を先に置く |
| `Process completed with exit code 1` | コマンドが失敗した | **1 つ上の行**に本当の原因がある |
| `Resource not accessible by integration` | 権限が足りない | `permissions:` を見直す（→ D2-4） |
| `Error: Input required and not supplied` | Action の必須入力が渡っていない | その Action のドキュメントで `with:` を確認 |
| 実行がそもそも始まらない | トリガー条件に合っていない | `on:` の指定を確認 |

### デバッグの道具

```yaml
# ① いま何が置かれているかを見る
- run: |
    pwd
    ls
    env | sort        # Windows ランナーでは Get-ChildItem Env: を使う

# ② 途中の変数の中身を見る
- run: echo "ref=${{ github.ref }} sha=${{ github.sha }}"

# ③ 失敗しても後続を走らせて情報を集める
- run: npm test
  continue-on-error: true

# ④ 失敗したときだけ追加情報を出す
- run: cat npm-debug.log
  if: failure()
```

**⑤ 再実行時のデバッグログ**
失敗した実行の画面右上 `Re-run jobs` → **`Enable debug logging`** にチェックを入れて再実行すると、
通常は出ない詳細ログが出ます。原因がわからないときの最終手段です。

---

# 第 II 部 — Day 2 の要点

## D2-1. CI パイプラインを組み立てる

### CI パイプラインの 4 段階

```
1. 取ってくる  (checkout)      ← リポジトリのコードを持ってくる
2. 用意する    (setup)         ← 言語ランタイムや依存関係を入れる
3. 組み立てる  (build)         ← ビルドする
4. 試す        (test)          ← テストを走らせる
```

これを YAML にすると、そのままステップの並びになります。

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5           # 1. 取ってくる

      - uses: actions/setup-node@v4         # 2. 用意する
        with:
          node-version: '22'
          cache: 'npm'

      - run: npm ci                         # 2. 依存関係
      - run: npm run build                  # 3. 組み立てる
      - run: npm test                       # 4. 試す
```

> **Java なら** `actions/setup-java` + `mvn -B verify`
> **Python なら** `actions/setup-python` + `pip install -r requirements.txt` + `pytest`
> **形は同じです。** 中身のコマンドが変わるだけです。

### `pull_request` トリガーがなぜ重要か

| トリガー | いつ気づけるか |
|---|---|
| `push:` だけ | **main に入ってしまった後** |
| `pull_request:` あり | **main に入る前** ← これが CI の本質 |

PR を出した瞬間にチェックが走り、PR の画面に結果が出ます。
**壊れているものは、マージする前に止まります。**

### 失敗を早く出す（fail fast）

```yaml
steps:
  - uses: actions/checkout@v5
  - run: npm ci
  - run: npm run lint        # ← 速いものを先に
  - run: npm test            # ← 遅いものを後に
  - run: npm run e2e         # ← いちばん遅いものを最後に
```

ステップは上から順に実行され、**1 つ落ちたらそこで止まります。**
速くて落ちやすいもの（lint、型チェック）を先に置くと、
フィードバックが数十秒で返ってきます。

### アーティファクト（ジョブ間でファイルを渡す）

ジョブは別のマシンなので、ファイルは共有されません。渡したいときはこうします。

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v5
      - run: npm ci && npm run build
      - uses: actions/upload-artifact@v4      # 保存する
        with:
          name: dist
          path: dist/
          retention-days: 7                   # 保存期間（＝コスト）

  deploy:
    needs: build                              # build の完了を待つ
    runs-on: ubuntu-latest
    steps:
      - uses: actions/download-artifact@v4    # 取り出す
        with:
          name: dist
          path: dist/
      - run: ls dist/
```

**アーティファクトの用途は 2 つ**です。

1. **ジョブ間でファイルを渡す**（ビルド成果物をデプロイジョブへ）
2. **失敗の証拠を残す**（テストレポート、スクリーンショット、ログ）

```yaml
- uses: actions/upload-artifact@v4
  if: failure()                    # 失敗したときだけ
  with:
    name: test-report
    path: reports/
```

### マトリクス（複数条件で一気に試す）

```yaml
jobs:
  test:
    runs-on: ${{ matrix.os }}
    strategy:
      fail-fast: false               # 1 つ落ちても他を止めない
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: ['20', '22']
    steps:
      - uses: actions/checkout@v5
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      - run: npm ci && npm test
```

これで **2 × 2 = 4 つのジョブが並列で**走ります。

> ⚠️ **マトリクスは組み合わせ数だけ課金されます。**
> 迷ったら `fail-fast: true`（既定）のままにして、1 つ落ちたら残りを止めましょう。

### 必須チェックにする（Required status checks）

CI を作っただけでは、**マージは止まりません。**
「テストが落ちていたらマージできない」状態にするには、**ブランチ保護**の設定が要ります。

```
Settings > Branches > Add branch protection rule
  Branch name pattern: main
  ☑ Require a pull request before merging
  ☑ Require status checks to pass before merging
      → 実行されたことのあるチェック名（例: test）を選ぶ
```

> **チェック名は、一度実行されないと選択肢に出てきません。**
> 先に PR を 1 つ作って CI を走らせてから設定してください。

---

## D2-2. シークレットと環境

### なぜシークレットが要るのか

```yaml
# ❌ 絶対にやってはいけない
- run: aws s3 sync ./dist s3://bucket --region ap-northeast-1
  env:
    AWS_ACCESS_KEY_ID: AKIAIOSFODNN7EXAMPLE
```

YAML に直接書くと、次のことが起こります。

- **Git の履歴に永久に残る**（後から消しても、履歴からは消えない）
- リポジトリを見られる全員に見える
- フォークされたら一緒についていく

### 置き場所

```
Settings > Secrets and variables > Actions
```

| 種類 | 用途 | 読み出し方 | 値は見える？ |
|---|---|---|---|
| **Secrets** | パスワード、トークン、キー | `${{ secrets.NAME }}` | **一度保存したら二度と見られない** |
| **Variables** | 機密でない設定値（リージョン名、ARN など） | `${{ vars.NAME }}` | 画面で見られる |

### スコープ（どこに置くか）

| スコープ | 見える範囲 | 使い分け |
|---|---|---|
| **Organization** | 組織内の（許可した）リポジトリ全部 | 全社共通のもの |
| **Repository** | そのリポジトリだけ | いちばん普通 |
| **Environment** | その環境を使うジョブだけ | **本番の資格情報はここ** |

> **本番の資格情報は Environment スコープに置いてください。**
> リポジトリスコープに置くと、どのブランチのどのワークフローからでも読めてしまいます。

### 扱いのルール

```yaml
# ❌ ログに出す
- run: echo "token is ${{ secrets.TOKEN }}"

# ❌ コマンドライン引数で渡す（プロセス一覧から見える）
- run: ./deploy.sh --token "${{ secrets.TOKEN }}"

# ✅ 環境変数で渡す
- run: ./deploy.sh
  env:
    TOKEN: ${{ secrets.TOKEN }}
```

> GitHub はログ上でシークレットを `***` にマスクしますが、
> **分割出力やエンコードを挟むとマスクは外れます。** 当てにしないでください。

### Environment（環境）と承認ゲート

`staging` / `production` のように、**デプロイ先ごとに設定と承認ルールを分ける**仕組みです。

```
Settings > Environments > New environment
  Name: production
  ☑ Required reviewers           → 承認しないと進まない
  ☑ Wait timer                   → 指定分だけ待つ
  Deployment branches            → main からのみ許可
  Environment secrets            → この環境専用の資格情報
```

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production        # ← これだけで承認ゲートがかかる
    steps:
      - run: ./deploy.sh
        env:
          TOKEN: ${{ secrets.DEPLOY_TOKEN }}   # environment の secret が使われる
```

ジョブは `environment:` の行で**一時停止し**、承認者が画面でボタンを押すまで進みません。
承認の記録は**実行履歴に永久に残ります**（＝監査証跡になります）。

---

## D2-3. クラウドへデプロイする

このセクションは **3 段構え**で進みます。

| | 何をするか | 必要なもの | いつ |
|---|---|---|---|
| **① 見る** | GitHub が発行する「身元証明書」の中身をログに表示する | **何も要りません** | 当日・全員 |
| **② 見る** | 講師が Azure App Service に実際にデプロイする | 講師の環境 | 当日・デモ |
| **③ 試す** | 同じことを御社の AWS で動かす | AWS アカウント | 持ち帰り |

**①は今日その場で、皆さんのリポジトリでも実行できます。**
クラウドのアカウントが 1 つも無くても、OIDC の本質は確認できます。

### 長期アクセスキーの問題

```yaml
# ⚠️ 動くが、望ましくない
env:
  AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
  AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
```

| | 長期アクセスキー | OIDC |
|---|---|---|
| **有効期間** | 失効させるまで**ずっと** | 実行ごとに発行・**数分で失効** |
| **保管場所** | GitHub の Secrets に保存 | **どこにも保存しない** |
| **ローテーション** | 人が定期的に入れ替える運用が要る | **不要** |
| **漏れたとき** | 気づくまで使われ続ける | **すぐ失効している** |
| **絞り込み** | キー単位（誰が使っても同じ） | **リポジトリ / ブランチ / 環境まで縛れる** |

### OIDC のしくみ

```
① GitHub Actions が実行される
② GitHub が「このリポジトリの、このブランチの、この環境で動いています」
   という短命の証明書（ID トークン）を発行する
③ Actions がそれをクラウド側に提示する
④ クラウドが「そのリポジトリなら OK」と判断し、一時的な資格情報を返す
⑤ その資格情報で S3 / ECS / Lambda / App Service などを操作する
```

**GitHub 側にもクラウド側にも、長期の秘密は置きません。**

### ① 身元証明書の中身を見る（クラウド不要）

デモリポジトリの `23-oidc-aws.yml` を `workflow_dispatch` で実行すると、
GitHub が発行したトークンの中身がログに表示されます。

```yaml
permissions:
  id-token: write          # ← これが無いとトークンを要求できない

steps:
  - name: トークンを取得して中身を見る
    run: |
      TOKEN=$(curl -sS \
        -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
        "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=sts.amazonaws.com" \
        | jq -r '.value')
      # JWT の真ん中（ペイロード）を取り出して読む
      echo "$TOKEN" | cut -d. -f2 | base64 -d 2>/dev/null | jq .
```

表示されるのはこういう内容です。

```json
{
  "iss": "https://token.actions.githubusercontent.com",
  "sub": "repo:my-org@123456/my-app@7890123:environment:production",
  "repository": "my-org/my-app",
  "workflow": "Deploy",
  "actor": "yamada-taro",
  "exp": 1756800000
}
```

| 項目 | 意味 |
|---|---|
| `iss` | 発行元。GitHub が発行したことを示す |
| `sub` | **誰なのか。**クラウド側はこの文字列を見て許可を判断する |
| `repository` / `workflow` / `actor` | どのリポジトリの・どのワークフローから・誰が動かしたか |
| `exp` | 有効期限。**数分で切れる**ので、ログに出ていてももう使えない |

> 💡 このトークンは GitHub が署名しています。
> 中身を書き換えても、クラウド側の検証で弾かれます。

> ⚠️ **`sub` の `@` のうしろの数字について**
> 2026 年 7 月 15 日以降に作られたリポジトリでは、`sub` に GitHub が割り当てた
> **変更されない ID** が入ります（`my-org@123456` の `123456` の部分）。
> リポジトリ名を変えてもこの値は変わらないため、名前ベースだった従来より安全です。
>
> **ここに表示された値を、次の ③ でそのままコピーして使ってください。**
> 手で組み立てると桁を間違えて必ず失敗します。
> 詳しくは 4.8 節を参照してください。

### ② クラウド側の設定（一度きり）

AWS でも Azure でも、やることは同じ 3 つです。

| やること | AWS | Azure |
|---|---|---|
| **1. GitHub を信頼先に登録** | IAM の ID プロバイダ | Entra ID のアプリ登録 |
| **2. 権限の入れ物を作る** | IAM ロール | サービスプリンシパル |
| **3. 使える相手を絞る** | 信頼ポリシーの `sub` 条件 | フェデレーション資格情報の `subject` |
| ログインに使う Action | `aws-actions/configure-aws-credentials` | `azure/login` |
| ワークフロー側の権限 | `id-token: write` | `id-token: write` |
| **GitHub に置く秘密** | **なし** | **なし** |

#### AWS の場合

**1. ID プロバイダを登録**

```
IAM > Identity providers > Add provider
  Provider type : OpenID Connect
  Provider URL  : https://token.actions.githubusercontent.com
  Audience      : sts.amazonaws.com
```

**2. ロールを作り、信頼ポリシーで `sub` を絞る**

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub":
        "repo:my-org@123456/my-repo@7890123:environment:production"
    }
  }
}
```

> 📌 **`sub` の値は、① のデモで表示されたものをそのままコピーしてください。**
> `@` のうしろの数字は GitHub が割り当てた ID なので、手では組み立てられません。
> コマンドで確認することもできます:
> ```bash
> gh api repos/OWNER/REPO/actions/oidc/customization/sub --jq .sub_claim_prefix
> ```

**この `sub` の絞り方が、セキュリティのすべてです。**

| 書き方 | 意味 | 評価 |
|---|---|---|
| `StringLike` + `repo:my-org/*` | 組織の**全リポジトリ**から引ける | ❌ 危険 |
| `StringLike` + `repo:.../my-repo:*` | そのリポジトリの**全ブランチ**から引ける | ⚠️ 甘い |
| `StringEquals` + `...:ref:refs/heads/main` | main ブランチからのみ | ✅ 良い |
| `StringEquals` + `...:environment:production` | **production 環境のジョブからのみ** | ✅✅ 最良 |

> ⚠️ **`StringLike` はワイルドカードが使える演算子です。**
> 完全一致で縛るときは `StringEquals` を使ってください。
> `StringLike` のまま運用すると、あとから `*` を足されても気づけません。

**3. ロール ARN を GitHub の Variables に入れる**

ロール ARN は機密ではないので `secrets` ではなく `vars` で構いません。

#### Azure の場合

```
Entra ID > アプリの登録 > 新規登録
  ↓
[証明書とシークレット] > [フェデレーション資格情報] > 資格情報の追加
  シナリオ  : GitHub Actions が Azure リソースをデプロイする
  Subject   : repo:my-org@123456/my-repo@7890123:environment:production
              ↑ ① のデモで表示された値をそのまま貼る
  ↓
対象リソースに RBAC ロールを割り当てる（サブスクリプション全体にしない）
```

> 💡 画面のフォームに Organization 名 / リポジトリ名を入力すると、
> Azure が従来形式の Subject を**自動で組み立ててしまいます**。
> 新形式のリポジトリではそれでは通りません。
> **[エンティティの種類] で「その他の発行者」を選び、Subject を直接入力してください。**

**Azure でも GitHub に置くのは秘密ではありません。**
クライアント ID / テナント ID / サブスクリプション ID は公開されても悪用できない値なので、
`secrets` ではなく `vars` に入れます。

### ③ GitHub 側のワークフロー

**AWS の場合**

```yaml
name: Deploy to AWS

on:
  push:
    branches: [ main ]

permissions:
  contents: read
  id-token: write          # ← これが無いと OIDC トークンを要求できない

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production          # ← sub に environment が入る
    steps:
      - uses: actions/checkout@v5

      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ap-northeast-1

      - run: aws sts get-caller-identity    # 誰として繋がったか確認
      - run: aws s3 sync ./dist s3://my-bucket/ --delete
```

**Azure の場合 — 変わるのは 2 か所だけ**

```yaml
permissions:
  contents: read
  id-token: write          # ← 同じ

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production          # ← 同じ
    steps:
      - uses: actions/checkout@v5

      - uses: azure/login@v2                        # ← ここが違う
        with:
          client-id:       ${{ vars.AZURE_CLIENT_ID }}
          tenant-id:       ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      - run: az account show                # 誰として繋がったか確認
      - uses: azure/webapps-deploy@v3       # ← ここが違う
        with:
          app-name: ${{ vars.AZURE_WEBAPP_NAME }}
          package: .
```

`permissions` / `environment` / `needs` / 承認ゲートは**まったく同じ**です。
クラウドが変わっても、覚えることは変わりません。

> ⚠️ **`permissions: id-token: write` を忘れると動きません。**
> これは OIDC でいちばん多いつまずきです。

> ⚠️ `aws-actions/configure-aws-credentials` も `azure/login` も**サードパーティ Action**です。
> 組織のポリシーで許可されているか、事前に確認してください。

### 持ち帰って試すための材料

デモリポジトリの `iac/` フォルダに、今日お見せしたものと同じ環境を作る手順一式を入れてあります。

| フォルダ | 中身 | 想定 |
|---|---|---|
| `iac/README.md` | 3 段構成の説明。**まずここから** | 全員 |
| `iac/azure/` | Bicep テンプレート ＋ 設定スクリプト | Azure を試す方 |
| `iac/aws/` | CloudFormation ＋ Terraform | **AWS を試す方** |

`iac/aws/` は、この資料の「AWS の場合」をそのままコード化したものです。
OIDC プロバイダ・IAM ロール・信頼ポリシー・S3 バケットまで一度に作れます。

> ⚠️ **必ず検証用アカウントで試してください。**
> IAM の変更は影響範囲が広く、本番アカウントでいきなり実行するものではありません。

### 切り戻し（ロールバック）

デプロイを自動化するときは、**戻し方を先に決めてください。**

| 方法 | やり方 | 向いている場面 |
|---|---|---|
| **前のバージョンを再デプロイ** | 前のコミットの実行を `Re-run` する | いちばん簡単。まずはこれ |
| **Revert コミット** | PR を revert して main に戻す | 履歴が素直に残る |
| **Blue/Green** | 待機系に出して切り替える | ダウンタイムを避けたい |

---

## D2-4. 安全に運用する

### 1. `permissions` を最小にする

ワークフローには自動で `GITHUB_TOKEN` が渡されます。
既定の権限が広いと、事故ったときの被害が大きくなります。

```yaml
# ✅ ワークフロー全体を読み取りだけにして
permissions:
  contents: read

jobs:
  comment:
    permissions:                 # 必要なジョブだけ足す
      contents: read
      pull-requests: write
```

**組織全体の既定を絞るのが本命です。**

```
Organization Settings > Actions > General
  Workflow permissions → Read repository contents permission
```

### 2. Action をコミット SHA で固定する

```yaml
# ❌ ブランチ参照 — 中身がいつ変わるかわからない
- uses: some-org/some-action@main

# ⚠️ タグ参照 — タグは付け替えられる
- uses: some-org/some-action@v3

# ✅ コミット SHA — 中身が確定する
- uses: some-org/some-action@a1b2c3d4e5f6...  # v3.1.0
```

「更新が面倒になるのでは」と思われますが、**Dependabot が自動で PR を出してくれます。**

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### 3. サードパーティ Action のポリシー

```
Organization Settings > Actions > General > Policies
  ○ Allow all actions                          ← 制御なし
  ● Allow <org>, and select non-<org>, actions ← 推奨
      ☑ Allow actions created by GitHub
      ☑ Allow actions by Marketplace verified creators
      許可リスト: aws-actions/*, ...
```

**「GitHub 製のみ許可」だと `aws-actions/configure-aws-credentials` が使えません。**
AWS へデプロイする場合は、許可リストに追加してください。

### 4. 外部入力をコマンドに埋め込まない

```yaml
# ❌ 危険 — PR タイトルがシェルとして解釈されうる
- run: echo "PR: ${{ github.event.pull_request.title }}"

# ✅ 安全 — 環境変数を経由させる
- run: echo "PR: $TITLE"
  env:
    TITLE: ${{ github.event.pull_request.title }}
```

`${{ }}` は**実行前に文字列としてそのまま埋め込まれます。**
PR タイトル、Issue 本文、ブランチ名など、**外部の人が決められる値**は必ず `env:` を経由させてください。

### 5. 監査

すべての実行は記録が残ります。

| 見るところ | わかること |
|---|---|
| **Actions タブの実行履歴** | いつ、誰の変更で、何が動いて、成功したか |
| **Environment の Deployments** | いつ、誰が承認して、本番に出たか |
| **Organization の Audit log** | 設定変更、シークレットの追加、ポリシー変更 |

**「誰がいつ何を出したか」が Excel ではなくシステムに残る**ことが、
CI/CD の見落とされがちな価値です。

---

## D2-5. 導入の進め方

### ランナーの選び方

| | GitHub-hosted | Self-hosted |
|---|---|---|
| **用意する人** | GitHub | 自社 |
| **毎回の状態** | まっさら | **前回の残骸が残る** |
| **社内ネットワーク** | 届かない | 届く |
| **費用** | 実行時間で課金 | マシン費用 + 運用工数 |
| **推奨** | **まずはこれ** | 社内リソースが必要な場合のみ |

> ⚠️ **Self-hosted ランナーを public リポジトリで使わないでください。**
> フォークからの PR で、任意のコードがそのマシン上で実行されます。

### コストの考え方

課金されるのは主に次の 3 つです。

1. **実行時間**（ジョブの分数 × ランナー種別の係数）
2. **ストレージ**（アーティファクトとログの保存）
3. **（Self-hosted なら）自社のマシン費用**

**効きやすい打ち手**

| 打ち手 | 効果 |
|---|---|
| `on:` を `branches:` / `paths:` で絞る | **無駄な実行そのものを減らす** ← 一番効く |
| `concurrency` で古い実行をキャンセル | 連続 push のときの重複を消す |
| `cache` で依存関係を再利用 | 毎回のインストール時間を削る |
| アーティファクトの `retention-days` を短く | ストレージ費用を削る |
| マトリクスの組み合わせを見直す | 組み合わせ数だけ課金されている |

```yaml
# 同じブランチの古い実行を自動でキャンセル
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

```yaml
# 依存関係のキャッシュ（setup-* に組み込みのものを使うのが簡単）
- uses: actions/setup-node@v4
  with:
    node-version: '22'
    cache: 'npm'
```

### 明日からの 3 歩

**第 1 歩 — 1 つのリポジトリで CI を回す（1〜2 週間）**
- いちばん小さいリポジトリを選ぶ
- `pull_request` でテストが走るだけの `ci.yml` を 1 本
- **ここで「落ちても放置しない」文化を作るのが本番**

**第 2 歩 — 必須チェックにする（2〜4 週目）**
- ブランチ保護で Required status checks を有効に
- チームが「赤いままマージしない」に慣れる

**第 3 歩 — staging への自動デプロイ（1〜2 か月目）**
- OIDC で AWS に繋ぐ（キーを置かない形を最初から作る）
- Environment を切って、production だけ承認を required に

> **一度にやらないでください。** 第 1 歩を飛ばして第 3 歩をやると、
> 壊れたものを速く配るだけの仕組みになります。

### 導入チェックリスト

- [ ] `on:` を `branches:` で絞ったか
- [ ] `permissions:` を最小にしたか（組織既定も見直したか）
- [ ] シークレットを YAML に直書きしていないか
- [ ] シークレットをログやコマンドライン引数に渡していないか
- [ ] 本番の資格情報を Environment スコープに置いたか
- [ ] production に承認ゲートを付けたか
- [ ] サードパーティ Action を SHA で固定したか
- [ ] Dependabot を有効にしたか
- [ ] 外部入力を `env:` 経由にしたか
- [ ] 切り戻しの手順を決めたか

---

# 第 III 部 — 発展編

> ここから先は**当日ほとんど扱いません。**
> 社内で本格導入するフェーズになったら読んでください。
> 記述は開発者 / DevOps エンジニア向けの密度になっています。

## 0. 発展編の狙い

次の 3 つの能力を身につけることを目標にしています。

| # | 能力 | 対応セクション |
|---|---|---|
| **WHY** | Actions が「なぜそう動くのか」を説明できる | 1, 2 |
| **SAFE** | 自分のワークフローの危険な箇所を指摘できる | 4 |
| **FAST** | 実行時間とコストを削る打ち手を選べる | 5 |

機能の網羅ではなく、**設計判断ができる状態**にすることを重視しています。

### 扱わないこと

- Marketplace の個別 Action の詳細解説
- GitHub 以外の CI ツールとの詳細な機能比較
- ランナー OS 自体のチューニング

---

## 1. 全体像とアーキテクチャ


### 1.1 Actions は「CI ツール」ではない

最初に壊しておきたい誤解です。GitHub Actions は **GitHub 上のイベントに反応する汎用の実行基盤**であり、CI/CD はその最大のユースケースにすぎません。

CI/CD 以外の実例:

- Issue にラベルが付いたら担当者を自動割り当てる
- Release が publish されたら社内ポータルに通知する
- 外部システムから `repository_dispatch` で任意のジョブを起動する
- 定期実行で依存関係の棚卸しレポートを生成する

> **なぜこの視点が重要か**
> 「CI ツール」だと思っていると CI 用の設計しか出てきません。運用自動化まで Actions に巻き取れると分かると、設計の選択肢が広がります。

### 1.2 3 層モデル

Actions を理解するうえで最も有効な整理が、**コントロールプレーン / オーケストレーション / 実行プレーン**の 3 層に分ける見方です。

| 層 | 役割 |
|---|---|
| ① コントロールプレーン | イベント受信 → ワークフロー探索 → YAML 解析 → Workflow Run 生成 |
| ② オーケストレーション | ジョブ DAG 構築 → キューイング → ランナーへディスパッチ |
| ③ 実行プレーン（Runner） | 実際のジョブ実行 → ログ・アーティファクトの返送 |

この整理から導かれる、実務で効く 4 つの帰結:

#### (a) ①と③は完全に分離している

ランナーは**自分から取りに行く**方式（アウトバウンド接続のみ）で動きます。

→ **self-hosted runner にインバウンドのファイアウォール穴を開ける必要がありません。**
ネットワーク部門への説明にそのまま使える論点です。

#### (b) Workflow Run は Checks の仕組みの上に載っている

PR 画面の Checks に Actions の結果が並ぶのはこのためです。

→ **サードパーティ CI と Actions を、ブランチ保護の必須チェックで完全に同列に扱えます。**
これが「既存 CI と並走しながら段階的に移行できる」ことの技術的な根拠です（詳細は 6.2）。

#### (c) ジョブは互いに独立した実行環境

同じワークフロー内でも、ジョブが違えば**別のマシン**です。

→ 「ジョブ間でファイルが引き継がれない」という最頻出のつまずきは、ここを押さえれば防げます。

#### (d) 実行系と UI 系は別系統

→ 「UI は見えるがジョブが queued のまま」なら実行プレーン側の問題、と障害の切り分けに当たりを付けられます。

### 1.3 実行単位の階層

このセッション中ずっと使う語彙です。ここで定義を固定します。

```
Workflow (1 ファイル = .github/workflows/*.yml)
 └─ Job (ランナー 1 台を占有。デフォルトで並列)
     └─ Step (常に逐次。ワークスペースを共有)
```

| 単位 | 実行環境 | ファイル共有 | 並列性 |
|---|---|---|---|
| Workflow | — | — | 独立して並列 |
| **Job** | **ランナー 1 台を占有** | **ジョブ間では共有されない** | デフォルト並列 |
| Step | ジョブと同じランナー | **同一ジョブ内では共有** | 常に逐次 |

**最重要ポイント**: ワークスペースを共有するのは **Step 間だけ**です。
ジョブをまたぐ受け渡しは、`outputs`（小さな値）か `artifacts`（ファイル）を使います（2.5 参照）。

> 「Job = ランナー 1 台を占有する」と理解しておくと、課金がジョブ実行時間の合計で決まること（5.1）にきれいに接続します。

---

## 2. ワークフローの基礎文法

### 2.1 骨格

毎回必ず登場する 4 要素です。以降のすべての話は「この骨格のどこに何を足すか」になります。

```yaml
name: CI

on:                        # ① いつ動くか
  pull_request:
    branches: [main]

permissions:               # ② 何を触れるか（4.2 で詳述）
  contents: read

jobs:
  build:                   # ③ どのマシンで
    runs-on: ubuntu-latest
    steps:                 # ④ 何をするか
      - uses: actions/checkout@v4
      - run: npm ci && npm test
```

**`actions/checkout` が必要な理由**: ランナーは**空のマシン**として起動します。リポジトリの中身は明示的に取りに行かないと存在しません。

**実務 Tips**: YAML のインデントミスは初学者の最大の詰まりどころです。エディタで YAML スキーマ補完を有効にしておくと激減します。

### 2.2 トリガーの選択

| やりたいこと | トリガー |
|---|---|
| PR のたびにテスト | `pull_request` |
| main へのマージでデプロイ | `push` (branches: [main]) |
| 手動実行したい | `workflow_dispatch` |
| 定期実行 | `schedule` |
| 別ワークフローの完了を受けて | `workflow_run` |
| 外部システムから起動 | `repository_dispatch` |
| Issue / PR の操作に反応 | `issues`, `issue_comment`, `label` |

#### ⚠ 最重要の落とし穴: デフォルトブランチ限定のトリガー

`issues` / `issue_comment` / `label` / `schedule` / `workflow_run` / `repository_dispatch` などは、**デフォルトブランチのワークフロー定義しか参照しません。**

つまり:

- feature ブランチでこれらのワークフローを書いても**動きません**
- **main にマージしてからでないとテストできません**

一方、`push` / `pull_request` / `workflow_dispatch` は対象の ref を参照するので、ブランチ上で普通にテストできます。

> **この非対称性が混乱の最大の原因です。** 「書いたのに動かない」と思ったら、まずトリガーの種類を確認してください。

### 2.3 コンテキスト

ワークフローが読める変数です。式 `${{ }}` の中で参照します。

| コンテキスト | 内容 | 注意 |
|---|---|---|
| `github` | イベント情報、リポジトリ、ref など | `github.event` は **外部入力**。信頼しない（4.6） |
| `env` | 環境変数 | |
| `secrets` | 機密値 | ログでマスクされる |
| `vars` | 非機密の設定値 | ログに出るので運用が楽 |
| `steps.<id>.outputs` | 同一ジョブ内の前ステップの出力 | |
| `needs.<job>.outputs` | 依存ジョブの出力 | `needs` の宣言が必須 |
| `matrix` | マトリックスの現在値 | |
| `runner` | ランナーの OS、一時ディレクトリなど | |

**設計上の重要な性質**: 式が評価されるのは「ワークフロー開始時」ではなく、**そのジョブが実行可能になった直前**です。
→ だから前段ジョブの `outputs` を使って `runs-on` やマトリックスを**動的に決められます**（2.6）。

**`secrets` と `vars` の使い分け**: 機密は `secrets`、非機密の設定値（環境名、リージョン、フラグなど）は `vars` に置くとログが読めて運用が楽になります。

### 2.4 条件分岐

`if` は **job レベル**と **step レベル**の 2 か所に書けます。

```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main'    # ジョブ丸ごとスキップ（コスト削減にも効く）
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
      - name: 失敗してもログは必ず収集
        if: always()
        run: ./collect-logs.sh
```

覚えておくべき関数:

| 関数 | 意味 |
|---|---|
| `success()` | 直前までのステップがすべて成功（`if` 省略時の既定） |
| `failure()` | いずれかが失敗 |
| `always()` | 成否にかかわらず必ず実行 |
| `cancelled()` | 実行がキャンセルされた |

**注意点**:

- `if` の中では `${{ }}` を省略できますが、混在させると読みにくくなります。チームでどちらかに統一してください。
- 「`if` が古い値を見ている気がする」という相談は、ほぼ **`needs` の張り忘れ**です。依存関係のないジョブは並列に走るので、そもそも前段の結果を待っていません。

### 2.5 ジョブ間のデータ受け渡し

1.3 の「ジョブは別マシン」問題の正式な解決策です。

| 渡すもの | 手段 |
|---|---|
| 小さな値（文字列、フラグ、バージョン番号） | **outputs** |
| ファイル、ビルド成果物 | **artifacts** |

```yaml
jobs:
  prepare:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.v.outputs.version }}
    steps:
      - id: v
        run: echo "version=1.2.3" >> "$GITHUB_OUTPUT"

  build:
    needs: prepare                              # ← これがないと outputs は読めない
    runs-on: ubuntu-latest
    steps:
      - run: echo "building ${{ needs.prepare.outputs.version }}"
      - uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/
```

**注意点**:

- `set-output` コマンドは**非推奨**です。`$GITHUB_OUTPUT` に書く方式を使ってください。古い記事のコピーに注意。
- artifacts はアップロード / ダウンロードに**時間と課金**がかかります。巨大なものを毎ジョブ受け渡す設計は避けてください。
- **`outputs` に機密を載せないでください。** ログや API から見えうる前提で設計します。

### 2.6 マトリックス

同じ処理を組み合わせ違いで並列実行します。

```yaml
jobs:
  test:
    strategy:
      fail-fast: false          # 1 つ落ちても残りを走らせる
      matrix:
        os: [ubuntu-latest, windows-latest]
        node: [20, 22]
    runs-on: ${{ matrix.os }}
```

**動的展開**（実務で強力なパターン）:

```yaml
jobs:
  detect:
    outputs:
      targets: ${{ steps.d.outputs.targets }}
    steps:
      - id: d
        run: echo 'targets=["api","web"]' >> "$GITHUB_OUTPUT"

  build:
    needs: detect
    strategy:
      matrix:
        target: ${{ fromJSON(needs.detect.outputs.targets) }}
```

変更のあったディレクトリだけをビルドする、といったモノレポ向けの構成が組めます。
これが成立するのは、2.3 で触れたとおり **`strategy` がジョブ実行の直前に評価される**からです。

**注意点**:

- `fail-fast` のデフォルトは `true`。全組み合わせの結果を知りたいテストでは `false` にします。
- 組み合わせ数は掛け算で増えます。3 OS × 4 バージョン = 12 ジョブ。課金もその分かかります（5.1）。

---

## 3. 再利用と部品化

### 3.1 3 つの手段の使い分け

粒度が違うだけ、と理解すると整理できます。

| 手段 | 粒度 | 追従 | 主な用途 |
|---|---|---|---|
| **Composite Action** | Step の束 | する | セットアップ手順の共通化 |
| **Reusable Workflow** | Job の束 | する | CI/CD パイプライン全体の標準化 |
| **Starter Workflow** | 初期テンプレート | **しない** | 新規リポジトリの出発点 |

> **よくある誤解**: Starter Workflow は一度コピーされたら追従しません。**テンプレートであって共有ライブラリではありません。**

**選び方の一言ルール**:

- ステップ数個の共通化 → **Composite**
- ジョブ丸ごと、権限やシークレットの受け渡しを伴う → **Reusable**
- 新規リポジトリの出発点を揃えたい → **Starter**

実務では、**組織の `.github` リポジトリに Reusable Workflow を集約し、各リポジトリからは数行呼ぶだけ**という形に落ち着くことが多いです。

### 3.2 Reusable Workflow

**呼ばれる側** (`.github/workflows/build.yml`):

```yaml
on:
  workflow_call:              # ← これが入口
    inputs:
      node-version:
        type: string
        default: '22'
    secrets:
      NPM_TOKEN:
        required: true

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
```

**呼ぶ側**:

```yaml
jobs:
  call:
    uses: my-org/.github/.github/workflows/build.yml@v1
    with:
      node-version: '20'
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
```

**設計上のポイント**:

- `inputs` / `secrets` を**明示的に宣言**する設計になっています。暗黙に環境を共有しないので、何が渡っているかが読めます。
- `secrets: inherit` は便利ですが、**渡す必要のないシークレットまで渡ります。** 組織横断で使うワークフローでは個別に列挙するほうが安全です。
- **呼び出し側の `permissions` が呼ばれる側の上限**になります。呼ばれる側で権限を増やすことはできません。この一方向性がセキュリティ上の要です。

### 3.3 Composite Action

`action.yml`:

```yaml
name: Setup
inputs:
  node-version:
    default: '22'
runs:
  using: composite            # ← これだけで Composite Action
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    - run: npm ci
      shell: bash             # ← composite では shell 指定が必須
```

呼び出し（同一リポジトリ内）:

```yaml
- uses: ./.github/actions/setup
  with:
    node-version: '20'
```

**注意点**:

- Composite Action の中では `secrets` コンテキストが直接使えません。必要なら `inputs` で受け取る設計にします。
- `run` ステップには `shell:` の指定が必須です。
- まずリポジトリ内で作り、育ってから別リポジトリに切り出すのが現実的な進め方です。

> 共通化のためだけに YAML アンカーを使うのは勧めません。可読性が落ちますし、正式な共通化手段がこうして用意されています。

---

## 4. セキュリティ

**このモジュールが本ワークショップの本題です。**

### 4.1 認識のリフレーミング

> **CI は「本番の認証情報を持っていて、しかもコードレビューが薄い実行環境」である。**

アプリケーションコードは必ずレビューされるのに、ワークフローの変更は「CI の設定でしょ」と流されがちです。**この非対称性が事故の温床**です。

攻撃者から見れば、アプリの脆弱性を探すより CI を通すほうが早い。だからここに攻撃が集中しています。

以降の内容はすべて、この前提から導かれる具体策です。

### 4.2 permissions を明示する

```yaml
permissions:
  contents: read              # ワークフロー冒頭で最小権限を宣言

jobs:
  release:
    permissions:
      contents: write         # 必要なジョブでだけ足す
      id-token: write
```

**`permissions` を書かないと、リポジトリまたは組織のデフォルト設定に従います。**
→ 環境依存になり、**別リポジトリにコピーしたら権限が変わります。**

**推奨**:

1. ワークフロー冒頭で `contents: read` を宣言
2. 必要なジョブでだけ権限を足す
3. 組織設定でデフォルトを read に寄せる（最も効きますが、既存ワークフローが壊れうるので段階的に）

> `write-all` を見つけたら必ず直してください。実務で最も頻繁に見つかる問題です。
> なお「権限を絞ると壊れるワークフローがある」という事実自体が、**今どれだけ広い権限で動いていたか**の証拠です。

### 4.3 GITHUB_TOKEN の性質

ジョブ開始時に自動発行され、ジョブ終了時に自動失効する**短命トークン**です。

| 性質 | 意味 |
|---|---|
| 短命 | ジョブのライフサイクルに閉じる |
| **リポジトリ境界を越えられない** | 他リポジトリは触れない |
| スコープ指定可能 | `permissions` で個別に絞れる |
| **push しても新たな workflow を起動しない** | 無限ループ防止の仕様 |

よく使うスコープ: `contents` / `pull-requests` / `issues` / `packages` / `id-token` / `attestations`

**「越えられない」性質が重要です。** 他リポジトリを触りたくなったとき、安易に PAT を Secrets に入れるのではなく、**GitHub App や OIDC を検討**する流れになります。

> 「Bot が push したのに CI が回らない」という相談の答えが、上表の最終行です。

### 4.4 ⚠ pull_request vs pull_request_target

**本ワークショップで最も危険な話です。**

| | `pull_request` | `pull_request_target` |
|---|---|---|
| 実行される文脈 | **PR のマージ結果** | **ベースブランチ** |
| フォークからの PR でシークレット | **渡らない** | **渡る** |
| フォークからの PR での権限 | read に落ちる | **write を持つ** |
| 安全性 | 安全側に倒れている | **取り扱い注意** |

#### 絶対にやってはいけないパターン

```yaml
# ❌ 危険 — 他人の任意コードが本番シークレット付きで実行される
on: pull_request_target
jobs:
  build:
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}   # ← フォーク側のコード
      - run: npm ci && npm run build                        # ← それを実行
```

**`pull_request_target` でフォーク側のコードを checkout して実行してはいけません。**

#### 正しい使い方

`pull_request_target` は、**コードを実行しない自動化に限定**します。

- PR にラベルを付ける
- PR にコメントする
- PR のメタデータを検証する

コードを動かしたいなら `pull_request` 側でやってください。

> 「うちは OSS じゃないから関係ない」と思われるかもしれませんが、**社内フォーク運用や外部委託先のフォークも同じ経路**です。

### 4.5 フォーク PR の設定

フォーク PR の挙動は**単一のスイッチではなく、複数の設定の組み合わせ**で決まります。だから「安全にしたつもり」が成立しにくい領域です。

監査するときは、次を**項目ごとに個別に**確認してください。

- [ ] フォークからの PR でシークレットを渡すか
- [ ] フォークからの PR で書き込み権限を与えるか
- [ ] 承認なしでワークフローを走らせるか（初回コントリビュータの扱い）

**運用方針**: 組織レベルで既定を締めておき、必要なリポジトリだけ緩める。逆方向は徹底できません。

外部コントリビュータを受け入れているリポジトリでは、**「初回コントリビュータは承認が必要」を必ず有効に**してください。

### 4.6 スクリプトインジェクション

```yaml
# ❌ 危険 — Issue タイトルがシェルとして解釈されうる
- run: echo "Title: ${{ github.event.issue.title }}"

# ✅ 安全 — 環境変数を経由させる
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "Title: $TITLE"
```

`run:` の中に `${{ }}` を直接埋めると、**式が文字列として展開されてからシェルに渡されます。** つまり値の中身がシェルとして解釈されえます。

**危険な入力源**（`github.event` 配下は基本すべて外部入力と考える）:

- Issue タイトル / 本文
- PR タイトル / 本文
- ブランチ名
- コメント本文

**対策は一貫しています**: `env:` に入れて `"$VAR"` で参照する。これでシェルの解釈を通りません。
`actions/github-script` を使う場合も同様に、テンプレートに直接埋めず `context` 経由で受け取ります。

### 4.7 サードパーティ Action を SHA で固定する

```yaml
# ❌ タグは可変 — 同じ @v3 が昨日と今日で別のコードになりうる
- uses: some-org/some-action@v3

# ✅ コミット SHA で固定
- uses: some-org/some-action@a1b2c3d4e5f6...  # v3.1.0
```

読みにくくなるので、**行末コメントにバージョンを併記する**のが慣習です。

**固定と更新はセットで導入します。** Dependabot に任せてください。

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

組織設定で「許可する Action を制限する」機能もあります。ここまで締めるかは組織の成熟度次第です。

> 自組織内の Action まで SHA 固定するかは議論になります。信頼境界をどこに引くかの話なので、正解は組織ごとに違います。

### 4.8 OIDC — 長期の認証情報を置かない

**発想の転換**: クラウドの長期認証情報を GitHub 側に保存せず、**実行のたびに短命トークンを取りに行く**。

> 具体的な設定手順とデモ用の IaC は **D2-3 章**にあります。ここは要点だけをまとめたものです。

```yaml
permissions:
  id-token: write             # ← 必須。忘れると失敗する
  contents: read

jobs:
  deploy:
    environment: production   # ← 信頼ポリシーで縛る対象にもなる
    steps:
      # Azure の場合
      - uses: azure/login@v2
        with:
          client-id: ${{ vars.AZURE_CLIENT_ID }}
          tenant-id: ${{ vars.AZURE_TENANT_ID }}
          subscription-id: ${{ vars.AZURE_SUBSCRIPTION_ID }}

      # AWS の場合（上と入れ替えるだけ）
      - uses: aws-actions/configure-aws-credentials@v6
        with:
          role-to-assume: ${{ vars.AWS_ROLE_ARN }}
          aws-region: ap-northeast-1
```

> **`secrets` ではなく `vars` を使っている点に注目してください。**
> クライアント ID もロール ARN も**単体では何もできない識別子**なので、隠す必要がありません。
> 本人であることの証明は、実行のたびに発行される短命トークンが担います。

**仕組み**: GitHub が発行する ID トークンをクラウド側が検証し、条件に合えば一時的な権限を返します。**GitHub 側に残る秘密がなくなります。**

**クラウド側の信頼ポリシーを絞ってください**:

| 縛る対象 | 書き方の例 |
|---|---|
| リポジトリ | `repo:my-org/my-repo:` で始まること |
| ブランチ | `repo:my-org/my-repo:ref:refs/heads/main` |
| **Environment** | `repo:my-org/my-repo:environment:production` |

> ⚠️ **AWS では `StringLike` ではなく `StringEquals` を使ってください。**
> `StringLike` はワイルドカードが効くため、`repo:my-org/*` のような書き方だと
> **組織内のどのリポジトリからでも引けてしまいます。**

**Environment で縛るのが最も強い**縛り方です。ブランチだけで縛ると、main に対する任意のワークフローから引けてしまいますが、Environment まで含めれば**承認ゲートを通ったジョブだけ**に限定できます。

#### ⚠️ 2026 年 7 月からの変更 — `sub` に ID が入るようになりました

**2026 年 7 月 15 日以降に作成されたリポジトリ**では、`sub` の形式が変わっています。

| | 形式 |
|---|---|
| 従来 | `repo:my-org/my-repo:environment:production` |
| **新** | `repo:my-org@123456/my-repo@7890123:environment:production` |

`@` のうしろの数字は、GitHub がその Organization / リポジトリに割り当てた**変更されない ID** です。リポジトリ名を変えても、Organization 名を変えても、この値は変わりません。

**なぜ変わったのか**: 従来の形式は名前ベースだったため、リポジトリを削除して**同じ名前で作り直す**と、以前の信頼ポリシーがそのまま効いてしまう余地がありました。ID ベースにすることで、この経路を塞いでいます。

**どちらの形式になるかの判定**:

| リポジトリ | 形式 |
|---|---|
| 2026 年 7 月 15 日**以降**に作成 | **新形式**（自動） |
| 2026 年 7 月 15 日以降にリネーム／移管 | **新形式**へ移行 |
| それ以前から存在し、そのまま | 従来形式（明示的にオプトインするまで） |

> **社内で 2 種類が混在します。** 新しく作るリポジトリは新形式、既存リポジトリは従来形式です。
> リポジトリごとに確認してください。

**確実な確認方法** — 推測で書かないでください:

```bash
# 方法 1: API で聞く（最も速い）
gh api repos/OWNER/REPO/actions/oidc/customization/sub --jq .sub_claim_prefix
# → repo:my-org@123456/my-repo@7890123

# 方法 2: 実際にトークンを発行して中身を見る
#   デモリポジトリの 23-oidc-aws.yml を実行すると、
#   ログの最後に「クラウド側に書くのはこの値です」と表示されます
```

> ⚠️ API のレスポンスに含まれる `use_immutable_subject` は「**明示的にオプトインしたか**」を表すフラグです。
> これが `false` でも、新しいリポジトリの `sub_claim_prefix` にはすでに ID が入っています。
> **このフラグではなく、`sub_claim_prefix` の値そのものを見てください。**

**混在期の実務的な対処** — 両方を許可しておけば、どちらでも通ります。

AWS の場合、`StringEquals` の値は配列にできます（OR 条件になります）:

```json
"StringEquals": {
  "token.actions.githubusercontent.com:sub": [
    "repo:my-org@123456/my-repo@7890123:environment:production",
    "repo:my-org/my-repo:environment:production"
  ]
}
```

Azure の場合、1 つのアプリ登録に**フェデレーション資格情報を複数**ぶら下げられます（新形式用と従来形式用の 2 つを作る）。

**間違えたときのエラー**:

| クラウド | メッセージ |
|---|---|
| Azure | `AADSTS700213: No matching federated identity record found for presented assertion subject '...'` |
| AWS | `Not authorized to perform sts:AssumeRoleWithWebIdentity` |

どちらも**メッセージの中に実際の `sub` が出ています**。それをそのままコピーして登録すれば直ります。

> この変更は **github.com のみ**です。GitHub Enterprise Server には影響しません。

**移行の進め方**: まずデプロイ系のワークフロー 1 本から始めるのが現実的です。既存の長期キーは、OIDC 経路が安定してから削除してください。

### 4.9 Environments

デプロイ先を表す単位で、次を付けられます。

| 機能 | 効果 |
|---|---|
| **承認ゲート** | 本番デプロイに人間の承認を挟める |
| 待機時間 | 一定時間後に自動で進む |
| **ブランチ制限** | 「main からしか本番にデプロイできない」を仕組みで担保 |
| **Environment 単位のシークレット** | 本番の認証情報は本番ジョブでしか読めない |

```yaml
jobs:
  deploy-prod:
    environment: production     # ← 承認ゲートが効く
    runs-on: ubuntu-latest
```

**設計のポイント**:

- Environment 単位のシークレットにすると、**前段のテストジョブからは本番の認証情報が見えません。**
- ブランチ制限と組み合わせると、運用ルールではなく**設定で縛れます。**
- **OIDC の信頼ポリシーに Environment を含める**と、クラウド側でも同じ境界を強制できます。4.8 とセットで設計してください。

### 4.10 セキュリティチェックリスト

自分のリポジトリで上から順に確認してください。

- [ ] `permissions` をワークフロー冒頭で明示している（既定は `contents: read`）
- [ ] `write-all` を使っていない
- [ ] `pull_request_target` でフォーク側のコードを checkout していない
- [ ] `run:` の中に `${{ github.event.* }}` を直接埋めていない
- [ ] サードパーティ Action を SHA で固定している
- [ ] Dependabot で Action の更新を回している
- [ ] 長期のクラウド認証情報を Secrets に置いていない（OIDC 化）
- [ ] 本番デプロイに Environment の承認ゲートがある
- [ ] シークレットを `env:` でグローバルに展開していない
- [ ] self-hosted runner をパブリックリポジトリで使っていない

**優先順位**: `permissions` → `pull_request_target` の確認 → SHA 固定 → OIDC の順。
全部いっぺんにやろうとすると挫折します。まず 1 リポジトリで試してから横展開してください。

---

## 5. パフォーマンスとコスト最適化

### 5.1 課金の仕組み

**課金 = ジョブの実行時間 × OS の係数**

| OS | 係数（Linux を 1 とした相対値） |
|---|---|
| Linux | **1** |
| Windows | **2** |
| macOS | **10** |

**最大の削減余地はここです。** 最初に問うべきは「本当に Windows / macOS が必要か」。
テストの一部だけ他 OS にする、という形で十分なケースが多いです。

パブリックリポジトリの GitHub-hosted runner は無料枠の扱いが異なります。組織の使用状況は請求画面で確認できます。**まず測ることから始めてください。**

### 5.2 施策の優先順位

効く順に並べています。

| 順位 | 施策 | 効果 |
|---|---|---|
| 1 | **concurrency で古い実行をキャンセル** | 走る回数が減る |
| 2 | **paths / paths-ignore フィルタ** | 走る回数が減る |
| 3 | `if` でジョブ単位のスキップ | 走る回数が減る |
| 4 | キャッシュ | 走る時間が減る |
| 5 | ジョブの並列化 | 体感時間が減る |
| 6 | ランナーの選択（OS / サイズ） | 単価が変わる |

> **基本戦略は「走る回数 → 走る時間 → 単価」の順で削ること。**
> 多くの組織はキャッシュから始めてしまいますが、その前に「そもそも走らせない」施策のほうが効きます。

### 5.3 concurrency — 費用対効果が最も高い 4 行

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

PR で連続 push したとき、古いコミットに対する CI は**結果を見ないのに最後まで走っています。** これを止めるだけで無駄が大きく減ります。

**注意点**:

- `group` に **`github.ref` を含めてください。** 含めないと別ブランチ同士でキャンセルし合います。
- **本番デプロイのワークフローでは `cancel-in-progress: false`** にします。デプロイ途中でキャンセルされると中途半端な状態になります。

### 5.4 キャッシュ

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

**キーの設計がすべてです。** 依存定義ファイルのハッシュをキーに含め、`restore-keys` で段階的なフォールバックを用意します。

**3 つの落とし穴**:

1. **キーが固定だと古いキャッシュを引き続けて更新されない**
2. **巨大なキャッシュは復元自体に時間がかかる** — ダウンロードと展開の時間がビルド短縮分を上回ることがある
3. **キャッシュはブランチのスコープを持つ** — feature ブランチからデフォルトブランチのキャッシュは読めるが、逆は読めない

**その他**:

- リポジトリごとに保存容量の上限があり、超えると古いものから消えます。使われていないキャッシュを大量に作らないでください。
- **キャッシュに機密を入れないでください。** ブランチをまたいで読まれえます。

### 5.5 上限値

暗記ではなく「存在すること」を知っておくのが目的です。詰まったときにドキュメントを引ける状態にしてください。

実務でぶつかりやすいもの:

| 項目 | 実務での現れ方 |
|---|---|
| **ジョブの実行時間上限** | 長時間バッチを Actions に載せようとして詰まる |
| **同時実行数の上限** | 大規模組織で「CI が詰まる」原因 |
| ワークフロー実行時間の上限 | 長いパイプラインで顕在化 |
| キャッシュ容量の上限 | 古いキャッシュが勝手に消える |
| API レート制限 | スクリプト系ジョブで顕在化 |

同時実行数はプランと組織で決まります。ここが原因なら、self-hosted や larger runner の検討につながります。

### 5.6 ランナーの選択肢

| 種類 | 特徴 | 使いどころ |
|---|---|---|
| **GitHub-hosted** | 使い捨て VM。**毎回クリーンな環境** | まずここから |
| **larger runner** | CPU / メモリ増強。単価は上がる | 実行時間短縮で総額が下がるなら |
| **self-hosted** | 自前管理。**環境の使い回しに注意** | 閉域網へのアクセス、特殊ハードウェア |

**larger runner の判断**: 単価は上がりますが実行時間が短くなれば総額は下がることがあります。**計算してから判断**してください。

**self-hosted の注意点**:

- 環境が使い回されるため、**前ジョブの残骸や認証情報が残りうる**
- 環境管理とセキュリティの責任が自組織に発生する
- **⚠ パブリックリポジトリで self-hosted runner を使わないでください。** フォークからの PR で任意コードが自社ネットワーク内で実行される危険があります。

#### Windows の self-hosted runner で最初にハマるところ

**既定のシェルが違います。** GitHub-hosted の Ubuntu では `bash`、Windows では PowerShell です。

> ⚠️ Windows の既定は `pwsh`（PowerShell 7）ですが、**pwsh が入っていない環境では
> `powershell`（Windows PowerShell 5.1）にフォールバック**します。
> 自前で構築した runner は 5.1 で動いていることが珍しくありません。
> そのため **`shell: pwsh` と明示すると、pwsh の無い環境では失敗します。**
> どちらでも動く書き方（`echo` / `cat` / `ls` / `Get-ChildItem` など）を選ぶのが安全です。

| よく書くコマンド | Linux (bash) | Windows (PowerShell) |
|---|---|---|
| `echo "文字列"` | ✅ | ✅ |
| `cat FILE` | ✅ | ✅（`Get-Content` の別名） |
| `ls` | ✅ | ✅（`Get-ChildItem` の別名） |
| `ls -la` | ✅ | ❌ そんなオプションは無い |
| `test -f FILE` | ✅ | ❌ そんなコマンドは無い |
| `echo "$MY_VAR"` | ✅ | ⚠️ **エラーにならず空で出る**（`$env:MY_VAR` が正しい） |

最後の行が最も危険です。**失敗せずに間違った結果が出る**ため、気づけません。

**対策は 2 つ**です。

```yaml
# ① シェルを明示する
- run: ls -la
  shell: bash
```

> ⚠️ ただし `shell: bash` は **Windows なら必ず使えるとは限りません。**
> Git for Windows を既定オプションでインストールすると、PATH に入るのは
> `C:\Program Files\Git\cmd` だけで、`bash.exe` のある `Git\bin` は入りません。
> GitHub-hosted の Windows ランナーは明示的に PATH を通しているので動きますが、
> **自前で構築した runner では `bash: command not found` になることがあります。**

```yaml
# ② 環境変数はシェルに渡さず、GitHub の式で埋める（推奨）
- run: echo "os = ${{ runner.os }}"
```

②の書き方なら、`${{ }}` はシェルに渡る**前に**展開されるため、
**どのシェルでも同じ結果**になります。移植性を最優先するならこちらです。

#### `run:` に日本語を書くと文字化けすることがある

Windows PowerShell 5.1 で動くランナーでは、**`run:` の中に書いた日本語がログで文字化けします。**

```yaml
- run: echo "はじめての GitHub Actions"
```

```text
# ログに出るもの
ã¯ã˜ã‚ã¦ã® GitHub Actions
```

原因は文字コードの解釈違いです。ランナーは `run:` の中身を **UTF-8** で一時ファイルに書き出しますが、
Windows PowerShell 5.1 は BOM の無いファイルを **システムの既定コードページ**（ANSI）として読むため、
日本語が別の文字として解釈されます。PowerShell 7（`pwsh`）は既定が UTF-8 なので、この問題は起きません。

**対策はシンプルです。**

| 書く場所 | 日本語 | 理由 |
|---|---|---|
| `name:`（ワークフロー名・ジョブ名・ステップ名） | ✅ 使える | GitHub が YAML を UTF-8 で読んで画面に出すため |
| `#` コメント | ✅ 使える | 実行されないため |
| **`run:` の中身** | ❌ 避ける | シェルに渡る途中で壊れる |

```yaml
# ✅ 表示名は日本語、出力は英数字
- name: あいさつを表示する
  run: echo "Hello GitHub Actions"
```

> 💡 これは「動くけれど読めない」タイプの問題で、**エラーにはなりません。**
> ログが読めないと原因調査に時間がかかるので、
> **`run:` の出力は英数字**と決めておくのが実務上は無難です。

**`$GITHUB_OUTPUT` / `$GITHUB_ENV` も同じ罠です。**
この本の後半に出てくる次の書き方は、**bash 専用**です。

```yaml
# ❌ Windows (pwsh) では $GITHUB_OUTPUT が空になり書き込みに失敗する
- run: echo "version=1.2.3" >> "$GITHUB_OUTPUT"
```

```yaml
# ✅ pwsh ならこう書く
- run: "version=1.2.3" >> $env:GITHUB_OUTPUT
```

シェルをまたいで同じ YAML を使いたい場合は、`shell:` を明示するか、
OS ごとにステップを分けて `if: runner.os == 'Windows'` で切り替えてください。

#### 作業フォルダ（ワークスペース）が使い回される

GitHub-hosted は毎回まっさらな VM ですが、**self-hosted は同じフォルダを使い回します。**

- 場所は `<ランナーのフォルダ>\_work\<リポジトリ名>\<リポジトリ名>`
- **同じリポジトリなら、ワークフローが違っても同じフォルダ**を使う
- `actions/checkout` は既定が `clean: true`（`git clean -ffdx` + `git reset --hard`）なので、
  **Git が追跡しているファイルは毎回復元される**

ここから、self-hosted 特有の事故が生まれます。

| 事故 | 何が起きるか |
|---|---|
| `actions/checkout` の書き忘れ | **前回の残りファイルで動いてしまう。** 別のランナーに割り当てられた瞬間に壊れる |
| ビルド生成物の残留 | 消したはずのファイルが混ざる |
| 認証情報の残留 | 前のジョブが書いた設定ファイルを、次のジョブが読めてしまう |

**確実にまっさらから始めたいとき**は、ジョブの先頭で明示的に空にします。

```yaml
- name: 作業フォルダを空にする
  run: |
    Get-ChildItem -Force |
      Remove-Item -Recurse -Force -ErrorAction Ignore

- uses: actions/checkout@v5
```

> 💡 「前回は動いたのに今日は失敗する」「隣の人は成功するのに自分は失敗する」の
> かなりの割合が、この使い回しに起因します。
> **CI が"たまたま緑"になっていないか**を疑う視点を持ってください。

Kubernetes 上でランナーを自動スケールさせる構成もあります。運用コストとのトレードオフで判断してください。

---

## 6. 運用・ガバナンス・スケール

### 6.1 組織全体への展開戦略

**4 ステップ。順番に意味があります。**

| # | ステップ | ポイント |
|---|---|---|
| 1 | **パイロット** | 1〜2 チームで実際に動く形を作る |
| 2 | **共通部品の切り出し** | パイロットの成果を Reusable Workflow 化 |
| 3 | **ガードレール** | 組織設定で既定を安全に |
| 4 | **計測** | 効果を可視化して継続的に改善 |

**いきなり全社標準を作らないでください。** 机上で設計した共通ワークフローは使われません。

**着地点**: 組織の `.github` リポジトリに Reusable Workflow を集約し、各リポジトリからは数行呼ぶだけ。

**ガードレールは「禁止」より「既定を安全にする」ほうが機能します**:

- `permissions` の既定を read にする
- 許可する Action を制限する
- フォーク PR の既定を締める

計測は最後に置いていますが、**実際は最初から仕込んでおくとよい**です。効果が見えないと予算が続きません。

### 6.2 他 CI からの移行

**一括移行しないでください。これが最大のメッセージです。**

**並走期間を設けます。** 1.2 (b) で説明したとおり、Actions と既存 CI はブランチ保護の必須チェックで同列に扱えるので、**両方を必須にして結果を突き合わせられます。**

**移行順**: 壊れても影響が小さいものから。

```
lint / ユニットテスト  →  ビルド  →  統合テスト  →  デプロイ
```

**変換ツールについて**: 出発点にはなりますが、そのまま使えることは少ないです。生成された YAML を**レビューする前提**で使ってください。

> 移行を機に「そもそもこのジョブは必要か」を棚卸ししてください。動いていないテストや誰も見ていないレポートが必ず見つかります。

### 6.3 トラブルシュート定番

| 症状 | 原因 / 対処 |
|---|---|
| **feature ブランチで書いたのに動かない** | `issues` / `schedule` / `workflow_run` 系はデフォルトブランチの定義しか見ない（2.2） |
| **schedule が止まった** | リポジトリ非アクティブによる自動無効化。バグではない。UI の文言を確認 |
| **ジョブ間でファイルが消える** | ジョブは別マシン。`artifacts` を使う（2.5） |
| **前段の outputs が読めない** | `needs` の張り忘れ |
| **Bot が push したのに CI が回らない** | `GITHUB_TOKEN` の push は新たな workflow を起動しない仕様（4.3） |
| **Re-run しても URL が変わらない** | 仕様。1 つの Run が複数の実行回を持つ。API で集計するときは実行回を意識しないと数字がずれる |
| **構文エラーを直したらまた別のエラー** | 正常。エラーの報告は途中で打ち切られることがある。直して push し直すサイクルが前提 |
| **ジョブが queued のまま** | 同時実行数の上限、またはランナーの空き待ち（5.5） |

> ローカルで再現するツールは便利ですが、本家とは別実装です。挙動が完全一致するわけではありません。**差異が出たら本家を正としてください。**

---

## 7. まとめ

### 持ち帰ってもらう 5 つ

1. **Actions は CI ツールではない** — イベント駆動の汎用実行基盤
2. **ジョブは別マシン** — 受け渡しは `outputs` / `artifacts`
3. **`permissions` を必ず書く** — 書かないと環境依存
4. **`pull_request_target` を疑う** — フォークのコードを実行しない
5. **走る回数から削る** — `concurrency` の 4 行が最も効く

### 明日からやる 3 つ（宿題）

どれも 30 分以内に終わります。

- [ ] **`concurrency` の 4 行**を主要リポジトリのワークフローに入れる（5.3）
- [ ] **`permissions: contents: read`** をワークフロー冒頭に宣言する（4.2）
- [ ] **`pull_request_target` を使っているワークフローを棚卸し**する（4.4）

---

# 付録

## 付録 Z. 用語集

わからない言葉が出てきたら、ここに戻ってきてください。

### CI/CD の言葉

| 用語 | 読み | 意味 |
|---|---|---|
| **CI** | シーアイ | Continuous Integration。コードを変更するたびに、自動でビルド・テストして壊れていないか確かめること |
| **CD** | シーディー | Continuous Delivery / Deployment。テストを通ったものを、自動で配布・デプロイすること |
| **パイプライン** | — | 「取ってくる → 組み立てる → 試す → 配る」という一連の自動処理の流れ |
| **ビルド** | — | ソースコードを、実際に動く形（実行ファイル、コンテナイメージ等）に変換すること |
| **デプロイ** | — | ビルドしたものを、実際に動く場所（サーバー、クラウド）に配置すること |
| **ステージング** | staging | 本番と同じ構成の検証環境 |
| **プロダクション** | production | 本番環境 |
| **ロールバック** | — | 問題が出たときに、前の状態に戻すこと |
| **fail fast** | — | 失敗するなら早く失敗させる。速いチェックを先に置く考え方 |

### GitHub Actions の言葉

| 用語 | 意味 |
|---|---|
| **ワークフロー** | Actions の処理を書いた YAML ファイル 1 本のこと。`.github/workflows/` に置く |
| **ジョブ (job)** | ワークフローの中の作業のかたまり。**1 ジョブ = 1 台の仮想マシン**。既定では並列に走る |
| **ステップ (step)** | ジョブの中で上から順に実行される 1 手 |
| **ランナー (runner)** | ワークフローを実際に動かすマシン |
| **GitHub-hosted runner** | GitHub が貸してくれる、毎回まっさらな仮想マシン |
| **Self-hosted runner** | 自社で用意するランナー。社内ネットワークに繋げる |
| **トリガー** | ワークフローを動かすきっかけ。`on:` で書く |
| **Action** | 再利用できる部品。`uses:` で呼び出す。例：`actions/checkout` |
| **`run:`** | シェルコマンドをそのまま実行する書き方 |
| **`uses:`** | 誰かが作った部品（Action）を呼び出す書き方 |
| **`with:`** | Action に渡す入力 |
| **`needs:`** | 「このジョブが終わってから動く」という依存関係の指定 |
| **`if:`** | 条件付き実行 |
| **コンテキスト** | `${{ github.sha }}` のように参照できる実行時の情報 |
| **マトリクス** | 複数の条件（OS × バージョンなど）で並列に実行するしくみ |
| **アーティファクト** | ワークフローが生成したファイルを、後から取り出せるように保存したもの |
| **キャッシュ** | 依存関係などを次回のために取っておくしくみ。速度対策 |
| **`concurrency`** | 同じグループの実行が重ならないようにするしくみ |
| **シークレット (Secrets)** | パスワードやトークンを安全に預ける仕組み。`${{ secrets.NAME }}` |
| **変数 (Variables)** | 機密でない設定値。`${{ vars.NAME }}` |
| **Environment** | `staging` `production` のように、デプロイ先ごとに設定や承認ルールを分ける単位 |
| **`GITHUB_TOKEN`** | 各実行に自動で渡される、そのリポジトリ用の一時トークン |
| **`permissions:`** | `GITHUB_TOKEN` に何を許すかの指定。最小にするのが原則 |
| **Required status checks** | 「このチェックが緑でないとマージできない」というブランチ保護の設定 |
| **再利用可能ワークフロー** | 他のワークフローから `uses:` で呼べるワークフロー |
| **Composite Action** | 複数ステップをひとつの Action にまとめたもの |

### セキュリティの言葉

| 用語 | 読み | 意味 |
|---|---|---|
| **OIDC** | オーアイディーシー | OpenID Connect。長期のアクセスキーを保存せずに、その場限りの資格情報でクラウドに接続する仕組み |
| **ID トークン** | — | OIDC で GitHub が発行する短命の証明書 |
| **`sub` クレーム** | サブ | ID トークンに入る「誰か」を表す文字列。`repo:org@123456/repo@7890123:environment:production` の形 |
| **STS** | エスティーエス | AWS Security Token Service。一時的な資格情報を発行する AWS のサービス |
| **信頼ポリシー** | trust policy | AWS のロールに対して「誰が引き受けてよいか」を書いたルール |
| **最小権限** | least privilege | 必要な権限だけを与えるという原則 |
| **SHA ピン留め** | — | Action をタグではなくコミット SHA で指定して、中身を確定させること |
| **スクリプトインジェクション** | — | 外部から来た文字列がシェルコマンドとして解釈されてしまう攻撃 |
| **サプライチェーン** | — | 自分が使っている外部の部品（ライブラリ、Action）の連鎖。ここが汚染されると影響が広い |
| **監査ログ** | audit log | 誰がいつ何をしたかの記録 |

### その他

| 用語 | 読み | 意味 |
|---|---|---|
| **YAML** | ヤムル / ヤメル | 設定を書くためのファイル形式。字下げに意味がある |
| **GHEC** | ジーエイチイーシー | GitHub Enterprise Cloud。クラウド版の企業向け GitHub |
| **Organization** | — | GitHub の組織アカウント。リポジトリとメンバーをまとめる単位 |
| **ブランチ保護** | — | 特定のブランチへの変更にルールをかける設定 |
| **Dependabot** | — | 依存関係の更新 PR を自動で作ってくれる GitHub の機能 |

---

## 付録 A. アンチパターン集

| アンチパターン | なぜ悪いか |
|---|---|
| `uses: foo/bar@main` | 上流の変更が即座に本番 CI に入る |
| すべてを 1 ジョブに詰め込む | 並列化できず、失敗箇所も分かりにくい |
| `permissions` 未指定 | 環境差で挙動が変わる。過剰権限になりやすい |
| self-hosted runner を使い回す | 前ジョブの残骸・認証情報が漏れる |
| シークレットを `env:` でグローバルに展開 | 全ステップ（= サードパーティ Action）に露出 |
| `if: always()` を安易に多用 | 失敗時にデプロイまで走る事故 |
| 巨大な matrix で全組み合わせ | 課金とキュー待ちの浪費。代表点に絞る |
| ログに `echo $SECRET` | マスクを回避してしまう書き方に注意 |

---

## 付録 B. トラブルシュート早見表

**症状から引く**

| 「〜が動かない」 | 見るべき節 |
|---|---|
| ワークフロー自体が起動しない | 2.2（トリガーの種類とブランチ） |
| ファイルが見つからない | 1.3 / 2.5（ジョブは別マシン） |
| 変数が空 | 2.3（コンテキスト）/ 2.5（`needs`） |
| 権限エラー | 4.2（`permissions`）/ 4.3（`GITHUB_TOKEN` の境界） |
| シークレットが渡らない | 4.4（フォーク PR）/ 4.9（Environment スコープ） |
| 遅い / 高い | 5.2（施策の優先順位） |
| キャッシュが効かない | 5.4（キーとブランチスコープ） |
| ジョブが待たされる | 5.5（同時実行数の上限） |

---

## 付録 C. 参考リンク

**公式ドキュメント（一次情報）**

- GitHub Actions ドキュメント: https://docs.github.com/actions
- ワークフロー構文リファレンス: https://docs.github.com/actions/reference/workflow-syntax-for-github-actions
- セキュリティ強化ガイド: https://docs.github.com/actions/security-guides/security-hardening-for-github-actions
- OIDC によるセキュリティ強化: https://docs.github.com/actions/deployment/security-hardening-your-deployments

**ツール / リポジトリ**

- ランナーイメージの内容: https://github.com/actions/runner-images
- キャッシュの棚卸し CLI: https://github.com/actions/gh-actions-cache
- Dependabot 設定リファレンス: https://docs.github.com/code-security/dependabot

> Actions は更新が速い領域です。記事より**一次情報を見る癖**をつけてください。
> 特にセキュリティ強化ガイドは、本ワークショップの内容の裏取りとして読む価値があります。

---

*このハンドアウトは GitHub Actions 実践ワークショップの配布資料です。*
