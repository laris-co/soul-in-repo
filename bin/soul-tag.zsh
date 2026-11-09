# soul-tag.zsh: sourced by soul-work.sh and soul-archive.sh (Nat 2026-11-09 "if /work or archive tag me let me see where
# go", "and then can you check like /ls"). Needs SAY (laris-team tools/discord-say.sh) and TEAM set before the call.
#   TAG   " <@id>" when SOUL_TAG is a Discord user id, else "": append it to every line posted in the room
#   FROM  SOUL_FROM when it is a channel id and this is not a step of a bigger command (SOUL_CHILD unset), else ""
#   soul_where <room> <owner/repo> [<skip>]   at the end of a run (not as a child): post the repo's part of `maw ls` in the
#         room (laris-team tools/room-ls.sh; skipped when that file is missing), then '<@id> 👉 <#room>' in FROM when FROM
#         is neither the room nor <skip> (the channel the report already went to)
TAG=""; [[ ${SOUL_TAG:-} =~ '^[0-9]{15,22}$' ]] && TAG=" <@$SOUL_TAG>"
FROM=""; [[ -z ${SOUL_CHILD:-} && ${SOUL_FROM:-} =~ '^[0-9]{15,22}$' ]] && FROM=$SOUL_FROM
soul_where() {
  local room=$1 repo=$2 skip=${3:-} ls=${SOUL_ROOM_LS:-$TEAM/tools/room-ls.sh}
  [[ -n ${SOUL_CHILD:-} || -z $room ]] && return 0
  if [[ -f $ls ]]; then
    BOT=laris-labs-oracle $SAY $room "$(bash $ls $repo)" >/dev/null && echo "  ✓ herdr view posted in <#$room>"
  fi
  if [[ -n $TAG && -n $FROM && $FROM != $room && $FROM != $skip ]]; then
    BOT=laris-labs-oracle $SAY $FROM "${TAG# } 👉 <#$room>" >/dev/null && echo "  ✓ pointer in <#$FROM>"
  fi
  return 0
}
