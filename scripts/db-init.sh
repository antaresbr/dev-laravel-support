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
pEnv=""
pAffix=""
pInitUser=""
pMigrate=""
pSeed=""
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --env <env>        Env file/ID
   --affix <affix>    Affix to be included in database vars;
                      e.g.: If --affix audit is specified, the variables DB_AUDIT_* will be used instead of DB_*
   --init-user        Flag to initialize database user
   --migrate          Flag to execute the migrations
   --seed             Flag to seed the database
   --no-header-infos  Flag to not show environment variables
   --help             Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--env" | "--affix" )
      zp="$1"
      shift 1
      [ $# -lt 1 ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--env")
          pEnv="$1"
        ;;
        "--affix")
          pAffix="$1"
          [ -z "${pAffix}" ] || SUPP_AFFIX="_${pAffix^^}"
        ;;
      esac
    ;;
    "--init-user")
       pInitUser="$1"
    ;;
    "--migrate")
       pMigrate="$1"
    ;;
    "--seed")
       pSeed="$1"
    ;;
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

supLoadEnvsAndLibs
[ $? -eq 0 ] || supError "Fail on supLoadEnvsAndLibs"

${SUPP_DB_DRIVER}_abort_if_exists_in_production
[ $? -ne 0 ] && supError "Fail to check database existence: ${SUPP_DB_DATABASE}"

${SUPP_DB_DRIVER}_init_db
[ $? -ne 0 ] && supError "Fail to init db"

if [ -n "${pInitUser}" ]
then
  ${SUPP_DB_DRIVER}_init_user
  [ $? -ne 0 ] && supError "Fail to init user"
fi

if [ -n "${pMigrate}" ]
then
  "${SUPP_BASE_SCRIPT_DIR}/db-migrate.sh" --no-header-infos --env "${pEnv}" --affix "${pAffix}"
  [ $? -ne 0 ] && supError "Fail to migrate"
fi

if [ -n "${pSeed}" ]
then
  "${SUPP_BASE_SCRIPT_DIR}/db-seed.sh" --no-header-infos --env "${pEnv}" --affix "${pAffix}"
  [ $? -ne 0 ] && supError "Fail to seed"
fi

echo ""
