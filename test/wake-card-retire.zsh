#!/usr/bin/env zsh
# laris-team #237: a soul taken out (herdr-soul out --go) or a closed worktree (wt-close --yes) must not stay a
# 💤 sleeper in /ls. bin/wake-card-retire moves its wake cards to herdr-sleep/attic/<date>_<label>/ (outside the */*.json
# glob space-sleep.sh list reads); nothing is deleted. Offline: a temp HERDR_SLEEP_STATE, no herdr, no Discord.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
fail() { print "FAIL: $*"; exit 1; }
export HERDR_SLEEP_STATE=$T/sleep
W=/g/github.com/o/r/wt/neo-oracle-soul; K=/g/github.com/o/r/wt/pulse-oracle-soul
card() { mkdir -p $HERDR_SLEEP_STATE/$1; print -r -- "{\"herdr_session\": \"$4\", \"space\": {\"cwd\": \"$3\"}}" > $HERDR_SLEEP_STATE/$1/$2.json; }
card 2026-11-08 r--neo-oracle-soul $W laris-co
card 2026-11-09 r--neo-oracle-soul $W/ laris-co      # same folder, newer card, trailing slash
card 2026-11-09 r--pulse-oracle-soul $K laris-co     # another soul: stays
count() { print -l $HERDR_SLEEP_STATE/**/*.json(N) | wc -l | tr -d ' '; }
n0=$(count)

out=$(python3 $HERE/bin/wake-card-retire $W/)
[[ $(print -r -- $out | grep -c '^card moved:') = 2 ]] || fail "not 2 moved: $out"
D=$HERDR_SLEEP_STATE/attic/$(date +%Y-%m-%d)_r--neo-oracle-soul
[[ -f $D/r--neo-oracle-soul.json && -f $D/2026-11-09_r--neo-oracle-soul.json ]] || fail "attic: $(ls $D)"
[[ -z $(print -l $HERDR_SLEEP_STATE/*/r--neo-oracle-soul.json(N)) ]] || fail "a card is still in the list glob"
[[ -f $HERDR_SLEEP_STATE/2026-11-09/r--pulse-oracle-soul.json ]] || fail "the other soul's card moved"
[[ $(count) = $n0 ]] || fail "a card was deleted ($(count) != $n0)"
print "retire: both cards to the attic, other soul untouched, nothing deleted: ok"

[[ $(python3 $HERE/bin/wake-card-retire $W) = "no wake card for $W" ]] || fail "second retire"
python3 $HERE/bin/wake-card-retire relative/path >/dev/null && fail "a relative path was taken" || true
print "no card / bad path: ok"

# herdr-soul: out retires only with --go, after the pane is closed; wt-close only with --yes (not --dry)
src=$(<$HERE/bin/herdr-soul)
outblk=${src#*$'\nout)\n'}; outblk=${outblk%%$'\n  ;;\n'*}
[[ $outblk = *'(( GO )) || { echo "(plan only; add --go to do 1-3 and 5)"; exit 0; }'*'pane closed"'*'wake-card-retire $W'* ]] || fail "out: retire not after the --go gate and pane close"
[[ $src = *'if (( YES && !DRY )); then python3 $HERE/wake-card-retire $W'*'exec $0 unlink $W $fl'* ]] || fail "wt-close: retire not gated on --yes"
print "herdr-soul out --go / wt-close --yes call it: ok"
print PASS
