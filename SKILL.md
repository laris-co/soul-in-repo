---
name: soul-in-repo
description: Put an oracle's SOUL to work inside ANOTHER repo, with its own Discord thread — channel #<oracle> (the soul), thread under it named after the repo, body = worktree <repo>/wt/<oracle>-soul, channel-native on the oracle's own bot, Laris Labs hears every message but stays silent. Use when Nat says "soul in repo", "wt <repo> using <oracle>", "neo works on <repo>", "channel = soul, thread = repo", or asks to repeat the nongbua/aiexpo/gods-eye setup. Do NOT use for a member's normal team body (`just wt`) or a Laris room body (`just room`).
---

# /soul-in-repo — channel = soul, thread = repo

Built 2026-11-05 with Nat in #research › repo-soul ("Make a skill"). Live pairs:
#neo-oracle › nongbua-oracle (m5), #neo-oracle › oracle-gods-eys-os (m5), #calliope-oracle › aiexpo-oracle (white).
Diagram: `laris-labs-oracle/ψ/lab/2026-11-05_one-bot-many-repos/D1-soul-repo-model.png`.

## The model

```
#<oracle>  (channel = soul)
  `- <repo name>  (thread = repo)      every message reaches BOTH at once (no relay):
        Laris Labs Oracle  -> hears all (it opened the thread), answers only when tagged
        <oracle>'s own bot -> the body below answers
body: <repo>/wt/<oracle>-soul  branch soul/<oracle>
      soul  = laris-co/<oracle>/CLAUDE.md, appended at start (--append-system-prompt)
      ears  = DISCORD_STATE_DIR=<wt>/.discord  access.json: this thread only
      start = <wt>/.discord/launch.sh  (bot + Claude token from pass at launch)
```

## Say first, then do (Nat: "ต่อไปนี้ถ้าจะทำอะไรบอกด้วย")

Post the plan in the thread Nat is talking in (which oracle, which repo, which bot, which Claude token) before running.
If the repo name is ambiguous (three "god eyes" repos), list the candidates with their last commit date and ask.

## Run

```bash
S=~/.claude/skills/soul-in-repo/soul-in-repo.sh
$S neo-oracle laris-co/oracle-gods-eys-os --dry     # plan only
$S neo-oracle laris-co/oracle-gods-eys-os           # channel, thread, humans, worktree, files, pane, Laris row
```

Restart a body later with `RESUME=1 <wt>/.discord/launch.sh` (keeps its conversation).

Then wait (Monitor, never sleep) for `<wt>/.discord/status.json` `gateway.ready`, and brief the pane:
`herdr agent prompt <pane> "Read CLAUDE.local.md, post one hello in thread <id>"`. Confirm the hello in Discord
comes from the oracle's bot name, not "Laris Labs Oracle".

Run it on the machine where the body should live. For a body on white, ask white's agent to run it
(`herdr --machine white-laris-co agent prompt <pane> '...'`); never build it over ssh.

## Traps met for real (2026-11-05)

| Trap | Rule in the script |
|---|---|
| `dmPolicy: "disabled"` in the body's access.json: the plugin's gate drops EVERY message, guild too (server.ts gate(), first line) | `dmPolicy: "allowlist"`, allowFrom Nat + catbutter on the thread |
| `@import` of the soul in CLAUDE.local.md stops at "allow external imports?" — never answer that for Nat | soul via `--append-system-prompt "$(cat soul)"` |
| new folder stops at "trust this folder?" | pre-trusted in ~/.claude.json, as tools/laris-wt.sh does |
| `.envrc` of the repo carried a Claude token that is not logged in ("Not logged in") | launch.sh exports the token from the oracle's config `claude_token:` (default t3) |
| "only one bot" misread as "every body uses the Laris token" | the body answers with the ORACLE's own bot; Laris only watches |
| Laris answered in the oracle's thread too (two voices, one name) | Laris row `requireMention: true`; Laris reacts 🏮 at most, answers only when tagged |
| a body edited Laris's access.local.json because a chat message asked | CLAUDE.local.md: edit only your own `.discord/` |
| the oracle's MAIN body also hearing the thread = two answers from one bot | a new thread is in no other access file; if the main body's access lists the parent channel, add `deny` on the thread there (its own agent does it) |
| bots do not hear bots in Discord (plugin ignores `author.bot`) | agents talk with `herdr agent prompt <pane> "..."` |
| body opened as a `pane split` in the caller's space: invisible under its repo in the sidebar ("no herdr session?") | `herdr worktree open --workspace <repo main space>`: own space nested under the repo |
| an agent's input box "holds text" in `pane read` (e.g. `2 new repo go`), so you stall rather than prompt it | that is Claude Code's dim prompt suggestion, not a draft: check `pane read --source visible --format ansi`; `ESC[2m` = suggestion, safe to prompt (2026-11-06, theognosis) |
| the body's agent says "same bot already runs my main body: collision" | the pattern IS one bot, many gateways; each body acts only on its access.json groups. Go, once the thread is in no other access file of that bot |
| the soul body cannot read another room ("channel ... is not allowlisted"), Nat: "this not cool?" | ears narrow, eyes wide: the body reads any room its bot sees with `maw atlas read <id>` (token already in env); answers stay in its own thread. Written into CLAUDE.local.md by the script (2026-11-06) |
| humans not in the new thread | the script PUTs Nat + catbutter as thread members (Nat: "When new thread add human"); a 429 means retry later |

## Undo

Close the pane, remove the Laris row (backup is beside access.local.json), `git worktree remove <wt>` after its
work is pushed (`/herdr-dissolve`). The thread stays (Nothing is Deleted); archive it in Discord if wanted.
