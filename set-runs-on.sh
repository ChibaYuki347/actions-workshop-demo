#!/usr/bin/env bash
# ラベルが判明したら、これ 1 発で教材全体の runs-on を差し替える。
#
#   ./set-runs-on.sh 'ubuntu-latest'
#   ./set-runs-on.sh '[ self-hosted, Windows, workshop ]'
#
# 差し替え対象:
#   1. template/ 配下の .yml の runs-on 行（RUNS_ON_MARKER 付き）
#   2. handson-guide.md のコードブロック内の runs-on 行（${{ }} を含む行は除く）
#   2b. handout.md 冒頭の「本日の環境では」注記
#   3. handson-guide.md 冒頭「本日使う値」の表セル
set -euo pipefail
cd "$(dirname "$0")"

if [ $# -ne 1 ]; then
  echo "usage: $0 <runs-on value>" >&2
  echo "  例: $0 '[ self-hosted, Windows, workshop ]'" >&2
  exit 1
fi
VALUE="$1"

echo "=== 1. ワークフロー / snippets ==="
for f in $(grep -rl 'RUNS_ON_MARKER' template/ --include='*.yml' || true); do
  perl -pi -e "s{^(\s*)runs-on:.*RUNS_ON_MARKER.*\$}{\$1runs-on: ${VALUE}   # RUNS_ON_MARKER}" "$f"
  echo "  updated: $f"
done

# 手順書（受講者がそのまま写す）だけを差し替える。
# handout.md は「読み物」なので ubuntu-latest のままにし、冒頭の注記で吸収する。
# ${{ }} を含む行（matrix など）は絶対に触らない。
echo "=== 2. 手順書のコードブロック ==="
for f in template/docs/handson-guide.md; do
  before=$(grep -c '^[[:space:]]\+runs-on:' "$f" || true)
  [ "$before" = "0" ] && continue
  perl -pi -e 's{^(\s+)runs-on:(?!.*\{\{).*$}{$1runs-on: '"${VALUE}"'}' "$f"
  echo "  updated: $f ($before 箇所)"
done

echo "=== 2b. handout.md 冒頭の注記 ==="
perl -pi -e "s{^> \*\*本日の環境では\*\* .*\$}{> **本日の環境では** \`runs-on:\` に \`${VALUE}\` を指定します（手順書の値が正です）。}" template/docs/handout.md
grep -n '本日の環境では' template/docs/handout.md || true

echo "=== 3. 「本日使う値」の表 ==="
perl -pi -e "s{^\| \*\*本日使う値\*\* \| .*\$}{| **本日使う値** | \`${VALUE}\` |}" template/docs/handson-guide.md
grep -n '本日使う値' template/docs/handson-guide.md || true

echo
echo "=== 差し替え後の runs-on 一覧 ==="
grep -rn '^[[:space:]]*runs-on:' template/ || true
