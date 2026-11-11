import { expect, test } from "bun:test";
import { existsSync, lstatSync, readFileSync } from "node:fs";
import { join } from "node:path";

// `maw plugin install laris-co/soul-in-repo` clones the whole repo and reads plugin.json at its root
// (maw-cli mod.pluginInstall.ts). maw-plugin/plugin.json stays for older `ln -s <repo>/maw-plugin` installs.
// Both must describe the same plugin; only `entry` differs, and neither path may cross a symlink.
const repo = join(import.meta.dir, "..", "..");
const read = (p: string) => JSON.parse(readFileSync(p, "utf8"));

test("root plugin.json = maw-plugin/plugin.json except entry", () => {
  const root = read(join(repo, "plugin.json"));
  const sub = read(join(repo, "maw-plugin", "plugin.json"));
  expect(root.entry).toBe("./maw-plugin/src/index.ts");
  expect(sub.entry).toBe("./src/index.ts");
  expect({ ...root, entry: "" }).toEqual({ ...sub, entry: "" });
});

test("each entry is a regular file reached without a symlink", () => {
  for (const [dir, file] of [[repo, "plugin.json"], [join(repo, "maw-plugin"), "plugin.json"]] as const) {
    const entry: string = read(join(dir, file)).entry;
    let p = dir;
    for (const part of entry.split("/")) {
      p = join(p, part);
      expect(lstatSync(p).isSymbolicLink()).toBe(false);
    }
    expect(lstatSync(p).isFile()).toBe(true);
  }
  // the plugin finds bin/herdr-soul two folders up from src/, as in a clone
  expect(existsSync(join(repo, "maw-plugin", "src", "..", "..", "bin", "herdr-soul"))).toBe(true);
});

test("README opens with the maw plugin Install block", () => {
  const md = readFileSync(join(repo, "README.md"), "utf8");
  const head = md.split("## Quick start")[0];
  expect(head).toContain("## Install\n\n```\nmaw plugin install laris-co/soul-in-repo\nmaw soul --help\n```\n\nUpdate: `maw plugin update soul`");
  expect(md).not.toMatch(/maw plugin install \//);
  const order = ["## Install", "## Quick start", "## Configuration", "## Safety", "## Notes", "## Development"].map(h => md.indexOf(h));
  expect(order.every(i => i >= 0)).toBe(true);
  expect([...order].sort((a, b) => a - b)).toEqual(order);
  expect(md.trimEnd().endsWith("```")).toBe(true);   // Development is the last section
});
