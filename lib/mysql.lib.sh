#!/bin/bash

if [ -z "${SUPP_MYSQL_LIB_SH}" ]
then

SUPP_MYSQL_LIB_SH="loaded"


function mysql_unset_credentials() {
  unset MYSQL_USER
  unset MYSQL_PWD
}


function mysql_root_credentials() {
  export MYSQL_USER="${DB_ROOT_USERNAME}"
  export MYSQL_PWD="${DB_ROOT_PASSWORD}"
}


function mysql_user_credentials() {
  export MYSQL_USER="${SUPP_DB_USERNAME}"
  export MYSQL_PWD="${SUPP_DB_PASSWORD}"
}


function mysql_params() {
  local params="--host=${SUPP_DB_HOST} --port=${SUPP_DB_PORT} --user=${MYSQL_USER} --max_allowed_packet ${MYSQL_MAX_ALLOWED_PACKET}"
  [ $# -gt 0 ] && params="${params} $@"
  echo -n "${params}"
}


function mysql_cmd() {
  echo -n "mysql $(mysql_params $@)"
}


function mysql_exec_file_prepare() {
  $(mysql_cmd) --execute="set global log_bin_trust_function_creators=1;"
}


function mysql_exec_file() {
  local zFile="$1"
  shift

  cat "${zFile}" \
    | sed "s/\`{{@DB_USER@}}\`/\`${SUPP_DB_USERNAME}\`/g" \
    | sed "s/\`dbadmin\`/\`${SUPP_DB_USERNAME}\`/g" \
    | $(mysql_cmd $@) --database=${SUPP_DB_DATABASE}
}


function mysql_abort_if_exists_in_production() {
  if [ "${SERVER_ENVIRONMENT}" == "${PRODUCTION_ENVIRONMENT}" ]
  then
    mysql_root_credentials

    local exists="$($(mysql_cmd) --skip-column-names --execute="SHOW DATABASES LIKE '${SUPP_DB_DATABASE}';" | grep -i "${SUPP_DB_DATABASE}")"
    [ $? -ne 0 ] && supError "Fail to check existence: ${SUPP_DB_DATABASE}"
    if [ -n "${exists}" ]
    then
      supError "Database already exists: ${SUPP_DB_DATABASE}"
    fi

    mysql_unset_credentials
  fi
}


function mysql_init_db() {
  echo "craeting database: ${SUPP_DB_HOST}.${SUPP_DB_DATABASE}"

  mysql_root_credentials
  mysql_exec_file_prepare

  if [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ]
  then
    $(mysql_cmd) --execute="DROP DATABASE IF EXISTS ${SUPP_DB_DATABASE};"
  fi
  $(mysql_cmd) --execute="CREATE SCHEMA IF NOT EXISTS ${SUPP_DB_DATABASE} ${MYSQL_DB_PREDICATES};"
  [ $? -ne 0 ] && supError "Fail to create database."

  mysql_unset_credentials
}


function mysql_init_user() {
  local _fn="mysql_init_user"

  if [ "${SUPP_FORCE_INIT_USER,,}" != "true" ] && [ "${DB_ROOT_USERNAME}" == "${SUPP_DB_USERNAME}" ]
  then
    echo "${_fn} | same user ROOT_USERNAME and DB_USERNAME"
    echo "${_fn} | ignored"
  else
    echo "${_fn} | ${SUPP_DB_USERNAME}"

    mysql_root_credentials

    $(mysql_cmd) --execute="CREATE USER IF NOT EXISTS ${SUPP_DB_USERNAME}@'%';"
    $(mysql_cmd) --execute="ALTER USER ${SUPP_DB_USERNAME}@'%' IDENTIFIED WITH mysql_native_password BY '${SUPP_DB_PASSWORD}';"
    $(mysql_cmd) --execute="GRANT SET_USER_ID,SHOW_ROUTINE ON *.* TO ${SUPP_DB_USERNAME}@'%';"
    $(mysql_cmd) --execute="GRANT ALL PRIVILEGES ON ${SUPP_DB_DATABASE}.* TO ${SUPP_DB_USERNAME}@'%' WITH GRANT OPTION;"

    mysql_unset_credentials
  fi
}


function mysql_dump() {
  local dumpParams="${pDumpParams}"
  [ -n "${dumpParams}" ] || dumpParams="${MYSQL_DUMP_PARAMS}"

  mysqldump $(mysql_params) ${dumpParams} \
    --no-tablespaces --no-create-db ${SUPP_DB_DATABASE} $@ \
    | sed "s/\`${SUPP_DB_USERNAME}\`/\`{{@DB_USER@}}\`/g" \
    | sed "s/\`dbadmin\`/\`{{@DB_USER@}}\`/g"
}

fi
