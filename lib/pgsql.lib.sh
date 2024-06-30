#!/bin/bash

if [ -z "${SUPP_PGSQL_LIB_SH}" ]
then

SUPP_PGSQL_LIB_SH="loaded"


function pgsql_unset_credentials() {
  unset PGUSER
  unset PGPASSWORD
}


function pgsql_root_credentials() {
  export PGUSER="${PGSQL_ROOT_USERNAME}"
  export PGPASSWORD="${PGSQL_ROOT_PASSWORD}"
}


function pgsql_user_credentials() {
  export PGUSER="${SUPP_DB_USERNAME}"
  export PGPASSWORD="${SUPP_DB_PASSWORD}"
}


function pgsql_params() {
  local params="--host=${SUPP_DB_HOST} --port=${SUPP_DB_PORT} --user=${PGUSER}"
  [ $# -gt 0 ] && params="${params} $@"
  echo -n "${params}"
}


function pgsql_cmd() {
  echo -n "psql $(pgsql_params $@)"
}


function pgsql_exec_file_prepare() {
  echo "pgsql_exec_file_prepare()"
}


function pgsql_exec_file() {
  local zFile="$1"
  shift

  cat "${zFile}" \
    | sed "s/\`{{@DB_USER@}}\`/\`${SUPP_DB_USERNAME}\`/g" \
    | sed "s/\`dbadmin\`/\`${SUPP_DB_USERNAME}\`/g" \
    | $(pgsql_cmd $@) --database=${SUPP_DB_DATABASE}
}


function pgsql_abort_if_exists_in_production() {
  if [ "${SERVER_ENVIRONMENT}" == "${PRODUCTION_ENVIRONMENT}" ]
  then
    pgsql_root_credentials

    local exists="$($(pgsql_cmd) --command="SELECT datname FROM pg_database WHERE datname = '${SUPP_DB_DATABASE}';" | grep -i "${SUPP_DB_DATABASE}")"
    [ $? -ne 0 ] && supError "Fail to check existence: ${SUPP_DB_DATABASE}"
    if [ -n "${exists}" ]
    then
      supError "Database already exists: ${SUPP_DB_DATABASE}"
    fi

    pgsql_unset_credentials
  fi
}


function pgsql_init_db() {
  echo "craeting database: ${SUPP_DB_HOST}.${SUPP_DB_DATABASE}"

  pgsql_root_credentials
  pgsql_exec_file_prepare

  if [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ]
  then
    $(pgsql_cmd) --command="DROP DATABASE IF EXISTS ${SUPP_DB_DATABASE};"
  fi
  $(pgsql_cmd) --command="CREATE DATABASE ${SUPP_DB_DATABASE} ${PGSQL_DB_PREDICATES};"
  [ $? -ne 0 ] && supError "Fail to create database."

  pgsql_unset_credentials
}


function pgsql_init_user() {
  local _fn="pgsql_init_user"

  if [ "${SUPP_FORCE_INIT_USER,,}" != "true" ] && [ "${PGSQL_ROOT_USERNAME}" == "${SUPP_DB_USERNAME}" ]
  then
    echo "${_fn} | same user ROOT_USERNAME and DB_USERNAME"
    echo "${_fn} | ignored"
  else
    echo "${_fn} | ${SUPP_DB_USERNAME}"

    pgsql_root_credentials

    $(pgsql_cmd) --command="SELECT 'CREATE USER ${SUPP_DB_USERNAME}' WHERE NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${SUPP_DB_USERNAME}');"
    $(pgsql_cmd) --command="ALTER USER ${SUPP_DB_USERNAME} WITH ENCRYPTED PASSWORD '${SUPP_DB_PASSWORD}';"
    $(pgsql_cmd) --command="GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${SUPP_DB_USERNAME};"
    $(pgsql_cmd) --command="GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${SUPP_DB_USERNAME};"
    $(pgsql_cmd) --command="GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ${SUPP_DB_USERNAME};"

    pgsql_unset_credentials
  fi
}


function pgsql_dump_to_file() {
  local dumpParams="${pDumpParams}"
  [ -n "${dumpParams}" ] || dumpParams="${PGSQL_DUMP_PARAMS}"

  pg_dump $(pgsql_params) ${dumpParams}  $@ > "${pFile}"
  local _ec=$?; [ $_ec -eq 0 ] || return $_ec

  sed -i "s/\`${SUPP_DB_USERNAME}\`/\`{{@DB_USER@}}\`/g" "${pFile}"
  _ec=$?; [ $_ec -eq 0 ] || return $_ec

  sed -i "s/\`dbadmin\`/\`{{@DB_USER@}}\`/g" "${pFile}"
  _ec=$?; [ $_ec -eq 0 ] || return $_ec
}

fi
