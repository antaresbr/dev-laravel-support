#!/bin/bash

function lbError() {
  local msgPrefix="laravel-bootstrap"
  [ $# -gt 1 ] && msgPrefix="${msgPrefix} | $1" && shift
  echo -e "\n${msgPrefix} | ERROR | $@\n" && exit 1
}

function lbWarn() {
  local msgPrefix="laravel-bootstrap"
  [ $# -gt 1 ] && msgPrefix="${msgPrefix} | $1" && shift
  echo -e "\n${msgPrefix} | WARN | $@\n"
}

BASE_DIR="$(realpath "$(dirname "$0")")"

#-- init parameters
pProject=""
pEnvironment=""
pWorkspacePhp=""
pOwner=""
pWwwGroup=""
pLaravelInstaller=""
#-- help message
msgHelp="
Use: $(basename $0) <options> <project>

options:
   --environment <name>       Environment name
   --workspace-php <name>     Script para acesso ao PHP no workspace; Ex.: workpace-php-82
   --owner <owner>            Storage's user owner; Deault sail
   --www-group <group>        Group of WWW server; Default: www-data
   --laravel-installer <bin>  Laravel installer inside workspace-php; Default: /home/<owner>/.config/composer/vendor/bin/laravel
   --help                     Show this help
"
#-- get parameters
while [ $# -gt 0 ]
do
  case "$1" in
    "--environment" | "--workspace-php" | "--owner" | "--www-group" | "--laravel-installer" )
      zp="$1"
      shift 1
      [ $# -lt 1 ] && lbError "Parameter: ${zp}, value not supplied"
      [ "${1:0:2}" == "--" ] && lbError "Parameter: ${zp}, invalid value: '$1'"
      case "$zp" in
        "--environment")
          pEnvironment="$1"
        ;;
        "--workspace-php")
          pWorkspacePhp="$1"
        ;;
        "--owner")
          pOwner="$1"
        ;;
        "--www-group")
          pWwwGroup="$1"
        ;;
        "--laravel-installer")
          pLaravelInstaller="$1"
        ;;
      esac
    ;;
    "--help")
       echo "${msgHelp}"
       exit 0;
    ;;
    *)
      if [ -z "${pProject}" ]
      then
        pProject="$1"
      else
        lbError "Invalid parameter: $1"
      fi
    ;;
  esac
  [ $# -gt 0 ] && shift 1
done

[ -n "${pProject}" ] || lbError "Parameter not supplied: project"
[ -n "${pEnvironment}" ] || lbError "Parameter not supplied: environment"
[ -n "${pWorkspacePhp}" ] || lbError "Parameter not supplied: workspace-php"

[ -n "${pOwner}" ] || pOwner="sail"
[ -n "${pWwwGroup}" ] || pWwwGroup="www-data"
[ -n "${pLaravelInstaller}" ] || pLaravelInstaller="/home/${pOwner}/.config/composer/vendor/bin/laravel"

GIT_BIN="$(which git)"
[ -n "${GIT_BIN}" ] || lbError "GIT binary not found"

"${pWorkspacePhp}" exec php --version &> /dev/null
[ $? -eq 0 ] || lbError "Fail to call '${pWorkspacePhp} exec php'"

if [ -d "${pProject}" ]
then
  lbWarn "Folder already exists: ${pProject}"
else
  projectHome="$(realpath --relative-to="${HOME}" "${BASE_DIR}")/${pProject}"
  echo ""
  echo "creating in [ ${projectHome} ]"
  "${pWorkspacePhp}" exec ${pLaravelInstaller} new "${projectHome}"
  [ $? -eq 0 ] || lbError "Fail to create project '${pProject}'"
fi

_target="${pProject}/composer.json"
[ -f "${_target}" ] || lbError "File not found: ${_target}"

_target="${pProject}/support"
if [ -d "${_target}" ]
then
  lbWarn "Folder already exists: ${_target}"
else
  mkdir "${_target}"
  cd "${_target}"
  [ $? -eq 0 ] || lbError "Fail to create ${_target}"

  _git_repo="https://github.com/antaresbr/dev-laravel-support.git"
  git clone "${_git_repo}" base
  [ $? -eq 0 ] || lbError "Fail to clone ${_git_repo}"

  cd base
  [ $? -eq 0 ] || lbError "Fail to chdir ${_target}/base"

  post-clone/setup.sh "${pEnvironment}"

  echo "--[[ support ]]--"

  cd ..
  [ $? -eq 0 ] || lbError "Fail to chdir ${_target}"
  POSTCLONE_IGNORE_GIT_REPO="TRUE" post-clone/setup.sh "${pEnvironment}"
fi

cd "${BASE_DIR}/${pProject}"
[ $? -eq 0 ] || lbError "Fail to chdir ${BASE_DIR}/${pProject}"

POSTCLONE_IGNORE_GIT_REPO="TRUE" post-clone/setup.sh "${pEnvironment}"
