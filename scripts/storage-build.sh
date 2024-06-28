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
pOwner=""
pWwwGroup=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --owner <owner>      Storage's user owner
   --www-group <group>  Group of WWW server; optional
   --help               Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--owner" | "--www-group" )
      zp="$1"
      shift 1
      [ $# -lt 1 ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--owner")
          pOwner="$1"
        ;;
        "--www-group")
          pWwwGroup="$1"
        ;;
      esac
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

[ -n "${pOwner}" ] || wsError "Parameter not supplied: owner"

STORAGE_DIR="${APP_DIR}/storage"
TCPDF_DIR="${APP_DIR}/legacy/tcpdf"

echo "Get SUDO credentials"
sudo ls -alF > /dev/null

supMakeDir "${STORAGE_DIR}"
supMakeDir "${STORAGE_DIR}/app/public"
supMakeDir "${STORAGE_DIR}/app/socket"
supMakeDir "${STORAGE_DIR}/dump"
supMakeDir "${STORAGE_DIR}/framework/cache/data"
supMakeDir "${STORAGE_DIR}/framework/sessions"
supMakeDir "${STORAGE_DIR}/framework/testing"
supMakeDir "${STORAGE_DIR}/framework/views"
supMakeDir "${STORAGE_DIR}/logs"
supMakeDir "${STORAGE_DIR}/tmp"

sudo touch "${STORAGE_DIR}/logs/laravel.log"
sudo chmod 664 "${STORAGE_DIR}/logs/laravel.log"

sudo chown -R ${pOwner} "${STORAGE_DIR}/"
if [ -n "${pWwwGroup}" ]
then
  sudo chgrp -R ${pWwwGroup} "${STORAGE_DIR}/"
fi

sudo chmod 775 "${STORAGE_DIR}/app/socket"

sudo find "${STORAGE_DIR}/framework/cache" -type d -exec chmod 775 {} \;
sudo find "${STORAGE_DIR}/framework/cache" -type f ! -iname .gitignore -exec chmod 664 {} \;
