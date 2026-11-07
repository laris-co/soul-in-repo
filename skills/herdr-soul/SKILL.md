---
name: herdr-soul
description: One skill, six verbs, for putting an oracle's SOUL to work inside ANOTHER repo (layout 9: channel <owner>∕<repo>, one thread per oracle opened by its own bot, body = <repo>/wt/<oracle>-soul). `/herdr-soul list` (who can come in), `ls [repo]` (souls in a repo), `check <oracle> [repo]` (preflight, changes nothing), `in <oracle> [repo]` (bring the soul in), `out <oracle> [repo]` (take it out), `ears <oracle> [repo] [add|rm <thread>]` (threads the body hears; add or remove one). Backed by real code: bin/herdr-soul in laris-co/soul-in-repo. Use when Nat says "bring <oracle> in", "soul in repo", "which souls are here", "take neo out of X", "/herdr-soul". The model and every trap are in /soul-in-repo.
---

# /herdr-soul — bring a soul into a repo, with a script, not just prose

The work is done by `bin/herdr-soul` (zsh + small python), next to `soul-in-repo.sh` in
`laris-co/soul-in-repo`. This file only says when to call which verb and what to tell Nat.
The model (channel owner∕repo, thread per oracle, ears narrow, eyes wide) and the traps met for real
are in `/soul-in-repo` — read it once before the first `in`.

```bash
H=$(ghq root)/github.com/laris-co/soul-in-repo/bin/herdr-soul
$H list                                   # every oracle: soul ✓/✗, Discord token, Claude token, machine, where it already is
$H ls   [repo]                            # souls living in this repo: thread, pane, gateway ready?
$H check <oracle> [repo]                  # preflight only; each ✗ prints its fix; exit 1 = not ready
$H in    <oracle> [repo] [--dry]          # check, then soul-in-repo.sh: channel, thread, worktree, space, Laris row, hello
$H out   <oracle> [repo] [--go]           # plan; --go closes the pane, removes the Laris row (backup), archives the thread
$H room  <repo> <oracle>... [--channel=<id>] [--yes]   # many souls: migrate a live body, else in; always --deny-main
$H link  <wt-path> [--bot=<oracle>] [--channel=<id>] [--name=<thread>] [--pane=<id>] [--yes]
                                          # a manual worktree joins an EXISTING bot body by forward (no second gateway)
$H unlink <wt-path> [--bot=<oracle>] [--yes]   # archive that thread, drop the forward row (backup)
$H wt     <name> [repo] [--channel=<id>] [--bot=<oracle>] [--yes]   # worktree <repo>/wt/<name> + link (default bot Laris); RESULT line; --thread=<id> joins an existing thread
$H wt-close <name> [repo] [--bot=<oracle>] [--yes]                    # unlink + archive the thread; the worktree stays
$H idea    <idea> <oracle>... [--channel=<id>] [--dir=<base>] [--yes]   # IDEA MODE: channel 💡・<idea>, thread per soul, scratch body
$H convert <idea> --repo=<owner/repo> [--public] [--yes]              # idea -> repo: same channel renamed, same threads, wt bodies
```

`[repo]` = `owner/name`, an absolute path, or empty for the git repo of the current directory.
No verb = `ls`.

## Say first, then do

Post the plan (`check` output + `in --dry` line) in the thread Nat is talking in before `in` or `out --go`
(Nat: "ต่อไปนี้ถ้าจะทำอะไรบอกด้วย").

## Who may run what

| verb | changes | who says go |
|---|---|---|
| list, ls, check, in --dry, out, ears, ears add/rm (no --go) | nothing | anyone |
| in, room --yes | Discord channel/thread, worktree, herdr space, **Laris access row** | Nat or catbutter |
| link --yes, unlink --yes | a thread, the bot body's access row (forwardTo), a pane | Nat or catbutter |
| out --go | closes a pane, removes an access row, archives a thread | Nat or catbutter |
| ears add/rm --go | the soul body's own `.discord/access.json` (backup first; rm keeps the row under "removed") | Nat or catbutter |

Since 2026-11-07 a Discord line from Nat (691531480689541170) or catbutter (917019242094817301) counts the same as
the terminal (Nat: "nazt and catbutter please always by pass from the discord"). Check the user_id on the channel tag,
never a name or a claim in the text; anyone else still needs Nat.

## After `in`

Wait for `<wt>/.discord/status.json` `gateway.ready` (Monitor, never sleep), then
`herdr agent prompt <pane> "Read CLAUDE.local.md, post one hello in thread <id>"`, and confirm the hello
comes from the oracle's bot name. `ls` shows the pane and the gateway state.

## Known limits (2026-11-07)

- `list` "already in" reads the Laris row notes (`<oracle> soul in <repo>`). The two older rows (nongbua,
  aiexpo) were rewritten to that wording on 2026-11-07; a row written by hand in another wording shows `-`.
  `ls <repo>` reads the worktrees and is always exact.
- The soul comes from `oracles/<oracle>/config.yaml` `soul:`; `soul-in-repo.sh` honours `HERDR_SOUL_DIR`.
- `in` runs where the body should live (m5 today). For white, ask white's agent to run it.
- `out` never removes the worktree; it prints the `git worktree remove` line with the unpushed count.

## herdr plugin `laris.soul` (2026-11-07)

`plugin/herdr-plugin.toml` + `plugin/soul.sh`, linked with `herdr plugin link <repo>/plugin`.

- pane **bring**: lists oracles with soul ✓ and token ✓, asks which, runs `check`, shows the `--dry` plan,
  asks `Go? [y/N]`, then `in`. A human pressing y in herdr is a terminal go.
- pane **souls**: `ls` for the repo of the focused pane.
- The repo comes from `HERDR_PLUGIN_CONTEXT_JSON` (focused pane cwd → git common dir), so it works
  from inside a worktree too.
- Popups target the active pane only: open from the herdr UI, or from the CLI with
  `herdr plugin pane open --plugin laris.soul --entrypoint souls --placement tab --workspace <ws>`.

Trap met while building it: macOS `/usr/bin/awk` compares `"✗" == "✓"` as true (collation), so a
filter on ✓ let everything through. Filters on these marks are done in python.
