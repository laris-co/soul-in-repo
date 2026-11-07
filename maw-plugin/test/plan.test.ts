import { expect, test } from "bun:test";
import { handler, plan } from "../src/index";

test("reads pass straight through", () => {
  expect(plan([])).toEqual({ argv: ["ls"], dry: false });
  expect(plan(["list"])).toEqual({ argv: ["list"], dry: false });
  expect(plan(["ls", "laris-co/soul-in-repo"])).toEqual({ argv: ["ls", "laris-co/soul-in-repo"], dry: false });
  expect(plan(["check", "neo", "laris-co/soul-in-repo"])).toEqual({ argv: ["check", "neo-oracle", "laris-co/soul-in-repo"], dry: false });
});

test("writes are a plan unless --yes", () => {
  expect(plan(["in", "neo", "laris-co/x"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--dry"], dry: true });
  expect(plan(["in", "neo-oracle", "laris-co/x", "--yes"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x"], dry: false });
  expect(plan(["in", "neo", "--yes", "--dry"])).toEqual({ argv: ["in", "neo-oracle", "--dry"], dry: true });
  expect(plan(["out", "pulse", "laris-co/x"])).toEqual({ argv: ["out", "pulse-oracle", "laris-co/x"], dry: true });
  expect(plan(["out", "pulse", "laris-co/x", "--yes"])).toEqual({ argv: ["out", "pulse-oracle", "laris-co/x", "--go"], dry: false });
});

test("migrate and --deny-main map to soul-in-repo.sh flags", () => {
  expect(plan(["migrate", "neo", "laris-co/x"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--migrate", "--dry"], dry: true });
  expect(plan(["migrate", "neo", "laris-co/x", "--deny-main", "--yes"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--migrate", "--deny-main"], dry: false });
  expect(plan(["in", "neo", "laris-co/x", "--deny-main"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--deny-main", "--dry"], dry: true });
  expect("error" in plan(["out", "neo", "--deny-main"])).toBe(true);
});

test("errors name the fix", () => {
  const e = plan(["in"]) as { error: string };
  expect(e.error).toContain("maw soul in <oracle> [repo]");
  expect((plan(["nope"]) as { error: string }).error).toContain("maw soul help");
  expect((plan(["ls", "--wat"]) as { error: string }).error).toContain("unknown flag --wat");
});

test("help", async () => {
  const r = await handler({ source: "cli", args: ["help"] });
  expect(r.ok).toBe(true);
  expect(r.output).toContain("--yes");
});

test("layout 9 flags pass through to in / migrate only", () => {
  expect(plan(["migrate", "pulse", "laris-co/x", "--chname=dash"])).toEqual({ argv: ["in", "pulse-oracle", "laris-co/x", "--migrate", "--chname=dash", "--dry"], dry: true });
  expect((plan(["in", "neo", "--main"]) as { error: string }).error).toContain("unknown flag --main");
  expect(plan(["in", "neo", "laris-co/x", "--chname=dash", "--yes"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--chname=dash"], dry: false });
  expect("error" in plan(["in", "neo", "--chname=weird"])).toBe(true);
  expect(plan(["migrate", "neo", "laris-co/x", "--channel=1568518331600867338"])).toEqual({ argv: ["in", "neo-oracle", "laris-co/x", "--migrate", "--channel=1568518331600867338", "--dry"], dry: true });
  expect("error" in plan(["in", "neo", "--channel=abc"])).toBe(true);
  expect("error" in plan(["out", "neo", "--chname=dash"])).toBe(true);
});

test("ears: ls reads, add|rm are a plan unless --yes", () => {
  const T = "1568526565242044558";
  expect(plan(["ears", "neo"])).toEqual({ argv: ["ears", "neo-oracle"], dry: false });
  expect(plan(["ears", "neo", "laris-co/x"])).toEqual({ argv: ["ears", "neo-oracle", "laris-co/x"], dry: false });
  expect(plan(["ears", "neo", "laris-co/x", "ls"])).toEqual({ argv: ["ears", "neo-oracle", "laris-co/x"], dry: false });
  expect(plan(["ears", "neo", "add", T])).toEqual({ argv: ["ears", "neo-oracle", "add", T], dry: true });
  expect(plan(["ears", "neo", "laris-co/x", "add", T, "--all"])).toEqual({ argv: ["ears", "neo-oracle", "laris-co/x", "add", T, "--all"], dry: true });
  expect(plan(["ears", "pulse", "laris-co/x", "add", T, "--all", "--yes"])).toEqual({ argv: ["ears", "pulse-oracle", "laris-co/x", "add", T, "--all", "--go"], dry: false });
  expect(plan(["ears", "neo", "rm", T, "--yes"])).toEqual({ argv: ["ears", "neo-oracle", "rm", T, "--go"], dry: false });
  expect(plan(["ears", "neo", "rm", T, "--yes", "--dry"])).toEqual({ argv: ["ears", "neo-oracle", "rm", T], dry: true });
});

test("ears: errors name the fix", () => {
  const err = (a: string[]) => (plan(a) as { error: string }).error;
  expect(err(["ears"])).toContain("maw soul ears <oracle>");
  expect(err(["ears", "neo", "add"])).toContain("maw soul ears neo add <thread id>");
  expect(err(["ears", "neo", "add", "abc"])).toContain("<thread id>");
  expect(err(["ears", "neo", "rm", "1568526565242044558", "--all"])).toContain("--all goes with ears add");
  expect(err(["ears", "neo", "--all"])).toContain("--all and --yes go with ears add|rm");
  expect(err(["ears", "neo", "--deny-main"])).toContain("not ears");
  expect(err(["in", "neo", "--all"])).toContain("--all goes with ears add");
  expect(err(["ears", "neo", "a/b", "c/d"])).toContain("too many words");
});
