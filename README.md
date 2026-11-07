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
