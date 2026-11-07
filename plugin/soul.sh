#!/usr/bin/env zsh
# laris.soul popup: works on the repo of the focused herdr pane.
set -uo pipefail
H=${0:A:h}/../bin/herdr-soul
cwd=$(python3 -c '
import json,os,sys
c=json.loads(sys.argv[1] or "{}")
for k in ("focused_pane","pane","workspace","worktree"):
    v=c.get(k) or {}
    if isinstance(v,dict):
        p=v.get("cwd") or v.get("checkout_path")
        if p: print(p); break
else: print(os.getcwd())' "${HERDR_PLUGIN_CONTEXT_JSON:-{\}}" 2>/dev/null) || cwd=$PWD
repo=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null | xargs dirname)
[[ -n $repo ]] || { echo "not a git repo: $cwd"; read -k1 "?any key"; exit 1; }
pause() { echo; read -k1 "?any key to close "; }
case ${1:-ls} in
ls) $H ls "$repo"; pause;;
bring)
  echo "repo: $repo"; echo
  $H list | python3 -c 'import sys
for i,l in enumerate(sys.stdin):
    f=l.split()
    if i==0 or (len(f)>2 and f[1]=="✓" and f[2]=="✓"): print(l,end="")'
  echo; read "o?oracle to bring in (empty = cancel): "
  [[ -z $o ]] && exit 0
  [[ $o = *-oracle ]] || o=$o-oracle
  echo; $H check "$o" "$repo" || { pause; exit 1; }
  echo; $H in "$o" "$repo" --dry 2>&1 | tail -1
  echo; read -k1 "go?Go? [y/N] "; echo
  [[ $go = [yY] ]] || { echo "cancelled"; pause; exit 0; }
  HERDR_SESSION=${HERDR_SESSION:-laris-co} $H in "$o" "$repo"
  pause;;
esac
