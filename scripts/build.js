// アーティファクトのデモ用に、それらしい成果物を dist/ に吐くだけのビルド。
import { mkdirSync, writeFileSync, readFileSync } from "node:fs";

const pkg = JSON.parse(readFileSync("package.json", "utf8"));
const target = process.env.BUILD_TARGET ?? "default";

mkdirSync("dist", { recursive: true });

const manifest = {
  name: pkg.name,
  version: process.env.APP_VERSION ?? pkg.version,
  target,
  builtAt: new Date().toISOString(),
  commit: process.env.GITHUB_SHA ?? "local",
};

writeFileSync(`dist/${target}.json`, JSON.stringify(manifest, null, 2));
writeFileSync("dist/app.txt", `built ${target} at ${manifest.builtAt}\n`);

console.log(`built dist/${target}.json`);
