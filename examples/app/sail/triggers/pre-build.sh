#!/bin/bash

TRIGGERS_DIR="$(dirname "$0")"
START_DIR=$(pwd)

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
_bootSource "${BASH_SOURCE[0]}" "${SAIL_DIR}/lib/triggers.lib.sh"

[ ! -d "${APP_DIR}/docker" ] || cp -pdvr "${APP_DIR}/docker/." "${SAIL_DOCKER_DIR}/app/resources/"

triggersTemplateFile "${SAIL_DOCKER_DIR}/app/temp/server.conf" "${SAIL_DOCKER_DIR}/app/server.conf.template"
