# soul-in-repo

Put an oracle's **soul** to work inside **another repo**, in that repo's Discord thread.

```
#repo                 one channel for every repo
  └─ <owner>/<repo>   thread = the repo, shared by every soul of it
body: <repo>/wt/<oracle>-soul   (branch soul/<oracle>)
ears: that thread only, answer only when tagged     eyes: every room the bot can see
```

- `SKILL.md`: the Claude Code skill (model, run steps, traps met for real, undo)
- `soul-in-repo.sh`: the script the skill runs

The script finds or creates #repo and the `<owner>/<repo>` thread (reused and unarchived if it exists), then the worktree, `.discord/access.json`,
`.discord/launch.sh`, its own herdr space and the Laris host row, then posts a hello.
Tokens come from `pass` at launch and never touch this repo.

Layout since 2026-11-07 (Nat): #repo › `<owner>/<repo>`. Bodies built before it still live in the old
channel = oracle threads: #neo-oracle › nongbua-oracle, oracle-gods-eys-os, esp32-line-beacon, soul-in-repo (m5) ·
#pulse-oracle › soul-in-repo (m5) · #calliope-oracle › aiexpo-oracle (white) · #digger-oracle › theognosis (white).
They stay as they are until each is rebuilt; old threads get archived, never deleted.

Install as a skill:

```bash
git clone git@github.com:laris-co/soul-in-repo.git ~/.claude/skills/soul-in-repo
```

Built 2026-11-05/06 by Laris Labs Oracle (AI) with Nat in #research › repo-soul.

## /herdr-soul — one skill, five verbs (2026-11-07)

```bash
bin/herdr-soul list | ls [repo] | check <oracle> [repo] | in <oracle> [repo] [--dry] | out <oracle> [repo] [--go]
```

Skill: `skills/herdr-soul/SKILL.md` (install: `ln -s <this repo>/skills/herdr-soul ~/.claude/skills/herdr-soul`).
`in` calls `check`, then `soul-in-repo.sh`. `in` and `out --go` touch the Laris access file: terminal go only.
`in` also passes `--migrate` and `--deny-main` through to `soul-in-repo.sh` (with `--migrate` it skips `check`, since the body is already in).

## maw soul — the same verbs from any folder (2026-11-07)

```bash
maw soul list | ls [repo] | check <oracle> [repo]
maw soul in <oracle> [repo] [--deny-main] [--yes]
maw soul migrate <oracle> [repo] [--deny-main] [--yes]
maw soul out <oracle> [repo] [--yes]
```

A thin maw plugin in `maw-plugin/`: every verb runs `bin/herdr-soul`, nothing is copied. The herdr plugin `laris.soul`
(`plugin/`) calls the same script, so all three fronts stay the same.

- `in`, `migrate` and `out` print the plan (`--dry`) unless `--yes` is given. They write access rows, so `--yes` is for
  Nat's go from a terminal only. The plan ends with the exact `--yes` line to run.
- `neo` means `neo-oracle`.
- Install: `ln -s <this repo>/maw-plugin ~/.maw/plugins/soul` (then `maw soul help`). Tests: `cd maw-plugin && bun test`.
