#!/usr/bin/env zsh
# bin/team-session (Nat 2026-11-11 "herdr session = team charter = repo, config file in the repo"): the session comes
# from <repo>/team.yaml `session:` when that session is running, else the caller's; bin/main-pane and bin/repo-space
# put their spaces there and say it when they fall back. Offline: stub herdr on PATH, no real herdr, no Discord.
set -euo pipefail
HERE=${0:A:h}/..; T=${$(mktemp -d):A}; trap 'rm -rf $T' EXIT
fail() { print -r -- "FAIL: $*"; exit 1; }
mkdir -p $T/bin; LOG=$T/log
cat > $T/bin/herdr <<'H'
#!/bin/zsh
print -r -- "herdr $*" >> $STUB_LOG
case "$*" in
  "session list")    cat $STUB/sessions.txt ;;
  *"pane list"*)     print '{"result":{"panes":[]}}' ;;
  *"worktree list"*) cat $STUB/wt.json ;;
  *"workspace create"*) print '{"result":{"pane":{"pane_id":"wNEW:p1"}}}' ;;
  *"worktree open"*) print '{"result":{"pane":{"pane_id":"wWT:p1"}}}' ;;
  *) print '{"ok":true}' ;;
esac
H
chmod +x $T/bin/herdr
export PATH=$T/bin:$PATH STUB=$T STUB_LOG=$LOG HERDR_SESSION=laris-co
TS=$HERE/bin/team-session
R=$T/arthur-vision-team; git init -q -b main $R
running() { print -r -- "Name status directory socket
laris-co running /x /x.sock
arthur-vision-team $1 /y /y.sock" > $T/sessions.txt; }
print '{"result":{"source":{"source_workspace_id":""},"worktrees":[]}}' > $T/wt.json

# 1. no team.yaml: the caller's session, herdr not asked
: > $LOG; [[ $(zsh $TS $R) = "laris-co current" ]] || fail "no team.yaml: $(zsh $TS $R)"
[[ ! -s $LOG ]] || fail "no team.yaml asked herdr: $(cat $LOG)"
print -r -- "no team.yaml: caller's session, herdr not asked: ok"

# 2. team.yaml session (quoted, with a comment) that is running: that session
print -r -- 'name: arthur-vision
repo: laris-co/arthur-vision-team
session: "arthur-vision-team"   # own herdr session = the repo name (Nat 2026-11-11)' > $R/team.yaml
running running
[[ $(zsh $TS $R) = "arthur-vision-team team.yaml" ]] || fail "running: $(zsh $TS $R)"
print -r -- "team.yaml session running: used: ok"

# 3. not running: never started, the caller's is used and named
running stopped
[[ $(zsh $TS $R) = "laris-co team.yaml:arthur-vision-team-not-running" ]] || fail "stopped: $(zsh $TS $R)"
! rg -q 'session (start|attach)' $LOG || fail "started a session: $(cat $LOG)"
print -r -- "team.yaml session stopped: caller's session, nothing started: ok"

# 4. main-pane: the new space lands in the team session; a stopped one falls back and the MAIN line says so
running running; : > $LOG
[[ $(zsh $HERE/bin/main-pane $R --yes | tail -1) = "MAIN wNEW:p1@arthur-vision-team started" ]] || fail "main-pane team: $(cat $LOG)"
rg -qF "herdr --session arthur-vision-team workspace create --cwd $R --label arthur-vision-team --no-focus" $LOG || fail "main-pane create: $(cat $LOG)"
! rg -q -- '--session laris-co' $LOG || fail "main-pane used laris-co: $(cat $LOG)"
running stopped; : > $LOG
out=$(zsh $HERE/bin/main-pane $R --yes | tail -1)
[[ $out = "MAIN wNEW:p1@laris-co started (team.yaml session arthur-vision-team not running: used laris-co)" ]] || fail "main-pane fallback: $out"
out=$(zsh $HERE/bin/main-pane $R); [[ $out = *"in herdr session laris-co (team.yaml:arthur-vision-team-not-running)"* ]] || fail "plan: $out"
print -r -- "main-pane: team session when running, fallback named in the MAIN line: ok"

# 5. repo-space: the worktree space opens in the team session too
running running; : > $LOG
print '{"result":{"source":{"source_workspace_id":"wR"},"worktrees":[]}}' > $T/wt.json
[[ $(zsh $HERE/bin/repo-space $R $R/wt/x wt/x) = wWT:p1 ]] || fail "repo-space pane: $(cat $LOG)"
rg -qF "herdr --session arthur-vision-team worktree open" $LOG || fail "repo-space session: $(cat $LOG)"
print -r -- "repo-space: worktree space in the team session: ok"

print -r -- "team-session: all ok"
