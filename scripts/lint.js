// 外部依存を増やさないための、ごく簡易な「lint っぽい」チェック。
// 本物の ESLint の代わりではなく、ワークショップで CI のステップを増やすためのものです。
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join, extname } from "node:path";

const targets = ["src", "test", "scripts"];
const problems = [];

function walk(dir) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) {
      walk(full);
    } else if (extname(full) === ".js") {
      check(full);
    }
  }
}

function check(file) {
  const lines = readFileSync(file, "utf8").split("\n");
  lines.forEach((line, i) => {
    if (line.includes("\t")) {
      problems.push(`${file}:${i + 1} タブ文字が含まれています`);
    }
    if (line.trimEnd() !== line) {
      problems.push(`${file}:${i + 1} 行末に空白があります`);
    }
  });
}

for (const dir of targets) {
  try {
    walk(dir);
  } catch {
    // ディレクトリが無い場合は無視
  }
}

if (problems.length > 0) {
  console.error(problems.join("\n"));
  console.error(`\n${problems.length} 件の問題が見つかりました`);
  process.exit(1);
}

console.log("lint: 問題は見つかりませんでした");
