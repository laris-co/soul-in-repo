#!/usr/bin/env zsh
# room/migrate state-dir detection must not die under set -euo pipefail when the soul has no worktree yet
# (no <wt>/.discord/launch.sh). Laris 2026-11-07: `maw soul room laris-co/00_mz_forwarder floodboy-oracle` exited 1 silently.
# Offline: runs only the detection lines of bin/herdr-soul and soul-in-repo.sh against an empty temp folder.
set -euo pipefail
HERE=${0:A:h}/..; T=$(mktemp -d); trap 'rm -rf $T' EXIT
W=$T/repo/wt/x-oracle-soul; HOME=$T/home; mkdir -p $HOME
line=$(rg -N '^    lsd=\$\(sed' $HERE/bin/herdr-soul)
eval "$line"; print "herdr-soul: ok (lsd='$lsd')"
line=$(rg -N '^    lsd=\$\(sed' $HERE/soul-in-repo.sh)
eval "$line"; print "soul-in-repo.sh: ok (lsd='$lsd')"
mkdir -p $W/.discord; print "export DISCORD_STATE_DIR='$T/st'" > $W/.discord/launch.sh
eval "$line"; [[ $lsd = $T/st ]] && print "launch line read: ok" || { print "launch line NOT read: '$lsd'"; exit 1; }
