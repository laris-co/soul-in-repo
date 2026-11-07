---
name: soul-link
description: Link a worktree with no bot of its own (a manual herdr wt, any checkout) to an existing bot body by FORWARD, so it hears and answers one Discord thread or channel without a second gateway. Uses `maw soul link/unlink` (soul-in-repo #12, #13) or the manual 3 steps. Use when Nat says "link this wt to Discord", "connect claude channel bot with somsri", "make this worktree talk in a thread", "soul link", or after creating a herdr worktree he wants in Discord. Do NOT use for a soul with its own bot token (use `maw soul in` / `maw soul room`).
---

# /soul-link — a worktree speaks through an existing bot

> One bot = one gateway. The bot body hears the room and types each line into the worktree's pane;
> the worktree answers send-only with that bot's token. Proven 2026-11-07: green-forest answered Nat in 4 s.

```
Discord thread/channel ──► bot body gateway (e.g. Somsri wG7)
                              │ access row: forwardTo=<wt path>, answerCmd=BOT=<bot> discord-say.sh
                              ▼
                         herdr agent prompt <pane whose cwd = wt>
                              │ "[discord #room · user · chat_id · message_id · answer: <cmd>] text"
                              ▼
                         claude in the wt ──► BOT=<bot> tools/discord-say.sh <chat_id> "<text>"
```

## 0. Before

- Discord go from Nat (691531480689541170) or catbutter (917019242094817301) by user_id, or a terminal go.
- Say the plan first: which wt, which bot, thread or whole channel, the thread name.
- If Nat says "compare", keep the old room AND add the new one. Never unlink on "compare".

## 1. With the CLI (soul-in-repo ≥ #12; `--whole-channel` needs #13)

```bash
# thread (default): bot opens <name> in the channel, adds the row, starts claude in a split
maw soul link <wt> --channel=<channel id> --name=<thread name> [--bot=somsri-oracle] [--pane=<p>]   # plan
maw soul link <wt> --channel=<channel id> --name=<thread name> --yes                              # do it

# whole channel: row on the channel, deny rows for every thread already in it (linkedBy=<wt>)
maw soul link <wt> --whole-channel=<channel id> --yes

maw soul unlink <wt> --yes        # archives the thread, drops the row (backup first)
```

- Without `--channel` it uses the repo's layout-9 channel from Laris's rows; it stops if there is none.
- It refuses a wt that is already linked ("unlink first") and a channel that already has a row.

## 2. By hand (when the CLI is missing or Nat wants it now)

```bash
SAY=/opt/Code/github.com/laris-co/laris-team/tools/discord-say.sh
BOT=somsri-oracle $SAY <channel id> "<name>: manual worktree, answers here through Somsri's bot"   # prints message id
BOT=somsri-oracle $SAY --thread <channel id> <message id> "<name>"                             # thread id = message id
```

Back up the bot's access file (`somsri-oracle/.discord/access.json`, or `~/.claude/channels/<bot>/access.local.json`), then add:

```json
"<thread id>": {"requireMention": false,
  "forwardTo": "<wt abs path>",
  "answerCmd": "BOT=somsri-oracle /opt/Code/github.com/laris-co/laris-team/tools/discord-say.sh",
  "allowFrom": ["691531480689541170", "917019242094817301"]}
```

Put a git-ignored `CLAUDE.local.md` in the wt (room id, "answer every forwarded line once with its answerCmd",
"never --channels, never a token"), then start claude in the wt's pane:

```bash
herdr pane run <pane> 'env -u DISCORD_BOT_TOKEN -u DISCORD_STATE_DIR claude --dangerously-skip-permissions "Read CLAUDE.local.md, post one hello in <thread id>, then wait for forwarded lines."'
```

The plugin re-reads access on every message: no restart.

## 3. Prove it

- Nat (or catbutter) types one untagged line in the room. The bot's own lines and Laris's never trigger a forward.
- `herdr pane read <pane> --source recent-unwrapped --lines 30 | rg 'discord #'` shows the forwarded line.
- `fetch_messages <room>` shows the answer under the bot's name.

## ⚠️ traps met for real (2026-11-07)

| trap | avoid |
|---|---|
| "go and compare" read as "move": thread unlinked, Nat's lines went nowhere for 4 min | compare = both rooms forward; unlink only on an explicit "move"/"stop" |
| an agent picked the channel name and created it with Laris's token | ask the name; channel creation belongs to Laris |
| a thread with no row falls back to its parent: a whole-channel row pulls every soul thread along | `--whole-channel` writes deny rows; prefer a dedicated channel |
| herdr worktrees live in `~/.herdr/worktrees/<repo>/…`, not `wt/` | forwardTo matches by cwd, any path works; `maw soul` soul verbs still want `wt/<oracle>-soul` |
| testing with your own message | forward fires only on allowFrom humans; ask Nat for one line |
| a line typed in the old room after a move is lost | tell Nat in the old room where the new one is |

— Laris Labs Oracle 🏮
