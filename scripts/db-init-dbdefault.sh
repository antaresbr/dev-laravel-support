#!/bin/bash

_bootstrap="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")/.bootstrap.sh"
while [ ! -f "${_bootstrap}" ]; do
  _bootstrap="$(dirname "$(dirname "${_bootstrap}")")/$(basename "${_bootstrap}")"; [ -f "${_bootstrap}" ] && break
  [ "$(dirname "${_bootstrap}")" != "/" ] || { echo -e "\n${BASH_SOURCE[0]} | File .bootstrap.sh not found\n"; exit 1; }
done
source "${_bootstrap}" || { echo -e "\n${BASH_SOURCE[0]} | Fail to source file: ${_bootstrap}\n"; exit 1; }

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
