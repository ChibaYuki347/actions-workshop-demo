// デプロイのデモ用の、依存パッケージゼロの HTTP サーバ。
//
// 「デプロイした」と言われてもピンと来ないので、
// ブラウザで開いたときに「いつの・どのコミットが動いているか」が
// 一目で分かるようにしてあります。
//
// ローカルで動かす:  npm start  →  http://localhost:3000

import { createServer } from "node:http";
import { version } from "./index.js";

const port = process.env.PORT ?? 3000;

// デプロイ時に埋め込まれる値（無ければローカル実行とみなす）
const commit = process.env.APP_COMMIT ?? "local";
const builtAt = process.env.APP_BUILT_AT ?? "-";
const shortCommit = commit.slice(0, 7);

function page() {
  return `<!doctype html>
<html lang="ja">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>GitHub Actions Workshop</title>
<style>
  :root { color-scheme: dark; }
  body {
    margin: 0; min-height: 100vh;
    display: grid; place-items: center;
    background: #0d1117; color: #e6edf3;
    font-family: "Segoe UI", "Hiragino Sans", "Noto Sans JP", system-ui, sans-serif;
  }
  .card { text-align: center; padding: 3rem; }
  h1 { font-size: clamp(2rem, 6vw, 3.5rem); margin: 0 0 .5rem; }
  .ok { color: #3fb950; font-size: clamp(3rem, 10vw, 6rem); line-height: 1; }
  dl { display: grid; grid-template-columns: auto auto; gap: .6rem 1.5rem;
       margin: 2.5rem auto 0; width: max-content; font-size: 1.1rem; }
  dt { color: #8b949e; text-align: right; }
  dd { margin: 0; text-align: left; font-family: ui-monospace, "Cascadia Code", monospace; }
  .hint { margin-top: 2.5rem; color: #8b949e; font-size: .95rem; }
</style>
</head>
<body>
  <div class="card">
    <div class="ok">&#10003;</div>
    <h1>デプロイできました</h1>
    <dl>
      <dt>バージョン</dt><dd>${version()}</dd>
      <dt>コミット</dt><dd>${shortCommit}</dd>
      <dt>デプロイ日時</dt><dd>${builtAt}</dd>
    </dl>
    <p class="hint">GitHub には、このクラウドの鍵は 1 つも置いていません。</p>
  </div>
</body>
</html>`;
}

createServer((req, res) => {
  // 死活監視用。ワークフローからここを叩いて確認します
  if (req.url === "/healthz") {
    res.writeHead(200, { "content-type": "application/json" });
    res.end(JSON.stringify({ status: "ok", commit, version: version() }));
    return;
  }
  res.writeHead(200, { "content-type": "text/html; charset=utf-8" });
  res.end(page());
}).listen(port, () => {
  console.log(`listening on http://localhost:${port} (commit: ${shortCommit})`);
});
