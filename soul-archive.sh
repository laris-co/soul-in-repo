#!/usr/bin/env zsh
# soul-archive.sh — ARCHIVE a finished repo room (Nat 2026-11-08 "we should have archive to handle this", issue #27).
#
#   soul-archive.sh <owner/repo> [--unarchive] [--by=<name>] [--yes]
#
# archive (= /done in the room, laris-co/laris-team#210):
#          1 each soul: its body 💤 sleeps ON ITS OWN MACHINE (here: laris-team tools/space-sleep.sh sleep --close; other
#            box, config.yaml machine:: that box's laris-team agent is asked by herdr prompt, never ssh), its own thread
#            archived (worktree + branch stay)
#          2 each /wt thread (Laris forward row into <repo>/wt): idle agent -> unlinked (thread archived, row dropped) and
#            💤 slept; busy agent -> kept with its thread (it may be making the PR), named in the archive line
#          3 the main checkout agent: idle -> 💤 slept (space closed); busy -> kept, named ("main still working")
#          4 every other open thread of the room (office included) archived
#          5 the channel moves to 🗄️ Archive with an 'archived by <who>' line
#          6 Laris row: archived true, archived_souls = the souls, archived_bodies = where each slept body lives
#            ({who, kind, cwd, machine, label, session}), souls [] / threads {}, requireMention true (tag-only)
#          the plan names any text typed in a pane and not sent (the sleep's /exit would drop it).
#          Worktrees and the repo are never removed. Nothing is deleted.
# --unarchive (= /work on the room): channel back to ⚡ active, row live again (requireMention false), then WAKE, never
#          start fresh: each recorded soul / main body wakes on the machine it slept on (--resume, same conversation),
#          skipped when a live body already runs there or here (herdr agent list by cwd), so never a second body.
#          Souls of an old archive (no record) come back with herdr-soul in, after the same live-body check.
# Plan by default (GETs only); --yes runs (Nat's or catbutter's go). Last line: RESULT room=<id> state=archived|active
# Tag + where (Nat 2026-11-09 "if /work or archive tag me let me see where go", "and then can you check like /ls"):
#   SOUL_TAG=<discord user id>  every line posted in the room ends with <@id>, so the caller is pinged there
#   SOUL_FROM=<channel id>      where the command was typed; when that is not the room, '<@id> 👉 <#room>' is posted there
#   when the run ends, the repo's part of `maw ls` is posted in the room (laris-team tools/room-ls.sh)
#   SOUL_CHILD=1                a step of a bigger command (/work's unarchive, room /done): tag only, no pointer, no view
set -euo pipefail
HERE=${0:A:h}
source $HERE/bin/soul-host.zsh   # SH_BOT / SH_ACC / SH_GUILD: Laris unless another server's host runs this
L=${HERDR_SOUL_LARIS:-$SH_ACC}
GUILD=$SH_GUILD
ARCH=${SOUL_ARCHIVE_CATEGORY:-$(sh_cat 1566648836359856249 archive)}    # 🗄️ Archive
ACTIVE=${SOUL_PROMOTE_CATEGORY:-$(sh_cat 1568658399149821952 active)}  # ⚡ active
TEAM=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}
SAY=$TEAM/tools/discord-say.sh
SP=${SOUL_SPACE_SLEEP:-$TEAM/tools/space-sleep.sh}   # sleep / wake / where / draft / on <machine> (laris-team)
source $HERE/bin/soul-tag.zsh   # TAG, FROM, soul_where <room> <repo> [<also-skip channel>]
HOST=$(hostname -s)
REPO=""; UN=0; YES=0; DRY=0; BY=Nat
for a in "$@"; do case $a in --yes) YES=1;; --dry) DRY=1;; --unarchive) UN=1;; --by=*) BY=${a#*=};;
  --*) echo "unknown $a"; exit 2;; *) REPO=$a;; esac; done
(( DRY )) && YES=0
[[ $REPO =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { echo "which repo? soul-archive.sh <owner/repo> [--unarchive] [--yes]"; exit 2; }
R=$(ghq root)/github.com/$REPO
LT=$(sh_token)
api() { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' -H 'User-Agent: soul-archive (laris-co/soul-in-repo, 1)' "$@"; }
row=$(python3 - $L $REPO <<'PY'
import json,sys
f,repo=sys.argv[1:]
g=json.load(open(f)).get("groups",{})
hits=[(k,v) for k,v in g.items() if v.get("layout")==9 and str(v.get("repo","")).lower()==repo.lower()]
if len(hits)!=1: print("ERR %d layout-9 rows for %s" % (len(hits),repo)); sys.exit()
k,v=hits[0]
print(k, "archived" if v.get("archived") else "active", " ".join(f"{o}={t}" for o,t in (v.get("threads") or {}).items()))
PY
)
[[ $row = ERR* ]] && { echo "stop: ${row#ERR }"; exit 1; }
CH=${row%% *}; rest=${row#* }; STATE=${rest%% *}; pairs=(${=${rest#$STATE}})
(( YES )) && how=RUN || how="plan only"
# the herdr machine label of an oracle's config.yaml machine: ("" = this box)
mlabel() { local m; m=$(sed -n 's/^machine: *\([^ #]*\).*/\1/p' $TEAM/oracles/$1/config.yaml 2>/dev/null | head -1)
  [[ -z $m || $m = $HOST ]] && return 0; local l; l=$(bash $SP machine $m 2>/dev/null || true); [[ $l = local ]] || print -r -- $l; }
# bodyat <cwd> [labels]: "<local|label> <pane> <status> <session>" or "none"
bodyat() { bash $SP where "$@" 2>/dev/null || echo none; }
draftof() { local d; d=$(bash $SP draft $1 ${2:-local} 2>/dev/null || true); [[ -n $d ]] && print -r -- " ⚠️ typed, not sent: '$d' (the sleep drops it)"; true; }

if (( UN )); then
  [[ $STATE = archived ]] || { echo "stop: room $CH of $REPO is not archived"; exit 1; }
  echo "unarchive: $REPO · room $CH · $how"
  echo "  1. channel back to ⚡ active ($ACTIVE), line 'unarchived by $BY'"
  echo "  2. Laris row live again (archived off, requireMention false)"
  back=(${=$(python3 -c 'import json,sys;print(" ".join(json.load(open(sys.argv[1]))["groups"][sys.argv[2]].get("archived_souls",[])))' $L $CH)})
  # bodies recorded by the archive: <who>\t<kind>\t<cwd>\t<machine>\t<label>
  bodies=(${(f)"$(python3 - $L $CH <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))["groups"][sys.argv[2]]
for b in r.get("archived_bodies",[]):
    print("\t".join([b.get("who") or "-",b.get("kind") or "-",b.get("cwd") or "-",b.get("machine") or "local",b.get("label") or "-"]))
PY
)"}); [[ -z ${bodies[1]:-} ]] && bodies=()
  n=3; wake=(); wnames=(); restore=(); fresh=(); seen=()
  for b in $bodies; do
    IFS=$'\t' read -r who kind cwd mach lab <<< "$b"
    [[ $mach = $HOST ]] && mach=local
    probe=(); [[ $mach != local ]] && probe+=$mach; [[ $kind = soul ]] && probe+=($(mlabel $who))
    [[ $kind = soul ]] && seen+=$who
    live=$(bodyat $cwd $probe)
    if [[ $live != none ]]; then
      echo "  $n. $kind $who: already awake on ${${live%% *}/local/$HOST} (${${live#* }%% *}) → skip, no second body"
      [[ $kind = soul ]] && restore+=$who
    elif [[ $kind = wt ]]; then echo "  $n. worktree ${cwd:t}: stays asleep (its thread was unlinked; /ls ☀️ wakes it)"
    else echo "  $n. $kind $who: ☀️ wake on ${mach/local/$HOST} ($lab, same conversation)"; wake+=$b; wnames+=$who; [[ $kind = soul ]] && restore+=$who
    fi; n=$((n+1))
  done
  for o in $back; do
    (( ${seen[(Ie)$o]} )) && continue
    live=$(bodyat $R/wt/$o-soul $(mlabel $o))
    if [[ $live != none ]]; then echo "  $n. soul $o: already awake on ${${live%% *}/local/$HOST} (${${live#* }%% *}) → skip, no second body"; restore+=$o
    else echo "  $n. soul $o: no sleep record (older archive) → herdr-soul in (its worktree reused, same conversation)"; fresh+=$o; fi
    n=$((n+1))
  done
  (( YES )) || { echo "plan only. To run (Nat's or catbutter's go): maw soul archive $REPO --unarchive --yes"; exit 0; }
  # back to ⚡ active AND on top of it, right under 📋 board (Nat 2026-11-08: "not same like unarchive ... on top in active";
  # a parent_id PATCH alone appends the channel at the bottom of the category)
  python3 - "$LT" $GUILD $CH $ACTIVE <<'PY2'
import json,os,sys,urllib.request
tok,g,ch,cat=sys.argv[1:]
H={"Authorization":"Bot "+tok,"Content-Type":"application/json","User-Agent":"soul-archive (laris-co/soul-in-repo, 1)"}
def req(u,m="GET",b=None):
    return urllib.request.urlopen(urllib.request.Request(os.environ.get("SOUL_DISCORD_API","https://discord.com/api/v10")+u,method=m,data=json.dumps(b).encode() if b is not None else None,headers=H),timeout=20)
try: chs=json.load(req(f"/guilds/{g}/channels"))
except Exception as e: print("  ✗ channel not moved (%s): move it to ⚡ active by hand" % e); sys.exit()
kids=sorted([c for c in chs if c.get("parent_id")==cat and c["id"]!=ch and c["type"] in (0,5,15)],key=lambda c:c["position"])
board=[c for c in kids if "board" in c["name"]]; rest=[c for c in kids if c not in board]
order=board+[{"id":ch}]+rest
body=[{"id":c["id"],"position":i,**({"parent_id":cat,"lock_permissions":False} if c["id"]==ch else {})} for i,c in enumerate(order)]
print("  ✓ channel to ⚡ active, on top (HTTP %d)" % req(f"/guilds/{g}/channels","PATCH",body).status)
PY2
  cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-unarchive
  # live again; souls that wake (or are awake) get their row place and thread back
  python3 - $L $CH ${restore} <<'PY'
import json,sys,time
f,ch,*back=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]
r["archived"]=False; r["requireMention"]=False
r["unarchived_at"]=time.strftime("%Y-%m-%dT%H:%M:%S%z")   # for /recent
at=r.get("archived_threads",{})
r["souls"]=sorted(set(r.get("souls",[]))|set(back))
r["threads"]={**r.get("threads",{}),**{o:at[o] for o in back if o in at}}
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
  echo "  ✓ Laris row live"
  for o in $restore; do
    t=$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["groups"][sys.argv[2]].get("threads",{}).get(sys.argv[3],""))' $L $CH $o)
    [[ -n $t ]] && api -o /dev/null -w "  ✓ $o: thread $t open again (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/$t -d '{"archived":false}' || true
  done
  BOT=$SH_BOT $SAY $CH "📦 **unarchived** by $BY · waking: ${${(j:, :)wnames}:-none}${fresh:+ · back in: ${(j:, :)fresh}}$TAG" >/dev/null && echo "  ✓ line in the room"
  for b in $wake; do
    IFS=$'\t' read -r who kind cwd mach lab <<< "$b"
    [[ $mach = $HOST ]] && mach=local
    if [[ $mach = local ]]; then bash $SP wake $lab 2>&1 | tail -1 | sed "s/^/  ☀️ $who: /" || true
    else bash $SP on $mach wake $lab --say=$CH 2>&1 | tail -1 | sed "s/^/  ☀️ $who: /" || true; fi
  done
  for o in $fresh; do
    if zsh $HERE/bin/herdr-soul in $o $REPO --channel=$CH --deny-main 2>&1 | grep -E 'done:|✗|stop' | sed "s/^/  $o: /"; then :; fi
  done
  python3 -c 'import json,sys
f,ch=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]; r["archived_souls"]=[o for o in r.get("archived_souls",[]) if o not in r.get("souls",[])]
r["archived_bodies"]=[b for b in r.get("archived_bodies",[]) if b.get("kind")=="wt"]
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)' $L $CH
  soul_where $CH $REPO
  echo "RESULT room=$CH state=active"; exit 0
fi

[[ $STATE = archived ]] && { echo "stop: room $CH of $REPO is archived already (--unarchive brings it back)"; exit 1; }
# /wt threads: Laris forward rows into <repo>/wt (not souls)
wts=(${(f)"$(python3 - $L "$R/wt/" <<'PY'
import json,sys
f,pre=sys.argv[1:]
for k,v in json.load(open(f)).get("groups",{}).items():
    w=v.get("forwardTo","")
    if w.startswith(pre) and not w.endswith("-soul"): print(w)
PY
)"}); [[ -z ${wts[1]:-} ]] && wts=()
# every other open thread of the room
others=(${(f)"$(api https://discord.com/api/v10/guilds/$GUILD/threads/active | python3 -c 'import json,sys
ch=sys.argv[1]; skip=set(sys.argv[2:])
for t in json.load(sys.stdin).get("threads",[]):
    if t.get("parent_id")==ch and t["id"] not in skip: print(t["id"]+" "+t.get("name",""))' $CH ${pairs#*=})"}); [[ -z ${others[1]:-} ]] && others=()
idle() { [[ $1 = idle || $1 = done ]]; }
on() { [[ $1 = local ]] && print -r -- $HOST || print -r -- $1; }
typeset -A LOC   # body cwd -> "<local|label> <pane> <status> <session>" | none
echo "archive: $REPO · room $CH · $how"
n=1
for p in $pairs; do
  o=${p%%=*}; t=${p#*=}; c=$R/wt/$o-soul; LOC[$c]=$(bodyat $c $(mlabel $o)); l=(${=LOC[$c]})
  if [[ $l[1] = none ]]; then b="no live body"
  elif idle $l[3]; then b="💤 sleeps on $(on $l[1]) ($l[2], space closed)$(draftof $l[2] $l[1])"
  else b="body $l[2] on $(on $l[1]) is $l[3]: kept running (a working agent is not put to sleep)"; fi
  echo "  $n. soul $o: $b; its thread $t archived (worktree stays)"; n=$((n+1))
done
for w in $wts; do
  LOC[$w]=$(bodyat $w); l=(${=LOC[$w]})
  if [[ $l[1] = none ]]; then echo "  $n. worktree ${w:t}: unlink (thread archived, row dropped), no agent (worktree stays)"
  elif idle $l[3]; then echo "  $n. worktree ${w:t}: unlink (thread archived, row dropped), agent $l[2] 💤 sleeps$(draftof $l[2]) (worktree stays)"
  else echo "  $n. worktree ${w:t}: agent $l[2] is $l[3]: kept with its thread (it may be opening the PR)"; fi
  n=$((n+1))
done
LOC[$R]=$(bodyat $R); l=(${=LOC[$R]})
if [[ $l[1] = none ]]; then :
elif idle $l[3]; then echo "  $n. main checkout agent $l[2]: 💤 sleeps (same conversation on /work)$(draftof $l[2])"; n=$((n+1))
else echo "  $n. main checkout agent $l[2] is $l[3]: kept, named in the archive line (main still working)"; n=$((n+1)); fi
for o in $others; do echo "  $n. thread '${o#* }' (${o%% *}): archive"; n=$((n+1)); done
echo "  $n. channel to 🗄️ Archive ($ARCH), line 'archived by $BY'"; n=$((n+1))
snames=(${pairs%%=*}); echo "  $n. Laris row: archived, archived_souls = ${${(j:, :)snames}:-none} + where each body slept (backup first)"
echo "     then the repo's herdr anchor space closes when nothing is left under it
     /work on this room wakes them on their own machines; the repo $REPO is not touched; nothing is deleted"
(( YES )) || { echo "plan only. To run (Nat's or catbutter's go): maw soul archive $REPO --yes"; exit 0; }

REC=$(mktemp); asleep=(); kept=()
# sleep <who> <kind> <cwd> [--close]: local now, another box through its agent; a slept body is recorded for /work
nap() {
  local who=$1 kind=$2 c=$3 cl=${4:-} l out lab; l=(${=LOC[$c]})
  [[ $l[1] = none ]] && return 0
  idle $l[3] || { kept+="$who ($l[2] $l[3])"; return 0; }
  lab=$(bash $SP label $c)
  if [[ $l[1] = local ]]; then
    out=$(bash $SP sleep $l[2] $cl 2>&1 | tail -1); echo "  💤 $who: $out"
    [[ $out = *slept* ]] || { kept+="$who ($l[2]: sleep refused)"; return 0; }
  else
    out=$(bash $SP on $l[1] sleep $l[2] $cl --say=$CH 2>&1 | tail -1); echo "  💤 $who: $out"
    [[ $out = asked* ]] || { kept+="$who ($l[2] on $l[1]: not asked)"; return 0; }
  fi
  asleep+="$who${${l[1]:#local}:+ on $l[1]}"
  print -r -- "$who"$'\t'"$kind"$'\t'"$c"$'\t'"$(on $l[1])"$'\t'"$lab"$'\t'"$l[4]" >> $REC
}
for p in $pairs; do
  o=${p%%=*}; t=${p#*=}; nap $o soul $R/wt/$o-soul --close
  api -o /dev/null -w "  ✓ $o: thread $t archived (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/$t -d '{"archived":true}'
done
for w in $wts; do
  l=(${=LOC[$w]})
  if [[ $l[1] != none ]] && ! idle $l[3]; then kept+="${w:t} ($l[2] $l[3])"; continue; fi
  zsh $HERE/bin/herdr-soul unlink $w --bot=$SH_BOT --yes 2>&1 | grep -E '✓|✗' | sed "s/^/  ${w:t}: /" || true
  nap ${w:t} wt $w --close
done
nap main main $R   # space kept here: anchor-close below closes it when nothing is left under it
for o in $others; do api -o /dev/null -w "  ✓ thread '${o#* }' archived (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/${o%% *} -d '{"archived":true}'; done
mainline=""; [[ -n ${(M)kept:#main *} ]] && mainline=" · main still working: ${${(M)kept:#main *}#main }"
others_kept=(${kept:#main *})
BOT=$SH_BOT $SAY $CH "🗄️ **archived** by $BY · 💤 asleep: ${${(j:, :)asleep}:-none}${others_kept:+ · kept (working): ${(j:, :)others_kept}}$mainline · worktrees + repo kept (nothing deleted) · \`/work\` here wakes them$TAG" >/dev/null && echo "  ✓ line in the room"
api -o /dev/null -w "  ✓ channel to 🗄️ Archive (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/$CH -d "{\"parent_id\":\"$ARCH\"}"
cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-archive
python3 - $L $CH $REC <<'PY'
import json,sys,time
f,ch,rec=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]
new=[dict(zip(["who","kind","cwd","machine","label","session"],l.rstrip("\n").split("\t"))) for l in open(rec) if l.strip()]
old=[b for b in r.get("archived_bodies",[]) if b.get("cwd") not in {n["cwd"] for n in new}]
r["archived_bodies"]=old+new
r["archived_souls"]=sorted(set(r.get("archived_souls",[]))|set(r.get("souls",[])))
r["archived_threads"]={**r.get("archived_threads",{}),**r.get("threads",{})}
r.update(archived=True, souls=[], threads={}, requireMention=True, archived_at=time.strftime("%Y-%m-%dT%H:%M:%S%z"))   # for /recent
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
rm -f $REC
echo "  ✓ Laris row archived (backup beside $L)"
zsh $HERE/bin/anchor-close $R || true   # the repo's anchor space goes too once its main agent sleeps (#25, laris-team#210)
soul_where $CH $REPO
echo "RESULT room=$CH state=archived${kept:+ kept=${(j:,:)${kept%% *}}}"
