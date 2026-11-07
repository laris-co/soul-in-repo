---
name: soul-in-repo
description: Put an oracle's SOUL to work inside ANOTHER repo, with a Discord thread — layout 9 (2026-11-07): ONE channel per repo named <owner>∕<repo>, ONE thread per oracle named <oracle>, opened by that oracle's own bot (hears every line there), body = worktree <repo>/wt/<oracle>-soul, Laris Labs keeps one row per repo channel and answers only when tagged; Somsri (soul center, #somsri) reads repo channels with eyes and answers only when tagged. Use when Nat says "soul in repo", "wt <repo> using <oracle>", "neo works on <repo>", "channel = soul, thread = repo", or asks to repeat the nongbua/aiexpo/gods-eye setup ("channel = soul" was the 2026-11-05 layout; #repo › owner/repo the morning of 2026-11-07; layout 9 since 06:34Z). Do NOT use for a member's normal team body (`just wt`) or a Laris room body (`just room`).
---

# /soul-in-repo — channel = <owner>∕<repo>, thread = <oracle> (layout 9)

Built 2026-11-05 with Nat in #research › repo-soul ("Make a skill"). Layouts so far:
1. 2026-11-05: `#<oracle> › <repo>` (channel = soul).
2. 2026-11-07 morning: `#repo › <owner>/<repo>`, every soul of a repo in one thread, answering only when tagged.
3. 2026-11-07 06:34Z, **layout 9** (Nat, via Laris): ONE channel per repo named `<owner>∕<repo>` (U+2215 DIVISION SLASH,
   Laris's pick; `--chname dash` gives `<owner>-<repo>`), ONE thread per oracle named `<oracle>`, opened by THAT oracle's
   own bot. Own thread: the soul hears every line untagged. Laris no longer owns the threads, so it never types there.
Bodies in older layouts stay as they are until migrated (`--migrate`); old threads are archived later, never deleted.
Diagram: `laris-labs-oracle/ψ/lab/2026-11-05_one-bot-many-repos/D1-soul-repo-model.png`.

## The model

```
<owner>∕<repo>  (channel = the repo; found by name, created once under one category, never a second one)
  |- neo-oracle      (thread opened by the Neo bot: Neo hears every line, requireMention false)
  `- pulse-oracle    (thread opened by the Pulse bot)
        repo channels hold ONLY soul threads. Somsri (soul center, home laris-co/somsri-oracle, room #somsri) is not
        a soul here: she reads with eyes and answers only when tagged (her own access file, not this script)
        Laris Labs Oracle: one row on the CHANNEL, requireMention true -> hears tags only, never types
        Laris row: {"layout": 9, "channel", "repo", "souls": [...], "threads": {oracle: thread}}
body: <repo>/wt/<oracle>-soul  branch soul/<oracle>
      soul  = <oracle>/CLAUDE.md, appended at start (--append-system-prompt)
      ears  = DISCORD_STATE_DIR=<body>/.discord  access.json: its own thread, requireMention false
      note  = CLAUDE.local.md in the worktree (never in a repo's main checkout: Claude Code reads it from parent
              folders, so every soul in wt/ would take it as its own)
      name  = DISCORD_ORACLE=<oracle>  (state dir is .discord, so the plugin cannot guess the oracle from it)
      start = <wt>/.discord/launch.sh  (bot + Claude token from pass at launch)
```

## Say first, then do (Nat: "ต่อไปนี้ถ้าจะทำอะไรบอกด้วย")

Post the plan in the thread Nat is talking in (which oracle, which repo, which bot, which Claude token) before running.
If the repo name is ambiguous (three "god eyes" repos), list the candidates with their last commit date and ask.

## Run

```bash
S=~/.claude/skills/soul-in-repo/soul-in-repo.sh
$S neo-oracle laris-co/oracle-gods-eys-os --dry     # plan only
$S neo-oracle laris-co/oracle-gods-eys-os           # channel owner∕repo, thread neo-oracle, humans, worktree, files, pane, Laris row
```

Restart a body later with `RESUME=1 <wt>/.discord/launch.sh` (keeps its conversation).

Move a LIVE body (any older layout) to its layout-9 thread: `$S <oracle> <owner>/<repo> --migrate --dry`, then
without `--dry`. It rewrites access.json, launch.sh and the soul note (backups
`.bak-<ts>-migrate`) and the Laris rows: the channel row gains the soul; the old thread row is kept, the soul leaves its
`souls[]`, and once none is left the row gets note "moved to layout 9" and requireMention true. It never opens a pane or
starts claude: re-running the plain script on a live body starts a second claude on the same bot token (rival gateway).
`--deny-main` (only after Nat's go) also writes `{ deny: true, earsOff: true }` for the repo channel into the oracle's MAIN body
`~/.claude/channels/<oracle>/access.local.json`, so a main body sharing the bot never hears or joins the soul threads
(Pulse's main body on white, w47:p1, joined #repo › laris-co/soul-in-repo that way, 2026-11-07). If the main body
lives on another machine (config.yaml `machine:`), the script prints the `herdr --machine` prompt for that box's agent.
`earsOff` is what makes it hold: the plugin checks `earsOff` on the room and on a thread's parent BEFORE the roll call
and the joined-thread pass; a plain `deny` is only seen later in findGroupPolicy, so a joined main body or a role roll
call still got through. Side effect: a trusted `!ears on` in the repo channel would lift it (it lifts only denies marked earsOff).

Restart steps (the live claude still runs the old files until it restarts):

1. Post a short "restarting, back in a minute" note in the thread (tags sent during the gap are lost: the gateway
   is down, 2026-11-07 Nat's two tags at 04:18:46/52 never arrived).
2. `/exit` the live claude: `herdr agent prompt <pane> "/exit"`.
3. WAIT for the fresh shell prompt, never sleep:
   `herdr pane wait-output <pane> --regex 'took [0-9]+[hms]' --source visible --lines 2 --timeout 30000`.
   After `/exit` the zsh prompt prints `... took 33m2s` then `❯` (seen live 2026-11-07, wG5/wG6). Only the bottom
   2 lines: while claude runs they are its status bar, after exit they are the new prompt. With `--lines 6` a STALE
   `took` line from an earlier restart still on screen matched at once, and the relaunch was typed into claude's
   exit and lost (twice). On timeout: STOP, read the pane (`herdr pane read <pane> --source visible --lines 20`),
   send nothing.
4. `herdr pane run <pane> 'RESUME=1 <wt>/.discord/launch.sh'` (the line the script prints).
   Check it took: `herdr pane wait-output <pane> --regex 'bypass permissions' --source visible --lines 3 --timeout 60000`
   (claude's status bar is back). On timeout: read the pane, do not type again.
5. Wait for `<wt>/.discord/status.json` `gateway.ready`, then `fetch_messages` the thread for anything sent in the gap.

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
| body's status.json said `oracle: laris-labs-oracle`: the plugin's myOracle() takes the name from the state dir basename, and `.discord` is not `<x>-oracle`, so it fell back to the host | launch.sh exports `DISCORD_ORACLE=<oracle>`; the plugin reads it once the laris-team server.ts PR lands. Existing bodies get it only when their launch.sh is rewritten and they restart with `RESUME=1` |
| "only one bot" misread as "every body uses the Laris token" | the body answers with the ORACLE's own bot; Laris only watches |
| Laris answered in the oracle's thread too (two voices, one name) | Laris row `requireMention: true`; Laris reacts 🏮 at most, answers only when tagged |
| one repo spread over many channels (#neo-oracle › soul-in-repo AND #pulse-oracle › soul-in-repo), souls never in one room (2026-11-07) | layout 9: ONE channel per repo, one thread per oracle in it; Laris row on the channel lists `souls` + `threads` |
| #repo layout: three bodies in one thread all hearing every line = duplicate answers ("make cli maw cli?" got the same plan twice, 2026-11-07) | layout 9: each soul answers in its own thread only; the shared room is the channel |
| same repo name in two orgs | channel name is always `<owner>∕<repo>` (from `origin`, else the ghq path); a channel name cannot hold `/`, so U+2215 stands in (untested until Nat's go; `--chname dash` if Discord refuses it) |
| a body edited Laris's access.local.json because a chat message asked | CLAUDE.local.md: edit only your own `.discord/` |
| the oracle's MAIN body also hearing the thread = two answers from one bot | a new thread is in no other access file; if the main body's access lists the parent channel, add `deny` on the thread there (its own agent does it) |
| bots do not hear bots in Discord (plugin ignores `author.bot`) | agents talk with `herdr agent prompt <pane> "..."` |
| body opened as a `pane split` in the caller's space: invisible under its repo in the sidebar ("no herdr session?") | `herdr worktree open --workspace <repo main space>`: own space nested under the repo |
| an agent's input box "holds text" in `pane read` (e.g. `2 new repo go`), so you stall rather than prompt it | that is Claude Code's dim prompt suggestion, not a draft: check `pane read --source visible --format ansi`; `ESC[2m` = suggestion, safe to prompt (2026-11-06, theognosis) |
| the body's agent says "same bot already runs my main body: collision" | the pattern IS one bot, many gateways; each body acts only on its access.json groups. Go, once the thread is in no other access file of that bot |
| the soul body cannot read another room ("channel ... is not allowlisted"), Nat: "this not cool?" | ears narrow, eyes wide: the body reads any room its bot sees with `maw atlas read <id>` (token already in env); answers stay in its own thread. Written into CLAUDE.local.md by the script (2026-11-06) |
| humans not in the new thread | the script PUTs Nat + catbutter as thread members (Nat: "When new thread add human"); a 429 means retry later |

## Since 2026-11-07

- `/herdr-soul` (verbs list / ls / check / in / out, `bin/herdr-soul`) wraps this script; the herdr plugin
  `laris.soul` wraps `/herdr-soul`. This file stays the reference for the model and the traps.
- Every live soul body has the guild eyes-only row (5 older bodies added 2026-11-07, backups `.bak-20261107-eyes`;
  white bodies did it themselves via herdr --machine).

## Undo

Close the pane, remove the Laris row (backup is beside access.local.json), `git worktree remove <wt>` after its
work is pushed (`/herdr-dissolve`). The thread stays (Nothing is Deleted); archive it in Discord if wanted.
