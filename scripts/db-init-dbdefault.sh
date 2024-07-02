#!/bin/bash

[ "$(type -t _bootError)" == "function" ] || function _bootError() {
  local scriptName="$(basename "$(realpath "$1")")" && shift
  scriptName="${scriptName%.*}"
  [ $# -gt 1 ] && [ -n "$1" ] && local prefix=" | $1" && shift
  echo -e "\n${scriptName}${prefix} | ERROR | $@ \n" && exit 1
}
[ "$(type -t _bootSource)" == "function" ] || function _bootSource() {
  local zCurrentScript="$1" && shift
  local zFileToSource="$1" && shift
  [ -f "${zFileToSource}" ] || _bootError "${zCurrentScript}" "_bootSource" "File not found: ${zFileToSource}"
  source "${zFileToSource}" || _bootError "${zCurrentScript}" "_bootSource" "Fail to source file: ${zFileToSource}"
}
_bootSource "${BASH_SOURCE[0]}" "$(dirname "$(dirname "$(realpath "${BASH_SOURCE[0]}")")")/lib/base.lib.sh"

#-- init parameters
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --no-header-infos  Flag to not show environment variables
   --help             Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--no-header-infos")
       pNoHeaderInfos="$1"
    ;;
    "--help")
       echo "${msgHelp}"
       exit 0;
    ;;
    *)
      wsError "Invalid parameter: $1"
    ;;
  esac
  [ $# -gt 0 ] && shift 1
done

pEnv="dbdefault"
supLoadEnvsAndLibs
[ $? -eq 0 ] || supError "Fail on supLoadEnvsAndLibs"

MIGRATIONS_DIR="${APP_DIR}/database/dbdefault"
[ -d "${MIGRATIONS_DIR}" ] || supError "Directory not found: ${MIGRATIONS_DIR}"

${SUPP_DB_DRIVER}_abort_if_exists_in_production
[ $? -ne 0 ] && supError "Fail to check database existence: ${SUPP_DB_DATABASE}"

${SUPP_DB_DRIVER}_init_db
[ $? -ne 0 ] && supError "Fail to init db"

${SUPP_DB_DRIVER}_init_user
[ $? -ne 0 ] && supError "Fail to init user"

php artisan migrate --realpath \
  --env "${pEnv}" \
  --database "${SUPP_DB_CONNECTION}" \
  --path "${APP_DIR}/database/dbdefault"
