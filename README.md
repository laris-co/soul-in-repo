# soul-in-repo

Put an oracle's **soul** to work inside **another repo**, in that repo's Discord thread.

## Install

```
maw plugin install laris-co/soul-in-repo
maw soul --help
```

Update: `maw plugin update soul`

## Quick start

Needs on the machine: herdr, `pass` (bot and claude tokens), `gh`, zsh, python3. Run from any folder; `[repo]` is
`owner/name`, an absolute path, or empty for the git repo of the current folder.

```
maw soul list                              # oracles that can come in: soul, token, machine, where they are
maw soul ls laris-co/soul-in-repo          # souls of a repo: thread, pane, gateway ready?
maw soul check neo laris-co/soul-in-repo   # preflight only; prints the fix for each failed item
maw soul in neo laris-co/soul-in-repo      # the plan; add --yes to bring the soul in (Nat's go)
maw soul doctor                            # read-only health check of every access row
```

```bash
maw soul list | ls [repo] | check <oracle> [repo]
maw soul in <oracle> [repo] [--deny-main] [--chname=dash] [--yes]
maw soul migrate <oracle> [repo] [--deny-main] [--chname=dash] [--yes]
maw soul out <oracle> [repo] [--yes]
maw soul ears <oracle> [repo] [add|rm <thread>] [--all] [--yes]
maw soul threads [repo]                     # which soul hears which thread (Discord GETs only)
maw soul doctor  [repo] [--online] [-j]     # read-only: dead forward/deny rows, rooms missing a repo or soul body
maw soul icon <oracle> [repo] [--off] [--yes] # own thread renamed '<icon>・<oracle>' by the soul's own bot
```

`maw soul --help` lists every verb (room, promote, work, archive, wt, wt-close, link, unlink) with its flags.
`neo` means `neo-oracle`.

## Configuration

Defaults fit m5 and white; the variables are for other hosts and for tests.

| variable | default | what |
|---|---|---|
| `HERDR_SOUL_BIN` | `bin/herdr-soul` beside the plugin | the script every verb runs |
| `HERDR_SESSION` | set by herdr in each pane, else `laris-co` | herdr session; a repo's `team.yaml` `session:` wins when that session is running (`bin/team-session`) |
| `HERDR_SOUL_TEAM` | `/opt/Code/github.com/laris-co/laris-team` | laris-team checkout (oracle configs, `discord-say.sh`) |
| `SOUL_HOST` | `laris-labs-oracle` | the server's host bot |
| `SOUL_HOST_STATE` | `SOUL_HOST` | the host's state dir name under `~/.claude/channels/` |
| `HERDR_SOUL_LARIS` | `~/.claude/channels/<host state>/access.local.json` | the host's access file |
| `HERDR_SOUL_CHANNELS` | `~/.claude/channels` | where bot state dirs live |
| `HERDR_SOUL_SOMSRI` | `<ghq>/github.com/laris-co/somsri-oracle/.discord/access.json` | Somsri center's access file |
| `HERDR_SOUL_MACHINE` | short hostname | this machine's name in `config.yaml` `machine:` |

Tokens are read from `pass` at launch (`discord/<oracle>-token`, `claude/token-<name>`) and never written to a file.

## Safety

- `in`, `migrate`, `out`, `room`, `link`, `unlink`, `wt`, `wt-close`, `promote`, `archive` and `work` print the plan
  unless `--yes` is given. They write access rows, so `--yes` is for Nat's go only. The plan ends with the exact
  `--yes` line to run.
- Each body edits only its own access file. Every file a script rewrites gets a `.bak-<ts>` beside it.
- Nothing is deleted: threads are archived, a room goes to 🗄️ Archive, worktrees stay until their work is pushed.

## Notes

### Layout 9

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

### The rooms ladder: from a talk to real work and back (Nat 2026-11-09, "yes go make all!")


```
1 talk     !!name @Bot …        a brainstorm thread, wherever you type it (#portal too); tagged bots join.
                                no repo, no worktree
2 promote  /promote             the talk becomes a repo + its 📦 room + the souls you pick   (herdr-soul promote)
3 work     /work · /wt          real work in a repo room: a worktree + its thread             (herdr-soul work · wt)
4 done     /done                stop: bodies 💤 sleep where they run, room to 🗄️ Archive; nothing is deleted.
                                /work wakes them on the same machine, same conversation       (herdr-soul archive)
```

The idea mode that came before (`herdr-soul idea` / `convert`, `soul-idea.sh`) is retired: steps 1 and 2 replaced it.
Its script is kept in [`attic/soul-idea/`](attic/soul-idea/README.md).

### /herdr-soul: the same verbs as a Claude Code skill (2026-11-07)


```bash
bin/herdr-soul list | ls [repo] | check <oracle> [repo] | in <oracle> [repo] [--dry] | out <oracle> [repo] [--go]
bin/herdr-soul doctor [repo] [--online] [-j]   # read-only health check of every access row; exit 1 on findings
bin/herdr-soul ears <oracle> [repo] [ls | add <thread> [--all] | rm <thread>] [--go]
```

Skill: `skills/herdr-soul/SKILL.md` (install: `ln -s <this repo>/skills/herdr-soul ~/.claude/skills/herdr-soul`).
`in` calls `check`, then `soul-in-repo.sh`. `in` and `out --go` touch the Laris access file: terminal go only.
`ls` lists every room row of each soul, layout-9 thread first (#9). `ears <oracle>` shows the same body's threads
with joined.json too (office is "every line (joined)" when it joined on a tag), old #repo rows last. `ears add|rm` is a plan unless `--go`; it runs
`bin/soul-ears` (Somsri Oracle's tool, copied unchanged) on that body's own access.json, backup `.bak-<ts>-ears` first.

`in` also passes `--migrate`, `--deny-main` and `--chname=dash` through to `soul-in-repo.sh` (with `--migrate` it skips `check`, since the body is already in).

A thin maw plugin in `maw-plugin/`: every verb runs `bin/herdr-soul`, nothing is copied. The herdr plugin `laris.soul`
(`plugin/`) calls the same script, so all three fronts stay the same. `plugin.json` at the repo root is the one
`maw plugin install` reads (it clones the whole repo, so the plugin finds `bin/herdr-soul` beside it);
`maw-plugin/plugin.json` is kept for older links to `maw-plugin/`.

Built 2026-11-05/06 by Laris Labs Oracle (AI) with Nat in #research › repo-soul.

## Development

```bash
git clone git@github.com:laris-co/soul-in-repo.git && cd soul-in-repo
ln -s "$PWD" ~/.maw/plugins/soul                 # maw soul from this checkout (older links to maw-plugin/ still work)
ln -s "$PWD" ~/.claude/skills/soul-in-repo       # the /soul-in-repo skill (SKILL.md)
ln -s "$PWD/skills/herdr-soul" ~/.claude/skills/herdr-soul
cd maw-plugin && bun test && cd ..               # plugin tests
for t in test/*.zsh; do zsh $t || echo "FAIL $t"; done   # offline script tests (stub herdr, no Discord)
```
