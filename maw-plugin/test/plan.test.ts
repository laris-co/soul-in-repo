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
  expect(err(["ears", "neo", "--deny-main"])).toContain("do not go with ears");
  expect(err(["ears", "neo", "--bot=x"])).toContain("do not go with ears");
  expect(err(["in", "neo", "--all"])).toContain("--all goes with ears add");
  expect(err(["ears", "neo", "a/b", "c/d"])).toContain("too many words");
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

test("threads reads; icon is a plan unless --yes", () => {
  expect(plan(["threads"])).toEqual({ argv: ["threads"], dry: false });
  expect(plan(["threads", "laris-co/soul-in-repo"])).toEqual({ argv: ["threads", "laris-co/soul-in-repo"], dry: false });
  expect(plan(["icon", "neo"])).toEqual({ argv: ["icon", "neo-oracle"], dry: true });
  expect(plan(["icon", "neo", "laris-co/x", "--yes"])).toEqual({ argv: ["icon", "neo-oracle", "laris-co/x", "--go"], dry: false });
  expect(plan(["icon", "pulse", "--off", "--yes"])).toEqual({ argv: ["icon", "pulse-oracle", "--off", "--go"], dry: false });
  expect(plan(["icon", "neo", "--yes", "--dry"])).toEqual({ argv: ["icon", "neo-oracle"], dry: true });
  const err = (a: string[]) => (plan(a) as { error: string }).error;
  expect(err(["icon"])).toContain("maw soul icon <oracle>");
  expect(err(["icon", "neo", "--all"])).toContain("icon takes only");
  expect(err(["ls", "--off"])).toContain("--off goes with icon");
});

test("idea / convert are retired: the error names !! + promote", () => {
  for (const v of [["idea", "fake-idea", "neo"], ["convert", "fake-idea", "--repo=laris-co/x"]]) {
    const e = plan(v) as { error: string };
    expect(e.error).toContain("retired");
    expect(e.error).toContain("maw soul promote <thread>");
  }
  expect("error" in plan(["in", "neo", "--dir=/tmp"])).toBe(true);
});

test("wt / wt-close: named worktree joined by forward, plan unless --yes", () => {
  expect(plan(["wt", "test-wt", "laris-co/00_mz_forwarder"])).toEqual({ argv: ["wt", "test-wt", "laris-co/00_mz_forwarder", "--dry"], dry: true });
  expect(plan(["wt", "fix-1", "--channel=1568518331600867338", "--bot=somsri", "--yes"])).toEqual({ argv: ["wt", "fix-1", "--bot=somsri", "--channel=1568518331600867338", "--yes"], dry: false });
  expect(plan(["wt-close", "fix-1", "laris-co/x", "--yes"])).toEqual({ argv: ["wt-close", "fix-1", "laris-co/x", "--yes"], dry: false });
  expect("error" in plan(["wt"])).toBe(true);
  expect("error" in plan(["wt", "bad name"])).toBe(true);
  expect("error" in plan(["wt", "a", "b", "c"])).toBe(true);
  expect("error" in plan(["wt", "a", "--name=x"])).toBe(true);
  expect("error" in plan(["wt-close", "a", "--channel=1568518331600867338"])).toBe(true);
});

test("--thread on link and wt: an existing thread, ids only, not with --whole-channel or on close", () => {
  const w = "/opt/Code/github.com/laris-co/x/wt/a";
  expect(plan(["link", w, "--thread=1568526565242044558"])).toEqual({ argv: ["link", w, "--thread=1568526565242044558", "--dry"], dry: true });
  expect(plan(["wt", "a", "laris-co/x", "--thread=1568526565242044558", "--yes"])).toEqual({ argv: ["wt", "a", "laris-co/x", "--thread=1568526565242044558", "--yes"], dry: false });
  expect("error" in plan(["link", w, "--thread=abc"])).toBe(true);
  expect("error" in plan(["wt", "a", "--thread=abc"])).toBe(true);
  expect("error" in plan(["link", w, "--thread=1568526565242044558", "--whole-channel=1568518331600867338"])).toBe(true);
  expect("error" in plan(["unlink", w, "--thread=1568526565242044558"])).toBe(true);
  expect("error" in plan(["wt-close", "a", "--thread=1568526565242044558"])).toBe(true);
});

test("promote: a thread id, then oracles; plan unless --yes", () => {
  const T = "1568876528010268692";
  expect(plan(["promote", T])).toEqual({ argv: ["promote", T, "--dry"], dry: true });
  expect(plan(["promote", T, "neo", "pulse-oracle"])).toEqual({ argv: ["promote", T, "neo-oracle", "pulse-oracle", "--dry"], dry: true });
  expect(plan(["promote", T, "neo", "--name=esp32-beacon", "--owner=laris-co", "--public", "--yes"]))
    .toEqual({ argv: ["promote", T, "neo-oracle", "--owner=laris-co", "--name=esp32-beacon", "--public", "--yes"], dry: false });
  expect(plan(["promote", T, "--yes", "--dry"])).toEqual({ argv: ["promote", T, "--dry"], dry: true });
  expect((plan(["promote"]) as { error: string }).error).toContain("maw soul promote <thread id>");
  expect((plan(["promote", "esp32"]) as { error: string }).error).toContain("which thread?");
  expect("error" in plan(["promote", T, "--channel=1568518331600867338"])).toBe(true);
  expect("error" in plan(["promote", T, "--deny-main"])).toBe(true);
  expect("error" in plan(["promote", T, "--bot=neo"])).toBe(true);
  expect("error" in plan(["promote", T, "--repo=a/b"])).toBe(true);
  expect("error" in plan(["promote", T, "--name=bad name"])).toBe(true);
  expect("error" in plan(["promote", T, "--owner=-x"])).toBe(true);
  expect((plan(["in", "neo", "--owner=laris-co"]) as { error: string }).error).toContain("go with promote");
});

test("promote --new passes through; --owner/--new only with promote", () => {
  const T = "1566303691781308466";
  expect(plan(["promote", T, "neo", "--new", "--yes"])).toEqual({ argv: ["promote", T, "neo-oracle", "--new", "--yes"], dry: false });
  expect("error" in plan(["in", "neo", "--new"])).toBe(true);
});

test("archive: one repo, plan unless --yes, --unarchive and --by pass through", () => {
  expect(plan(["archive", "nat-build-with-oracle/promote-demo"])).toEqual({ argv: ["archive", "nat-build-with-oracle/promote-demo", "--dry"], dry: true });
  expect(plan(["archive", "a/b", "--unarchive", "--by=nazt_", "--yes"])).toEqual({ argv: ["archive", "a/b", "--unarchive", "--by=nazt_", "--yes"], dry: false });
  expect("error" in plan(["archive"])).toBe(true);
  expect("error" in plan(["in", "neo", "--unarchive"])).toBe(true);
});

test("work: a repo or a github url, then oracles", () => {
  expect(plan(["work", "https://github.com/Soul-Brews-Studio/discord-voice-bot"])).toEqual({ argv: ["work", "Soul-Brews-Studio/discord-voice-bot", "--dry"], dry: true });
  expect(plan(["work", "a/b", "neo", "--yes"])).toEqual({ argv: ["work", "a/b", "neo-oracle", "--yes"], dry: false });
  expect("error" in plan(["work"])).toBe(true);
});

test("archive help says it sleeps and wakes, never restarts (laris-team#210)", async () => {
  const r = await handler({ source: "cli", args: ["help"] });
  expect(r.output).toContain("sleep on");
  expect(r.output).toContain("wakes them where they slept");
  expect(plan(["archive", "o/r", "--unarchive"])).toEqual({ argv: ["archive", "o/r", "--unarchive", "--dry"], dry: true });
});

test("doctor is a read: no --dry, its own flags pass through", () => {
  expect(plan(["doctor"])).toEqual({ argv: ["doctor"], dry: false });
  expect(plan(["doctor", "laris-co/x", "--online", "-j"])).toEqual({ argv: ["doctor", "laris-co/x", "--online", "-j"], dry: false });
  expect((plan(["ls", "--online"]) as { error: string }).error).toContain("goes with doctor");
  expect("error" in plan(["doctor", "a/b", "c/d"])).toBe(true);
});
