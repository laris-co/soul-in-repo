// maw soul: put an oracle's soul to work inside another repo, from any folder.
// A thin front. Every verb runs bin/herdr-soul (which runs soul-in-repo.sh for `in`); no logic is copied here,
// so maw soul, /herdr-soul and the herdr plugin laris.soul always do the same thing.
//
//   maw soul list                          oracles that can come in
//   maw soul ls      [repo]                souls of a repo (default: the repo of the current folder)
//   maw soul check   <oracle> [repo]       preflight, changes nothing, prints the fix for each failed item
//   maw soul in      <oracle> [repo]       plan; --yes brings the soul in
//   maw soul out     <oracle> [repo]       plan; --yes takes it out (herdr-soul out --go)
//   maw soul migrate <oracle> [repo]       plan; --yes moves a LIVE body to #repo (soul-in-repo.sh --migrate)
//   maw soul room    <repo> <oracle>...    layout 9 for many souls: migrate a live body, else in; always --deny-main
//   maw soul idea    <idea> <oracle>...    IDEA MODE: channel 💡・<idea>, a thread per soul, body = scratch dir
//   maw soul convert <idea> --repo=o/r     idea -> repo: same channel (renamed 📦・o∕r), same threads, wt bodies
//   maw soul promote <thread> [<oracle>...] a talk thread -> repo (origin/thread.md) + room 📦・o∕r + souls; archive it
//   maw soul wt      <name> [repo]         worktree <repo>/wt/<name> + link (default bot laris-labs-oracle)
//   maw soul wt-close <name> [repo]        unlink it, archive the thread, keep the worktree
//   maw soul link    <wt-path>             a manual worktree joins an existing bot body by forward (no second gateway)
//   maw soul unlink  <wt-path>             archive its thread, drop the forward row (--whole-channel: + its deny rows)
//   maw soul ears    <oracle> [repo] [ls]  threads the body hears; add|rm <thread> [--all]: plan, --yes writes
//                                          (herdr-soul ears --go, which runs bin/soul-ears on the body's own access.json)
//   --deny-main / --chname=dash on in / migrate: passed to soul-in-repo.sh (layout 9: channel per repo,
//   thread per oracle)
//
// in / out / migrate write access rows. Without --yes they only print the plan (--dry), so an agent
// that runs them by mistake changes nothing. Run them with --yes only on Nat's go from a terminal.
import { spawnSync } from "node:child_process";
import { existsSync, realpathSync } from "node:fs";
import { dirname, join } from "node:path";

type InvokeContext = { source: "cli" | string; args: string[] };
type PluginResult = { ok: boolean; output?: string; error?: string };

const HELP = `maw soul — an oracle's soul at work inside another repo (front for bin/herdr-soul)

  maw soul list                         oracles that can come in (soul, token, machine, where they are)
  maw soul ls        [repo]             souls of a repo: thread, pane, gateway ready?
  maw soul check     <oracle> [repo]    preflight only; prints the fix for each failed item
  maw soul in        <oracle> [repo]    plan; add --yes to bring the soul in
  maw soul out       <oracle> [repo]    plan; add --yes to take it out
  maw soul migrate   <oracle> [repo]    plan; add --yes to move a live body to its own thread in <owner>∕<repo>
  maw soul room      <repo> <oracle>... plan for many souls at once (migrate a live body, else in; always --deny-main);
                                        --channel=<id> reuses an existing room; add --yes to run
  maw soul idea      <idea> <oracle>... plan; IDEA MODE before a repo exists: channel 💡・<idea>, a thread per soul
                                        (its own bot), body <soul>/ψ/lab/<idea> (--dir=<base>), Laris row mode idea
  maw soul convert   <idea> --repo=<owner/repo> [--public]   plan; the idea becomes a repo (private by default):
                                        channel renamed 📦・<owner>∕<repo>, each soul rebuilt in <repo>/wt on the SAME thread
  maw soul promote   <thread> [<oracle>...]   plan; a talk thread becomes a repo with its own room:
                                        name from the thread (--name=<repo>), repo <owner>/<name> (--owner=, default
                                        nat-build-with-oracle; private unless --public; reused if it exists),
                                        origin/thread.md + messages.jsonl committed (secret scan first), channel
                                        📦・<owner>∕<name> + Laris row, each <oracle> in with its own thread, then
                                        '📦 moved to' in the thread and it is archived. Last line: RESULT repo= room=
                                        Existing repo first: without --name, a repo on this machine with a close
                                        name stops the plan (exit 3, MATCH lines): confirm with --owner= --name=,
                                        or --new for a new repo
  maw soul wt        <name> [repo]      plan; worktree <repo>/wt/<name> (branch wt/<name>, reused if there), then link:
                                        thread <name> in the repo's layout-9 channel (--channel=<id>), forward row,
                                        claude beside the bot body. --bot=<oracle> (default laris-labs-oracle).
                                        Last line on success: RESULT thread=<id> pane=<pane> wt=<path>
                                        --thread=<id>: use that EXISTING thread of the repo channel (no new post)
  maw soul wt-close  <name> [repo]      plan; unlink it and archive the thread, the worktree stays
  maw soul link      <wt-path>          plan; a manual worktree joins an existing bot body by forward (no second gateway):
                                        thread opened by the bot, forward row in its access, claude in the wt beside it.
                                        --bot=<oracle> (default somsri-oracle) --channel=<id> --name=<thread> --pane=<id>
                                        --whole-channel=<id>: forward the whole channel, no thread; its threads without
                                        a row get {deny: true, linkedBy: <wt>} (listed in the plan)
  maw soul unlink    <wt-path>          plan; archive the thread, drop the forward row + its deny rows (backup).
                                        --bot=<oracle> --whole-channel=<id>
  maw soul ears      <oracle> [repo]    threads the body hears: own thread, office (joined), old rows
  maw soul ears      <oracle> [repo] add|rm <thread> [--all]
                                        plan; add --yes to write the body's access.json (backup first;
                                        rm keeps the entry under "removed"). --all = every line, else tag only

  [repo]  owner/name, an absolute path, or empty = the git repo of this folder
  --deny-main  with in / migrate: also keep the oracle's main body out of the repo channel
  --channel=<id>  with in / migrate: use this channel (default: find it by name, icon prefix allowed)
  --chname=dash  with in / migrate: channel <owner>-<repo> instead of <owner>∕<repo> (U+2215)
  --dry   plan only (the default for in/out/migrate)
  --yes   run it. These write access rows: only on Nat's go from a terminal.
  HERDR_SOUL_BIN=<path>  use another herdr-soul (default: ../../bin/herdr-soul beside this plugin)`;

const WRITES = new Set(["in", "out", "migrate", "room", "link", "unlink", "idea", "convert", "wt", "wt-close", "promote"]);
const READS = new Set(["list", "ls", "check"]);

const oracleName = (o: string) => (o.endsWith("-oracle") ? o : `${o}-oracle`);

// herdr-soul argv for a maw soul call, or an error. Pure, so it is tested without running anything.
export function plan(args: string[]): { argv: string[]; dry: boolean } | { error: string } {
  const yes = args.includes("--yes");
  const dryAsked = args.includes("--dry");
  const denyMain = args.includes("--deny-main");
  const chname = args.find(a => a.startsWith("--chname="));
  const pin = args.find(a => a.startsWith("--channel="));
  const all = args.includes("--all");
  const owner = args.find(a => a.startsWith("--owner="));
  const fresh = args.includes("--new");
  if (pin && !/^--channel=\d{15,22}$/.test(pin)) return { error: `${pin}: use --channel=<channel id>` };
  if (chname && !["--chname=slash", "--chname=dash"].includes(chname)) return { error: `${chname}: use --chname=slash or --chname=dash` };
  const linkOpts = args.filter(a => /^--(bot|name|pane|whole-channel|thread)=/.test(a));
  const ideaOpts = args.filter(a => /^--(dir|repo)=/.test(a) || a === "--public" || a === "--private");
  const rest = args.filter(a => a !== "--yes" && a !== "--dry" && a !== "--deny-main" && a !== "--all" && a !== chname && a !== pin && !linkOpts.includes(a) && !ideaOpts.includes(a) && a !== owner && a !== "--new");
  const verb = rest[0] ?? "ls";
  const pos = rest.slice(1);
  const unknown = pos.find(a => a.startsWith("--"));
  if (unknown) return { error: `unknown flag ${unknown}\n  maw soul help` };
  if (all && verb !== "ears") return { error: "--all goes with ears add, not " + verb };
  if ((owner || fresh) && verb !== "promote") return { error: "--owner and --new go with promote, not " + verb };
  if (verb === "promote") {
    const th = pos[0];
    if (!th || !/^\d{15,22}$/.test(th)) return { error: "which thread?\n  maw soul promote <thread id> [<oracle>...] [--owner=<owner>] [--name=<repo>] [--public] [--yes]" };
    if (denyMain || chname || pin) return { error: "--deny-main, --chname and --channel do not go with promote (the room is found or made by name)" };
    if (linkOpts.some(a => !a.startsWith("--name=")) || ideaOpts.some(a => /^--(dir|repo)=/.test(a))) return { error: "promote takes --owner=<owner>, --name=<repo>, --public or --private" };
    const nm = linkOpts.find(a => a.startsWith("--name="));
    if (nm && !/^--name=[A-Za-z0-9._-]{1,100}$/.test(nm)) return { error: `${nm}: a repo name is letters, digits, '.', '_' and '-'` };
    if (owner && !/^--owner=[A-Za-z0-9][A-Za-z0-9-]{0,38}$/.test(owner)) return { error: `${owner}: use --owner=<github owner>` };
    const d = !yes || dryAsked;
    return { argv: ["promote", th, ...pos.slice(1).map(oracleName), ...(owner ? [owner] : []), ...(nm ? [nm] : []), ...ideaOpts, ...(fresh ? ["--new"] : []), ...(d ? ["--dry"] : ["--yes"])], dry: d };
  }
  if (verb === "ears") return earsPlan(pos, yes && !dryAsked, all, !!(denyMain || chname || pin || linkOpts.length));
  if (READS.has(verb)) {
    if (verb === "check" && !pos[0]) return { error: "which oracle?\n  maw soul check <oracle> [repo]" };
    if (verb === "check") return { argv: ["check", oracleName(pos[0]!), ...pos.slice(1)], dry: false };
    return { argv: [verb, ...pos], dry: false };
  }
  if (!WRITES.has(verb)) return { error: `unknown verb ${verb}\n  maw soul help` };
  if (verb === "wt" || verb === "wt-close") {
    const name = pos[0];
    if (!name || !/^[A-Za-z0-9][A-Za-z0-9._-]*$/.test(name)) return { error: `which name?\n  maw soul ${verb} <name> [repo]` };
    if (pos.length > 2) return { error: `maw soul ${verb} <name> [repo]: one repo at most` };
    if (denyMain || chname || ideaOpts.length) return { error: `--deny-main, --chname, --dir, --repo do not go with ${verb}` };
    if (linkOpts.some(a => !/^--(bot|pane|thread)=/.test(a)) || (verb === "wt-close" && (pin || linkOpts.some(a => /^--(pane|thread)=/.test(a))))) return { error: `${verb} takes --bot=<oracle>${verb === "wt" ? ", --pane=<id>, --channel=<id> and --thread=<id>" : ""}` };
    const th = linkOpts.find(a => a.startsWith("--thread="));
    if (th && !/^--thread=\d{15,22}$/.test(th)) return { error: `${th}: use --thread=<thread id>` };
    const d = !yes || dryAsked;
    return { argv: [verb, name, ...pos.slice(1), ...linkOpts, ...(pin ? [pin] : []), ...(d ? ["--dry"] : ["--yes"])], dry: d };
  }
  if (linkOpts.length && verb !== "link" && verb !== "unlink") return { error: "--bot, --name and --pane go with link / unlink" };
  if (ideaOpts.length && verb !== "idea" && verb !== "convert") return { error: "--dir, --repo, --public and --private go with idea / convert" };
  if (verb === "idea" || verb === "convert") {
    const name = pos[0];
    if (!name || !/^[a-z0-9][a-z0-9-]*$/.test(name)) return { error: `idea name: lowercase letters, digits and '-'\n  maw soul ${verb} <idea> ${verb === "idea" ? "<oracle>..." : "--repo=<owner/repo>"}` };
    if (denyMain || chname) return { error: `--deny-main and --chname do not go with ${verb}` };
    const d = !yes || dryAsked;
    if (verb === "idea") {
      if (pos.length < 2) return { error: "which oracles?\n  maw soul idea <idea> <oracle>..." };
      if (ideaOpts.some(a => !a.startsWith("--dir="))) return { error: "idea takes --dir=<base> and --channel=<id>; --repo goes with convert" };
      return { argv: ["idea", name, ...pos.slice(1).map(oracleName), ...ideaOpts, ...(pin ? [pin] : []), ...(d ? ["--dry"] : ["--yes"])], dry: d };
    }
    const repo = ideaOpts.find(a => a.startsWith("--repo="));
    if (!repo || !/^--repo=[\w.-]+\/[\w.-]+$/.test(repo)) return { error: "convert needs --repo=<owner>/<repo>" };
    if (pos.length > 1) return { error: "convert takes the souls from the idea's Laris row, not from the command line" };
    return { argv: ["convert", name, ...ideaOpts, ...(pin ? [pin] : []), ...(d ? ["--dry"] : ["--yes"])], dry: d };
  }
  if (verb === "link" || verb === "unlink") {
    if (!pos[0]) return { error: `which worktree?\n  maw soul ${verb} <wt-path> [--bot=<oracle>] [--yes]` };
    if (denyMain || chname) return { error: `--deny-main and --chname do not go with ${verb}` };
    const thr = linkOpts.find(a => a.startsWith("--thread="));
    if (thr && !/^--thread=\d{15,22}$/.test(thr)) return { error: `${thr}: use --thread=<thread id>` };
    if (thr && linkOpts.some(a => a.startsWith("--whole-channel="))) return { error: "--whole-channel and --thread: pick one" };
    if (verb === "unlink" && (pin || linkOpts.some(a => !/^--(bot|whole-channel)=/.test(a)))) return { error: "unlink takes only --bot=<oracle> and --whole-channel=<id>" };
    const whole = linkOpts.find(a => a.startsWith("--whole-channel="));
    if (whole && !/^--whole-channel=\d{15,22}$/.test(whole)) return { error: `${whole}: use --whole-channel=<channel id>` };
    if (whole && pin) return { error: "--whole-channel and --channel: pick one" };
    const d = !yes || dryAsked;
    return { argv: [verb, pos[0]!, ...linkOpts, ...(pin ? [pin] : []), d ? "--dry" : "--yes"], dry: d };
  }
  if (verb === "room") {
    if (pos.length < 2) return { error: "which repo and oracles?\n  maw soul room <repo> <oracle>... [--channel=<id>] [--yes]" };
    if (denyMain || chname) return { error: "room always passes --deny-main; --chname is for in / migrate" };
    const dryRoom = !yes || dryAsked;
    return { argv: ["room", pos[0]!, ...pos.slice(1).map(oracleName), ...(pin ? [pin] : []), dryRoom ? "--dry" : "--yes"], dry: dryRoom };
  }
  if (!pos[0]) return { error: `which oracle?\n  maw soul ${verb} <oracle> [repo]` };
  const oracle = oracleName(pos[0]);
  const repo = pos.slice(1);
  const dry = !yes || dryAsked;
  if (verb === "out" && (denyMain || chname || pin)) return { error: "--deny-main, --chname and --channel go with in or migrate, not out" };
  if (verb === "out") return { argv: ["out", oracle, ...repo, ...(dry ? [] : ["--go"])], dry };
  const pass = [...(verb === "migrate" ? ["--migrate"] : []), ...(denyMain ? ["--deny-main"] : []), ...(chname ? [chname] : []), ...(pin ? [pin] : [])];
  return { argv: ["in", oracle, ...repo, ...pass, ...(dry ? ["--dry"] : [])], dry };
}

// ears <oracle> [repo] [ls | add <thread> | rm <thread>]
function earsPlan(pos: string[], yes: boolean, all: boolean, otherFlag: boolean): { argv: string[]; dry: boolean } | { error: string } {
  if (otherFlag) return { error: "--deny-main, --chname, --channel and link options do not go with ears" };
  if (!pos[0]) return { error: "which oracle?\n  maw soul ears <oracle> [repo] [add|rm <thread>]" };
  const oracle = oracleName(pos[0]);
  const subAt = pos.findIndex((a, i) => i > 0 && ["ls", "add", "rm"].includes(a));
  const repo = pos.slice(1, subAt < 0 ? undefined : subAt);
  if (repo.length > 1) return { error: `too many words: ${repo.join(" ")}\n  maw soul ears ${pos[0]} [repo] [add|rm <thread>]` };
  const sub = subAt < 0 ? "ls" : pos[subAt]!;
  if (sub === "ls") {
    if (all || yes) return { error: "--all and --yes go with ears add|rm" };
    return { argv: ["ears", oracle, ...repo], dry: false };
  }
  const thread = pos[subAt + 1];
  if (!thread || !/^\d{15,22}$/.test(thread)) return { error: `which thread?\n  maw soul ears ${pos[0]} ${[...repo, sub].join(" ")} <thread id>` };
  if (pos.length > subAt + 2) return { error: `too many words after ${thread}` };
  if (all && sub === "rm") return { error: "--all goes with ears add, not rm" };
  return { argv: ["ears", oracle, ...repo, sub, thread, ...(all ? ["--all"] : []), ...(yes ? ["--go"] : [])], dry: !yes };
}

export function herdrSoul(): string {
  if (process.env.HERDR_SOUL_BIN) return process.env.HERDR_SOUL_BIN;
  const here = dirname(realpathSync(import.meta.path));
  return join(here, "..", "..", "bin", "herdr-soul");
}

export async function handler(ctx: InvokeContext): Promise<PluginResult> {
  const args = ctx.args ?? [];
  if (["help", "-h", "--help"].includes(args[0] ?? "")) return { ok: true, output: HELP };
  const p = plan(args);
  if ("error" in p) return { ok: false, error: p.error };
  const bin = herdrSoul();
  if (!existsSync(bin)) return { ok: false, error: `herdr-soul not found at ${bin}\n  HERDR_SOUL_BIN=/opt/Code/github.com/laris-co/soul-in-repo/bin/herdr-soul maw soul ${args.join(" ")}` };
  // stdio inherited: the human sees soul-in-repo.sh's steps live, and its prompts still work
  const r = spawnSync("zsh", [bin, ...p.argv], { stdio: "inherit" });
  if (r.error) return { ok: false, error: `cannot run zsh: ${r.error.message}` };
  const verb = p.argv[0];
  const tail = p.dry && (WRITES.has(args.find(a => !a.startsWith("--")) ?? "") || p.argv[0] === "ears")
    ? `\nplan only. To run it (Nat's go, from a terminal):\n  maw soul ${args.filter(a => a !== "--dry").join(" ")} --yes`
    : "";
  return r.status === 0 ? { ok: true, output: tail.trim() || undefined } : { ok: false, error: `herdr-soul ${verb} exited ${r.status}` };
}

export default handler;

if (import.meta.main) {
  const result = await handler({ source: "cli", args: process.argv.slice(2) });
  if (result.output) console.log(result.output);
  if (result.error) console.error(result.error);
  process.exit(result.ok ? 0 : 1);
}
