#!/usr/bin/env zsh
# herdr-soul doctor is READ-ONLY and finds what it says it finds (issue for item 4 of the 2026-11-09 handoff).
# Offline: temp access files, temp ghq, temp team config. No Discord, no pass, no herdr (no --online).
# The access files are hashed before and after every run; any change fails the test.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
fail() { print "FAIL: $*"; exit 1; }
export HERDR_SOUL_GHQ=$T/ghq HERDR_SOUL_TEAM=$T/team HERDR_SOUL_CHANNELS=$T/channels HERDR_SOUL_MACHINE=m5
export HERDR_SOUL_LARIS=$T/channels/laris-labs-oracle/access.local.json HERDR_SOUL_SOMSRI=$T/somsri/access.json
mkdir -p $T/bin; print '#!/bin/sh\nexit 1' > $T/bin/herdr; chmod +x $T/bin/herdr; PATH=$T/bin:$PATH   # no real herdr
mkdir -p $T/channels/laris-labs-oracle $T/channels/odin-oracle $T/somsri $T/team/oracles/{neo,pulse,far}-oracle
print 'machine: white   # lives on white' > $T/team/oracles/far-oracle/config.yaml
# repo o/live: neo has a body, pulse has none, far lives on white
mkdir -p $T/ghq/github.com/o/live/wt/neo-oracle-soul/.discord $T/live-wt
cat > $HERDR_SOUL_LARIS <<JSON
{"groups": {
  "100": {"layout": 9, "channel": "100", "repo": "o/live", "souls": ["neo-oracle", "pulse-oracle", "far-oracle"],
          "threads": {"neo-oracle": "101", "pulse-oracle": "102", "far-oracle": "103", "ghost-oracle": "104"}},
  "200": {"layout": 9, "channel": "200", "repo": "o/gone", "souls": [], "threads": {}},
  "300": {"layout": 9, "channel": "300", "repo": "o/live", "archived": true, "souls": [], "threads": {},
          "archived_bodies": [{"who": "main", "kind": "main", "cwd": "$T/slept-here", "machine": "m5"},
                              {"who": "far-oracle", "kind": "soul", "cwd": "/not/on/this/box", "machine": "white"}]},
  "400": {"forwardTo": "$T/no-such-wt", "note": "link: thread x forwards to worktree"},
  "401": {"forwardTo": "$T/live-wt", "note": "link: alive"}
}}
JSON
print "{\"groups\": {\"500\": {\"deny\": true, \"linkedBy\": \"$T/gone-wt\"}, \"501\": {\"deny\": true}}}" > $T/channels/odin-oracle/access.local.json
print '{"groups": {}}' > $HERDR_SOUL_SOMSRI
hashes() { shasum $HERDR_SOUL_LARIS $T/channels/odin-oracle/access.local.json $HERDR_SOUL_SOMSRI; }
before=$(hashes)

set +e; out=$(zsh $HERE/bin/herdr-soul doctor); rc=$?; set -e
[[ $(hashes) = $before ]] || fail "access files changed"
[[ $rc = 1 ]] || fail "exit $rc with findings, want 1"$'\n'"$out"
want=(
  "✗ dead-forward 400 forwardTo $T/no-such-wt is gone -> fix: herdr-soul unlink $T/no-such-wt --bot=laris-labs-oracle"
  "✗ dead-deny 500 deny row linkedBy $T/gone-wt is gone"
  "✗ repo-missing 200 room for o/gone"
  "✗ soul-no-body 100 pulse-oracle in souls[] of o/live"
  "✗ thread-no-soul 100 threads{ghost-oracle: 104}"
  "✗ archived-body-gone 300 main main slept in $T/slept-here"
  "· remote: skipped (check on white) 100 far-oracle in o/live"
)
for w in $want; do [[ $out = *"$w"* ]] || fail "missing: $w"$'\n'"$out"; done
[[ $out != *"neo-oracle in souls[]"* ]] || fail "neo has a body, flagged anyway"
[[ $out != *"401"* ]] || fail "live forward flagged"
[[ $out != *"/not/on/this/box"* ]] || fail "a body on another box flagged as gone"
[[ $out = *"6 findings, 1 remote skipped" ]] || fail "summary: ${out##*$'\n'}"
print "offline findings (6) + remote skipped: ok"

set +e; js=$(zsh $HERE/bin/herdr-soul doctor -j); rc=$?; set -e
[[ $rc = 1 ]] || fail "-j exit $rc"
python3 -c 'import json,sys;d=json.loads(sys.argv[1]);assert len(d["findings"])==6 and len(d["skipped"])==1 and d["online"] is False, d' "$js" || fail "-j shape"
print -- "-j JSON: ok"

set +e; out=$(zsh $HERE/bin/herdr-soul doctor o/gone); rc=$?; set -e
[[ $out = *"repo-missing 200"* && $out != *"soul-no-body"* ]] || fail "[repo] filter: $out"
print "[repo] filter: ok"

# clean: only good rows -> exit 0
print '{"groups": {"401": {"forwardTo": "'$T/live-wt'"}}}' > $HERDR_SOUL_LARIS
print '{"groups": {}}' > $T/channels/odin-oracle/access.local.json
before=$(hashes)
out=$(zsh $HERE/bin/herdr-soul doctor) || fail "clean run exit $?: $out"
[[ $(hashes) = $before ]] || fail "access files changed (clean run)"
[[ $out = *", 0 findings" ]] || fail "clean summary: $out"
print "clean: exit 0: ok"
print "PASS"
