#!/usr/bin/env zsh
# soul-archive.sh — ARCHIVE a finished repo room (Nat 2026-11-08 "we should have archive to handle this", issue #27).
#
#   soul-archive.sh <owner/repo> [--unarchive] [--by=<name>] [--yes]
#
# archive: 1 each soul: its pane closed, its own thread archived (worktree + branch stay)
#          2 each /wt thread (Laris forward row into <repo>/wt): unlinked (herdr-soul unlink: thread archived, row dropped),
#            its agent pane closed (worktree stays)
#          3 every other open thread of the room (office included) archived
#          4 the channel moves to 🗄️ Archive with an 'archived by <who>' line
#          5 Laris row: archived true, archived_souls = the souls, souls [] / threads {}, requireMention true (tag-only)
#          the repo is never touched. Nothing is deleted.
# --unarchive: channel back to ⚡ active, row live again (requireMention false); souls come back with /soul.
# Plan by default (GETs only); --yes runs (Nat's or catbutter's go). Last line: RESULT room=<id> state=archived|active
set -euo pipefail
HERE=${0:A:h}
L=${HERDR_SOUL_LARIS:-$HOME/.claude/channels/laris-labs-oracle/access.local.json}
GUILD=1560847800881643520
ARCH=${SOUL_ARCHIVE_CATEGORY:-1566648836359856249}    # 🗄️ Archive
ACTIVE=${SOUL_PROMOTE_CATEGORY:-1568658399149821952}  # ⚡ active
SAY=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}/tools/discord-say.sh
REPO=""; UN=0; YES=0; DRY=0; BY=Nat
for a in "$@"; do case $a in --yes) YES=1;; --dry) DRY=1;; --unarchive) UN=1;; --by=*) BY=${a#*=};;
  --*) echo "unknown $a"; exit 2;; *) REPO=$a;; esac; done
(( DRY )) && YES=0
[[ $REPO =~ '^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$' ]] || { echo "which repo? soul-archive.sh <owner/repo> [--unarchive] [--yes]"; exit 2; }
R=$(ghq root)/github.com/$REPO
LT=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
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
agent_in() { herdr agent list 2>/dev/null | python3 -c 'import json,sys
w=sys.argv[1]; print(next((x["pane_id"] for x in json.load(sys.stdin)["result"]["agents"] if x.get("cwd")==w),""))' $1; }

if (( UN )); then
  [[ $STATE = archived ]] || { echo "stop: room $CH of $REPO is not archived"; exit 1; }
  echo "unarchive: $REPO · room $CH · $how"
  echo "  1. channel back to ⚡ active ($ACTIVE), line 'unarchived by $BY'"
  back=$(python3 -c 'import json,sys;print(" ".join(json.load(open(sys.argv[1]))["groups"][sys.argv[2]].get("archived_souls",[])))' $L $CH)
  echo "  2. Laris row live again (archived off, requireMention false)"
  echo "  3. souls back online: ${back:-none} (each: its worktree reused, own thread, own bot, same conversation)"
  (( YES )) || { echo "plan only. To run (Nat's or catbutter's go): maw soul archive $REPO --unarchive --yes"; exit 0; }
  # back to ⚡ active AND on top of it, right under 📋 board (Nat 2026-11-08: "not same like unarchive ... on top in active";
  # a parent_id PATCH alone appends the channel at the bottom of the category)
  python3 - "$LT" $GUILD $CH $ACTIVE <<'PY2'
import json,sys,urllib.request
tok,g,ch,cat=sys.argv[1:]
H={"Authorization":"Bot "+tok,"Content-Type":"application/json","User-Agent":"soul-archive (laris-co/soul-in-repo, 1)"}
def req(u,m="GET",b=None):
    return urllib.request.urlopen(urllib.request.Request("https://discord.com/api/v10"+u,method=m,data=json.dumps(b).encode() if b is not None else None,headers=H),timeout=20)
chs=json.load(req(f"/guilds/{g}/channels"))
kids=sorted([c for c in chs if c.get("parent_id")==cat and c["id"]!=ch and c["type"] in (0,5,15)],key=lambda c:c["position"])
board=[c for c in kids if "board" in c["name"]]; rest=[c for c in kids if c not in board]
order=board+[{"id":ch}]+rest
body=[{"id":c["id"],"position":i,**({"parent_id":cat,"lock_permissions":False} if c["id"]==ch else {})} for i,c in enumerate(order)]
print("  ✓ channel to ⚡ active, on top (HTTP %d)" % req(f"/guilds/{g}/channels","PATCH",body).status)
PY2
  cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-unarchive
  python3 - $L $CH <<'PY'
import json,sys
f,ch=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]
r["archived"]=False; r["requireMention"]=False
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
  echo "  ✓ Laris row live"
  BOT=laris-labs-oracle $SAY $CH "📦 **unarchived** by $BY · souls coming back: ${back:-none}" >/dev/null && echo "  ✓ line in the room"
  for o in ${=back}; do
    if zsh $HERE/bin/herdr-soul in $o $REPO --channel=$CH --deny-main 2>&1 | grep -E 'done:|✗|stop' | sed "s/^/  $o: /"; then :; fi
  done
  python3 -c 'import json,sys
f,ch=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]; r["archived_souls"]=[o for o in r.get("archived_souls",[]) if o not in r.get("souls",[])]
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)' $L $CH
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
echo "archive: $REPO · room $CH · $how"
n=1
for p in $pairs; do o=${p%%=*}; t=${p#*=}; echo "  $n. soul $o: close pane ${$(agent_in $R/wt/$o-soul):-(none)}, archive its thread $t (worktree stays)"; n=$((n+1)); done
for w in $wts; do echo "  $n. worktree ${w:t}: unlink (thread archived, row dropped), close pane ${$(agent_in $w):-(none)} (worktree stays)"; n=$((n+1)); done
for o in $others; do echo "  $n. thread '${o#* }' (${o%% *}): archive"; n=$((n+1)); done
echo "  $n. channel to 🗄️ Archive ($ARCH), line 'archived by $BY'"; n=$((n+1))
snames=(${pairs%%=*}); echo "  $n. Laris row: archived, archived_souls = ${${(j:, :)snames}:-none}, tag-only (backup first)"
echo "     then the repo's herdr anchor space closes when nothing is left under it
     the repo $REPO is not touched; nothing is deleted"
(( YES )) || { echo "plan only. To run (Nat's or catbutter's go): maw soul archive $REPO --yes"; exit 0; }

for p in $pairs; do
  o=${p%%=*}; t=${p#*=}; P=$(agent_in $R/wt/$o-soul)
  [[ -n $P ]] && herdr pane close $P >/dev/null 2>&1 && echo "  ✓ $o: pane $P closed"
  api -o /dev/null -w "  ✓ $o: thread $t archived (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/$t -d '{"archived":true}'
done
for w in $wts; do
  zsh $HERE/bin/herdr-soul unlink $w --bot=laris-labs-oracle --yes 2>&1 | grep -E '✓|✗' | sed "s/^/  ${w:t}: /" || true
  P=$(agent_in $w); [[ -n $P ]] && herdr pane close $P >/dev/null 2>&1 && echo "  ✓ ${w:t}: pane $P closed"
done
for o in $others; do api -o /dev/null -w "  ✓ thread '${o#* }' archived (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/${o%% *} -d '{"archived":true}'; done
BOT=laris-labs-oracle $SAY $CH "🗄️ **archived** by $BY · souls out, threads archived, worktrees + repo kept (nothing deleted) · \`/archive\` here brings it back" >/dev/null && echo "  ✓ line in the room"
api -o /dev/null -w "  ✓ channel to 🗄️ Archive (HTTP %{http_code})\n" -X PATCH https://discord.com/api/v10/channels/$CH -d "{\"parent_id\":\"$ARCH\"}"
cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-archive
python3 - $L $CH <<'PY'
import json,sys
f,ch=sys.argv[1:]; a=json.load(open(f)); r=a["groups"][ch]
r["archived_souls"]=sorted(set(r.get("archived_souls",[]))|set(r.get("souls",[])))
r["archived_threads"]={**r.get("archived_threads",{}),**r.get("threads",{})}
r.update(archived=True, souls=[], threads={}, requireMention=True)
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
echo "  ✓ Laris row archived (backup beside $L)"
zsh $HERE/bin/anchor-close $R || true   # the repo's empty anchor space goes too (#25 follow-up)
echo "RESULT room=$CH state=archived"
