#!/bin/bash

_bootstrap="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")/.bootstrap.sh"
while [ ! -f "${_bootstrap}" ]; do
  _bootstrap="$(dirname "$(dirname "${_bootstrap}")")/$(basename "${_bootstrap}")"; [ -f "${_bootstrap}" ] && break
  [ "$(dirname "${_bootstrap}")" != "/" ] || { echo -e "\n${BASH_SOURCE[0]} | File .bootstrap.sh not found\n"; exit 1; }
done
source "${_bootstrap}" || { echo -e "\n${BASH_SOURCE[0]} | Fail to source file: ${_bootstrap}\n"; exit 1; }

#-- init parameters
pOwner=""
pWwwGroup=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --owner <owner>      Storage's user owner
   --www-group <group>  Group of WWW server; Default: www-data
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

[ -n "${pWwwGroup}" ] || pWwwGroup="www-data"

STORAGE_DIR="${APP_DIR}/storage"

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

sudo --user="${pOwner}" ln -s "../storage/app/public" "${APP_DIR}/public/storage"
