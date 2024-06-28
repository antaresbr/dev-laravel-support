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
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --env <env>        Env file/ID
   --affix            Affix to be included in database vars;
                      e.g.: If --affix audit is specified, the variables DB_AUDIT_* will be used instead of DB_*
   --no-header-infos  Flag to not show environment variables
   --help             Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--env" | '--affix' )
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

supAbortIfProduction
[ $? -eq 0 ] || supError "Fail on supAbortIfProduction"

artParams="db:seed"
[ -z "${pEnv}" ] || artParams="${artParams} --env=${pEnv}"
php artisan ${artParams}
