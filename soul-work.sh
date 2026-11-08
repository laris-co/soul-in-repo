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
# 4 souls   each <oracle> not in the room yet: herdr-soul room <repo> <oracle> --channel=<id> --yes
# Plan by default: the report is printed, nothing is created or posted. --yes runs (Nat's or catbutter's go).
# Last line of a run: RESULT repo=<o/r> room=<id> souls=<a,b|->
set -euo pipefail
HERE=${0:A:h}
TEAM=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}
L=${HERDR_SOUL_LARIS:-$HOME/.claude/channels/laris-labs-oracle/access.local.json}
GUILD=1560847800881643520
ROOMCAT=${SOUL_PROMOTE_CATEGORY:-1568658399149821952}   # ⚡ active
PREFIX=${SOUL_CHPREFIX-📦・}
SAY=$TEAM/tools/discord-say.sh
ghq=$(ghq root)
REPO=""; YES=0; DRY=0; ORACLES=()
for a in "$@"; do case $a in --yes) YES=1;; --dry) DRY=1;; --*) echo "unknown $a"; exit 2;;
  *) if [[ -z $REPO ]]; then REPO=$a; else ORACLES+=${a%-oracle}-oracle; fi;; esac; done
(( DRY )) && YES=0
REPO=${REPO#https://github.com/}; REPO=${REPO#http://github.com/}; REPO=${REPO#github.com/}; REPO=${REPO%.git}; REPO=${REPO%/}
REPO=$(print -r -- $REPO | cut -d/ -f1-2)
[[ $REPO =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { echo "which repo? soul-work.sh <owner/repo | github url> [<oracle>...] [--yes]"; exit 2; }
ORACLES=(${(u)ORACLES})
R=$ghq/github.com/$REPO
LT=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
api() { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' -H 'User-Agent: soul-work (laris-co/soul-in-repo, 1)' "$@"; }
(( YES )) && how=RUN || how="plan only"
vis=$(gh repo view $REPO --json visibility -q .visibility 2>/dev/null || true)
[[ -n $vis ]] || { echo "stop: $REPO not found on GitHub (or no access)"; exit 1; }
echo "work: $REPO (${vis:l}) · souls: ${(j:, :)ORACLES:-none} · $how"
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
[[ $have = ARCHIVED ]] && { echo "stop: room $CH is archived: /archive there brings it back first"; exit 1; }
[[ $have = NOROW ]] && insouls=() || insouls=(${=have})
todo=(${ORACLES:|insouls})
if [[ -n $CH ]]; then echo "  2. room: ♻️ <#$CH> exists -> reuse${${have:#NOROW}:+ (souls: ${(j:, :)insouls:-none})}"
else echo "  2. room: create '$PREFIX$CHN' under ⚡ active + Laris row"; fi
for o in $todo; do echo "  4. soul $o: herdr-soul room $REPO $o --channel=${CH:-<new>} --yes"; done
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
[[ -d $R/.git ]] || { ghq get -p $REPO >/dev/null 2>&1 || ghq get $REPO >/dev/null 2>&1 || true; }
[[ -d $R/.git ]] || { echo "stop: could not clone $REPO"; exit 1; }
git -C $R fetch -q origin 2>/dev/null || true
echo "  ✓ repo $R"
if [[ -z $CH ]]; then
  CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"type":0,"parent_id":sys.argv[2],"topic":"repo "+sys.argv[3]+": /work room; one thread per oracle soul"}))' "$PREFIX$CHN" $ROOMCAT $REPO)" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
  [[ -n $CH ]] || { echo "stop: could not create channel '$PREFIX$CHN'"; exit 1; }
  echo "  ✓ channel '$PREFIX$CHN' created: $CH"
fi
if [[ $have = NOROW ]]; then
  cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-work
  python3 - $L $CH "$CHN" $REPO <<'PY'
import json,sys
f,ch,chn,repo=sys.argv[1:]; a=json.load(open(f)); g=a.setdefault("groups",{})
g.setdefault(ch,{"requireMention":False,"allowFrom":["691531480689541170","917019242094817301"],"layout":9,"channel":chn,
  "repo":repo,"souls":[],"threads":{},"note":f"repo channel {chn} (layout 9): opened by /work; Laris hears every line, answers only when tagged"})
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
  echo "  ✓ Laris row: channel $CH, repo $REPO"
fi
BOT=laris-labs-oracle $SAY $CH "$(report $R | head -c 1900)" >/dev/null && echo "  ✓ report posted in <#$CH>"
okso=()
if (( ${#todo} )); then
  zsh $HERE/bin/herdr-soul room $REPO $todo --channel=$CH --yes | grep -E 'done:|✗|stop|deny-main: main body on' || true
  now=$(python3 -c 'import json,sys
print(" ".join(json.load(open(sys.argv[1])).get("groups",{}).get(sys.argv[2],{}).get("souls",[])))' $L $CH)
  for o in $todo; do [[ " $now " = *" $o "* ]] && okso+=$o; done
fi
all=($insouls $okso); all=(${(u)all})
echo "RESULT repo=$REPO room=$CH souls=${${(j:,:)all}:--}"
