#!/usr/bin/env zsh
# soul-archive.sh plans (laris-co/laris-team#210), offline: pass, ghq and laris-team's space-sleep.sh are stubs.
#  archive  : an idle soul on another machine sleeps THERE, an idle main sleeps, a busy main is kept and named
#  unarchive: a recorded body wakes where it slept, a body that is already live anywhere is skipped (no second body),
#             a soul of an older archive (no record) comes back with herdr-soul in
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
mkdir -p $T/bin $T/ghq/github.com/o/r $T/team/oracles/far-oracle
print 'machine: farbox' > $T/team/oracles/far-oracle/config.yaml
print '#!/bin/sh\necho tok' > $T/bin/pass
print "#!/bin/sh\necho $T/ghq" > $T/bin/ghq
print '#!/bin/sh\nexit 0' > $T/bin/herdr   # never the real herdr in a test
# space-sleep stub: FAKE_LIVE = "<cwd>=<answer>;..." for where; machine farbox -> farbox-laris-co
cat > $T/sp.sh <<'SH'
case $1 in
where) c=$2; echo "$FAKE_LIVE" | tr ';' '\n' | while IFS='=' read -r k v; do [ "$k" = "$c" ] && { echo "$v"; exit 3; }; done; [ $? = 3 ] || echo none;;
machine) [ "$2" = farbox ] && echo farbox-laris-co;;
draft) [ "$2" = p9 ] && echo "half a sentence";;
sleep) echo "$2 sleep $3" >> "$SPLOG"; echo "x: slept → card";;
on) echo "$2 $3 $4 $5" >> "$SPLOG"; echo "asked $2 h1: space-sleep.sh $3 $4";;
label) echo "$(basename "$(dirname "$(dirname "$2")")")--$(basename "$2")";;
wake) echo "local wake $2" >> "$SPLOG"; echo "woke $2";;
esac
SH
chmod +x $T/bin/* ; export PATH=$T/bin:$PATH HERDR_SOUL_TEAM=$T/team SOUL_SPACE_SLEEP=$T/sp.sh HERDR_SOUL_LARIS=$T/acc.json SPLOG=$T/sp.log SOUL_DISCORD_API=http://127.0.0.1:9
R=$T/ghq/github.com/o/r
fail() { print "FAIL: $1"; print -r -- "$out"; exit 1; }

print '{"groups":{"100000000000000001":{"layout":9,"repo":"o/r","souls":["far-oracle"],"threads":{"far-oracle":"100000000000000002"}}}}' > $T/acc.json
# archive plan: GETs the active threads; curl is stubbed to an empty list
print '#!/bin/sh\necho "{\\"threads\\":[]}"' > $T/bin/curl; chmod +x $T/bin/curl
export FAKE_LIVE="$R/wt/far-oracle-soul=farbox-laris-co p9 idle s1;$R=local m1 idle s2"; out=$(zsh $HERE/soul-archive.sh o/r --dry)
[[ $out = *"soul far-oracle: 💤 sleeps on farbox-laris-co (p9"* ]] || fail "remote soul not slept on its machine"
[[ $out = *"typed, not sent: 'half a sentence'"* ]] || fail "draft not named"
[[ $out = *"main checkout agent m1: 💤 sleeps"* ]] || fail "idle main not slept"
print "archive: remote soul + idle main + draft ok"
export FAKE_LIVE="$R=local m1 working s2"; out=$(zsh $HERE/soul-archive.sh o/r --dry)
[[ $out = *"main checkout agent m1 is working: kept, named"* ]] || fail "busy main not kept"
print "archive: busy main kept ok"

cat > $T/acc.json <<JSON
{"groups":{"100000000000000001":{"layout":9,"repo":"o/r","archived":true,"souls":[],"threads":{},
 "archived_souls":["far-oracle","old-oracle"],"archived_threads":{"far-oracle":"100000000000000002"},
 "archived_bodies":[{"who":"far-oracle","kind":"soul","cwd":"$R/wt/far-oracle-soul","machine":"farbox-laris-co","label":"r--far-oracle-soul","session":"s1"},
                    {"who":"main","kind":"main","cwd":"$R","machine":"$(hostname -s)","label":"r","session":"s2"}]}}}
JSON
export FAKE_LIVE=""; out=$(zsh $HERE/soul-archive.sh o/r --unarchive --dry)
[[ $out = *"soul far-oracle: ☀️ wake on farbox-laris-co (r--far-oracle-soul"* ]] || fail "remote soul not woken where it slept"
[[ $out = *"main main: ☀️ wake on $(hostname -s)"* ]] || fail "main not woken"
[[ $out = *"soul old-oracle: no sleep record"*"herdr-soul in"* ]] || fail "old archive fallback missing"
print "unarchive: wake where slept + old fallback ok"
export FAKE_LIVE="$R/wt/far-oracle-soul=farbox-laris-co p9 idle s1;$R/wt/old-oracle-soul=local p3 idle s3"; out=$(zsh $HERE/soul-archive.sh o/r --unarchive --dry)
[[ $out = *"soul far-oracle: already awake on farbox-laris-co (p9) → skip, no second body"* ]] || fail "live remote body not skipped"
[[ $out = *"soul old-oracle: already awake"*"skip"* ]] || fail "live old soul not skipped"
[[ $out != *"herdr-soul in"* ]] || fail "herdr-soul in planned beside a live body"
print "unarchive: live bodies skipped, never a second body ok"

# runs (--yes) against the stubs: what was slept / woken, and what the row records
print '{"groups":{"100000000000000001":{"layout":9,"repo":"o/r","souls":["far-oracle"],"threads":{"far-oracle":"100000000000000002"}}}}' > $T/acc.json
: > $T/sp.log
export FAKE_LIVE="$R/wt/far-oracle-soul=farbox-laris-co p9 idle s1;$R=local m1 working s2"; out=$(zsh $HERE/soul-archive.sh o/r --yes 2>&1)
[[ $(<$T/sp.log) = "farbox-laris-co sleep p9 --close" ]] || fail "remote sleep not asked on farbox: $(<$T/sp.log)"
[[ $out = *"RESULT room=100000000000000001 state=archived kept=main"* ]] || fail "busy main not in RESULT"
rec=$(python3 -c 'import json,sys;r=json.load(open(sys.argv[1]))["groups"]["100000000000000001"];b=r["archived_bodies"];print(r["archived"],len(b),b[0]["who"],b[0]["machine"],b[0]["label"],b[0]["session"])' $T/acc.json)
[[ $rec = "True 1 far-oracle farbox-laris-co r--far-oracle-soul s1" ]] || { out=$rec; fail "row record"; }
print "archive run: asked farbox, busy main kept, body recorded ok"
: > $T/sp.log
export FAKE_LIVE=""; out=$(zsh $HERE/soul-archive.sh o/r --unarchive --yes 2>&1) || fail "unarchive run exited $?"
[[ $(<$T/sp.log) = "farbox-laris-co wake r--far-oracle-soul --say=100000000000000001" ]] || fail "remote wake not asked: $(<$T/sp.log)"
row=$(python3 -c 'import json,sys;r=json.load(open(sys.argv[1]))["groups"]["100000000000000001"];print(r["archived"],r["souls"],r["threads"],r["archived_bodies"])' $T/acc.json)
[[ $row = "False ['far-oracle'] {'far-oracle': '100000000000000002'} []" ]] || { out=$row; fail "row after unarchive"; }
print "unarchive run: woken on farbox, soul + thread back in the row ok"
