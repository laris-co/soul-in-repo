#!/usr/bin/env zsh
# link --thread must refuse a thread that already forwards to ANOTHER worktree, and allow the same worktree or no row.
# Offline: runs the check from bin/herdr-soul against a fake access file.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
print '{"groups":{"111":{"forwardTo":"/wt/a"},"222":{"requireMention":true,"note":"office"}}}' > $T/acc.json
code=$(rg -N -A2 '^    other=\$\(python3 -c' $HERE/bin/herdr-soul | sed '1s/^    other=\$(python3 -c .//; $s/'"'"' \$ACC \$THPIN \$W)$//')
chk() { python3 -c "$code" $T/acc.json $1 $2; }
[[ $(chk 111 /wt/b) = /wt/a ]] && print "other worktree: refused ok" || { print "other worktree NOT refused"; exit 1; }
[[ -z $(chk 111 /wt/a) ]] && print "same worktree: allowed ok" || { print "same worktree refused"; exit 1; }
[[ -z $(chk 222 /wt/b) ]] && print "row without forwardTo: allowed ok" || { print "office row refused"; exit 1; }
[[ -z $(chk 333 /wt/b) ]] && print "no row: allowed ok" || exit 1
