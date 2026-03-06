#!/bin/bash

if [ -z "${SUPP_MYSQL_LIB_SH}" ]
then

SUPP_MYSQL_LIB_SH="loaded"


function mysql_unset_credentials() {
  unset MYSQL_USER
  unset MYSQL_PWD
}


function mysql_root_credentials() {
  export MYSQL_USER="${MYSQL_ROOT_USERNAME}"
  export MYSQL_PWD="${MYSQL_ROOT_PASSWORD}"
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
    | sed "s/\`root\`/\`${SUPP_DB_USERNAME}\`/g" \
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


function mysql_abort_if_not_exists() {
  mysql_root_credentials

  local exists="$($(mysql_cmd) --skip-column-names --execute="SHOW DATABASES LIKE '${SUPP_DB_DATABASE}';" | grep -i "${SUPP_DB_DATABASE}")"
  [ $? -ne 0 ] && supError "Fail to check existence: ${SUPP_DB_DATABASE}"
  if [ -z "${exists}" ]
  then
    supError "Database does not exists: ${SUPP_DB_DATABASE}"
  fi

  mysql_unset_credentials
}


function mysql_init_db() {
  echo "creating database: ${SUPP_DB_DATABASE}@${SUPP_DB_HOST}"

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

  if [ "${SUPP_FORCE_INIT_USER,,}" != "true" ] && [ "${MYSQL_ROOT_USERNAME}" == "${SUPP_DB_USERNAME}" ]
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


function mysql_dump_to_file() {
  local dumpParams="${pDumpParams}"
  [ -n "${dumpParams}" ] || dumpParams="${MYSQL_DUMP_PARAMS}"

  mysqldump $(mysql_params) ${dumpParams} \
   --no-tablespaces --no-create-db ${SUPP_DB_DATABASE} $@ \
   > "${pFile}"
  local _ec=$?; [ $_ec -eq 0 ] || return $_ec

  sed -i "s/\`${SUPP_DB_USERNAME}\`/\`{{@DB_USER@}}\`/g" "${pFile}"
  _ec=$?; [ $_ec -eq 0 ] || return $_ec

  sed -i "s/\`dbadmin\`/\`{{@DB_USER@}}\`/g" "${pFile}"
  sed -i "s/\`root\`/\`{{@DB_USER@}}\`/g" "${pFile}"
  _ec=$?; [ $_ec -eq 0 ] || return $_ec
}


function mysql_cleanup_triggers() {
  echo ""
  echo "::[ cleanup triggers ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  echo "
SELECT
  TRIGGER_SCHEMA, TRIGGER_NAME
FROM
  INFORMATION_SCHEMA.TRIGGERS
WHERE
  TRIGGER_SCHEMA = '${SUPP_DB_DATABASE}'
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while read -r schema trigger
    do
      echo "   > ${schema}.${trigger};"
      $(mysql_cmd) --execute="DROP TRIGGER IF EXISTS ${schema}.${trigger};"
      [ $? -eq 0 ] || echo "     ! fail to drop"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}


function mysql_cleanup_routines() {
  echo ""
  echo "::[ cleanup routines ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  
  echo "
SELECT
  ROUTINE_SCHEMA, ROUTINE_NAME, ROUTINE_TYPE
FROM
  INFORMATION_SCHEMA.ROUTINES
WHERE
  ROUTINE_SCHEMA = '${SUPP_DB_DATABASE}'
  AND ROUTINE_TYPE in ('FUNCTION', 'PROCEDURE')
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while read -r schema function_name routine_type
    do
      echo "   > ${routine_type} : ${schema}.${function_name};"
      # O comando correto para funções é DROP FUNCTION
      $(mysql_cmd) --execute="DROP ${routine_type} IF EXISTS ${schema}.${function_name};"
      [ $? -eq 0 ] || echo "     ! fail to drop"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}


function mysql_cleanup_views() {
  echo ""
  echo "::[ cleanup views ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  echo "
SELECT
    TABLE_SCHEMA, TABLE_NAME
FROM
    INFORMATION_SCHEMA.TABLES
WHERE
    TABLE_SCHEMA = '${SUPP_DB_DATABASE}'
    AND TABLE_TYPE = 'VIEW'
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while read -r schema table
    do
      echo "   > ${schema}.${table};"
      $(mysql_cmd) --execute="DROP VIEW IF EXISTS ${schema}.${table};"
      [ $? -eq 0 ] || echo "     ! fail to drop"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}


function mysql_cleanup_foreign_keys() {
  echo ""
  echo "::[ cleanup foreign keys ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  echo "
SELECT
    TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_NAME
FROM
    INFORMATION_SCHEMA.TABLE_CONSTRAINTS
WHERE
    TABLE_SCHEMA = '${SUPP_DB_DATABASE}'
    AND CONSTRAINT_TYPE = 'FOREIGN KEY'
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while read -r schema table constraint
    do
      echo "   > ${schema}.${table}.${constraint};"
      $(mysql_cmd) --execute="ALTER TABLE ${schema}.${table} DROP FOREIGN KEY ${constraint};"
      [ $? -eq 0 ] || echo "     ! fail to drop"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}


function mysql_cleanup_auto_increment() {
  echo ""
  echo "::[ cleanup auto increment ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  echo "
SELECT 
    TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, IS_NULLABLE
FROM 
    information_schema.COLUMNS 
WHERE 
    TABLE_SCHEMA = '${SUPP_DB_DATABASE}'
    AND EXTRA = 'auto_increment'
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while IFS=$'\t' read -r schema table column_name column_type is_nullable
    do
      echo "   > ${schema}.${table}.${column_name};"

      if [ "${is_nullable}" == "NO" -o "${is_nullable}" == "NOT NULL" ]
      then
        is_nullable="NOT NULL"
      else
        is_nullable=""
      fi

      $(mysql_cmd) --execute="ALTER TABLE ${schema}.${table} MODIFY COLUMN ${column_name} ${column_type} ${is_nullable};"
      [ $? -eq 0 ] || echo "     ! fail to alter"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}


function mysql_cleanup_primary_keys() {
  echo ""
  echo "::[ cleanup primary keys ]::"

  [ "${SERVER_ENVIRONMENT}" != "${PRODUCTION_ENVIRONMENT}" ] || supError "Database is production, ignored"

  mysql_root_credentials

  local sqlFile="$(mktemp)"
  [ $? -eq 0 ] || supError "Fail to create temp file"
  echo "
SELECT
    TABLE_SCHEMA, TABLE_NAME
FROM
    INFORMATION_SCHEMA.STATISTICS
WHERE
    TABLE_SCHEMA = '${SUPP_DB_DATABASE}'
    AND INDEX_NAME = 'PRIMARY'
;
" > "${sqlFile}"
  [ $? -eq 0 ] || supError "Fail to write to temp file: ${sqlFile}"

  local _rs=$(mysql_exec_file "${sqlFile}" --silent --skip-column-names)
  [ $? -eq 0 ] || supError "Fail to execute sql file: ${sqlFile}"

  if [ -n "${_rs}" ]
  then
    echo "${_rs}" | while read -r schema table
    do
      echo "   > ${schema}.${table};"
      $(mysql_cmd) --execute="ALTER TABLE ${schema}.${table} DROP PRIMARY KEY;"
      [ $? -eq 0 ] || echo "     ! fail to drop"
    done
  fi

  [ ! -f "${sqlFile}" ] || rm -f "${sqlFile}"

  mysql_unset_credentials
}

fi
