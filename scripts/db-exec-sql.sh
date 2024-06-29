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
pFile=""
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --env <env>        Env file/ID
   --affix <affix>    Affix to be included in database vars;
                      e.g.: If --affix audit is specified, the variables DB_AUDIT_* will be used instead of DB_*
   --file <file>      SQL file to be executed; Can be specified multiple times
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
          [ -n "${pFile}" ] && pFile="${pFile}"$'\n'
          pFile="${pFile}$1"
          echo ${pFile}
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

supLoadEnvsAndLibs
[ $? -eq 0 ] || supError "Fail on supLoadEnvsAndLibs"

${DB_DRIVER}_root_credentials
[ $? -eq 0 ] || supError "Fail to set root credentials"

${DB_DRIVER}_exec_file_prepare
[ $? -eq 0 ] || supError "Fail on ${DB_DRIVER}_exec_file_prepare"

${DB_DRIVER}_user_credentials
[ $? -eq 0 ] || supError "Fail to set user credentials"

IFS=$'\n'
for file in ${pFile}
do
  echo ": ${file}"

  if [ ! -f "${file}" ]
  then
    echo "  -> não encontrado"
  else
    ${DB_DRIVER}_exec_file "${file}"
    exitCode="$?"
    if [ ${exitCode} -ne 0 ]
    then
      echo "  -> falha ao executar, ${exitCode}"
    else
      echo "  -> executado"
    fi
  fi

  echo ""
done
IFS=
