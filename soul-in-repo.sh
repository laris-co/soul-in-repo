#!/usr/bin/env zsh
# soul-in-repo.sh <oracle> <repo> [--category <id>] [--dry]
#   <oracle>  e.g. neo-oracle  (soul = $(ghq root)/github.com/laris-co/<oracle>, bot = pass discord/<oracle>-token)
#   <repo>    owner/name (in ghq) or an absolute path
# One guild, many repos (Nat 2026-11-05): channel = the oracle (soul), thread under it = the repo.
# Builds: #<oracle> channel (if missing) -> thread <repo name> -> worktree <repo>/wt/<oracle>-soul ->
# .discord/{access.json,launch.sh} -> own herdr space under the repo (worktree open) -> Laris host row (hears, silent) -> hello.
# Runs on the machine of the Laris host bot (m5 today). Tokens only from pass, never printed.
set -euo pipefail
oracle=${1:?oracle}; repo=${2:?repo}; shift 2
CAT=1560847801838215259   # 🔬・research category
DRY=0
while (( $# )); do case $1 in --category) CAT=$2; shift 2;; --dry) DRY=1; shift;; *) echo "unknown $1"; exit 2;; esac; done
GUILD=1560847800881643520
NAT=691531480689541170; CB=917019242094817301
TEAM=/opt/Code/github.com/laris-co/laris-team
SAY=$TEAM/tools/discord-say.sh
ghq=$(ghq root)
soul=$ghq/github.com/laris-co/$oracle
[[ -f $soul/CLAUDE.md ]] || { echo "no soul: $soul/CLAUDE.md"; exit 1; }
[[ $repo = /* ]] && R=$repo || R=$ghq/github.com/$repo
[[ -d $R/.git || -f $R/.git ]] || { echo "not a repo: $R"; exit 1; }
name=${R:t}; W=$R/wt/$oracle-soul
cfg=$TEAM/oracles/$oracle/config.yaml
ctok=$(sed -n 's/^claude_token: *\([^ #]*\).*/\1/p' $cfg 2>/dev/null | head -1); ctok=${ctok:-t3}
pass show discord/$oracle-token >/dev/null || { echo "no pass discord/$oracle-token"; exit 1; }
pass show claude/token-$ctok >/dev/null || { echo "no pass claude/token-$ctok"; exit 1; }
git -C $R check-ignore -q wt/ || { echo "wt/ is not ignored in $R: add it to .gitignore first"; exit 1; }
echo "plan: #$oracle > thread $name · worktree $W (branch soul/$oracle) · bot $oracle · claude $ctok"
(( DRY )) && exit 0

T=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
api() { curl -sS -H "Authorization: Bot $T" -H 'Content-Type: application/json' "$@"; }
# 1. channel #<oracle> under the category (find or create)
CH=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c "import json,sys
print(next((c['id'] for c in json.load(sys.stdin) if c.get('name')=='$oracle' and c.get('type')==0),''))")
[[ -n $CH ]] || CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
  -d "{\"name\":\"$oracle\",\"type\":0,\"parent_id\":\"$CAT\",\"topic\":\"$oracle soul works in other repos: one thread per repo\"}" \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
# 2. thread named after the repo, opened by the Laris bot (so Laris hears it: own thread)
M=$(api -X POST https://discord.com/api/v10/channels/$CH/messages -d "{\"content\":\"🧵 **$name** — $oracle soul ทำงานใน repo $name\"}" \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
TH=$($SAY --thread $CH $M "$name" | rg -o '[0-9]{17,}')
# 2b. add the humans to the thread (Nat 2026-11-05: "When new thread add human")
for u in $NAT $CB; do api -o /dev/null -w "add human $u %{http_code}\n" -X PUT https://discord.com/api/v10/channels/$TH/thread-members/$u; done
# 3. worktree + soul note
git -C $R fetch -q origin main 2>/dev/null || true
[[ -d $W ]] || git -C $R worktree add -q -b soul/$oracle $W origin/main 2>/dev/null || git -C $R worktree add -q $W soul/$oracle
mkdir -p $W/.discord
cat > $W/.discord/access.json <<J
{ "dmPolicy": "allowlist", "allowFrom": [], "pending": {},
  "groups": { "$TH": { "requireMention": false, "allowFrom": ["$NAT", "$CB"] } },
  "guilds": { "$GUILD": { "requireMention": true, "allowFrom": ["eyes-only"],
    "note": "auto read allowlist: fetch any room in the guild; allowFrom matches no one, so nothing outside the thread is heard" } } }
J
cat > $W/CLAUDE.local.md <<MD
# $oracle soul in $name (written by /soul-in-repo, channel = soul, thread = repo)

You are **$oracle**, working inside the repo **$name** (worktree $W, branch soul/$oracle).
Your soul ($soul/CLAUDE.md) is appended at start. The repo's own CLAUDE.md is the project you work on.

- Discord: channel-native on YOUR OWN bot. Ears = .discord/access.json: thread $name ($TH) only.
- Answer with the Discord reply tool; sign as yourself. Laris Labs Oracle hears this thread and stays silent.
- Ears narrow, eyes wide: answer only in thread $TH, but read any room your bot can see with
  fetch_messages (access.json has a guild-wide eyes-only row: every room readable, none heard).
- Edit only your own .discord/ files. Never edit another bot's access file.
- Talk to other agents with \`herdr agent prompt <pane> "..."\` (bots do not hear bots in Discord).
MD
ex=$(git -C $W rev-parse --git-common-dir)/info/exclude
for l in .discord/ CLAUDE.local.md; do grep -qxF $l $ex 2>/dev/null || echo $l >> $ex; done
cat > $W/.discord/launch.sh <<L
#!/bin/zsh
cd '$W'
export DISCORD_STATE_DIR='$W/.discord'
export DISCORD_BOT_TOKEN="\$(pass show discord/$oracle-token | head -1)"
export CLAUDE_CODE_OAUTH_TOKEN="\$(pass show claude/token-$ctok | head -1)"
export CLAUDE_TOKEN_NAME=$ctok
exec claude --dangerously-skip-permissions --channels=plugin:discord@claude-plugins-official \${RESUME:+--continue} --append-system-prompt "\$(cat '$soul/CLAUDE.md')"
L
chmod +x $W/.discord/launch.sh
# 4. pre-trust the new folder (same as tools/laris-wt.sh)
python3 - $W <<'PY'
import json, os, sys
f = os.path.expanduser("~/.claude.json"); d = json.load(open(f))
d.setdefault("projects", {}).setdefault(sys.argv[1], {}).update(hasTrustDialogAccepted=True)
tmp = f + ".soul-in-repo"; json.dump(d, open(tmp, "w"), indent=2); os.replace(tmp, f)
PY
# 5. its OWN space nested under the repo (herdr worktree open), never a split in the caller's space:
#    a split hides the body under the caller's repo in the sidebar (Nat 2026-11-05: "no herdr session? how come?")
S=${HERDR_SESSION:-laris-co}
wsof() { herdr --session $S worktree list --cwd "$R" | python3 -c 'import sys,json
try: print(json.load(sys.stdin)["result"]["source"].get("source_workspace_id") or "")
except Exception: print("")'; }
MWS=$(wsof); [[ -n $MWS ]] || { herdr --session $S workspace create --cwd "$R" --label "$name" --no-focus >/dev/null; MWS=$(wsof); }
P=$(herdr --session $S worktree open --workspace "$MWS" --path "$W" --label "wt/$oracle-soul" --no-focus \
  | python3 -c 'import sys,re; print(re.search(r"\"pane_id\": ?\"([^\"]+)\"", sys.stdin.read()).group(1))')
herdr --session $S pane run $P "$W/.discord/launch.sh" >/dev/null
# 6. Laris host row: hears (own thread), answers only when tagged
L=$HOME/.claude/channels/laris-labs-oracle/access.local.json
cp $L $L.bak-$(date +%Y%m%d-%H%M%S)-soul-$name
python3 - $L $TH "$oracle" "$name" <<'PY'
import json, sys
f, th, o, n = sys.argv[1:]; a = json.load(open(f))
a.setdefault("groups", {})[th] = {"requireMention": True, "allowFrom": ["691531480689541170", "917019242094817301"],
  "note": f"{o} soul in {n} answers with its own bot; Laris hears (own thread), silent unless tagged"}
json.dump(a, open(f, "w"), indent=2)
PY
echo "done: #$oracle ($CH) > $name ($TH) · $W · pane $P"
echo "next: wait for $W/.discord/status.json gateway.ready, then: herdr agent prompt $P 'Read CLAUDE.local.md, post one hello in thread $TH'"
