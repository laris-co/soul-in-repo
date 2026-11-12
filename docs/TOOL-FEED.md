# Tool feed — let the room see what a soul is doing

Every soul in a repo talks through the Discord plugin (`Soul-Brews-Studio/claude-discord-channel`). Since plugin
version `0.0.4-sbs.3` that plugin also ships a **tool feed**: while a soul works on a Discord request, its tool
calls appear in the same thread, a few lines at a time, then a done line.

```
🔧 Bash: Install and register self-hosted runner on odoo20
🔧 Write: odoo20-stack/ops.sh
🔧 Bash: Trigger ops verify via workflow_dispatch and read log
✅ 3 tools · 0m 41s
```

Nothing to install in soul-in-repo: a soul gets the feed from the plugin it already runs.

## How it works

| hook (Claude Code) | `tool-feed.sh` | what happens |
|---|---|---|
| `UserPromptSubmit` | `start` | reads `chat_id` from the `<channel source="plugin:discord:discord" chat_id="…">` tag; a turn typed in the terminal has no tag → no feed |
| `PreToolUse` | `tool` | one line `🔧 <tool>: <what>`; secrets masked; lines within 1.5 s go out as **one new message** |
| `Stop` | `stop` | `✅ N tools · Xm Ys` |

- `<what>`: Bash → its `description` (else the command) · Read/Write/Edit → last two path parts · MCP → first argument.
  `react` and `edit_message` are not shown.
- Masked before leaving the machine: `Bearer …`, `Bot …`, `apiv3_…`, `key/token/secret/pass…=value`, `curl -u user:pass`,
  `-P password` (`tests/tool-feed-mask.test.sh` in the plugin repo).
- New messages, never edits — the same choice as the NSM 🔧 hook, so a long job reads like a log.

## Configure

| env | default | meaning |
|---|---|---|
| `DISCORD_TOOL_FEED` | `1` | `0` turns the feed off for that body |
| `DISCORD_TOOL_FEED_BATCH` | `1.5` | seconds of tool calls per message |
| `DISCORD_TOOL_FEED_THINK` | `0` | `1` adds `💭 think (Ns)` and `💬 <first words>` lines from the transcript |
| `DISCORD_BOT_TOKEN` | from `<state dir>/.env` | same rule as the plugin's `server.ts`: real env wins |

State lives in `<state dir>/tool-feed/` (`DISCORD_STATE_DIR`, default `~/.claude/channels/discord`). Needs `jq` and `curl`;
works without `flock` (macOS).

## Traps met on 2026-11-12

- **Two copies post twice.** floodboy-oracle and DustBoy-Oracle had their own `.claude/hooks/tool-feed.sh` in
  `settings.local.json`. With the plugin version installed, drop the local copy or set `DISCORD_TOOL_FEED=0`.
- **A repo-level hook lives in the working tree.** Switching branches turned floodboy's local feed off until it was
  merged — another reason the plugin is the right home.
- **`bash -n` does not check jq inside the script.** A quoting slip inside an embedded jq program broke the think lines
  once; run the real path after every edit.
- **Hook text is shown, not just run.** Never echo a token into a Bash `description`; the mask is a safety net, not a
  licence.
- **Find the reference first.** The format took 11 commits because the original (NSM's 🔧 hook) was found only at the
  end, by relic5 *semantic* search after five keyword searches missed it.

## History

| date | step |
|---|---|
| 2026-03-09 | Feed Logger: `feed-log.sh` hook writes every event to `~/.oracle/feed.log` (local only) |
| 2026-03-22 | maw server tails `feed.log`: `time · oracle · host · PostToolUse · project · session » Bash ✓` |
| 2026-03-23 | maw-js: hooks `POST /api/feed` → WebSocket instead of file polling |
| 2026-10-09 | xiaoer-oracle's 🔧 hook for the NSM team posts `🔧 <tool>: <detail>` to Discord for Discord turns |
| 2026-11-12 | floodboy-oracle `tool-feed.sh` (PR #73), then moved into the plugin (claude-discord-channel PR #6) |
