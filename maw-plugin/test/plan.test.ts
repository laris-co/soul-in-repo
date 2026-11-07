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

test("room: many souls, plan unless --yes, channel pin passes through", () => {
  expect(plan(["room", "laris-co/nongbua-oracle", "neo", "digger-oracle"])).toEqual({ argv: ["room", "laris-co/nongbua-oracle", "neo-oracle", "digger-oracle", "--dry"], dry: true });
  expect(plan(["room", "laris-co/x", "neo", "--channel=1567747387102072912", "--yes"])).toEqual({ argv: ["room", "laris-co/x", "neo-oracle", "--channel=1567747387102072912", "--yes"], dry: false });
  expect(plan(["room", "laris-co/x", "neo", "--yes", "--dry"])).toEqual({ argv: ["room", "laris-co/x", "neo-oracle", "--dry"], dry: true });
  expect("error" in plan(["room", "laris-co/x"])).toBe(true);
  expect("error" in plan(["room", "laris-co/x", "neo", "--chname=dash"])).toBe(true);
});

test("link / unlink: plan unless --yes, link options pass through", () => {
  const w = "/Users/x/.herdr/worktrees/soul-in-repo/worktree-green-forest-241b";
  expect(plan(["link", w])).toEqual({ argv: ["link", w, "--dry"], dry: true });
  expect(plan(["link", w, "--bot=somsri-oracle", "--name=green", "--channel=1568518331600867338", "--yes"])).toEqual({ argv: ["link", w, "--bot=somsri-oracle", "--name=green", "--channel=1568518331600867338", "--yes"], dry: false });
  expect(plan(["unlink", w, "--yes"])).toEqual({ argv: ["unlink", w, "--yes"], dry: false });
  expect("error" in plan(["link"])).toBe(true);
  expect("error" in plan(["unlink", w, "--name=x"])).toBe(true);
  expect("error" in plan(["in", "neo", "--bot=x"])).toBe(true);
});

test("link --whole-channel: channel id only, not with --channel; unlink takes it too", () => {
  const w = "/opt/Code/github.com/laris-co/x";
  expect(plan(["link", w, "--whole-channel=1568518331600867338"])).toEqual({ argv: ["link", w, "--whole-channel=1568518331600867338", "--dry"], dry: true });
  expect(plan(["unlink", w, "--whole-channel=1568518331600867338", "--yes"])).toEqual({ argv: ["unlink", w, "--whole-channel=1568518331600867338", "--yes"], dry: false });
  expect("error" in plan(["link", w, "--whole-channel=abc"])).toBe(true);
  expect("error" in plan(["link", w, "--whole-channel=1568518331600867338", "--channel=1568518331600867338"])).toBe(true);
});
