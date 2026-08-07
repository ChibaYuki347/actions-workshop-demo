import { test } from "node:test";
import assert from "node:assert/strict";
import { add, greet, version } from "../src/index.js";

test("add sums two numbers", () => {
  assert.equal(add(2, 3), 5);
});

test("greet returns a greeting", () => {
  assert.equal(greet("Octocat"), "Hello, Octocat!");
});

test("greet rejects empty input", () => {
  assert.throws(() => greet(""), TypeError);
});

test("version falls back to a dev version", () => {
  assert.match(version(), /^\d+\.\d+\.\d+/);
});
