#!/usr/bin/env zsh
# soul-promote.sh — PROMOTE: a Discord talk thread becomes a repo with its own room (Nat 2026-11-08 "build and merge
# all please asap", via Laris, after the promote-demo run by hand that morning: thread 1568876528010268692 ->
# nat-build-with-oracle/promote-demo).
#
#   soul-promote.sh <thread-id> [<oracle>...] [--owner=<owner>] [--name=<repo>] [--public] [--yes]
#
# 1 name  from the thread name: an icon prefix '🧬・' and a leading '!!' are dropped, then lowercase-dash
#         ('ESP32 beacon' -> esp32-beacon). --name=<repo> sets it.
# 2 repo  <owner>/<name> (--owner=, default nat-build-with-oracle): gh repo create, private unless --public, or reuse it
#         when it exists (its visibility is never changed); ghq get; wt/ and .discord/ ignored.
# 3 save  maw atlas download <thread> -> origin/thread.md (readable) + origin/messages.jsonl (raw) + origin/attachments/,
#         secret scan BEFORE anything is created, then commit + push. An existing checkout that is dirty or off its
#         default branch is left alone: the files stay in a temp folder and the path is printed.
# 4 room  channel '📦・<owner>∕<name>' found by name (as soul-in-repo.sh does) or created under ⚡ active (where Nat
#         keeps the live repo rooms; Nat 2026-11-08: "i can not see that promote" when it sat in 📦 repos); a Laris row
#         (layout 9, souls []) when it has none. Each <oracle> given comes in with herdr-soul room <repo> <oracle>...
#         --channel=<id> --yes (its own thread and worktree); a soul already in the room is skipped. No oracle = room
#         only: /soul or maw soul room adds souls later.
# 5 link  as Laris: '📦 moved to <#room>' in the thread, then archive it (Nothing is Deleted: one message brings it
#         back); a first line in a room this run created.
# Refused: soul threads, worktree threads, the office, repo channels. Plan by default: lookups are GETs, nothing is
# written. --yes runs (Nat's or catbutter's go). Last line of a run: RESULT repo=<o/r> room=<id> from=<id> souls=<a,b|->
set -euo pipefail
HERE=${0:A:h}
TEAM=${HERDR_SOUL_TEAM:-/opt/Code/github.com/laris-co/laris-team}
L=${HERDR_SOUL_LARIS:-$HOME/.claude/channels/laris-labs-oracle/access.local.json}
GUILD=1560847800881643520; NAT=691531480689541170; CB=917019242094817301
ROOMCAT=${SOUL_PROMOTE_CATEGORY:-1568658399149821952}  # ⚡ active (📦 repos 1568651567144374314 holds parked rooms)
PREFIX=${SOUL_CHPREFIX-📦・}                          # icon prefix for a NEW channel (same as soul-in-repo.sh)
OWNER=${SOUL_PROMOTE_OWNER:-nat-build-with-oracle}
SAY=$TEAM/tools/discord-say.sh
ghq=$(ghq root)
TH=""; NAME=""; PRIV=1; VISSET=0; YES=0; DRY=0; ORACLES=()
for a in "$@"; do case $a in
  --yes) YES=1;; --dry) DRY=1;; --owner=*) OWNER=${a#*=};; --name=*) NAME=${a#*=};;
  --private) PRIV=1; VISSET=1;; --public) PRIV=0; VISSET=1;;
  -h|--help) sed -n 2,23p $0; exit 0;;
  --*) echo "unknown $a"; echo "  soul-promote.sh <thread-id> [<oracle>...] [--owner=<owner>] [--name=<repo>] [--public] [--yes]"; exit 2;;
  *) if [[ -z $TH ]]; then TH=$a; else ORACLES+=${a%-oracle}-oracle; fi;; esac; done
(( DRY )) && YES=0
[[ $TH = <-> && ${#TH} -ge 15 ]] || { echo "which thread? soul-promote.sh <thread-id> [<oracle>...] [--owner=<owner>] [--name=<repo>] [--yes]"; exit 2; }
[[ $OWNER =~ '^[A-Za-z0-9][A-Za-z0-9-]{0,38}$' ]] || { echo "--owner=<github owner>, not '$OWNER'"; exit 2; }
[[ -z $NAME || $NAME =~ '^[A-Za-z0-9._-]{1,100}$' ]] || { echo "--name=<repo>: letters, digits, '.', '_' and '-', not '$NAME'"; exit 2; }
ORACLES=(${(u)ORACLES})
LT=$(pass show discord/laris-labs-oracle-token | head -1 | tr -d '[:space:]')
[[ -n $LT ]] || { echo "stop: no pass discord/laris-labs-oracle-token"; exit 1; }
api() { curl -sS -H "Authorization: Bot $LT" -H 'Content-Type: application/json' -H 'User-Agent: soul-promote (laris-co/soul-in-repo, 1)' "$@"; }
soul_dir() { local s=$(sed -n 's/^soul: *"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' $TEAM/oracles/$1/config.yaml 2>/dev/null | head -1 | sed "s#{ghq}#$ghq#")
  echo ${s:-$ghq/github.com/laris-co/$1}; }
(( YES )) && how=RUN || how="plan only"

# ── 1. the thread and its name ──
info=$(api https://discord.com/api/v10/channels/$TH | python3 -c '
import json,sys
d=json.load(sys.stdin)
if d.get("type") not in (10,11,12): print("ERR %s is not a thread (%s)" % (sys.argv[1], d.get("message") or "type %s" % d.get("type"))); sys.exit()
if d.get("guild_id")!=sys.argv[2]: print("ERR thread %s is not in the Laris Co guild" % sys.argv[1]); sys.exit()
m=d.get("thread_metadata",{})
print(d.get("parent_id","-"), "archived" if m.get("archived") else "open", d.get("message_count",0), d.get("name",""))' $TH $GUILD)
[[ $info = ERR* ]] && { echo "stop: ${info#ERR }"; exit 1; }
PARENT=${info%% *}; rest=${info#* }; TSTATE=${rest%% *}; rest=${rest#* }; TCOUNT=${rest%% *}; TNAME=${rest#* }
PNAME=$(api https://discord.com/api/v10/channels/$PARENT | python3 -c 'import json,sys;print(json.load(sys.stdin).get("name","?"))' 2>/dev/null || echo "?")
guard=$(python3 - $L $TH <<'PY'
import json,sys
f,t=sys.argv[1:]
try: g=json.load(open(f)).get("groups",{})
except Exception: g={}
for k,v in g.items():
    th=v.get("threads") or {}
    if v.get("layout")==9 and t in th.values():
        print("soul thread (%s in %s)" % (next(o for o,x in th.items() if x==t), v.get("repo","?"))); sys.exit()
r=g.get(t) or {}
if r.get("forwardTo"): print("worktree thread (forwards to %s)" % r["forwardTo"])
elif r.get("layout")==9: print("repo channel")
PY
)
[[ -z $guard ]] || { echo "stop: $TH is a $guard: promote takes a plain talk thread"; exit 1; }
[[ ${TNAME:l} = (office|*・office) ]] && { echo "stop: '$TNAME' is a repo room's office thread: promote takes a plain talk thread"; exit 1; }
base=${TNAME#*・}
SLUG=${NAME:-$(python3 -c 'import re,sys,unicodedata
s=unicodedata.normalize("NFKD",sys.argv[1]).encode("ascii","ignore").decode().lower().lstrip("!")
s=re.sub(r"[^a-z0-9._-]+","-",s); s=re.sub(r"-+","-",s).strip("-._")
print(s[:100])' "$base")}
[[ -n $SLUG && $SLUG != (.|..) ]] || { echo "stop: the thread name '$TNAME' gives no repo name (a-z 0-9 . _ -): pass --name=<repo>"; exit 1; }
REPO=$OWNER/$SLUG; R=$ghq/github.com/$REPO
CHN=${(L)REPO/\//∕}
echo "promote: thread $TH '$TNAME' ($TCOUNT messages, $TSTATE, in #$PNAME) -> repo $REPO · souls: ${(j:, :)ORACLES:-none (room only)} · $how"
[[ -n $NAME ]] && nn="(--name)" || nn="(from the thread name; --name=<repo> sets another)"
echo "  1. name: $SLUG $nn"

# ── 2. the repo ──
vis=$(gh repo view $REPO --json visibility -q .visibility 2>/dev/null || true)
want=$( (( PRIV )) && echo private || echo public)
if [[ -n $vis ]]; then
  vnote=""; (( VISSET )) && [[ ${vis:l} != $want ]] && vnote=" (it stays ${vis:l}: promote never changes visibility)"
  echo "  2. repo: $REPO exists on GitHub (${vis:l}) -> reuse$vnote"
else echo "  2. repo: gh repo create $REPO --$want"; fi
COMMIT=1; why=""
if [[ -d $R/.git ]]; then
  if git -C $R rev-parse -q --verify HEAD >/dev/null 2>&1; then
    def=$(git -C $R symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null || true); def=${def#origin/}; def=${def:-main}
    br=$(git -C $R branch --show-current); dirty=$(git -C $R status --porcelain | wc -l | tr -d ' ')
    (( dirty )) && { COMMIT=0; why="$dirty uncommitted change(s)"; }
    [[ $br = $def ]] || { COMMIT=0; why="${why:+$why, }on branch '$br', not '$def'"; }
  fi
  echo "     checkout: $R${why:+ ($why: the export is NOT committed, it stays in a temp folder)}"
else echo "     checkout: ghq get -p $REPO -> $R"; fi
OMD=origin/thread.md; OJS=origin/messages.jsonl
if [[ -f $R/$OMD ]] && ! rg -qF "Discord thread $TH " $R/$OMD; then OMD=origin/thread-$TH.md; OJS=origin/messages-$TH.jsonl; fi

# ── 3. save (planned) ──
echo "  3. save: maw atlas download $TH -> $OMD + $OJS (+ origin/attachments/), secret scan first, commit + push"
[[ -n $vis ]] && rd=" · README.md only if the repo has none" || rd=" · README.md"
echo "     .gitignore: wt/ .discord/$rd"

# ── 4. the room ──
CH=$(api https://discord.com/api/v10/guilds/$GUILD/channels | python3 -c 'import json,sys
n=sys.argv[1]
def hit(c):
    m=c.get("name","").lower()
    return c.get("type")==0 and (m==n or m.endswith("・"+n))
hits=[c["id"]+"="+c["name"] for c in json.load(sys.stdin) if hit(c)]
print(hits[0].split("=")[0] if len(hits)==1 else ("MANY:"+", ".join(hits) if hits else ""))' "$CHN")
[[ $CH = MANY:* ]] && { echo "stop: more than one channel matches '$CHN' (${CH#MANY:}); rename one first"; exit 1; }
have=$(python3 -c 'import json,os,sys
g={}
for f in (os.path.join(os.path.dirname(sys.argv[1]),"access.json"), sys.argv[1]):   # a row in either file counts
    try:
        for k,v in json.load(open(f)).get("groups",{}).items(): g.setdefault(k,{}).update(v)
    except Exception: pass
r=g.get(sys.argv[2])
print("NOROW" if r is None else " ".join(r.get("souls",[])))' $L ${CH:-none})
[[ $have = NOROW ]] && insouls=() || insouls=(${=have})
todo=(${ORACLES:|insouls}); skip=(${ORACLES:*insouls})
if [[ -n $CH ]]; then echo "  4. room: channel $CH ('$CHN') exists -> reuse${${have:#NOROW}:+; Laris row there (souls: ${(j:, :)insouls:-none})}"
else echo "  4. room: create channel '$PREFIX$CHN' under ⚡ active ($ROOMCAT) with the Laris token"; fi
[[ $have = NOROW ]] && echo "     Laris row: groups[${CH:-<new channel>}] = {layout 9, repo $REPO, souls [], requireMention false} (backup first)"
fail=0
for o in $todo; do
  sd=$(soul_dir $o); bad=""
  [[ -f $TEAM/oracles/$o/config.yaml ]] || bad="no oracles/$o/config.yaml"
  [[ -n $bad || -f $sd/CLAUDE.md ]] || bad="no soul at $sd"
  [[ -n $bad ]] || pass show discord/$o-token >/dev/null 2>&1 || bad="no pass discord/$o-token"
  if [[ -n $bad ]]; then echo "     ✗ $o: $bad"; fail=1; else echo "     soul $o: herdr-soul room $REPO $o --channel=${CH:-<new>} --yes (own thread + wt/$o-soul, --deny-main)"; fi
done
(( ${#skip} )) && echo "     already in the room, skipped: ${(j:, :)skip}"

# ── 5. link (planned) ──
if [[ $TSTATE = archived ]]; then echo "  5. link: thread $TH is archived already: no new post"
else echo "  5. link: as Laris post '📦 moved to <#room>' in thread $TH, then archive it (nothing deleted)"; fi
(( fail )) && { echo "stop: fix the ✗ items above first (or leave those oracles out)"; exit 1; }
if (( ! YES )); then
  echo "plan only. To run (Nat's or catbutter's go): maw soul promote $TH${ORACLES:+ ${(j: :)ORACLES}}${NAME:+ --name=$NAME}$([[ $OWNER = ${SOUL_PROMOTE_OWNER:-nat-build-with-oracle} ]] || echo " --owner=$OWNER")$( (( PRIV )) || echo ' --public') --yes"
  exit 0
fi

# ════ RUN ════
# 3a. export + secret scan first: nothing is created when the thread holds a secret
X=$(mktemp -d -t soul-promote); trap 'rm -rf $X' EXIT
{ DISCORD_BOT_TOKEN=$LT maw atlas download $TH --out=$X 2>&1 || true; } | tail -1 | sed 's/^/  atlas: /'
tgz=($X/**/*$TH*.tar.gz(N)); [[ -n ${tgz[1]:-} ]] || { echo "stop: maw atlas download $TH wrote no archive (nothing created)"; exit 1; }
mkdir -p $X/x && tar -xzf ${tgz[1]} -C $X/x
D=($X/x/**/*$TH(N/)); D=${D[1]:-}
[[ -n $D && -f $D/messages.jsonl ]] || { echo "stop: no messages.jsonl in the export (nothing created)"; exit 1; }
hits=$( { rg -c -i -e 'sk-ant-' -e 'sk-[a-z0-9]{32,}' -e 'ghp_[A-Za-z0-9]{20,}' -e 'github_pat_' -e 'AKIA[0-9A-Z]{16}' \
  -e 'BEGIN [A-Z ]*PRIVATE KEY' -e 'xox[abps]-[A-Za-z0-9-]{10,}' -e '[MN][A-Za-z0-9_-]{23,25}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}' \
  -e 'CLAUDE_CODE_OAUTH_TOKEN=' $D 2>/dev/null || true; } | awk -F: '{s+=$NF} END{print s+0}')
(( hits == 0 )) || { echo "stop: the secret scan found $hits hit(s) in the thread export: nothing created. Redact the messages, then rerun"; exit 1; }
python3 - $D/messages.jsonl $X/thread.md $TH "$TNAME" "$PNAME" <<'PY'
import json,sys
src,dst,th,name,parent=sys.argv[1:]
rows=[json.loads(l) for l in open(src) if l.strip()]
rows.sort(key=lambda r: r.get("timestamp") or "")
out=[f"# thread: {name}","",f"from Discord thread {th} in #{parent} · {len(rows)} messages · exported by maw atlas (maw soul promote)",""]
for r in rows:
    a=r.get("author") or {}; who=a.get("global_name") or a.get("username") or "?"
    t=(r.get("timestamp") or "")[:16].replace("T"," ")
    out.append(f"**{who}** · {t}  ")
    out.append((r.get("content") or "").strip() or "(no text)")
    for f in r.get("attachments") or []: out.append(f"📎 {f.get('filename','file')}")
    out.append("")
open(dst,"w").write("\n".join(out))
PY
echo "  ✓ exported: ${tgz[1]:t} ($(wc -l < $D/messages.jsonl | tr -d ' ') messages), secret scan clean"
# 2. repo
if [[ -z $vis ]]; then
  gh repo create $REPO --$want --description "Born from the Discord thread '$TNAME' (maw soul promote, $(date +%Y-%m-%d))" >/dev/null
  echo "  ✓ repo $REPO created ($want)"
fi
[[ -d $R/.git ]] || { ghq get -p $REPO >/dev/null 2>&1 || ghq get $REPO >/dev/null 2>&1 || true; }
[[ -d $R/.git ]] || { echo "stop: could not clone $REPO to $R"; exit 1; }
# 3b. files + commit
if (( COMMIT )); then
  T=$R
  git -C $R rev-parse -q --verify HEAD >/dev/null 2>&1 || git -C $R symbolic-ref HEAD refs/heads/main
  git -C $R rev-parse -q --verify HEAD >/dev/null 2>&1 && { git -C $R pull -q --ff-only 2>/dev/null || true; }
else T=$X/keep; mkdir -p $T; fi
OLDMD=0; [[ -f $T/$OMD ]] && OLDMD=1
mkdir -p $T/origin
cp $X/thread.md $T/$OMD; cp $D/messages.jsonl $T/$OJS
[[ -n $(ls -A $D/attachments 2>/dev/null) ]] && { mkdir -p $T/origin/attachments; cp -R $D/attachments/. $T/origin/attachments/; }
if (( COMMIT )); then
  add=(.gitignore origin)
  for l in wt/ .discord/; do git -C $R check-ignore -q $l 2>/dev/null || echo $l >> $R/.gitignore; done
  if [[ ! -e $R/README.md ]]; then
    cat > $R/README.md <<MD
# $SLUG

Born from the Discord thread **$TNAME** ($TH) in #$PNAME, promoted $(date +%Y-%m-%d) with \`maw soul promote\`.

- \`$OMD\`: the thread as text; \`$OJS\`: the raw export (\`maw atlas download\`).
- Room: Discord channel $PREFIX$CHN, one thread per oracle soul. Souls work in \`wt/<oracle>-soul\` worktrees (ignored here).

Promoted by Laris Labs Oracle (AI) for Nat Weerawan.
MD
    add+=README.md
  fi
  git -C $R add -- $add
  if git -C $R diff --cached --quiet; then echo "  • $OMD unchanged: nothing to commit"
  else
    [[ $OLDMD = 1 ]] && subj="$SLUG: $OMD re-exported from Discord thread $TH ('$TNAME')" || subj="$SLUG: born from Discord thread $TH ('$TNAME')"
    git -C $R commit -qm "$subj

$OMD + $OJS from maw atlas download (soul-promote.sh, laris-co/soul-in-repo)." && echo "  ✓ commit $(git -C $R rev-parse --short HEAD): $OMD"
  fi
  git -C $R push -q -u origin HEAD 2>&1 | tail -1 | sed 's/^/  push: /' || true
  git -C $R rev-parse -q --verify '@{u}' >/dev/null 2>&1 && [[ -z $(git -C $R rev-list @{u}..HEAD 2>/dev/null) ]] \
    && echo "  ✓ pushed to $REPO" || echo "  ✗ not pushed: git -C $R push -u origin HEAD"
else
  KEEP=$HOME/.maw/promote/$SLUG-$TH; mkdir -p $KEEP; cp -R $T/. $KEEP/
  echo "  • not committed ($why): the export is in $KEEP; copy it into the repo by hand"
fi
# 4. room
NEWROOM=0
if [[ -z $CH ]]; then
  CH=$(api -X POST https://discord.com/api/v10/guilds/$GUILD/channels \
    -d "$(python3 -c 'import json,sys;print(json.dumps({"name":sys.argv[1],"type":0,"parent_id":sys.argv[2],"topic":"repo "+sys.argv[3]+": promoted from the thread "+sys.argv[4]+"; one thread per oracle soul"}))' "$PREFIX$CHN" $ROOMCAT $REPO "$TNAME")" \
    | python3 -c 'import json,sys;print(json.load(sys.stdin).get("id",""))')
  [[ -n $CH ]] || { echo "stop: could not create channel '$PREFIX$CHN' (repo $REPO is done; rerun to retry the room)"; exit 1; }
  NEWROOM=1; echo "  ✓ channel '$PREFIX$CHN' created: $CH"
fi
if [[ $have = NOROW ]]; then
  cp -p $L $L.bak-$(date +%Y%m%d-%H%M%S)-promote
  python3 - $L $CH "$CHN" $REPO $TH <<'PY'
import json,sys
f,ch,chn,repo,th=sys.argv[1:]; a=json.load(open(f)); g=a.setdefault("groups",{})
if ch not in g:
    g[ch]={"requireMention":False,"allowFrom":["691531480689541170","917019242094817301"],"layout":9,"channel":chn,
      "repo":repo,"souls":[],"threads":{},
      "note":f"repo channel {chn} (layout 9): promoted from thread {th}; souls come in with /soul or maw soul room; Laris hears every line, answers only when tagged"}
json.dump(a,open(f,"w"),indent=2,ensure_ascii=False)
PY
  echo "  ✓ Laris row: channel $CH, repo $REPO (backup beside $L)"
fi
okso=(); failso=()
if (( ${#todo} )); then
  if zsh $HERE/bin/herdr-soul room $REPO $todo --channel=$CH --yes; then okso=($todo)
  else
    now=$(python3 -c 'import json,sys
try: print(" ".join(json.load(open(sys.argv[1])).get("groups",{}).get(sys.argv[2],{}).get("souls",[])))
except Exception: print("")' $L $CH)
    for o in $todo; do [[ " $now " = *" $o "* ]] && okso+=$o || failso+=$o; done
  fi
fi
# 5. link
if [[ $TSTATE != archived ]]; then
  BOT=laris-labs-oracle $SAY $TH "📦 **moved to <#$CH>** · repo \`$REPO\` · this thread is saved in \`$OMD\`. Archived here, nothing deleted: one message brings it back." >/dev/null \
    && echo "  ✓ moved-to line in thread $TH"
  api -o /dev/null -w "  ✓ thread $TH archived (HTTP %{http_code})\n" -X PATCH -H 'X-Audit-Log-Reason: maw soul promote' \
    https://discord.com/api/v10/channels/$TH -d '{"archived":true}'
fi
if (( NEWROOM )); then
  souls=(${insouls} ${okso}); souls=(${(u)souls})
  BOT=laris-labs-oracle $SAY $CH "📦 **$REPO** born from the thread <#$TH> ('$TNAME', $TCOUNT messages) · history in \`$OMD\` · souls: ${${(j:, :)souls}:-none yet} · \`/soul\` adds one, \`/wt\` opens a worktree" >/dev/null \
    && echo "  ✓ first line in the room"
fi
(( ${#failso} )) && echo "  ✗ souls that did not come in: ${(j:, :)failso} (see above; rerun: maw soul room $REPO ${(j: :)failso} --channel=$CH --yes)"
echo "done: thread $TH -> repo $REPO, room $CH${okso:+, souls in: ${(j:, :)okso}}"
all=($insouls $okso); all=(${(u)all})
echo "RESULT repo=$REPO room=$CH from=$TH souls=${${(j:,:)all}:--}"
(( ${#failso} == 0 ))
