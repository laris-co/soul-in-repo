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
  expect("error" in plan(["out", "neo", "--chname=dash"])).toBe(true);
});
