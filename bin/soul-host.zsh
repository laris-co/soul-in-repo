# soul-host.zsh — which host bot a soul-in-repo step speaks for (sourced, zsh).
# Nat 2026-11-10 ("ahhh it still fixed always fixed for this?", "ok we fix?", "make it cool now fool loop ?"): the whole
# room loop (/work, /soul, /done, /archive, unarchive) works for ANY server's host, not only Laris. Unset = Laris Labs
# Oracle in Laris Labs Ltd, as before. The Discord plugin of another server's host (access.host) exports, at start:
#   SOUL_HOST=<oracle>         its bot: token pass discord/<oracle>-token, every post goes out as it
#   SOUL_HOST_STATE=<dir>      its state dir under ~/.claude/channels (default = SOUL_HOST): access.local.json lives there
#   SOUL_GUILD=<id>            its server
#   SOUL_HOST_CWD=<folder>     its body's folder (the repo main it runs in), when known
#   HERDR_SESSION=<session>    its herdr session (herdr sets it for every pane)
SOUL_LARIS_GUILD=1560847800881643520
SH_BOT=${SOUL_HOST:-laris-labs-oracle}
SH_DIR=${SOUL_HOST_STATE:-$SH_BOT}
SH_ACC=$HOME/.claude/channels/$SH_DIR/access.local.json
SH_GUILD=${SOUL_GUILD:-$SOUL_LARIS_GUILD}
if [[ $SH_BOT == laris-labs-oracle ]]; then SH_NAME=Laris; else SH_NAME=${(C)${SH_BOT%-oracle}}; fi
sh_laris() { [[ $SH_GUILD == $SOUL_LARIS_GUILD ]] }
sh_token() { pass show discord/$SH_BOT-token | head -1 | tr -d '[:space:]' }
# the host's access.local.json, made (600) when a host has none yet
sh_acc_ready() { [[ -f $SH_ACC ]] || { (umask 077; print -r -- '{}' > $SH_ACC); echo "  ✓ $SH_ACC created" } }
# sh_cat <laris category id> <word>: Laris's own category in Laris Labs Ltd; in another server, the first category whose
# name holds <word> (case-blind: "active", "archive"), else empty
sh_cat() {
  sh_laris && { print -r -- $1; return }
  local t; t=$(sh_token)
  curl -sS -H "Authorization: Bot $t" https://discord.com/api/v10/guilds/$SH_GUILD/channels 2>/dev/null | python3 -c 'import json,sys
w=sys.argv[1].lower()
try: c=[x for x in json.load(sys.stdin) if x.get("type")==4 and w in x.get("name","").lower()]
except Exception: c=[]
print(c[0]["id"] if c else "")' $2 2>/dev/null || true
}
