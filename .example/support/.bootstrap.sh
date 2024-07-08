#!/bin/bash

[ "$(type -t _bootError)" == "function" ] || function _bootError() {
  local scriptName="$(basename "$(realpath -s "$1")")" && shift
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
[ -n "${BOOTSTRAP_DIR}" ] || BOOTSTRAP_DIR="$(dirname "$(realpath -s "${BASH_SOURCE[0]}")")"
[ -n "${SUPP_BASE_LIB_SH}" ] || _bootSource "${BASH_SOURCE[0]}" "${BOOTSTRAP_DIR}/base/lib/base.lib.sh"
