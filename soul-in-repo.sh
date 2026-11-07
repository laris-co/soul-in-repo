#!/usr/bin/env zsh
# soul-in-repo.sh <oracle> <repo> [--category <id>] [--migrate] [--deny-main] [--dry]
#   --migrate  move a LIVE body to #repo › <owner>/<repo>: rewrite its access.json, CLAUDE.local.md, launch.sh
#              (backups beside them) and the Laris rows; NO worktree, trust, pane or launch (a second claude on
#              the same bot token = rival gateway). Prints the restart line for the existing pane.
#   --deny-main  (pending Nat's go) also write { deny: true, earsOff: true } for the #repo channel into the oracle's MAIN body
#              access.local.json, so a main body sharing the bot never hears or joins #repo threads (Pulse's main
#              body on white joined #repo › laris-co/soul-in-repo, 2026-11-07). Local machine: written here (backup);
#              main body on another machine: prints the herdr --machine prompt for that box's agent, never ssh.
#   <oracle>  e.g. neo-oracle  (soul = $(ghq root)/github.com/laris-co/<oracle>, bot = pass discord/<oracle>-token)
#   <repo>    owner/name (in ghq) or an absolute path
# One guild, many repos (Nat 2026-11-07, was channel = oracle since 2026-11-05): ONE channel #repo,
# one thread per repo named <owner>/<repo>. Every soul of that repo shares the thread and answers only when tagged.
# Builds: #repo (if missing) -> thread <owner>/<repo> (reused + unarchived if it exists) -> humans ->
# worktree <repo>/wt/<oracle>-soul -> .discord/{access.json,launch.sh} -> own herdr space under the repo
# (worktree open) -> Laris host row (hears, silent unless tagged) -> hello.
# Runs on the machine of the Laris host bot (m5 today). Tokens only from pass, never printed.
set -euo pipefail
oracle=${1:?oracle}; repo=${2:?repo}; shift 2
CAT=1560847801838215259   # 🔬・research category
DRY=0; MIG=0; DENYMAIN=0
while (( $# )); do case $1 in --category) CAT=$2; shift 2;; --dry) DRY=1; shift;; --migrate) MIG=1; shift;; --deny-main) DENYMAIN=1; shift;; *) echo "unknown $1"; exit 2;; esac; done
GUILD=1560847800881643520
NAT=691531480689541170; CB=917019242094817301
TEAM=/opt/Code/github.com/laris-co/laris-team
SAY=$TEAM/tools/discord-say.sh
ghq=$(ghq root)
soul=${HERDR_SOUL_DIR:-$ghq/github.com/laris-co/$oracle}
[[ -f $soul/CLAUDE.md ]] || { echo "no soul: $soul/CLAUDE.md"; exit 1; }
[[ $repo = /* ]] && R=$repo || R=$ghq/github.com/$repo
[[ -d $R/.git || -f $R/.git ]] || { echo "not a repo: $R"; exit 1; }
name=${R:t}; W=$R/wt/$oracle-soul
# <owner>/<repo> from origin (github ssh or https), else from the ghq path
full=$(git -C $R remote get-url origin 2>/dev/null | sed -E 's#^(git@[^:]+:|[a-z+]+://[^/]+/)##; s#\.git$##')
[[ $full = */* ]] || full=${R#$ghq/github.com/}
[[ $full = */* ]] || { echo "cannot tell <owner>/<repo> for $R (no origin, not under ghq)"; exit 1; }
CHN=repo
cfg=$TEAM/oracles/$oracle/config.yaml
ctok=$(sed -n 's/^claude_token: *\([^ #]*\).*/\1/p' $cfg 2>/dev/null | head -1); ctok=${ctok:-t3}
pass show discord/$oracle-token >/dev/null || { echo "no pass discord/$oracle-token"; exit 1; }
pass show claude/token-$ctok >/dev/null || { echo "no pass claude/token-$ctok"; exit 1; }
git -C $R check-ignore -q wt/ || { echo "wt/ is not ignored in $R: add it to .gitignore first"; exit 1; }
echo "plan: #$CHN > thread $full (find or create; reuse + unarchive if it exists; humans Nat + catbutter)"
echo "      worktree $W (branch soul/$oracle) · bot $oracle · claude $ctok · DISCORD_ORACLE=$oracle"
echo "      ears: that thread, requireMention true (shared by every soul of $full) · eyes: guild read-only"
echo "      Laris row: that thread, requireMention true (silent unless tagged)"
S=${HERDR_SESSION:-laris-co}
if (( MIG )); then
  [[ -f $W/.discord/access.json ]] || { echo "migrate: no live body at $W (no .discord/access.json)"; echo "  build it instead: $0 $oracle $repo"; exit 1; }
  OLD=$(python3 -c 'import json,sys;print(next(iter(json.load(open(sys.argv[1])).get("groups",{})),""))' $W/.discord/access.json)
  # the pane that runs this body now (herdr pane list, matched on cwd)
  P=$(herdr --session $S pane list 2>/dev/null | python3 -c 'import json,sys
w=sys.argv[1]
try: print(next((p["pane_id"] for p in json.load(sys.stdin)["result"]["panes"] if (p.get("foreground_cwd") or p.get("cwd"))==w),""))
except Exception: print("")' $W)
  echo "migrate: old thread ${OLD:-none} -> #$CHN › $full · live pane ${P:-not found}"
  echo "      rewrite (backup .bak-<ts>-migrate beside each): $W/.discord/access.json, $W/.discord/launch.sh, $W/CLAUDE.local.md"
  echo "      Laris: add/merge new thread row; old thread row ${OLD:-none} kept, note 'moved to #repo', requireMention true"
  echo "      skip: worktree, trust, herdr pane, launch, hello"
fi
MACH=$(sed -n 's/^machine: *\([^ #]*\).*/\1/p' $cfg 2>/dev/null | head -1); HOST=$(hostname -s)
ML=$HOME/.claude/channels/$oracle/access.local.json
if (( DENYMAIN )); then
  if [[ -z $MACH || $MACH = $HOST ]]; then echo "      deny-main: groups[#$CHN id] deny+earsOff in $ML (main body here on $HOST; backup first)"
  else echo "      deny-main: main body lives on $MACH: print the herdr --machine prompt for its agent (no ssh edit)"; fi
fi
(( DRY )) && { echo "dry: nothing touched"; exit 0; }

T=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
api() { curl -sS -H "Authorization: Bot $T" -H 'Content-Type: application/json' "$@"; }
# 1. channel #repo under the category (find or create)
CH=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c "import json,sys
print(next((c['id'] for c in json.load(sys.stdin) if c.get('name')=='$CHN' and c.get('type')==0),''))")
[[ -n $CH ]] || CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
  -d "{\"name\":\"$CHN\",\"type\":0,\"parent_id\":\"$CAT\",\"topic\":\"one thread per repo (<owner>/<repo>); souls answer only when tagged\"}" \
  | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
# 2. thread <owner>/<repo>: reuse it if it exists (active or archived), else the Laris bot opens it (own thread: Laris hears)
findth() { python3 -c 'import json,sys
d=json.load(sys.stdin); ch,n=sys.argv[1:]
print(next((t["id"] for t in d.get("threads",[]) if t.get("parent_id")==ch and t.get("name")==n),""))' $CH "$full"; }
TH=$(api https://discord.com/api/v10/guilds/$GUILD/threads/active | findth)
before=""
while [[ -z $TH ]]; do
  page=$(api "https://discord.com/api/v10/channels/$CH/threads/archived/public?limit=100${before:+&before=$before}")
  TH=$(print -r -- $page | findth)
  [[ -n $TH ]] && break
  before=$(print -r -- $page | python3 -c 'import json,sys
d=json.load(sys.stdin); t=d.get("threads",[])
print(t[-1]["thread_metadata"]["archive_timestamp"] if d.get("has_more") and t else "")')
  [[ -n $before ]] || break
done
if [[ -n $TH ]]; then
  api -o /dev/null -w "reuse thread $TH (unarchive) %{http_code}\n" -X PATCH https://discord.com/api/v10/channels/$TH \
    -d '{"archived":false,"auto_archive_duration":10080}'
else
  M=$(api -X POST https://discord.com/api/v10/channels/$CH/messages -d "{\"content\":\"🧵 **$full** — souls ทำงานใน repo นี้ ตอบเมื่อถูก tag เท่านั้น\"}" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
  TH=$(api -X POST https://discord.com/api/v10/channels/$CH/messages/$M/threads \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1][:100],"auto_archive_duration":10080}))' "$full")" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])')
fi
# 2b. add the humans to the thread (Nat 2026-11-05: "When new thread add human")
for u in $NAT $CB; do api -o /dev/null -w "add human $u %{http_code}\n" -X PUT https://discord.com/api/v10/channels/$TH/thread-members/$u; done
# 3. worktree + soul note (migrate: worktree exists; back up the 3 files it rewrites, Nothing is Deleted)
if (( MIG )); then
  ts=$(date +%Y%m%d-%H%M%S)
  for f in $W/.discord/access.json $W/.discord/launch.sh $W/CLAUDE.local.md; do [[ -f $f ]] && cp -p $f $f.bak-$ts-migrate; done
else
  git -C $R fetch -q origin main 2>/dev/null || true
  [[ -d $W ]] || git -C $R worktree add -q -b soul/$oracle $W origin/main 2>/dev/null || git -C $R worktree add -q $W soul/$oracle
fi
mkdir -p $W/.discord
cat > $W/.discord/access.json <<J
{ "dmPolicy": "allowlist", "allowFrom": [], "pending": {},
  "groups": { "$TH": { "requireMention": true, "allowFrom": ["$NAT", "$CB"] } },
  "guilds": { "$GUILD": { "requireMention": true, "allowFrom": ["eyes-only"],
    "note": "auto read allowlist: fetch any room in the guild; allowFrom matches no one, so nothing outside the thread is heard" } } }
J
cat > $W/CLAUDE.local.md <<MD
# $oracle soul in $name (written by /soul-in-repo, channel = #repo, thread = $full)

You are **$oracle**, working inside the repo **$name** (worktree $W, branch soul/$oracle).
Your soul ($soul/CLAUDE.md) is appended at start. The repo's own CLAUDE.md is the project you work on.

- Discord: channel-native on YOUR OWN bot. Ears = .discord/access.json: thread #repo › $full ($TH) only.
- Every soul of $full shares this thread. Answer ONLY when your bot is tagged (requireMention); sign as yourself.
  Laris Labs Oracle hears this thread too and stays silent unless tagged.
- Ears narrow, eyes wide: answer only in thread $TH, but read any room your bot can see with
  fetch_messages (access.json has a guild-wide eyes-only row: every room readable, none heard).
- Edit only your own .discord/ files. Never edit another bot's access file.
- Talk to other agents with \`herdr agent prompt <pane> "..."\` (bots do not hear bots in Discord).
MD
ex=$(git -C $W rev-parse --git-common-dir)/info/exclude
for l in .discord/ CLAUDE.local.md 'CLAUDE.local.md.bak-*'; do grep -qxF $l $ex 2>/dev/null || echo $l >> $ex; done
cat > $W/.discord/launch.sh <<L
#!/bin/zsh
cd '$W'
export DISCORD_STATE_DIR='$W/.discord'
export DISCORD_ORACLE=$oracle
export DISCORD_BOT_TOKEN="\$(pass show discord/$oracle-token | head -1)"
export CLAUDE_CODE_OAUTH_TOKEN="\$(pass show claude/token-$ctok | head -1)"
export CLAUDE_TOKEN_NAME=$ctok
exec claude --dangerously-skip-permissions --channels=plugin:discord@claude-plugins-official \${RESUME:+--continue} --append-system-prompt "\$(cat '$soul/CLAUDE.md')"
L
chmod +x $W/.discord/launch.sh
if (( ! MIG )); then
# 4. pre-trust the new folder (same as tools/laris-wt.sh)
python3 - $W <<'PY'
import json, os, sys
f = os.path.expanduser("~/.claude.json"); d = json.load(open(f))
d.setdefault("projects", {}).setdefault(sys.argv[1], {}).update(hasTrustDialogAccepted=True)
tmp = f + ".soul-in-repo"; json.dump(d, open(tmp, "w"), indent=2); os.replace(tmp, f)
PY
# 5. its OWN space nested under the repo (herdr worktree open), never a split in the caller's space:
#    a split hides the body under the caller's repo in the sidebar (Nat 2026-11-05: "no herdr session? how come?")
wsof() { herdr --session $S worktree list --cwd "$R" | python3 -c 'import sys,json
try: print(json.load(sys.stdin)["result"]["source"].get("source_workspace_id") or "")
except Exception: print("")'; }
MWS=$(wsof); [[ -n $MWS ]] || { herdr --session $S workspace create --cwd "$R" --label "$name" --no-focus >/dev/null; MWS=$(wsof); }
P=$(herdr --session $S worktree open --workspace "$MWS" --path "$W" --label "wt/$oracle-soul" --no-focus \
  | python3 -c 'import sys,re; print(re.search(r"\"pane_id\": ?\"([^\"]+)\"", sys.stdin.read()).group(1))')
herdr --session $S pane run $P "$W/.discord/launch.sh" >/dev/null
fi
# 6. Laris host row: hears (own thread), answers only when tagged
L=$HOME/.claude/channels/laris-labs-oracle/access.local.json
cp $L $L.bak-$(date +%Y%m%d-%H%M%S)-soul-$name
python3 - $L $TH "$oracle" "$full" "${OLD:-}" <<'PY'
import json, sys
f, th, o, n, old = sys.argv[1:]; a = json.load(open(f))
if old and old != th and old in a.get("groups", {}):
    r = a["groups"][old]; r["requireMention"] = True
    r["note"] = f"moved to #repo › {n} (2026-11-07 layout); kept, not deleted. was: {r.get('note', '')}"[:500]
row = a.setdefault("groups", {}).get(th, {})
souls = sorted(set(row.get("souls", [])) | {o})
a["groups"][th] = {"requireMention": True, "allowFrom": ["691531480689541170", "917019242094817301"], "souls": souls, "repo": n,
  "note": f"repo thread {n}: souls {', '.join(souls)} answer with their own bots when tagged; Laris hears (own thread), silent unless tagged"}
json.dump(a, open(f, "w"), indent=2)
PY
# 7. (--deny-main) the oracle's MAIN body must never hear or join #repo threads (same bot, own access files)
if (( DENYMAIN )); then
  DROW="{\"deny\": true, \"earsOff\": true, \"note\": \"#$CHN threads belong to soul bodies (soul-in-repo --deny-main); main body stays out\"}"
  if [[ -z $MACH || $MACH = $HOST ]]; then
    if [[ -d ${ML:h} ]]; then
      [[ -f $ML ]] && cp $ML $ML.bak-$(date +%Y%m%d-%H%M%S)-deny-repo || echo '{}' > $ML
      python3 - $ML $CH <<'PY'
import json, sys
f, ch = sys.argv[1:]; a = json.load(open(f))
row = a.setdefault("groups", {}).setdefault(ch, {})
row.update(deny=True, earsOff=True); row.setdefault("note", "#repo threads belong to soul bodies (soul-in-repo --deny-main); main body stays out")
json.dump(a, open(f, "w"), indent=2)
PY
      echo "deny-main: #$CHN ($CH) denied in $ML (restart or wait for the main body's access reload)"
    else echo "deny-main: no main body state dir ${ML:h} on $HOST: nothing written"; fi
  else
    echo "deny-main: main body on $MACH. Ask its agent (find the pane: herdr --machine <label> agent list; labels: herdr machine list):"
    echo "  herdr --machine <label> agent prompt <pane> 'In ~/.claude/channels/$oracle/access.local.json (backup first) set groups[\"$CH\"] = $DROW; report back to $(hostname -s) ${HERDR_PANE_ID:-<my pane>}'"
  fi
fi
if (( MIG )); then
  echo "done: migrated $oracle to #$CHN ($CH) > $full ($TH) · $W"
  echo "the live claude still runs the OLD files. Restart it in pane ${P:-<pane>}, one step at a time:"
  echo "  1. post a short 'restarting' note in thread $TH"
  echo "  2. herdr agent prompt ${P:-<pane>} '/exit'"
  echo "  3. herdr pane wait-output ${P:-<pane>} --regex 'took [0-9]+[hms]' --source visible --lines 2 --timeout 30000"
  echo "     (bottom 2 lines only: claude's status bar while it runs, the fresh prompt after exit; timeout = stop, read the pane, send nothing)"
  echo "  4. restart: herdr pane run ${P:-<pane>} 'RESUME=1 $W/.discord/launch.sh'"
  echo "  5. herdr pane wait-output ${P:-<pane>} --regex 'bypass permissions' --source visible --lines 3 --timeout 60000   (claude is back)"
  exit 0
fi
echo "done: #$CHN ($CH) > $full ($TH) · $W · pane $P"
echo "next: wait for $W/.discord/status.json gateway.ready, then: herdr agent prompt $P 'Read CLAUDE.local.md, post one hello in thread $TH'"
