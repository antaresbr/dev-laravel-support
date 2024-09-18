#!/bin/bash

_bootstrap="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")/.bootstrap.sh"
while [ ! -f "${_bootstrap}" ]; do
  _bootstrap="$(dirname "$(dirname "${_bootstrap}")")/$(basename "${_bootstrap}")"; [ -f "${_bootstrap}" ] && break
  [ "$(dirname "${_bootstrap}")" != "/" ] || { echo -e "\n${BASH_SOURCE[0]} | File .bootstrap.sh not found\n"; exit 1; }
done
source "${_bootstrap}" || { echo -e "\n${BASH_SOURCE[0]} | Fail to source file: ${_bootstrap}\n"; exit 1; }

SUPP_DB_DRIVER="mysql"

#-- init parameters
pHost=""
pPort=""
pDatabase=""
pUser=""
pPassword=""
pFile=""
pDumpParams=""
pNoHeaderInfos=""
#-- help message
msgHelp="
Use: $(basename $0) <options>

options:
   --host <nost>             Host server name/address
   --port <port>             Host port; Defaul 3306
   --database <database>     Database name
   --user <user>             Server user name
   --password <password>     Server user password
   --file <file>             Dump file to be created in APP_DIR/storage/dump;
                             If ommited: <DB_DATABASE>_<YYYY>-<MM>-<DD>_<HH>h<MM>_${SUPP_DB_DRIVER}.backup
   --dump-params '<params>'  Driver dump params
   --no-header-infos         Flag to not show environment variables
   --help                    Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--host" | "--port" | "--database" | "--user" | "--password" | "--file" | "--dump-params" )
      zp="$1"
      shift 1
      [ $# -lt 1 ] && wsError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && wsError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--host")
          pHost="$1"
        ;;
        "--port")
          pPort="$1"
        ;;
        "--database")
          pDatabase="$1"
        ;;
        "--user")
          pUser="$1"
        ;;
        "--password")
          pPassword="$1"
        ;;
        "--file")
          pFile="$1"
        ;;
        "--dump-params")
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

_pns=""
[ -n "${pHost}" ] || _pns="host"
[ -n "${_pns}" ] || [ -n "${pDatabase}" ] || _pns="database"
[ -n "${_pns}" ] || [ -n "${pUser}" ] || _pns="user"
[ -n "${_pns}" ] || [ -n "${pPassword}" ] || _pns="password"
[ -z "${_pns}" ] || supError "Parameter not supplied: ${_pns}"
unset _pns

[ -n "${pPort}" ] || pPort="3306"

supLoadDriver
[ $? -eq 0 ] || supError "Fail on supLoadDriver"

if [ -z "${pFile}" ]
then
  dumpDir="${APP_DIR}/storage/dump"
  [ -d "${dumpDir}" ] || mkdir "${dumpDir}"
  pFile="${dumpDir}/${pDatabase}_$(date '+%Y-%m-%d_%Hh%M')_${SUPP_DB_DRIVER}.backup"
fi

wsLog "creating '${pFile}' ..."

${SUPP_DB_DRIVER}_user_credentials
[ $? -eq 0 ] || supError "Fail to set user credentials"

${SUPP_DB_DRIVER}_dump_to_file "$@"
[ $? -eq 0 ] || supError "Fail to dump"

wsLog "done."
echo ""
