#!/bin/bash

if [ -z "${SUPP_BASE_LIB_SH}" ]
then

SUPP_BASE_LIB_SH="loaded"

[ -n "${PRODUCTION_ENVIRONMENT}" ] || PRODUCTION_ENVIRONMENT="production"

SUPP_BASE_LIB_DIR=$(realpath -s "$(dirname "${BASH_SOURCE[0]}")")
SUPP_BASE_DIR=$(dirname "${SUPP_BASE_LIB_DIR}")
SUPP_BASE_SCRIPT_DIR="${SUPP_BASE_DIR}/scripts"
SUPP_BASE_TINKER_DIR="${SUPP_BASE_DIR}/tinker"
SUPP_DIR=$(dirname "${SUPP_BASE_DIR}")
SUPP_SCRIPT_DIR="${SUPP_DIR}/scripts"
APP_DIR=$(dirname "${SUPP_DIR}")
START_DIR=$(pwd)


[ "$(type -t _bootError)" == "function" ] || function _bootError() {
  local scriptName="$(basename "$(realpath "$1")")" && shift
  scriptName="${scriptName%.*}"
  [ $# -gt 1 ] && scriptName="${scriptName} | $1" && shift
  echo -e "\n${scriptName} | ERROR | $@ \n" && exit 1
}
[ "$(type -t _bootSource)" == "function" ] || function _bootSource() {
  local zCurrentScript="$1" && shift
  local zFileToSource="$1" && shift
  [ -f "${zFileToSource}" ] || _bootError "${zCurrentScript}" "_bootSource" "File not found: ${zFileToSource}"
  source "${zFileToSource}" || _bootError "${zCurrentScript}" "_bootSource" "Fail to source file: ${zFileToSource}"
}
_bootSource "${BASH_SOURCE[0]}" "${SUPP_DIR}/.workspace-lib/base.lib.sh"

wsSourceFile "${WORKSPACE_LIB_DIR}/env-var.lib.sh"
wsSourceFile "${WORKSPACE_LIB_DIR}/text.lib.sh"


function supError() {
  local msgPrefix="support-lib"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  wsError "${msgPrefix}" "$@"
}


function supWarn() {
  local msgPrefix="support-lib"
  if [ $# -gt 1 ]
  then
    msgPrefix="${msgPrefix} | $1"
    shift
  fi
  wsWarn "${msgPrefix}" "$@"
}


function supMakeDir() {
  local zDir="$1"
  if [ -n "${zDir}" ]
  then
    [ ! -d "${zDir}" ] && sudo mkdir -p "${zDir}"
    sudo chmod 775 "${zDir}"
  fi
}


function supAbortIfProduction() {
  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Aborted in production environment"
}


function supSetEnvFileNames() {
  if [ -n "${APP_ENV_DIR}" ]
  then
    APP_ENV_GLOBALS="${APP_DIR}/${APP_ENV_DIR}/.globals"
    APP_ENV_FILE="${APP_DIR}/${APP_ENV_DIR}"
  else
    APP_ENV_GLOBALS=""
    APP_ENV_FILE="${APP_DIR}"
  fi
  if [ -z "${pEnv}" ]
  then
    APP_ENV_FILE="${APP_ENV_FILE}/.env"
  else
    if [ -f "${APP_ENV_FILE}/.${pEnv}" ] 
    then
      APP_ENV_FILE="${APP_ENV_FILE}/.${pEnv}"
    else
      APP_ENV_FILE="${APP_ENV_FILE}/.env.${pEnv}"
    fi
  fi
}


function supLoadEnvsAndLibs() {
  local _fn="supLoadEnvs"
  [ -n "${SERVER_ENVIRONMENT}" ] || supError "${_fn}" "SERVER_ENVIRONMENT not defined"

  supSetEnvFileNames
  wsSourceFileIfExists "${APP_ENV_GLOBALS}"
  wsSourceFile "${APP_ENV_FILE}"

  [ -n "${SUPP_AFFIX}" ] && SUPP_DB_DRIVER="$(envVarGet "DB${SUPP_AFFIX}_DRIVER")"
  [ -z "${SUPP_AFFIX}" ] && SUPP_DB_DRIVER="${DB_DRIVER}"
  [ -n "${SUPP_DB_DRIVER}" ] || supError "Impossible to get SUPP_DB_DRIVER <DB${SUPP_AFFIX}_DRIVER>"

  wsSourceFile "${SUPP_DIR}/env/${SUPP_DB_DRIVER}-${SERVER_ENVIRONMENT}-env"

  [ "$(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_USERNAME)" != "{{DB_USERNAME}}" ] || ${SUPP_DB_DRIVER^^}_ROOT_USERNAME="${DB_USERNAME}"
  [ "$(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_PASSWORD)" != "{{DB_PASSWORD}}" ] || ${SUPP_DB_DRIVER^^}_ROOT_PASSWORD="${DB_PASSWORD}"

  [ -z "$(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_USERNAME)" ] && supError "${_fn}" "${SUPP_DB_DRIVER^^}_ROOT_USERNAME not defined"
  [ -z "$(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_PASSWORD)" ] && supError "${_fn}" "${SUPP_DB_DRIVER^^}_ROOT_PASSWORD not defined"
  
  wsSourceFile "${SUPP_BASE_LIB_DIR}/${SUPP_DB_DRIVER}.lib.sh"

  SUPP_DB_CONNECTION="$(envVarGet "DB${SUPP_AFFIX}_CONNECTION")"
  SUPP_DB_HOST="$(envVarGet "DB${SUPP_AFFIX}_HOST")"
  SUPP_DB_PORT="$(envVarGet "DB${SUPP_AFFIX}_PORT")"
  SUPP_DB_DATABASE="$(envVarGet "DB${SUPP_AFFIX}_DATABASE")"
  SUPP_DB_USERNAME="$(envVarGet "DB${SUPP_AFFIX}_USERNAME")"
  SUPP_DB_PASSWORD="$(envVarGet "DB${SUPP_AFFIX}_PASSWORD")"

  [ -n "${SUPP_DB_CONNECTION}" ] || supError "${_fn}" "SUPP_DB_CONNECTION/DB${SUPP_AFFIX}_CONNECTION not defined"
  [ -n "${SUPP_DB_HOST}" ] || supError "${_fn}" "SUPP_DB_HOST/DB${SUPP_AFFIX}_HOST not defined"
  [ -n "${SUPP_DB_PORT}" ] || supError "${_fn}" "SUPP_DB_PORT/DB${SUPP_AFFIX}_PORT not defined"
  [ -n "${SUPP_DB_DATABASE}" ] || supError "${_fn}" "SUPP_DB_DATABASE/DB${SUPP_AFFIX}_DATABASE not defined"
  [ -n "${SUPP_DB_USERNAME}" ] || supError "${_fn}" "SUPP_DB_USERNAME/DB${SUPP_AFFIX}_USERNAME not defined"
  [ -n "${SUPP_DB_PASSWORD}" ] || supError "${_fn}" "SUPP_DB_PASSWORD/DB${SUPP_AFFIX}_PASSWORD not defined"

  if [ "${SUPP_SHOW_DB_INFOS^^}" != "FALSE" ] && [ -z "${pNoHeaderInfos}" ]
  then
    echo ""
    echo " SUPP_DB_DRIVER      : ${SUPP_DB_DRIVER}"
    echo " SUPP_DB_CONNECTION  : ${SUPP_DB_CONNECTION}"
    echo " SUPP_DB_HOST        : ${SUPP_DB_HOST}"
    echo " SUPP_DB_PORT        : ${SUPP_DB_PORT}"
    echo " SUPP_DB_DATABASE    : ${SUPP_DB_DATABASE}"
    echo " SUPP_DB_USERNAME    : ${SUPP_DB_USERNAME}"
    if [ "${SERVER_ENVIRONMENT}" == "${PRODUCTION_ENVIRONMENT}" ]
    then
      echo " SUPP_DB_PASSWORD    : ******"
    else
      echo " SUPP_DB_PASSWORD    : ${SUPP_DB_PASSWORD}"
      echo ""
      echo " ${SUPP_DB_DRIVER^^}_ROOT_USERNAME : $(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_USERNAME)"
      echo " ${SUPP_DB_DRIVER^^}_ROOT_PASSWORD : $(envVarGet ${SUPP_DB_DRIVER^^}_ROOT_PASSWORD)"
    fi
    if [ "${SERVER_ENVIRONMENT}" == "${PRODUCTION_ENVIRONMENT}" ]
    then
      echo ""
      echo " ** PRODUCTION ENVIRONMENT **"
    fi
    echo ""
  fi
}

[ -n "${SERVER_ENVIRONMENT}" ] || supError "SERVER_ENVIRONMENT não definido"

wsSourceFile "${SUPP_DIR}/env/${SERVER_ENVIRONMENT}-env"

fi
