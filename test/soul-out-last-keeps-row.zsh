#!/usr/bin/env zsh
# `herdr-soul out` of the LAST soul must keep a layout-9 room row (souls [], threads {}); issue #38.
# The row was deleted 3 times (2026-11-08 twice, 2026-11-09 once) and restored by hand each time.
# Offline: runs bin/soul-row-out on a temp access file, then the /work room lookup of soul-work.sh on the kept row.
# No Discord, no pass.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
fail() { print "FAIL: $*"; exit 1; }
L=$T/access.local.json
cat > $L <<'JSON'
{"groups": {
  "100": {"layout": 9, "channel": "100", "repo": "o/one", "requireMention": false, "note": "keep me",
          "souls": ["neo-oracle"], "threads": {"neo-oracle": "101"}},
  "200": {"layout": 9, "channel": "200", "repo": "o/two", "requireMention": false, "note": "x",
          "souls": ["neo-oracle", "pulse-oracle"], "threads": {"neo-oracle": "201", "pulse-oracle": "202"}},
  "300": {"requireMention": true, "note": "thread row: souls neo-oracle answer", "souls": ["neo-oracle"]}
}}
JSON
row() { python3 -c 'import json,sys;print(json.dumps(json.load(open(sys.argv[1]))["groups"].get(sys.argv[2])))' $L $1; }

# 1. layout 9, last soul out: row kept, souls [] threads {}, note and requireMention untouched
[[ $(python3 $HERE/bin/soul-row-out $L 100 neo-oracle) = kept ]] || fail "layout 9 last soul: not 'kept'"
python3 -c 'import json,sys;r=json.load(open(sys.argv[1]))["groups"]["100"]
assert r["souls"]==[] and r["threads"]=={}, r
assert r["note"]=="keep me" and r["requireMention"] is False, r' $L || fail "row 100: $(row 100)"
print "layout 9, last soul out: row kept (souls [], threads {}): ok"

# 2. layout 9, one of two souls out: only that soul dropped
[[ $(python3 $HERE/bin/soul-row-out $L 200 neo-oracle) = dropped ]] || fail "layout 9 two souls: not 'dropped'"
python3 -c 'import json,sys;r=json.load(open(sys.argv[1]))["groups"]["200"]
assert r["souls"]==["pulse-oracle"] and r["threads"]=={"pulse-oracle":"202"}, r' $L || fail "row 200: $(row 200)"
print "layout 9, one of two out: other soul stays: ok"

# 3. legacy per-thread row, last soul out: the row IS the thread, so it goes
[[ $(python3 $HERE/bin/soul-row-out $L 300 neo-oracle) = removed ]] || fail "legacy last soul: not 'removed'"
[[ $(row 300) = null ]] || fail "row 300 still there: $(row 300)"
print "legacy row, last soul out: row removed: ok"

# 4. no row: nothing written
sum=$(shasum $L); [[ $(python3 $HERE/bin/soul-row-out $L 999 neo-oracle) = norow ]] || fail "missing row: not 'norow'"
[[ $(shasum $L) = $sum ]] || fail "missing row: file changed"
print "no row: nothing written: ok"

# 5. /work on the kept souls [] row: soul-work.sh still finds it and plans "reuse"
have_lines=$(sed -n '/^have=\$(python3 -c/,/\$L \${CH:-none})$/p' $HERE/soul-work.sh)
[[ -n $have_lines ]] || fail "soul-work.sh: room lookup lines not found"
reuse_line=$(rg -N '^if \[\[ -n \$CH \]\]; then echo "  2\. room: ' $HERE/soul-work.sh)
[[ -n $reuse_line ]] || fail "soul-work.sh: reuse plan line not found"
CH=100; PREFIX=""; CHN=x
eval "$have_lines"
[[ $have != (NOROW|ARCHIVED) ]] || fail "souls [] row read as '$have'"
[[ $have = NOROW ]] && insouls=() || insouls=(${=have})
out=$(eval "$reuse_line; fi")
[[ $out = *"<#100> exists -> reuse"* ]] || fail "work plan: '$out'"
print "work plan on souls [] row: '$out': ok"
print "PASS"
