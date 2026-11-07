#!/usr/bin/env zsh
# soul-in-repo.sh <oracle> <repo> [--category <id>] [--channel <id>] [--chname slash|dash] [--migrate] [--deny-main] [--dry]
#   Layout 9 (Nat 2026-11-07 06:34Z, #research › repo-soul): ONE channel per repo, named <owner>∕<repo>
#   (U+2215 DIVISION SLASH; --chname dash or CHNAME=dash gives <owner>-<repo>), ONE thread per oracle, named <oracle>,
#   opened by THAT oracle's own bot. Own thread: the soul hears every line untagged. Laris Labs Oracle keeps one row per
#   repo channel (requireMention false, same as the souls: hears every line, answers only when tagged; Nat 2026-11-07 "why not same?") listing souls[] and threads{oracle: thread}.
#   Was: #repo › <owner>/<repo> shared by every soul (morning of 2026-11-07); before that #<oracle> › <repo> (2026-11-05).
#   --migrate    move a LIVE body to its layout-9 thread: rewrite its access.json, launch.sh and soul note (backups
#                beside them) and the Laris rows; NO worktree, trust, pane or launch (a second claude on the same bot
#                token = rival gateway). The old thread row is kept, never deleted (note 'moved to layout 9').
#                Prints the restart steps for the existing pane.
#   --channel <id>  use this channel (e.g. a room Nat made by hand); default: match the name, icon prefix allowed
#   --deny-main  also write { deny: true, earsOff: true } for the repo channel into the oracle's MAIN body
#                access.local.json, so a main body sharing the bot never hears or joins the soul threads. Local machine:
#                written here (backup); main body on another machine: prints the herdr --machine prompt for its agent.
#   <oracle>  e.g. neo-oracle  (soul = config.yaml soul: or $(ghq root)/github.com/laris-co/<oracle>, bot = pass discord/<oracle>-token)
#   <repo>    owner/name (in ghq) or an absolute path
# Builds: channel <owner>∕<repo> (find by name or create, never a second one) -> thread <oracle> (the soul's bot finds,
# reuses + unarchives, or opens it) -> humans -> worktree <repo>/wt/<oracle>-soul -> .discord/{access.json,
# launch.sh} + soul note -> own herdr space under the repo -> Laris channel row -> hello.
# Runs on the machine of the Laris host bot (m5 today). Tokens only from pass, never printed.
set -euo pipefail
oracle=${1:?oracle}; repo=${2:?repo}; shift 2
CAT=${SOUL_CATEGORY:-1560847801838215259}   # 🔬・research category
CHNAME=${CHNAME:-slash}
PREFIX=${SOUL_CHPREFIX-📦・}   # icon prefix for a NEW channel (Nat's pilot room); SOUL_CHPREFIX= for none
CHPIN=""
DRY=0; MIG=0; DENYMAIN=0
while (( $# )); do case $1 in
  --category) CAT=$2; shift 2;; --channel) CHPIN=$2; shift 2;; --channel=*) CHPIN=${1#*=}; shift;; --chname) CHNAME=$2; shift 2;; --chname=*) CHNAME=${1#*=}; shift;;
  --dry) DRY=1; shift;; --migrate) MIG=1; shift;; --deny-main) DENYMAIN=1; shift;;
  *) echo "unknown $1"; echo "  usage: $0 <oracle> <repo> [--category <id>] [--channel <id>] [--chname slash|dash] [--migrate] [--deny-main] [--dry]"; exit 2;; esac; done
[[ $CHNAME = (slash|dash) ]] || { echo "--chname is slash or dash, not '$CHNAME'"; echo "  $0 $oracle $repo --chname dash --dry"; exit 2; }
FL=""; (( MIG )) && FL+=" --migrate"   # flags to repeat in a printed fix line
GUILD=1560847800881643520
NAT=691531480689541170; CB=917019242094817301
TEAM=/opt/Code/github.com/laris-co/laris-team
ghq=$(ghq root)
soul=${HERDR_SOUL_DIR:-$ghq/github.com/laris-co/$oracle}
[[ -f $soul/CLAUDE.md ]] || { echo "no soul: $soul/CLAUDE.md"; exit 1; }
[[ $repo = /* ]] && R=$repo || R=$ghq/github.com/$repo
[[ -d $R/.git || -f $R/.git ]] || { echo "not a repo: $R"; exit 1; }
name=${R:t}
W=$R/wt/$oracle-soul
# <owner>/<repo> from origin (github ssh or https), else from the ghq path
full=$(git -C $R remote get-url origin 2>/dev/null | sed -E 's#^(git@[^:]+:|[a-z+]+://[^/]+/)##; s#\.git$##')
[[ $full = */* ]] || full=${R#$ghq/github.com/}
[[ $full = */* ]] || { echo "cannot tell <owner>/<repo> for $R (no origin, not under ghq)"; exit 1; }
# channel name: Discord lowercases text channel names; dash form keeps only [a-z0-9_-]
if [[ $CHNAME = slash ]]; then CHN=${(L)full/\//∕}
else CHN=$(print -r -- ${(L)full} | sed -E 's#[^a-z0-9_-]+#-#g'); fi
cfg=$TEAM/oracles/$oracle/config.yaml
ctok=$(sed -n 's/^claude_token: *\([^ #]*\).*/\1/p' $cfg 2>/dev/null | head -1); ctok=${ctok:-t3}
pass show discord/$oracle-token >/dev/null || { echo "no pass discord/$oracle-token"; exit 1; }
pass show claude/token-$ctok >/dev/null || { echo "no pass claude/token-$ctok"; exit 1; }
git -C $R check-ignore -q wt/ || { echo "wt/ is not ignored in $R: add it to .gitignore first"; echo "  echo wt/ >> $R/.gitignore && git -C $R commit -m 'ignore wt/' .gitignore"; exit 1; }
NOTE=$W/CLAUDE.local.md
echo "plan: channel '$CHN' (layout 9; ${CHPIN:+pinned $CHPIN, else }match '$CHN' or '<icon>・$CHN', else create '$PREFIX$CHN' under category $CAT; never a second one)"
echo "      thread '$oracle' in it, found/reused/unarchived or opened by the $oracle bot (own thread); humans Nat + catbutter"
echo "      worktree $W (branch soul/$oracle) · bot $oracle · claude $ctok · DISCORD_ORACLE=$oracle"
echo "      ears: thread '$oracle', requireMention false (its own thread) · eyes: guild read-only · note: $NOTE"
echo "      Laris row: the CHANNEL '$CHN', requireMention false (hears every line, answers only when tagged), souls[] += $oracle, threads{$oracle}"
S=${HERDR_SESSION:-laris-co}
OLD=""; P=""
if (( MIG )); then
  # the live body's state dir: <wt>/.discord, or the DISCORD_STATE_DIR its launch line exports, or the older
  # per-soul dir ~/.claude/channels/<oracle>-<repo> (calliope-oracle on white, 2026-11-07)
  SD=$W/.discord
  if [[ ! -f $SD/access.json ]]; then
    lsd=$(sed -n "s/^export DISCORD_STATE_DIR=['\"]\{0,1\}\([^'\"]*\).*/\1/p" $W/.discord/launch.sh 2>/dev/null | head -1)
    for c in ${lsd/#\~/$HOME} $HOME/.claude/channels/$oracle-$name; do [[ -n $c && -f $c/access.json ]] && { SD=$c; break; }; done
  fi
  [[ -f $SD/access.json ]] || { echo "migrate: no live body for $oracle in $W (no access.json in $W/.discord, in the launch line's DISCORD_STATE_DIR, or in ~/.claude/channels/$oracle-$name)"; echo "  build it instead: $0 $oracle $repo"; exit 1; }
  [[ $SD = $W/.discord ]] || echo "migrate: state dir is $SD (kept: access.json is rewritten there, launch.sh points at it)"
  OLD=$(python3 -c 'import json,sys;print(next(iter(json.load(open(sys.argv[1])).get("groups",{})),""))' $SD/access.json)
  # the pane that runs this body now (herdr pane list, matched on cwd)
  P=$(herdr --session $S pane list 2>/dev/null | python3 -c 'import json,sys
w=sys.argv[1]
try: print(next((p["pane_id"] for p in json.load(sys.stdin)["result"]["panes"] if (p.get("foreground_cwd") or p.get("cwd"))==w),""))
except Exception: print("")' $W)
  echo "migrate: old thread ${OLD:-none} -> '$CHN' › '$oracle' · live pane ${P:-not found}"
  echo "      rewrite (backup .bak-<ts>-migrate beside each): $SD/access.json, $W/.discord/launch.sh, $NOTE"
  echo "      Laris: old row ${OLD:-none} kept: $oracle leaves its souls[]; when none is left, note 'moved to layout 9', requireMention true"
  echo "      skip: worktree, trust, herdr pane, launch, hello"
fi
MACH=$(sed -n 's/^machine: *\([^ #]*\).*/\1/p' $cfg 2>/dev/null | head -1); HOST=$(hostname -s)
ML=$HOME/.claude/channels/$oracle/access.local.json
# Layout 9: the soul's thread is owned by the oracle's bot, and the plugin gives an own thread requireMention false on
# EVERY body of that bot. A running main body therefore hears the soul's thread too (white Pulse main heard Nat's 'ok?' in
# the pilot room, 2026-11-07 07:17Z). Warn loudly; Nat decides per run (never a silent default).
MAINBODY=""
[[ -n $MACH ]] && MAINBODY="config.yaml machine: $MACH"
MS=$HOME/.claude/channels/$oracle/status.json
if [[ -f $MS ]]; then
  mp=$(python3 -c 'import json,sys;d=json.load(open(sys.argv[1]));print("" if d.get("stopped_at") else d.get("pid") or "")' $MS 2>/dev/null || true)
  [[ -n $mp ]] && kill -0 $mp 2>/dev/null && MAINBODY="${MAINBODY:+$MAINBODY; }live main body here (pid $mp, $MS)"
fi
if [[ -n $MAINBODY && $DENYMAIN = 0 ]]; then
  echo "⚠⚠ WARNING: $oracle has a main body ($MAINBODY) and --deny-main is missing."
  echo "⚠⚠ Its own-thread rule lets that main body hear thread '$oracle' too: two answers from one bot."
  echo "⚠⚠ To keep it out, run with --deny-main (Nat decides per run):"
  echo "     $0 $oracle $repo --deny-main$FL${CHPIN:+ --channel $CHPIN} --dry"
fi
if (( DENYMAIN )); then
  if [[ -z $MACH || $MACH = $HOST ]]; then echo "      deny-main: groups[channel '$CHN' id] deny+earsOff in $ML (main body here on $HOST; backup first)"
  else echo "      deny-main: main body lives on $MACH: print the herdr --machine prompt for its agent (no ssh edit)"; fi
fi
LT=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
ST=$(pass show discord/$oracle-token | head -1 | tr -d '[:space:]')
api()  { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' "$@"; }   # Laris: the channel
sapi() { curl -sS -H "Authorization: Bot $ST" -H 'Content-Type: application/json' "$@"; }   # the soul: its thread
# 1. channel: --channel <id> pins it; else find by name anywhere in the guild. A name matches '<owner>∕<repo>' exactly or
#    with an icon prefix ending in '・' ('📦・laris-co∕soul-in-repo', Nat's pilot 2026-11-07). Two matches = stop.
#    Lookups are GETs, so --dry runs them too and shows what a real run would reuse.
if [[ -n $CHPIN ]]; then
  CH=$(api https://discord.com/api/v10/channels/$CHPIN | python3 -c 'import json,sys
d=json.load(sys.stdin); g=sys.argv[1]
print(d["id"] if d.get("type")==0 and d.get("guild_id")==g else "")' $GUILD)
  [[ -n $CH ]] || { echo "stop: --channel $CHPIN is not a text channel of guild $GUILD"; echo "  $0 $oracle $repo --dry$FL   (find it by name instead)"; exit 1; }
  echo "channel pinned: $CH"
else
  CH=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c 'import json,sys
n=sys.argv[1]
def hit(c):
    m=c.get("name","").lower()
    return c.get("type")==0 and (m==n or m.endswith("・"+n))
hits=[c["id"]+"="+c["name"] for c in json.load(sys.stdin) if hit(c)]
print(hits[0].split("=")[0] if len(hits)==1 else ("MANY:"+", ".join(hits) if hits else ""))' "$CHN")
  [[ $CH = MANY:* ]] && { echo "stop: more than one channel matches '$CHN' (${CH#MANY:}); pin one:"; echo "  $0 $oracle $repo --channel <id>$FL"; exit 1; }
  [[ -n $CH ]] && echo "channel found: $CH"
fi
# 2. thread <oracle>: the soul's own bot finds it (active, then archived pages) or opens it, so the soul owns its thread
findth() { python3 -c 'import json,sys
d=json.load(sys.stdin); ch,n=sys.argv[1:]
print(next((t["id"] for t in d.get("threads",[]) if t.get("parent_id")==ch and t.get("name")==n),""))' $CH "$oracle"; }
TH=""
if [[ -n $CH ]]; then
  TH=$(sapi https://discord.com/api/v10/guilds/$GUILD/threads/active | findth)
  before=""
  while [[ -z $TH ]]; do
    page=$(sapi "https://discord.com/api/v10/channels/$CH/threads/archived/public?limit=100${before:+&before=$before}")
    TH=$(print -r -- $page | findth)
    [[ -n $TH ]] && break
    before=$(print -r -- $page | python3 -c 'import json,sys
d=json.load(sys.stdin); t=d.get("threads",[])
print(t[-1]["thread_metadata"]["archive_timestamp"] if d.get("has_more") and t else "")')
    [[ -n $before ]] || break
  done
fi
if (( DRY )); then
  [[ -n $CH ]] || echo "channel: none yet, a real run creates '$PREFIX$CHN' under category $CAT"
  [[ -n $TH ]] && echo "thread '$oracle': reuse $TH" || echo "thread '$oracle': none yet, the $oracle bot opens it"
  echo "dry: nothing touched (lookups were GETs)"; exit 0
fi
if [[ -z $CH ]]; then
  CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"type":0,"parent_id":sys.argv[2],"topic":"repo "+sys.argv[3]+": one thread per oracle soul, each opened by its own bot"}))' "$PREFIX$CHN" $CAT "$full")" \
    | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("id",""))')
  [[ -n $CH ]] || { echo "stop: could not create channel '$PREFIX$CHN' (name refused?); retry with the dash name:"; echo "  $0 $oracle $repo --chname dash$FL"; exit 1; }
  echo "channel '$PREFIX$CHN' created: $CH"
fi
if [[ -n $TH ]]; then
  sapi -o /dev/null -w "reuse thread $TH (unarchive) %{http_code}\n" -X PATCH https://discord.com/api/v10/channels/$TH \
    -d '{"archived":false,"auto_archive_duration":10080}'
else
  TH=$(sapi -X POST https://discord.com/api/v10/channels/$CH/threads \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1][:100],"type":11,"auto_archive_duration":10080}))' "$oracle")" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
  [[ -n $TH ]] || { echo "stop: the $oracle bot could not open its thread in $CH (no Create Public Threads there?)"; echo "  check the bot's role on category $CAT, then rerun: $0 $oracle $repo$FL"; exit 1; }
  echo "thread '$oracle' opened by the $oracle bot: $TH"
fi
# 2b. add the humans to the thread (Nat 2026-11-05: "When new thread add human")
for u in $NAT $CB; do sapi -o /dev/null -w "add human $u %{http_code}\n" -X PUT https://discord.com/api/v10/channels/$TH/thread-members/$u; done
# 3. worktree + backups of what a migrate rewrites (Nothing is Deleted)
if (( MIG )); then
  ts=$(date +%Y%m%d-%H%M%S)
  for f in $SD/access.json $W/.discord/launch.sh $NOTE; do [[ -f $f ]] && cp -p $f $f.bak-$ts-migrate; done
else
  git -C $R fetch -q origin main 2>/dev/null || true
  [[ -d $W ]] || git -C $R worktree add -q -b soul/$oracle $W origin/main 2>/dev/null || git -C $R worktree add -q $W soul/$oracle
fi
SD=${SD:-$W/.discord}
mkdir -p $W/.discord $SD
cat > $SD/access.json <<J
{ "dmPolicy": "allowlist", "allowFrom": [], "pending": {},
  "groups": { "$TH": { "requireMention": false, "allowFrom": ["$NAT", "$CB"],
    "note": "own thread '$oracle' in channel '$CHN' (layout 9): hears every line" } },
  "guilds": { "$GUILD": { "requireMention": true, "allowFrom": ["eyes-only"],
    "note": "auto read allowlist: fetch any room in the guild; allowFrom matches no one, so nothing outside the thread is heard" } } }
J
BODY="the repo $full (worktree $W, branch soul/$oracle)"
note_text() { cat <<MD
# $oracle in $full (written by soul-in-repo.sh, layout 9: channel '$CHN', thread '$oracle')

You are **$oracle**, working in $BODY.
Your soul ($soul/CLAUDE.md) is appended at start. The repo's own files are the project you work on.

- Discord: channel-native on YOUR OWN bot. Ears = .discord/access.json: your own thread '$oracle' ($TH) in channel '$CHN'.
  Every line there is for you (no tag needed). Sign as yourself.
- Other oracles of $full each have their own thread in the same channel. Laris Labs Oracle hears the channel but only
  answers when tagged.
- Ears narrow, eyes wide: answer only in thread $TH, but read any room your bot can see with fetch_messages
  (access.json has a guild-wide eyes-only row: every room readable, none heard).
- Edit only your own .discord/ files. Never edit another bot's access file.
- Talk to other agents with \`herdr agent prompt <pane> "..."\` (bots do not hear bots in Discord).
- Every report starts with where you are: machine · pane · path (branch).
MD
}
# absolute: in a worktree --git-common-dir is relative to the cwd, not to -C (digger-oracle theognosis on white)
ex=$(git -C $R rev-parse --path-format=absolute --git-common-dir)/info/exclude
note_text > $W/CLAUDE.local.md
for l in .discord/ CLAUDE.local.md 'CLAUDE.local.md.bak-*'; do grep -qxF $l $ex 2>/dev/null || echo $l >> $ex; done
cat > $W/.discord/launch.sh <<L
#!/bin/zsh
cd '$W'
export DISCORD_STATE_DIR='$SD'
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
# 6. Laris channel row: one per repo channel, requireMention false like the souls (Nat "why not same?"), answers only when tagged; old thread row kept (Nothing is Deleted)
L=$HOME/.claude/channels/laris-labs-oracle/access.local.json
cp $L $L.bak-$(date +%Y%m%d-%H%M%S)-soul-$name
python3 - $L $CH "$CHN" $TH "$oracle" "$full" "${OLD:-}" <<'PY'
import json, sys
f, ch, chn, th, o, n, old = sys.argv[1:]; a = json.load(open(f)); g = a.setdefault("groups", {})
if old and old != th and old != ch and old in g:
    r = g[old]
    if "souls" in r:
        r["souls"] = [s for s in r["souls"] if s != o]
        if "threads" in r: r["threads"].pop(o, None)
    if not r.get("souls"):
        r["requireMention"] = True
        r["note"] = f"moved to layout 9 › {chn} (2026-11-07); kept, not deleted. was: {r.get('note', '')}"[:500]
row = g.get(ch, {})
souls = sorted(set(row.get("souls", [])) | {o})
threads = {**row.get("threads", {}), o: th}
g[ch] = {"requireMention": False, "allowFrom": ["691531480689541170", "917019242094817301"], "layout": 9,
  "channel": chn, "repo": n, "souls": souls, "threads": threads,
  "note": f"repo channel {chn} (layout 9): souls {', '.join(souls)} each answer in their own thread; Laris hears every line, answers only when tagged"}
json.dump(a, open(f, "w"), indent=2)
PY
# 7. (--deny-main) the oracle's MAIN body must never hear or join this repo channel (same bot, own access files)
if (( DENYMAIN )); then
  DROW="{\"deny\": true, \"earsOff\": true, \"note\": \"repo channel $CHN belongs to soul bodies (soul-in-repo --deny-main); main body stays out\"}"
  if [[ -z $MACH || $MACH = $HOST ]]; then
    if [[ -d ${ML:h} ]]; then
      [[ -f $ML ]] && cp $ML $ML.bak-$(date +%Y%m%d-%H%M%S)-deny-repo || echo '{}' > $ML
      python3 - $ML $CH "$CHN" <<'PY'
import json, sys
f, ch, chn = sys.argv[1:]; a = json.load(open(f))
row = a.setdefault("groups", {}).setdefault(ch, {})
row.update(deny=True, earsOff=True); row.setdefault("note", f"repo channel {chn} belongs to soul bodies (soul-in-repo --deny-main); main body stays out")
json.dump(a, open(f, "w"), indent=2)
PY
      echo "deny-main: '$CHN' ($CH) denied in $ML (restart or wait for the main body's access reload)"
    else echo "deny-main: no main body state dir ${ML:h} on $HOST: nothing written"; fi
  else
    echo "deny-main: main body on $MACH. Ask its agent (find the pane: herdr --machine <label> agent list; labels: herdr machine list):"
    echo "  herdr --machine <label> agent prompt <pane> 'In ~/.claude/channels/$oracle/access.local.json (backup first) set groups[\"$CH\"] = $DROW; report back to $(hostname -s) ${HERDR_PANE_ID:-<my pane>}'"
  fi
fi
if (( MIG )); then
  echo "done: migrated $oracle to '$CHN' ($CH) › '$oracle' ($TH) · $W"
  echo "the live claude still runs the OLD files. Restart it in pane ${P:-<pane>}, one step at a time:"
  echo "  1. post a short 'restarting' note in the old thread ${OLD:-<old thread>}"
  echo "  2. herdr agent prompt ${P:-<pane>} '/exit'"
  echo "  3. herdr pane wait-output ${P:-<pane>} --regex 'took [0-9]+[hms]' --source visible --lines 2 --timeout 30000"
  echo "     (bottom 2 lines only: claude's status bar while it runs, the fresh prompt after exit; timeout = stop, read the pane, send nothing)"
  echo "  4. restart: herdr pane run ${P:-<pane>} 'RESUME=1 $W/.discord/launch.sh'"
  echo "  5. herdr pane wait-output ${P:-<pane>} --regex 'bypass permissions' --source visible --lines 3 --timeout 60000   (claude is back)"
  exit 0
fi
echo "done: '$CHN' ($CH) › '$oracle' ($TH) · $W · pane $P"
echo "next: wait for ${SD:-$W/.discord}/status.json gateway.ready, then: herdr agent prompt $P 'Read CLAUDE.local.md, post one hello in thread $TH'"
