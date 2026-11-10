#!/usr/bin/env zsh
# bin/somsri-in (issue #49): plan touches nothing, refusals, --yes writes .somsri/ and swaps the main pane.
# Offline: stub herdr + pass on PATH (they log their calls), temp repos, temp Laris access file, temp plugin dir.
# No Discord, no real pass, no real herdr.
set -euo pipefail
HERE=${0:A:h}/..; T=${$(mktemp -d):A}; trap 'rm -rf $T' EXIT
fail() { print "FAIL: $*"; exit 1; }
SIN=$HERE/bin/somsri-in
mkdir -p $T/bin $T/ghq/github.com/laris-co $T/somsri $T/plugin/0.0.4/laris
print '# Somsri soul' > $T/somsri/CLAUDE.md
print 'export function threadInherits(p) { return !p.rootOnly }' > $T/plugin/0.0.4/laris/rowpolicy.ts
LOG=$T/calls.log; : > $LOG
cat > $T/bin/herdr <<'H'
#!/bin/zsh
print -r -- "herdr $*" >> $HERDR_STUB_LOG
case "$*" in
  *"agent list"*) cat $HERDR_STUB_AGENTS ;;
  *) print '{"ok":true}' ;;
esac
H
cat > $T/bin/pass <<'P'
#!/bin/zsh
print -r -- "pass $*" >> $HERDR_STUB_LOG
[[ $2 = discord/somsri-oracle-token ]] && { print SECRET-TOKEN-STUB; exit 0; }
exit 1
P
chmod +x $T/bin/herdr $T/bin/pass
mkrepo() { local r=$T/ghq/github.com/laris-co/$1; git init -q -b main $r; git -C $r remote add origin git@github.com:laris-co/$1.git
  git -C $r -c user.email=t@t -c user.name=t commit -q --allow-empty -m init; print $r; }
R1=$(mkrepo room-one); R2=$(mkrepo room-two); R3=$(mkrepo no-room)
cat > $T/laris.json <<'J'
{"groups": {
  "901": {"layout": 9, "repo": "laris-co/room-one", "requireMention": false, "souls": ["neo-oracle"]},
  "902": {"layout": 9, "repo": "laris-co/room-two", "requireMention": true, "souls": []}
}}
J
agents() { print -r -- "{\"result\":{\"agents\":[$1]}}" > $T/agents.json; }
agents "{\"pane_id\":\"wA:p1\",\"agent\":\"claude\",\"agent_status\":\"idle\",\"cwd\":\"$R1/\",\"foreground_cwd\":\"$R1\"},
        {\"pane_id\":\"wB:p1\",\"agent\":\"claude\",\"agent_status\":\"idle\",\"cwd\":\"$R2\"}"
export PATH=$T/bin:$PATH HERDR_STUB_LOG=$LOG HERDR_STUB_AGENTS=$T/agents.json GHQ_ROOT=$T/ghq \
  HERDR_SOUL_LARIS=$T/laris.json SOMSRI_PLUGIN_DIR=$T/plugin SOMSRI_HOME=$T/somsri HERDR_SESSION=laris-co SOMSRI_WAIT_MS=1000
sum() { shasum $T/laris.json; git -C $1 status --porcelain; ls -a $1; cat $1/.git/info/exclude 2>/dev/null; }

# 1. plan: reads only
before=$(sum $R1); out=$(zsh $SIN laris-co/room-one)
[[ $out = *"room <#901> (laris-co/room-one)"* && $out = *"main pane      wA:p1@laris-co"* ]] || fail "plan: $out"
[[ $out = *"requireMention False -> true"* && $out = *"dry: nothing touched"* ]] || fail "plan text: $out"
[[ $(sum $R1) = $before ]] || fail "plan changed files"
! rg -q 'pass show|pane run|agent prompt' $LOG || fail "plan called: $(cat $LOG)"
print -r -- "plan reads only, finds room 901 + main pane by cwd with a trailing slash: ok"

# 2. refusals
out=$(zsh $SIN $R3 --yes 2>&1) && fail "no room row: exit 0"
[[ $out = *"no layout-9 room row for laris-co/no-room"* ]] || fail "no room: $out"
git -C $R1 worktree add -q -b wtx $R1/wt/x 2>/dev/null
out=$(zsh $SIN $R1/wt/x --yes 2>&1) && fail "worktree: exit 0"; [[ $out = *"is a worktree"* ]] || fail "worktree: $out"
mv $T/plugin/0.0.4/laris/rowpolicy.ts $T/rp.ts
out=$(zsh $SIN $R1 --yes 2>&1) && fail "no rootOnly: exit 0"; [[ $out = *"plugin without rootOnly"* ]] || fail "plugin: $out"
mv $T/rp.ts $T/plugin/0.0.4/laris/rowpolicy.ts
agents ""; out=$(zsh $SIN $R1 --yes 2>&1) && fail "no pane: exit 0"; [[ $out = *"no main pane"* ]] || fail "no pane: $out"
[[ ! -e $R1/.somsri ]] || fail "a refusal wrote .somsri"
print -r -- "refuses: no room row · a worktree · plugin without rootOnly · no main pane (and writes nothing): ok"

# 3. --yes: files, exclude, swap in the same pane, Laris edit printed (not done)
agents "{\"pane_id\":\"wA:p1\",\"agent\":\"claude\",\"agent_status\":\"idle\",\"cwd\":\"$R1\"},
        {\"pane_id\":\"wB:p1\",\"agent\":\"claude\",\"agent_status\":\"idle\",\"cwd\":\"$R2\"}"
lsum=$(shasum $T/laris.json); : > $LOG
out=$(zsh $SIN $R1 --yes)
python3 -I -c 'import json,sys
a=json.load(open(sys.argv[1]))
r=a["groups"]["901"]; assert r["rootOnly"] is True and r["requireMention"] is False, r
assert set(r["allowFrom"])=={"691531480689541170","917019242094817301"}, r
assert list(a["groups"])==["901"], a["groups"]
assert a["guilds"]["1560847800881643520"]["deny"] is True, a' $R1/.somsri/access.json || fail "access.json"
rg -qx '/\.somsri/' $R1/.git/info/exclude || fail "exclude"
[[ -z $(git -C $R1 status --porcelain) ]] || fail "repo dirty: $(git -C $R1 status --porcelain)"
! rg -q SECRET-TOKEN-STUB $R1/.somsri || fail "token written to disk"
rg -q "pass show discord/somsri-oracle-token" $R1/.somsri/launch.sh || fail "launch: token not from pass"
rg -q "DISCORD_STATE_DIR='$R1/.somsri'" $R1/.somsri/launch.sh || fail "launch: state dir"
rg -q 'RESUME:\+--continue' $R1/.somsri/launch.sh || fail "launch: --continue"
rg -q "$T/somsri/CLAUDE.md" $R1/.somsri/launch.sh || fail "launch: soul"
rg -q 'room <#901>' $R1/.somsri/body.md || fail "body: room card"
[[ $(shasum $T/laris.json) = $lsum ]] || fail "Laris file edited"
[[ $out = *'groups["901"].requireMention = true'* ]] || fail "Laris edit not printed: $out"
order=$(rg -o 'agent wait wA:p1|agent prompt wA:p1 /exit|pane run wA:p1 RESUME=1 \S+' $LOG | tr '\n' '|')
[[ $order = "agent wait wA:p1|agent prompt wA:p1 /exit|pane run wA:p1 RESUME=1 $R1/.somsri/launch.sh|" ]] || fail "swap order: $order"
print -r -- "--yes: .somsri written + excluded, token only from pass, rootOnly row + guild deny, swap wait/exit/run in wA:p1, Laris printed: ok"

# 4. online already: refuse; rerun after it went stale makes backups
print '{}' > $R1/.somsri/status.json
out=$(zsh $SIN $R1 --yes 2>&1) && fail "online: exit 0"; [[ $out = *"already online"* ]] || fail "online: $out"
touch -t 202001010000 $R1/.somsri/status.json
out=$(zsh $SIN $R1 --yes) ; [[ $out = *"old files kept as .bak-"* ]] || fail "rerun: $out"
print -r -- "already online (fresh status.json): refused; stale: rerun with backups: ok"

# 5. a second room: its own state dir, same bot
out=$(zsh $SIN laris-co/room-two --yes)
python3 -I -c 'import json,sys
a=json.load(open(sys.argv[1])); assert list(a["groups"])==["902"], a' $R2/.somsri/access.json || fail "room two rows"
rg -q "pass show discord/somsri-oracle-token" $R2/.somsri/launch.sh || fail "room two token"
rg -q "pane run wB:p1 RESUME=1 $R2/.somsri/launch.sh" $LOG || fail "room two swap: $(cat $LOG)"
print -r -- "two rooms: two state dirs, one bot, each hears only its own room: ok"
print PASS
