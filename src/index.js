// ワークショップ用の最小アプリケーション。
// 依存パッケージをゼロにしてあるので、オフラインでも `npm ci` / `npm test` が動きます。

export function add(a, b) {
  return a + b;
}

export function greet(name) {
  if (typeof name !== "string" || name.trim() === "") {
    throw new TypeError("name must be a non-empty string");
  }
  return `Hello, ${name}!`;
}

export function version() {
  return process.env.APP_VERSION ?? "0.0.0-dev";
}

if (import.meta.url === `file://${process.argv[1]}`) {
  console.log(greet(process.argv[2] ?? "GitHub Actions"));
  console.log(`version: ${version()}`);
}
