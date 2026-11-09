#!/usr/bin/env zsh
# SOUL_TAG / SOUL_FROM / SOUL_CHILD (Nat 2026-11-09 "if /work or archive tag me let me see where go", "check like /ls").
# Offline: bin/soul-tag.zsh with a stub SAY that records "<channel>|<text>" and a stub room-ls. No Discord, no pass.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
fail() { print "FAIL: $*"; exit 1; }
NAT=691531480689541170 ROOM=1568518331600867338 PORTAL=1566000000000000001 THREAD=1569000000000000002
print -r -- '#!/bin/sh
printf "%s|%s\n" "$1" "$2" >> "$LOG"' > $T/say; chmod +x $T/say
print -r -- 'echo "VIEW $1"' > $T/room-ls.sh
run() {   # run <env...> -- <room> <repo> [skip]: source the helper in a clean zsh, call soul_where, print TAG then the posts
  local -a envs; while [[ $1 != -- ]]; do envs+=$1; shift; done; shift
  rm -f $T/log
  env -i PATH=$PATH LOG=$T/log SAY=$T/say TEAM=$T SOUL_ROOM_LS=$T/room-ls.sh $envs zsh -c "source $HERE/bin/soul-tag.zsh; print -r -- \"TAG=[\$TAG]\"; soul_where $* >/dev/null" 
  [[ -f $T/log ]] && cat $T/log || true
}
out=$(run SOUL_TAG=$NAT SOUL_FROM=$PORTAL -- $ROOM o/r)
[[ $out = "TAG=[ <@$NAT>]"$'\n'"$ROOM|VIEW o/r"$'\n'"$PORTAL|<@$NAT> 👉 <#$ROOM>" ]] || fail "typed in another channel:"$'\n'"$out"
print "typed elsewhere: tag, view in the room, pointer where typed: ok"
out=$(run SOUL_TAG=$NAT SOUL_FROM=$ROOM -- $ROOM o/r)
[[ $out = "TAG=[ <@$NAT>]"$'\n'"$ROOM|VIEW o/r" ]] || fail "typed in the room: $out"
print "typed in the room: no pointer: ok"
out=$(run SOUL_TAG=$NAT SOUL_FROM=$THREAD -- $ROOM o/r $THREAD)
[[ $out != *"$THREAD|"* ]] || fail "pointer posted where the report already went: $out"
print "report went to the typing thread: no pointer: ok"
out=$(run SOUL_TAG=$NAT SOUL_FROM=$PORTAL SOUL_CHILD=1 -- $ROOM o/r)
[[ $out = "TAG=[ <@$NAT>]" ]] || fail "child posted: $out"
print "child step: tag kept, no view, no pointer: ok"
out=$(run SOUL_TAG='123; rm -rf /' SOUL_FROM=$PORTAL -- $ROOM o/r)
[[ $out = "TAG=[]"$'\n'"$ROOM|VIEW o/r" ]] || fail "bad tag: $out"
print "bad tag: no mention, no pointer: ok"
out=$(run SOUL_ROOM_LS=$T/missing.sh -- $ROOM o/r)
[[ $out = "TAG=[]" ]] || fail "room-ls missing: $out"
print "no room-ls.sh: view skipped: ok"
# the scripts use it: tagged room lines, the view at the end, the unarchive step as a child
rg -q 'unarchived\*\* by .*\$TAG" >/dev/null' $HERE/soul-archive.sh || fail "soul-archive: unarchived line not tagged"
rg -q 'archived\*\* by .*\$TAG" >/dev/null' $HERE/soul-archive.sh || fail "soul-archive: archived line not tagged"
(( $(rg -c '^ *soul_where \$CH \$REPO' $HERE/soul-archive.sh) == 2 )) || fail "soul-archive: soul_where not at both ends"
rg -q 'SOUL_CHILD=1 zsh \$HERE/soul-archive.sh' $HERE/soul-work.sh || fail "soul-work: unarchive not run as a child"
rg -q '\)\)\)\$TAG" --focus' $HERE/soul-work.sh || fail "soul-work: report not tagged"
rg -q '^soul_where \$CH \$REPO \$POST' $HERE/soul-work.sh || fail "soul-work: no soul_where at the end"
print "scripts wired: ok"
print "PASS"
