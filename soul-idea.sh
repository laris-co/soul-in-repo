#!/usr/bin/env zsh
# soul-idea.sh — IDEA MODE and CONVERT (Nat 2026-11-07 22:03 "yes go!", via Laris).
#
#   soul-idea.sh idea    <idea> <oracle>... [--channel=<id>] [--dir=<base>] [--yes]
#   soul-idea.sh convert <idea> --repo=<owner/repo> [--public] [--yes]
#
# IDEA MODE: an idea before there is a code repo. ONE channel '💡・<idea>' (found by name, pinned with --channel, or
#   created under the research category with the Laris token), ONE thread per oracle opened by THAT oracle's own bot
#   (same as repo mode). The body is a scratch dir per soul, default <soul repo>/ψ/lab/<idea> (--dir=<base> gives
#   <base>/<oracle>), with .discord/{access.json,launch.sh} and CLAUDE.local.md ("idea mode: research and sketches,
#   no code repo yet"). Laris keeps one row on the channel: requireMention false, mode "idea".
# CONVERT: the idea becomes a repo. 1) gh repo create (private unless --public) when missing, ghq get, wt/ ignored;
#   2) rename the channel '💡・<idea>' -> '📦・<owner>∕<repo>' (same id, history kept); 3) per soul: stop its idea
#   body, build <repo>/wt/<oracle>-soul with soul-in-repo.sh --channel <same channel>, which finds and reuses the SAME
#   thread, copy the idea notes into the worktree (idea-notes/, never committed by this script), keep the idea
#   .discord as .discord.bak-<ts>-converted; 4) Laris row mode "repo", repo set.
# Plan by default: lookups are GETs, nothing is written. --yes runs (access rows: Nat's or catbutter's go).
set -euo pipefail
VERB=${1:-}; IDEA=${2:-}; shift 2 2>/dev/null || { sed -n 2,18p $0; exit 2; }
[[ $VERB = (idea|convert) ]] || { sed -n 2,18p $0; exit 2; }
[[ $IDEA =~ '^[a-z0-9][a-z0-9-]*$' ]] || { echo "idea name: lowercase letters, digits and '-' (Discord channel name), not '$IDEA'"; exit 2; }
YES=0; CHPIN=""; DIRBASE=""; REPO=""; PRIV=1; ORACLES=()
for a in "$@"; do case $a in
  --yes) YES=1;; --dry) YES=0;; --channel=*) CHPIN=${a#*=};; --dir=*) DIRBASE=${a#*=};; --repo=*) REPO=${a#*=};;
  --private) PRIV=1;; --public) PRIV=0;;
  --*) echo "unknown $a"; exit 2;; *) ORACLES+=${${a%-oracle}}-oracle;; esac; done
[[ -z $CHPIN || $CHPIN = <-> ]] || { echo "--channel=<channel id>, not $CHPIN"; exit 2; }
HERE=${0:A:h}
GUILD=1560847800881643520; NAT=691531480689541170; CB=917019242094817301
CAT=${SOUL_CATEGORY:-1560847801838215259}          # idea channels: 🔬・research until Nat names an ideas category
REPOCAT=${SOUL_REPO_CATEGORY:-1568651567144374314}  # 📦 repos: where convert moves the channel
TEAM=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}
L=${HERDR_SOUL_LARIS:-$HOME/.claude/channels/laris-labs-oracle/access.local.json}
S=${HERDR_SESSION:-laris-co}
ghq=$(ghq root)
CHN="💡・$IDEA"
LT=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
api() { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' "$@"; }
soul_dir() { local s=$(sed -n 's/^soul: *"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' $TEAM/oracles/$1/config.yaml 2>/dev/null | head -1 | sed "s#{ghq}#$ghq#")
  echo ${s:-$ghq/github.com/laris-co/$1}; }
ctok_of() { local t=$(sed -n 's/^claude_token: *\([^ #]*\).*/\1/p' $TEAM/oracles/$1/config.yaml 2>/dev/null | head -1); echo ${t:-t3}; }
agent_in() { herdr agent list 2>/dev/null | python3 -c 'import json,sys
w=sys.argv[1]; a=json.load(sys.stdin)["result"]["agents"]
print(next((x["pane_id"] for x in a if x.get("cwd")==w and x.get("agent")),""))' $1; }
# the channel: pinned, else exactly '💡・<idea>' (after convert it is '📦・<owner>∕<repo>', found through the Laris row)
find_channel() {
  if [[ -n $CHPIN ]]; then
    api https://discord.com/api/v10/channels/$CHPIN | python3 -c 'import json,sys
d=json.load(sys.stdin); print(d["id"]+"="+d.get("name","") if d.get("type")==0 and d.get("guild_id")==sys.argv[1] else "")' $GUILD
  else
    api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c 'import json,sys
n=sys.argv[1]; h=[c["id"]+"="+c["name"] for c in json.load(sys.stdin) if c.get("type")==0 and c.get("name")==n]
print(h[0] if len(h)==1 else ("MANY:"+", ".join(h) if h else ""))' "$CHN"
  fi; }
# a thread named <oracle> in the channel, as that oracle's bot (active, then archived pages)
find_thread() {  # $1 bot token, $2 channel, $3 name
  python3 - "$1" "$2" "$3" $GUILD <<'PY'
import json,sys,urllib.request
tok,ch,n,g=sys.argv[1:]
def get(u):
    r=urllib.request.Request("https://discord.com/api/v10"+u,headers={"Authorization":"Bot "+tok,"User-Agent":"soul-idea (laris-co/soul-in-repo, 1)"})
    return json.load(urllib.request.urlopen(r,timeout=20))
for t in get(f"/guilds/{g}/threads/active").get("threads",[]):
    if t.get("parent_id")==ch and t.get("name")==n: print(t["id"]); sys.exit()
before=""
while True:
    d=get(f"/channels/{ch}/threads/archived/public?limit=100"+(f"&before={before}" if before else ""))
    for t in d.get("threads",[]):
        if t.get("name")==n: print(t["id"]); sys.exit()
    if not d.get("has_more") or not d.get("threads"): break
    before=d["threads"][-1]["thread_metadata"]["archive_timestamp"]
print("")
PY
}
office_hint() { echo "  • office thread: the Somsri bot opens 'office' in channel $1; rows for it in somsri-oracle/.discord (all) and in each soul (tag)"; }

if [[ $VERB = idea ]]; then
  (( ${#ORACLES} )) || { echo "which oracles?  soul-idea.sh idea $IDEA neo-oracle pulse-oracle"; exit 2; }
  [[ -z $REPO ]] || { echo "--repo goes with convert"; exit 2; }
  (( YES )) && how=RUN || how="plan only"
  echo "idea: '$IDEA' · channel '$CHN' · souls: ${(j:, :)ORACLES} · $how"
  hit=$(find_channel)
  [[ $hit = MANY:* ]] && { echo "stop: more than one channel named '$CHN' (${hit#MANY:}); pin one with --channel=<id>"; exit 1; }
  [[ -n $CHPIN && -z $hit ]] && { echo "stop: --channel=$CHPIN is not a text channel of guild $GUILD"; exit 1; }
  CH=${hit%%=*}
  [[ -n $CH ]] && echo "channel: reuse $CH (#${hit#*=})" || echo "channel: none yet, a run creates '$CHN' under category $CAT (Laris token)"
  fail=0
  for o in $ORACLES; do
    soul=$(soul_dir $o); ctok=$(ctok_of $o)
    B=${DIRBASE:+${DIRBASE:A}/$o}; B=${B:-$soul/ψ/lab/$IDEA}
    echo; echo "── $o · body $B"
    [[ -f $soul/CLAUDE.md ]] || { echo "  ✗ no soul at $soul"; fail=1; continue; }
    pass show discord/$o-token >/dev/null 2>&1 || { echo "  ✗ no pass discord/$o-token"; fail=1; continue; }
    pass show claude/token-$ctok >/dev/null 2>&1 || { echo "  ✗ no pass claude/token-$ctok"; fail=1; continue; }
    [[ -f $B/.discord/access.json ]] && { echo "  ✗ $B already has a body (.discord/access.json): nothing to do"; fail=1; continue; }
    ST=$(pass show discord/$o-token | head -1 | tr -d '[:space:]')
    TH=""; [[ -n $CH ]] && TH=$(find_thread $ST $CH $o)
    echo "  thread '$o': ${TH:+reuse $TH}${TH:-none yet, the $o bot opens it}"
    echo "  files: $B/.discord/{access.json,launch.sh} (ears: thread '$o', all; eyes: guild) · $B/CLAUDE.local.md (idea mode)"
    echo "  pane: own herdr space 'idea:$IDEA/${o%-oracle}' in $B, launch.sh"
    [[ $B = $soul/* && -f $soul/CLAUDE.local.md ]] && echo "  ⚠ $soul/CLAUDE.local.md exists: claude in $B loads it too (parent folder). Check it says nothing for the main body only, or use --dir="
    (( YES )) || continue
    if [[ -z $CH ]]; then
      CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
        -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"type":0,"parent_id":sys.argv[2],"topic":"idea "+sys.argv[3]+": research and sketches, one thread per oracle soul (soul-idea.sh)"}))' "$CHN" $CAT $IDEA)" \
        | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
      [[ -n $CH ]] || { echo "stop: could not create channel '$CHN'"; exit 1; }
      echo "  ✓ channel '$CHN' created: $CH"
    fi
    sapi() { curl -sS -H "Authorization: Bot $ST" -H 'Content-Type: application/json' "$@"; }
    if [[ -n $TH ]]; then sapi -o /dev/null -w "  ✓ reuse thread $TH (unarchive) %{http_code}\n" -X PATCH https://discord.com/api/v10/channels/$TH -d '{"archived":false,"auto_archive_duration":10080}'
    else
      TH=$(sapi -X POST https://discord.com/api/v10/channels/$CH/threads \
        -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1][:100],"type":11,"auto_archive_duration":10080}))' $o)" \
        | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
      [[ -n $TH ]] || { echo "  ✗ the $o bot could not open its thread in $CH (no Create Public Threads?)"; fail=1; continue; }
      echo "  ✓ thread '$o' opened by the $o bot: $TH"
    fi
    for u in $NAT $CB; do sapi -o /dev/null -w "  ✓ add human $u %{http_code}\n" -X PUT https://discord.com/api/v10/channels/$TH/thread-members/$u; done
    mkdir -p $B/.discord
    cat > $B/.discord/access.json <<J
{ "dmPolicy": "allowlist", "allowFrom": [], "pending": {},
  "groups": { "$TH": { "requireMention": false, "allowFrom": ["$NAT", "$CB"],
    "note": "own thread '$o' in idea channel '$CHN': hears every line" } },
  "guilds": { "$GUILD": { "requireMention": true, "allowFrom": ["eyes-only"],
    "note": "auto read allowlist: fetch any room in the guild; allowFrom matches no one, so nothing outside the thread is heard" } } }
J
    cat > $B/CLAUDE.local.md <<MD
# $o in idea '$IDEA' (written by soul-idea.sh: channel '$CHN', thread '$o')

**Idea mode: research and sketches, no code repo yet.** You are **$o**; your soul is $soul/CLAUDE.md.
This folder ($B) is your scratch space for the idea: notes, links, sketches, small experiments. When Nat turns the idea
into a repo (soul-idea.sh convert), these files are copied into the repo worktree, so keep them readable.

- Discord: channel-native on YOUR OWN bot. Ears = .discord/access.json: your own thread '$o' ($TH) in '$CHN'.
  Every line there is for you. Other oracles of the idea have their own threads in the same channel.
- Laris Labs Oracle hears the channel and answers only when tagged.
- Edit only your own .discord/ files. Talk to agents with \`herdr agent prompt <pane> "..."\`.
- Every report starts with where you are: machine · pane · path.
MD
    gd=$(git -C $B rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
    if [[ -n $gd ]]; then  # inside the soul repo: never commit the body files
      top=$(git -C $B rev-parse --show-toplevel); rel=${B#$top/}
      for l in $rel/.discord/ $rel/CLAUDE.local.md; do grep -qxF $l $gd/info/exclude 2>/dev/null || echo $l >> $gd/info/exclude; done
    fi
    app=""; [[ $B = $soul/* ]] || app=" --append-system-prompt \"\$(cat '$soul/CLAUDE.md')\""
    cat > $B/.discord/launch.sh <<LS
#!/bin/zsh
cd '$B'
export DISCORD_STATE_DIR='$B/.discord'
export DISCORD_ORACLE=$o
export DISCORD_BOT_TOKEN="\$(pass show discord/$o-token | head -1)"
export CLAUDE_CODE_OAUTH_TOKEN="\$(pass show claude/token-$ctok | head -1)"
export CLAUDE_TOKEN_NAME=$ctok
exec claude --dangerously-skip-permissions --channels=plugin:discord@claude-plugins-official \${RESUME:+--continue}$app
LS
    chmod +x $B/.discord/launch.sh
    python3 - $B <<'PY'
import json, os, sys
f = os.path.expanduser("~/.claude.json"); d = json.load(open(f))
d.setdefault("projects", {}).setdefault(sys.argv[1], {}).update(hasTrustDialogAccepted=True)
tmp = f + ".soul-idea"; json.dump(d, open(tmp, "w"), indent=2); os.replace(tmp, f)
PY
    P=$(herdr --session $S workspace create --cwd $B --label "idea:$IDEA/${o%-oracle}" --no-focus | python3 -c 'import sys,re; m=re.search(r"\"pane_id\": ?\"([^\"]+)\"", sys.stdin.read()); print(m.group(1) if m else "")')
    [[ -n $P ]] && herdr --session $S pane run $P "$B/.discord/launch.sh" >/dev/null && echo "  ✓ body starting in $P" || echo "  ✗ no herdr pane: start it by hand: $B/.discord/launch.sh"
    cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-idea-$IDEA
    python3 - $L $CH "$CHN" $TH $o $IDEA <<'PY'
import json, sys
f, ch, chn, th, o, idea = sys.argv[1:]; a = json.load(open(f)); g = a.setdefault("groups", {})
row = g.get(ch, {}); souls = sorted(set(row.get("souls", [])) | {o}); threads = {**row.get("threads", {}), o: th}
g[ch] = {"requireMention": False, "allowFrom": ["691531480689541170", "917019242094817301"], "layout": 9, "mode": "idea",
  "idea": idea, "channel": chn, "souls": souls, "threads": threads,
  "note": f"idea channel {chn}: souls {', '.join(souls)} each answer in their own thread; Laris hears every line, answers only when tagged"}
json.dump(a, open(f, "w"), indent=2, ensure_ascii=False)
PY
    echo "  ✓ Laris row: channel $CH mode idea, souls += $o"
  done
  echo
  echo "Laris row: channel ${CH:-<new>} {requireMention: false, mode: idea, idea: $IDEA, souls[], threads{}}"
  echo "not done here (by hand, on Nat's go):"
  office_hint ${CH:-<channel>}
  echo "  • main bodies: a soul's main body shares its bot; deny+earsOff channel ${CH:-<channel>} in its access.local.json"
  (( YES )) || echo "plan only. To run (Nat's go): soul-idea.sh idea $IDEA ${(j: :)ORACLES}${CHPIN:+ --channel=$CHPIN}${DIRBASE:+ --dir=$DIRBASE} --yes"
  exit $fail
fi

# ── convert ──
[[ $REPO =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { echo "convert needs --repo=<owner>/<repo>"; exit 2; }
(( ${#ORACLES} == 0 )) || { echo "convert takes the souls from the idea's Laris row, not from the command line"; exit 2; }
(( YES )) && how=RUN || how="plan only"
row=$(python3 - $L $IDEA "$CHPIN" <<'PY'
import json,sys
f,idea,pin=sys.argv[1:]
try: g=json.load(open(f)).get("groups",{})
except Exception: g={}
hits=[(k,v) for k,v in g.items() if v.get("mode")=="idea" and v.get("idea")==idea and (not pin or k==pin)]
if len(hits)!=1: print("ERR %d idea rows for '%s' in %s" % (len(hits),idea,f)); sys.exit()
k,v=hits[0]; print(k, " ".join(f"{o}={v.get('threads',{}).get(o,'-')}" for o in v.get("souls",[])))
PY
)
[[ $row = ERR* ]] && { echo "stop: ${row#ERR }"; echo "  (is '$IDEA' an idea? soul-idea.sh idea $IDEA <oracle>... first)"; exit 1; }
CH=${row%% *}; pairs=(${=row#* })
R=$ghq/github.com/$REPO
NEWN="📦・${(L)REPO/\//∕}"
echo "convert: idea '$IDEA' -> repo $REPO · channel $CH · souls: ${(j:, :)${(@)pairs%%=*}} · $how"
cur=$(api https://discord.com/api/v10/channels/$CH | python3 -c 'import json,sys;print(json.load(sys.stdin).get("name","?"))')
exists=$(gh repo view $REPO --json name -q .name 2>/dev/null || true)
echo "  1. repo: ${exists:+exists on GitHub}${exists:-gh repo create $REPO --$( (( PRIV )) && echo private || echo public) --add-readme}; ghq get $REPO -> $R; wt/ in .gitignore"
echo "  2. channel $CH: rename '#$cur' -> '$NEWN' and move it to category $REPOCAT (📦 repos); same id, history kept"
n=3
for p in $pairs; do
  o=${p%%=*}; th=${p#*=}; soul=$(soul_dir $o)
  B=$soul/ψ/lab/$IDEA; [[ -f $B/.discord/access.json || -z $DIRBASE ]] || B=${DIRBASE:A}/$o
  pane=$(agent_in $B)
  echo "  $n. $o (thread $th): stop idea body ${pane:-(no live pane)} in $B, keep $B/.discord as .discord.bak-<ts>-converted"
  echo "     soul-in-repo.sh $o $REPO --channel $CH --deny-main: worktree $R/wt/$o-soul, same thread $th, own pane, Laris row"
  echo "     copy idea notes $B/* -> $R/wt/$o-soul/idea-notes/ (not committed; the soul decides)"
  n=$((n+1))
done
echo "  $n. Laris row $CH: mode 'repo', repo $REPO (idea '$IDEA' kept as was_idea)"
echo "not done here: office thread ($(office_hint $CH | sed 's/^  • //'))"
(( YES )) || { echo "plan only. To run (Nat's go): soul-idea.sh convert $IDEA --repo=$REPO$( (( PRIV )) || echo ' --public') --yes"; exit 0; }

# 1. repo
if [[ -z $exists ]]; then gh repo create $REPO --$( (( PRIV )) && echo private || echo public) --add-readme >/dev/null && echo "  ✓ repo $REPO created"; fi
[[ -d $R ]] || ghq get -p $REPO >/dev/null 2>&1 || ghq get $REPO >/dev/null
if ! git -C $R check-ignore -q wt/; then
  echo wt/ >> $R/.gitignore && git -C $R add .gitignore && git -C $R commit -qm "ignore wt/ (soul worktrees)" && git -C $R push -q && echo "  ✓ wt/ ignored in $REPO"
fi
# 2. channel rename
api -o /dev/null -w "  ✓ channel rename -> '$NEWN', category $REPOCAT %{http_code}\n" -X PATCH https://discord.com/api/v10/channels/$CH \
  -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"parent_id":sys.argv[4],"topic":"repo "+sys.argv[2]+" (was idea "+sys.argv[3]+"): one thread per oracle soul"}))' "$NEWN" $REPO $IDEA $REPOCAT)"
# 3. souls
for p in $pairs; do
  o=${p%%=*}; soul=$(soul_dir $o); B=$soul/ψ/lab/$IDEA
  [[ -f $B/.discord/access.json ]] || { [[ -n $DIRBASE ]] && B=${DIRBASE:A}/$o; }
  pane=$(agent_in $B)
  if [[ -n $pane ]]; then  # one bot = one gateway: the idea body stops before the repo body starts
    herdr pane send-text $pane '/exit' >/dev/null && herdr pane send-keys $pane Enter >/dev/null
    for i in {1..30}; do [[ -z $(agent_in $B) ]] && break; sleep 2; done
    [[ -z $(agent_in $B) ]] || { echo "  ✗ $o: idea body in $pane did not stop; skipped (nothing changed for $o)"; continue; }
    echo "  ✓ $o: idea body in $pane stopped"
  fi
  ts=$(date +%Y%m%d-%H%M%S)
  [[ -d $B/.discord ]] && mv $B/.discord $B/.discord.bak-$ts-converted
  HERDR_SOUL_DIR=$soul zsh $HERE/soul-in-repo.sh $o $REPO --channel $CH --deny-main
  mkdir -p $R/wt/$o-soul/idea-notes
  rsync -a --exclude '.discord*' --exclude 'CLAUDE.local.md' $B/ $R/wt/$o-soul/idea-notes/ && echo "  ✓ $o: idea notes copied to $R/wt/$o-soul/idea-notes/"
done
# 4. Laris row
cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-convert-$IDEA
python3 - $L $CH $REPO $IDEA <<'PY'
import json,sys
f,ch,repo,idea=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]
r.update(mode="repo", repo=repo, was_idea=idea); r.pop("idea",None)
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
echo "  ✓ Laris row $CH: mode repo, repo $REPO"
echo "done: idea '$IDEA' is repo $REPO; channel $CH '$NEWN'"
