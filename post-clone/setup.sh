#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
BASE_DIR="$(dirname "${SCRIPT_DIR}")"

function _postCloneSetup_cleanUp() {
  [ ! -L "${SCRIPT_DIR}/lib" ] || rm "${SCRIPT_DIR}/lib"
  [ ! -f "${setupLibFile}" ] || rm "${setupLibFile}"
  echo ""
}
trap _postCloneSetup_cleanUp EXIT

function pcsError() {
  local msgPrefix="post-clone/setup"
  [ $# -gt 1 ] && msgPrefix="${msgPrefix} | $1" && shift
  [[ $(type -t wsError) == function ]] && wsError "${msgPrefix}" "$@" && exit 1
  echo -e "\n${msgPrefix} | ERROR | $@\n" && exit 1
}

setupLibFile="${SCRIPT_DIR}/setup.lib.sh"
[ -L "${setupLibFile}" ] && [ ! -e "${setupLibFile}" ] && rm "${setupLibFile}"
if [ ! -f "${setupLibFile}" ]
then
  wsSetupLibFile="${BASE_DIR}/.workspace-lib/post-clone/$(basename "${setupLibFile}")"
  [ -f "${wsSetupLibFile}" ] && ln -s "$(realpath --relative-to="${SCRIPT_DIR}" "${wsSetupLibFile}")" "${setupLibFile}"
  [ -f "${setupLibFile}" ] || curl --silent --output "${setupLibFile}" "https://raw.githubusercontent.com/antaresbr/dev-workspace-lib/master/post-clone/setup.lib.sh"
fi
[ -f "${setupLibFile}" ] || pcsError "File not found, ${setupLibFile}"
source "${setupLibFile}" || pcsError "Failed to source file, ${setupLibFile}"
