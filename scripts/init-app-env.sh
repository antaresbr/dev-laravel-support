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

[ -n "${APP_ENV_DIR}" ] || supError "APP_ENV_DIR not defined"

#-- init parameters
pEnvId=""
pEnvName=""
pLinkId=""
pVar=""
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --env-id <id>       Env File ID
   --env-name <name>   Env file extension name
   --link-id <id>      URL link prefix
   --var <name=value>  Variable to be used in template; Can be specified multiple times
   --no-header-infos   Flag to not show environment variables
   --help              Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--env-id" | "--env-name" | "--link-id" )
      zp="$1"
      shift 1
      [ $# -lt 1 ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--env-id")
          pEnvId="$1"
        ;;
        "--env-name")
          pEnvName="$1"
        ;;
        "--link-id")
          pLinkId="$1"
        ;;
        "--var")
          zv="$1"
          if [ -z "${zv}" ] || [ "${zv}" == "$(echo "${zv}" | tr -d '=')" ]
          then
            wsError="Parameter: ${zp}, invalid value: '${zv}'"
          fi
          [ -n "${pVar}" ] && pVar="${pVar}"$'\n'
          pVar="${pVar}${zv}"
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

[ -z "${pEnvId}" ] && supError "Parameter not supplied, env-id"
[ "${pEnvId}" != "app" ] && [ "${#pEnvId}" -ne 4 ] && supError "Invalid parameter value, env-id ${pEnvId}"

[ -z "${pLinkId}" ] && [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] && pLinkId="${pEnvId}"
[ -z "${pLinkId}" ] && supError "Parameter not supplied, link-id"

envDir="${APP_DIR}/${APP_ENV_DIR}"
envExample="${envDir}/.example/.env.app.example"
envFile="${envDir}/.env"
[ -z "${pEnvName}" ] || envFile="${envFile}.${pEnvName}"

envVars="\
ENVIRONMENT=${SERVER_ENVIRONMENT}
APP_ID=${pEnvId}
APP_DEBUG=1
URL_PROTO=${URL_PROTO}
LINK_ID=${pLinkId}
URL_DOMAIN=${URL_DOMAIN}
${pVar}
"

[ ! -f "${envExample}" ] && supError "File not found: ${envExample}"
[ -f "${envFile}" ] && supError "File already exists: ${envFile}"

wsTemplateFile "${envFile}" "${envExample}" "${envVars}"

if [ "${SERVER_ENVIRONMENT}" == "${PRODUCTION_ENVIRONMENT}" ]
then
  dbPass="$(supRandomPassword 32)"
  adminPass="$(supRandomPassword 20)"

  sed "s/^APP_DEBUG=.*/APP_DEBUG=false/g" -i "${envFile}"
  sed "s/^DB_PASSWORD=.*/DB_PASSWORD=\"${dbPass}\"/g" -i "${envFile}"
  sed "s/^DB_ADMIN_USER_PASSWORD=.*/DB_ADMIN_USER_PASSWORD=\"${adminPass}\"/g" -i "${envFile}"
fi

envFileBackup="${envDir}/backup/$(basename "${envFile}")"
if [ -f "${envFileBackup}" ]
then
  supSourceFile "${envFileBackup}"
  sed "s|^APP_KEY=.*|APP_KEY=${APP_KEY}|g" -i "${envFile}"
  sed "s|^APP_URL=.*|APP_URL=${APP_URL}|g" -i "${envFile}"
  sed "s|^DB_PASSWORD=.*|DB_PASSWORD=\"${DB_PASSWORD}\"|g" -i "${envFile}"
  sed "s|^DB_ADMIN_USER_PASSWORD=.*|DB_ADMIN_USER_PASSWORD=\"${DB_ADMIN_USER_PASSWORD}\"|g" -i "${envFile}"
fi

[ -n "${INIT_ENV_FILE_OWNER}" ] && chown -v "${INIT_ENV_FILE_OWNER}" "${envFile}"
[ -n "${INIT_ENV_FILE_MODE}" ] && chmod -v "${INIT_ENV_FILE_MODE}" "${envFile}"

echo "File created, ${envFile}"

echo ""
