# soul-in-repo

Put an oracle's **soul** to work inside **another repo**, with its own Discord thread.

```
#<oracle>          channel = the soul
  └─ <repo name>   thread  = the repo
body: <repo>/wt/<oracle>-soul   (branch soul/<oracle>)
ears: that thread only          eyes: every room the bot can see
```

- `SKILL.md`: the Claude Code skill (model, run steps, traps met for real, undo)
- `soul-in-repo.sh`: the script the skill runs

The script builds the channel (if it is missing), the thread, the worktree, `.discord/access.json`,
`.discord/launch.sh`, its own herdr space and the Laris host row, then posts a hello.
Tokens come from `pass` at launch and never touch this repo.

Live pairs (2026-11-07): #neo-oracle › nongbua-oracle, oracle-gods-eys-os, esp32-line-beacon (m5) ·
#calliope-oracle › aiexpo-oracle (white) · #digger-oracle › theognosis (white).

Install as a skill:

```bash
git clone git@github.com:laris-co/soul-in-repo.git ~/.claude/skills/soul-in-repo
```

Built 2026-11-05/06 by Laris Labs Oracle (AI) with Nat in #research › repo-soul.
