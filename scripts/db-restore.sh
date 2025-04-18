#!/bin/bash

_bootstrap="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")/.bootstrap.sh"
while [ ! -f "${_bootstrap}" ]; do
  _bootstrap="$(dirname "$(dirname "${_bootstrap}")")/$(basename "${_bootstrap}")"; [ -f "${_bootstrap}" ] && break
  [ "$(dirname "${_bootstrap}")" != "/" ] || { echo -e "\n${BASH_SOURCE[0]} | File .bootstrap.sh not found\n"; exit 1; }
done
source "${_bootstrap}" || { echo -e "\n${BASH_SOURCE[0]} | Fail to source file: ${_bootstrap}\n"; exit 1; }

#-- init parameters
pEnv=""
pAffix=""
pFile=""
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --env <env>        Env file/ID
   --affix <affix>    Affix to be included in database vars;
                      e.g.: If --affix audit is specified, the variables DB_AUDIT_* will be used instead of DB_*
   --file <file>      Dump file to be restored
   --no-header-infos  Flag to not show environment variables
   --help             Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--env" | "--affix" | "--file" )
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
        "--file")
          pFile="$1"
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

[ -n "${pFile}" ] || supError "Parameter not supplied: file"
[ -f "${pFile}" ] || supError "File not found: ${pFile}"

supLoadEnvsAndLibs
[ $? -eq 0 ] || supError "Fail on supLoadEnvsAndLibs"

echo ""
"${SUPP_BASE_SCRIPT_DIR}/db-init.sh" --no-header-infos --init-user --env "${pEnv}" --affix "${pAffix}"
[ $? -ne 0 ] && exit 1

wsLog "restoring '${pFile}' ..."

echo ""
${SUPP_DB_DRIVER}_user_credentials
[ $? -eq 0 ] || supError "Fail to set user credentials"

echo ""
${SUPP_DB_DRIVER}_exec_file "${pFile}"
[ $? -eq 0 ] || supError "Fail to restore"

wsLog "done."
echo ""
