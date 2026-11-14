#!/usr/bin/env zsh
# bin/main-pane (#48): reuse a live main, start one in a free pane / a split / a new space, skip bot-body mains;
# bin/anchor-close keeps a space whose main agent reports only a foreground_cwd or a trailing slash;
# bin/repo-space labels a new space '<repo>' and types nothing into it.
# Offline: stub herdr on PATH answers from JSON files and logs every call. No Discord, no real herdr.
set -euo pipefail
HERE=${0:A:h}/..; T=${$(mktemp -d):A}; trap 'rm -rf $T' EXIT
fail() { print -r -- "FAIL: $*"; exit 1; }
mkdir -p $T/bin; LOG=$T/log
cat > $T/bin/herdr <<'H'
#!/bin/zsh
print -r -- "herdr $*" >> $STUB_LOG
case "$*" in
  *"pane list"*)     cat $STUB/panes.json ;;
  *"agent list"*)    cat $STUB/agents.json ;;
  *"worktree list"*) cat $STUB/wt.json ;;
  *"workspace create"*) print '{"result":{"pane":{"pane_id":"wNEW:p1"}}}' ;;
  *"pane split"*)    print '{"result":{"pane":{"pane_id":"wS:p2"}}}' ;;
  *) print '{"ok":true}' ;;
esac
H
chmod +x $T/bin/herdr
export PATH=$T/bin:$PATH STUB=$T STUB_LOG=$LOG HERDR_SESSION=laris-co
R=$T/repo; git init -q -b main $R
panes() { print -r -- "{\"result\":{\"panes\":[$1]}}" > $T/panes.json; }
agents() { print -r -- "{\"result\":{\"agents\":[$1]}}" > $T/agents.json; }
ws() { print -r -- "{\"result\":{\"source\":{\"source_workspace_id\":\"$1\"},\"worktrees\":[$2]}}" > $T/wt.json; }
MP=$HERE/bin/main-pane

# 1. live main (cwd with a trailing slash): reused, nothing started
panes "{\"pane_id\":\"wS:p1\",\"agent\":\"claude\",\"agent_status\":\"idle\",\"cwd\":\"$R/\",\"workspace_id\":\"wS\"}"; ws wS ""; : > $LOG
[[ $(zsh $MP $R --yes | tail -1) = "MAIN wS:p1@laris-co reused (claude idle)" ]] || fail "reuse: $(zsh $MP $R --yes)"
! rg -q 'pane run|workspace create|pane split' $LOG || fail "reuse started something: $(cat $LOG)"
print -r -- "live main (trailing slash): reused, nothing started: ok"

# 2. space with a free shell pane (foreground_cwd only): plan touches nothing, --yes starts claude there
panes "{\"pane_id\":\"wS:p1\",\"agent\":null,\"cwd\":\"/elsewhere\",\"foreground_cwd\":\"$R\",\"workspace_id\":\"wS\"}"; : > $LOG
out=$(zsh $MP $R); [[ $out = *"start claude in its free pane wS:p1"* && $out = *"MAIN wS:p1@laris-co planned" ]] || fail "plan: $out"
! rg -q 'pane run|workspace create|pane split' $LOG || fail "plan acted: $(cat $LOG)"
[[ $(zsh $MP $R --yes | tail -1) = "MAIN wS:p1@laris-co started" ]] || fail "free pane"
rg -qF "pane run wS:p1 cd '$R' && { claude --continue || claude; }" $LOG || fail "free pane run: $(cat $LOG)"
print -r -- "free pane: plan reads only, --yes runs 'claude --continue || claude' in it: ok"

# 3. space exists, its only pane at the repo is a busy non-claude shell elsewhere: split
panes "{\"pane_id\":\"wS:p1\",\"agent\":null,\"cwd\":\"/elsewhere\",\"workspace_id\":\"wS\"}"; : > $LOG
[[ $(zsh $MP $R --yes | tail -1) = "MAIN wS:p2@laris-co started" ]] || fail "split: $(cat $LOG)"
rg -qF "pane split wS:p1 --direction down --cwd $R --no-focus" $LOG || fail "split call: $(cat $LOG)"
print -r -- "space without a free pane: split, claude in the new pane: ok"

# 4. no space: create one labelled <repo>
panes ""; ws "" ""; : > $LOG
[[ $(zsh $MP $R --yes | tail -1) = "MAIN wNEW:p1@laris-co started" ]] || fail "create"
rg -qF "workspace create --cwd $R --label repo --no-focus" $LOG || fail "create call: $(cat $LOG)"
print -r -- "no space: created at the main checkout, label '<repo>': ok"

# 5. main is a bot body: skipped, herdr untouched
for d in .discord .somsri; do mkdir -p $R/$d; : > $R/$d/launch.sh; : > $LOG
  [[ $(zsh $MP $R --yes) = "MAIN - skip"* ]] || fail "$d not skipped"; [[ ! -s $LOG ]] || fail "$d: herdr called"; rm -rf $R/$d; done
print -r -- "main is a bot body (.discord/ or .somsri/): skipped, herdr not called: ok"

# 5b. main is a bot body marked only in .envrc (PhoneBooth, 2026-11-12): skipped, herdr untouched
for l in 'export DISCORD_STATE_DIR="$HOME/.claude/channels/x-oracle"' '  DISCORD_BOT_TOKEN="$(pass show discord/x-token)"'; do
  print -r -- "use flake"$'\n'"$l" > $R/.envrc; : > $LOG
  out=$(zsh $MP $R --yes); [[ $out = "MAIN - skip main is a bot body ($R/.envrc sets DISCORD_"* ]] || fail ".envrc not skipped: $out"
  [[ ! -s $LOG ]] || fail ".envrc: herdr called"; done
# a commented line, or another DISCORD_ variable, is not a bot body
print -r -- '# export DISCORD_STATE_DIR=/old'$'\n''export DISCORD_TOKEN_ENTRY_NOTE=x' > $R/.envrc; panes ""; ws "" ""
[[ $(zsh $MP $R | tail -1) = "MAIN -@laris-co planned" ]] || fail "commented .envrc skipped: $(zsh $MP $R)"
rm -f $R/.envrc
print -r -- "main is a bot body by .envrc (DISCORD_STATE_DIR / DISCORD_BOT_TOKEN): skipped; commented line is not: ok"

# 6. anchor-close keeps the space while a main agent runs there (foreground_cwd only / trailing slash)
ws wS ""; agents "{\"pane_id\":\"wS:p1\",\"cwd\":\"/elsewhere\",\"foreground_cwd\":\"$R/\"}"; : > $LOG
out=$(zsh $HERE/bin/anchor-close $R); [[ $out = *"kept: an agent runs at main (wS:p1)"* ]] || fail "anchor-close: $out"
! rg -q 'workspace close' $LOG || fail "anchor-close closed it"
agents ""; out=$(zsh $HERE/bin/anchor-close $R --dry); [[ $out = *"would close"* ]] || fail "anchor-close empty: $out"
print -r -- "anchor-close: main by foreground_cwd keeps the space; nothing left = would close: ok"

# 7. repo-space: a new space is labelled '<repo>' and gets no 'no agent runs here' line
ws "" ""; : > $LOG
zsh $HERE/bin/repo-space $R $R/wt/x x >/dev/null 2>&1 || true
rg -qF "workspace create --cwd $R --label repo --no-focus" $LOG || fail "repo-space label: $(cat $LOG)"
! rg -q 'no agent runs here|pane run' $LOG || fail "repo-space typed into the space"
print -r -- "repo-space: new space labelled '<repo>', nothing typed into it: ok"
print PASS
