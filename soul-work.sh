#!/usr/bin/env zsh
# soul-work.sh — WORK on a repo from Discord (Nat 2026-11-08 "it should have like /work for report like /work <github url>",
# "gogogo"). Finds (or clones) the repo, finds or makes its room, posts a report there, brings souls in.
#
#   soul-work.sh <owner/repo | github url> [<oracle>...] [--yes]
#
# 1 repo    on this machine already, else ghq get -p
# 2 room    channel '<icon>・<owner>∕<repo>' found by name, else created under ⚡ active + Laris row (layout 9, souls []);
#           never a second room
# 3 report  posted in the room: what it is (README), last commits, open PRs + issues, checkouts on this machine
#           (room-status: worktrees, agents, 🧹 stale)
# 4 main    the repo's herdr space on its main checkout with a plain claude main agent (bin/main-pane, #48): reused when
#           live, else started; the Laris row forwards the room ROOT's untagged lines to it (forwardTo + forwardRoot,
#           laris-team#241). Skipped when the main is a bot body (.discord/) or the room's Somsri (.somsri/, #49).
# 5 souls   each <oracle> not in the room yet: herdr-soul room <repo> <oracle> --channel=<id> --yes
# --post=<id>: post the report in that channel or thread instead of the room (/work typed inside a room).
# Plan by default: the report is printed, nothing is created or posted. --yes runs (Nat's or catbutter's go).
# Last line of a run: RESULT repo=<o/r> room=<id> souls=<a,b|-> main=<pane@session|->
# Tag + where (Nat 2026-11-09 "if /work or archive tag me let me see where go", "and then can you check like /ls"):
#   SOUL_TAG=<discord user id>  every line posted in the room ends with <@id>, so the caller is pinged there
#   SOUL_FROM=<channel id>      where the command was typed; when that is not the room, '<@id> 👉 <#room>' is posted there
#   when the run ends, the repo's part of `maw ls` is posted in the room (laris-team tools/room-ls.sh)
#   SOUL_CHILD=1                a step of a bigger command (/work's unarchive, room /done): tag only, no pointer, no view
# Any server's host (Nat 2026-11-10 "ahhh it still fixed always fixed for this?", "ok we fix?"): /work typed to another
# server's host bot (PhoneBooth in Phone booth Co Ltd) makes the room THERE, with that bot's row and voice. The plugin
# sets these when the bot that answered is a host (access.host); unset = Laris Labs Oracle in Laris Labs Ltd, as before.
#   SOUL_HOST=<oracle>          the bot: token pass discord/<oracle>-token, posts as it
#   SOUL_HOST_STATE=<dir>       its state dir name under ~/.claude/channels (default = SOUL_HOST), for access.local.json
#   SOUL_GUILD=<id>             its server; the room category is SOUL_PROMOTE_CATEGORY, else a category named "active"
#                               there, else "⚡ active" is created (on a run)
set -euo pipefail
HERE=${0:A:h}
TEAM=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}
HOST=${SOUL_HOST:-laris-labs-oracle}
source $HERE/bin/soul-host.zsh   # sh_state_dir: <bot> or <bot>-<machine>, newest status.json
HOSTDIR=${SOUL_HOST_STATE:-$(sh_state_dir $HOST)}
L=${HERDR_SOUL_LARIS:-$HOME/.claude/channels/$HOSTDIR/access.local.json}
LARIS_GUILD=1560847800881643520
GUILD=${SOUL_GUILD:-$LARIS_GUILD}
[[ $GUILD == $LARIS_GUILD ]] && ROOMCAT=${SOUL_PROMOTE_CATEGORY:-1568658399149821952} || ROOMCAT=${SOUL_PROMOTE_CATEGORY:-}   # ⚡ active
HNAME=${${HOST%-oracle}:-laris}; [[ $HOST == laris-labs-oracle ]] && HNAME=Laris || HNAME=${(C)HNAME}
PREFIX=${SOUL_CHPREFIX-📦・}
SAY=$TEAM/tools/discord-say.sh
source $HERE/bin/soul-tag.zsh   # TAG, FROM, soul_where <room> <repo> [<also-skip channel>]
ghq=$(ghq root)
REPO=""; YES=0; DRY=0; ORACLES=(); POST=""
for a in "$@"; do case $a in --yes) YES=1;; --dry) DRY=1;; --post=*) POST=${a#*=};; --*) echo "unknown $a"; exit 2;;
  *) if [[ -z $REPO ]]; then REPO=$a; else ORACLES+=${a%-oracle}-oracle; fi;; esac; done
(( DRY )) && YES=0
REPO=${REPO#https://github.com/}; REPO=${REPO#http://github.com/}; REPO=${REPO#github.com/}; REPO=${REPO%.git}; REPO=${REPO%/}
REPO=$(print -r -- $REPO | cut -d/ -f1-2)
[[ $REPO =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { echo "which repo? soul-work.sh <owner/repo | github url> [<oracle>...] [--yes]"; exit 2; }
ORACLES=(${(u)ORACLES})
R=$ghq/github.com/$REPO
LT=$(pass show discord/$HOST-token | head -1 | tr -d '[:space:]')
api() { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' -H 'User-Agent: soul-work (laris-co/soul-in-repo, 1)' "$@"; }
# the room category in another host's server: one whose name holds "active" (⚡ active), else made on a run
if [[ -z $ROOMCAT ]]; then
  ROOMCAT=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c 'import json,sys
c=[x for x in json.load(sys.stdin) if x.get("type")==4 and "active" in x.get("name","").lower()]
print(c[0]["id"] if c else "")' 2>/dev/null || true)
fi
(( YES )) && how=RUN || how="plan only"
vis=$(gh repo view $REPO --json visibility -q .visibility 2>/dev/null || true)
[[ -n $vis ]] || { echo "stop: $REPO not found on GitHub (or no access)"; exit 1; }
echo "work: $REPO (${vis:l}) · souls: ${(j:, :)ORACLES:-none} · $how · host $HOST${SOUL_HOST_CWD:+ (cwd from plugin)}"
if [[ -d $R/.git ]]; then echo "  1. repo: $R"; else echo "  1. repo: ghq get -p $REPO -> $R"; fi
CHN=${(L)REPO/\//∕}
CH=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c 'import json,sys
n=sys.argv[1]
hits=[c["id"] for c in json.load(sys.stdin) if c.get("type")==0 and (c.get("name","").lower()==n or c.get("name","").lower().endswith("・"+n))]
print(hits[0] if len(hits)==1 else ("MANY" if hits else ""))' "$CHN")
[[ $CH = MANY ]] && { echo "stop: more than one channel matches '$CHN'"; exit 1; }
have=$(python3 -c 'import json,sys
try: g=json.load(open(sys.argv[1])).get("groups",{})
except Exception: g={}
r=g.get(sys.argv[2]); print("NOROW" if r is None else ("ARCHIVED" if r.get("archived") else " ".join(r.get("souls",[]))))' $L ${CH:-none})
UNARCH=0
if [[ $have = ARCHIVED ]]; then   # Nat 2026-11-08 "work should auto unarchive?": yes, /work brings an archived room back
  # laris-team#210: /work = bring back. Its bodies WAKE where they slept (same conversation); a live one is skipped
  UNARCH=1; echo "  ♻️  room $CH is archived: /work unarchives it first (back on top of ⚡ active, bodies woken where they slept)"
  zsh $HERE/soul-archive.sh $REPO --unarchive --dry 2>&1 | sed -n '/^  [0-9]*\. /p' | sed 's/^  /     /' || true
  have=$(python3 -c 'import json,sys;print(" ".join(json.load(open(sys.argv[1]))["groups"][sys.argv[2]].get("archived_souls",[])))' $L $CH)
fi
[[ $have = NOROW ]] && insouls=() || insouls=(${=have})
todo=(${ORACLES:|insouls})
if [[ -n $CH ]]; then echo "  2. room: ♻️ <#$CH> exists -> reuse${${have:#NOROW}:+ (souls: ${(j:, :)insouls:-none})}"
else echo "  2. room: create '$PREFIX$CHN' under ⚡ active (${ROOMCAT:-new category}) in guild $GUILD + $HNAME row ($HOSTDIR)"; fi
# the host's own body runs in this repo's main (PhoneBooth in PhoneBooth-project/phonebooth-oracle): no second main agent,
# and its row must not forward the room to itself
# the host body's folder: SOUL_HOST_CWD from the plugin, else the cwd its own status.json records (met 2026-11-10: a
# /work typed in a PhoneBooth thread arrived without SOUL_HOST_CWD and pointed the row at PhoneBooth's own body again).
# Laris keeps its old behaviour (its laris-team room may rely on the forward), so the fallback is for other hosts only
[[ $HOST == laris-labs-oracle && -z ${SOUL_HOST_CWD:-} ]] && HOSTCWD='' || HOSTCWD=${SOUL_HOST_CWD:-$(python3 -c 'import json,sys
try: print(json.load(open(sys.argv[1])).get("cwd") or "")
except Exception: print("")' $HOME/.claude/channels/$HOSTDIR/status.json 2>/dev/null)}
SELFMAIN=0; [[ -n $HOSTCWD && ${HOSTCWD:A} == ${R:A} ]] && SELFMAIN=1
if (( SELFMAIN )); then mainplan="MAIN - skip main is the host's own body ($HOST)"
elif [[ -d $R/.git ]]; then mainplan=$(zsh $HERE/bin/main-pane $R | tail -1); else mainplan="MAIN - planned (after the clone)"; fi
echo "  4. main: ${mainplan#MAIN }"
for o in $todo; do echo "  5. soul $o: herdr-soul room $REPO $o --channel=${CH:-<new>} --yes"; done
(( ${#ORACLES} > ${#todo} )) && echo "     already in the room: ${(j:, :)${ORACLES:*insouls}}"

report() {   # $1 = repo path (may be missing in a plan)
  local d=$1 desc readme lines prs iss
  desc=$(gh repo view $REPO --json description -q '.description // ""' 2>/dev/null || true)
  prs=$(gh pr list -R $REPO --state open --json number -q length 2>/dev/null || echo "?")
  iss=$(gh issue list -R $REPO --state open --json number -q length 2>/dev/null || echo "?")
  echo "🛠️ **work: $REPO** (${vis:l})"
  [[ -n $desc ]] && echo "> $desc"
  if [[ -d $d/.git ]]; then
    readme=$(ls $d/README* 2>/dev/null | head -1 || true)
    [[ -n $readme ]] && { lines=$(grep -v -E '^\s*(#|$|<|!\[|\[!)' $readme | head -2 | cut -c1-160); [[ -n $lines ]] && print -r -- "$lines" | sed 's/^/- /'; }
    echo "**Last commits**"
    git -C $d log -5 --format='- `%h` %cs %s' origin/HEAD 2>/dev/null || git -C $d log -5 --format='- `%h` %cs %s'
  fi
  echo "**Open:** $prs PRs · $iss issues"
  if [[ -d $d/.git ]]; then
    echo '```'
    THREADS='{}' python3 $TEAM/tools/room-status.py $REPO 2>/dev/null | sed -n '1,12p' | grep -v '^STALE_COUNT' | cut -c1-110
    echo '```'
  fi
}
echo "  3. report (posted in the room):"
report $R | sed 's/^/     | /'
(( YES )) || { echo "plan only. To run (Nat's or catbutter's go): maw soul work $REPO${ORACLES:+ ${(j: :)ORACLES}} --yes"; exit 0; }

# ════ RUN ════
(( UNARCH )) && SOUL_CHILD=1 zsh $HERE/soul-archive.sh $REPO --unarchive --by=work --yes | grep -E '✓|✗|☀️|done:|stop' | sed 's/^/  unarchive: /' || true
[[ -d $R/.git ]] || { ghq get -p $REPO >/dev/null 2>&1 || ghq get $REPO >/dev/null 2>&1 || true; }
[[ -d $R/.git ]] || { echo "stop: could not clone $REPO"; exit 1; }
git -C $R fetch -q origin 2>/dev/null || true
echo "  ✓ repo $R"
if [[ -z $CH && -z $ROOMCAT ]]; then
  ROOMCAT=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels -d '{"name":"⚡ active","type":4}' \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
  [[ -n $ROOMCAT ]] || { echo "stop: could not create category '⚡ active' in guild $GUILD"; exit 1; }
  echo "  ✓ category '⚡ active' created: $ROOMCAT"
fi
if [[ -z $CH ]]; then
  CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"type":0,"parent_id":sys.argv[2],"topic":"repo "+sys.argv[3]+": /work room; one thread per oracle soul"}))' "$PREFIX$CHN" $ROOMCAT $REPO)" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
  [[ -n $CH ]] || { echo "stop: could not create channel '$PREFIX$CHN'"; exit 1; }
  echo "  ✓ channel '$PREFIX$CHN' created: $CH"
fi
if [[ $have = NOROW ]]; then
  [[ -f $L ]] || { (umask 077; print -r -- '{}' > $L); echo "  ✓ $L created"; }
  cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-work
  python3 - $L $CH "$CHN" $REPO $HNAME <<'PY'
import json,sys
f,ch,chn,repo,who=sys.argv[1:]; a=json.load(open(f)); g=a.setdefault("groups",{})
g.setdefault(ch,{"requireMention":False,"allowFrom":["691531480689541170","917019242094817301"],"layout":9,"channel":chn,
  "repo":repo,"souls":[],"threads":{},"note":f"repo channel {chn} (layout 9): opened by /work; {who} hears every line, answers only when tagged"})
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
  echo "  ✓ $HNAME row: channel $CH, repo $REPO"
fi
# --post=<channel or thread id> (Nat 2026-11-08 "/work . in the thread"): the report goes where /work was typed
BOT=$HOST $SAY ${POST:-$CH} "$(report $R | head -c $(( 1900 - ${#TAG} )))$TAG" --focus $REPO >/dev/null && echo "  ✓ report posted in <#${POST:-$CH}>"
# 4. main pane (#48): reuse or start; the room's root talks to it through the Laris row (forwardRoot, laris-team#241)
if (( SELFMAIN )); then MAINLINE="MAIN - skip main is the host's own body ($HOST)"; else MAINLINE=$(zsh $HERE/bin/main-pane $R --yes | tail -1); fi
MAIN=${${=MAINLINE}[2]}
echo "  ✓ main: ${MAINLINE#MAIN }"
PLUGDIR=${SOMSRI_PLUGIN_DIR:-$HOME/.claude/plugins/cache/claude-plugins-official/discord}
if [[ $MAIN != - && $MAINLINE != *skip* ]] && ! rg -q forwardRoot $PLUGDIR/*/server.ts(N) $PLUGDIR/*/laris/rowpolicy.ts(N) /dev/null 2>/dev/null; then
  echo "  -- Laris row not pointed at main: this machine's plugin has no forwardRoot (laris-team#241), a plain forwardTo would take threads too"
elif [[ $MAIN != - && $MAINLINE != *skip* ]]; then
  python3 - $L $CH $R <<'PY2'
import json,sys,shutil,time
f,ch,r=sys.argv[1:]; a=json.load(open(f)); row=a.get("groups",{}).get(ch)
if row is not None and not (row.get("forwardTo")==r and row.get("forwardRoot") is True):
    shutil.copy2(f, f+".bak-"+time.strftime("%Y%m%d-%H%M%S")+"-main")
    row["forwardTo"]=r; row["forwardRoot"]=True
    json.dump(a,open(f,"w"),indent=2,ensure_ascii=False); print("  ✓ Laris row: room root (untagged) -> main "+r)
PY2
fi
okso=()
if (( ${#todo} )); then
  zsh $HERE/bin/herdr-soul room $REPO $todo --channel=$CH --yes | grep -E 'done:|✗|stop|deny-main: main body on' || true
  now=$(python3 -c 'import json,sys
print(" ".join(json.load(open(sys.argv[1])).get("groups",{}).get(sys.argv[2],{}).get("souls",[])))' $L $CH)
  for o in $todo; do [[ " $now " = *" $o "* ]] && okso+=$o; done
fi
all=($insouls $okso); all=(${(u)all})
soul_where $CH $REPO $POST   # the herdr view in the room; the pointer where /work was typed (unless the report went there)
echo "RESULT repo=$REPO room=$CH souls=${${(j:,:)all}:--} main=${${MAIN:#-}:--}"
