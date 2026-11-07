# soul-in-repo

Put an oracle's **soul** to work inside **another repo**, in that repo's Discord thread.

```
<owner>∕<repo>        one channel per repo (U+2215; --chname dash: <owner>-<repo>)
  ├─ neo-oracle       one thread per oracle, opened by its own bot (soul threads only)
  └─ pulse-oracle     Somsri (soul center, #somsri) reads with eyes, answers when tagged
body: <repo>/wt/<oracle>-soul   (branch soul/<oracle>)
ears: its own thread, every line     eyes: every room the bot can see     Laris: tags only
```

- `SKILL.md`: the Claude Code skill (model, run steps, traps met for real, undo)
- `soul-in-repo.sh`: the script the skill runs

The script finds or creates the `<owner>∕<repo>` channel (never a second one), the soul's bot finds or opens its `<oracle>` thread (reused and unarchived if it exists), then the worktree, `.discord/access.json`,
`.discord/launch.sh`, its own herdr space and the Laris host row, then posts a hello.
Tokens come from `pass` at launch and never touch this repo.

Layout 9 since 2026-11-07 06:34Z (Nat): channel `<owner>∕<repo>` › thread `<oracle>`. Before it: #repo › `<owner>/<repo>`
(soul-in-repo's Neo and Pulse; move with `--migrate`). Before that, channel = oracle threads: #neo-oracle › nongbua-oracle, oracle-gods-eys-os, esp32-line-beacon, soul-in-repo (m5) ·
#pulse-oracle › soul-in-repo (m5) · #calliope-oracle › aiexpo-oracle (white) · #digger-oracle › theognosis (white).
They stay as they are until each is rebuilt; old threads get archived, never deleted.

Install as a skill:

```bash
git clone git@github.com:laris-co/soul-in-repo.git ~/.claude/skills/soul-in-repo
```

Built 2026-11-05/06 by Laris Labs Oracle (AI) with Nat in #research › repo-soul.

## /herdr-soul — one skill, six verbs (2026-11-07)

```bash
bin/herdr-soul list | ls [repo] | check <oracle> [repo] | in <oracle> [repo] [--dry] | out <oracle> [repo] [--go]
bin/herdr-soul ears <oracle> [repo] [ls | add <thread> [--all] | rm <thread>] [--go]
```

Skill: `skills/herdr-soul/SKILL.md` (install: `ln -s <this repo>/skills/herdr-soul ~/.claude/skills/herdr-soul`).
`in` calls `check`, then `soul-in-repo.sh`. `in` and `out --go` touch the Laris access file: terminal go only.
`ls` and `ears` show every thread a body hears (access.json + joined.json): its own layout-9 thread first, office
("every line (joined)" when it joined on a tag), old #repo rows last. `ears add|rm` is a plan unless `--go`; it runs
`bin/soul-ears` (Somsri Oracle's tool, copied unchanged) on that body's own access.json, backup `.bak-<ts>-ears` first.

`in` also passes `--migrate`, `--deny-main` and `--chname=dash` through to `soul-in-repo.sh` (with `--migrate` it skips `check`, since the body is already in).

## maw soul — the same verbs from any folder (2026-11-07)

```bash
maw soul list | ls [repo] | check <oracle> [repo]
maw soul in <oracle> [repo] [--deny-main] [--chname=dash] [--yes]
maw soul migrate <oracle> [repo] [--deny-main] [--chname=dash] [--yes]
maw soul out <oracle> [repo] [--yes]
maw soul ears <oracle> [repo] [add|rm <thread>] [--all] [--yes]
```

A thin maw plugin in `maw-plugin/`: every verb runs `bin/herdr-soul`, nothing is copied. The herdr plugin `laris.soul`
(`plugin/`) calls the same script, so all three fronts stay the same.

- `in`, `migrate`, `out` and `ears add|rm` print the plan (`--dry`) unless `--yes` is given. They write access rows, so `--yes` is for
  Nat's go from a terminal only. The plan ends with the exact `--yes` line to run.
- `neo` means `neo-oracle`.
- Install: `ln -s <this repo>/maw-plugin ~/.maw/plugins/soul` (then `maw soul help`). Tests: `cd maw-plugin && bun test`.
