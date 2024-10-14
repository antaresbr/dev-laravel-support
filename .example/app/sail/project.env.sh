#!/bin/bash

if [ -z "${PROJECT_ENV_SH}" ]
then

PROJECT_ENV_SH="loaded"

[ -z "${APP_PORT}" ] && sailError "APP_PORT not defined"
[ -z "${UBUNTU_CODENAME}" ] && sailError "UBUNTU_CODENAME not defined"
[ -z "${SERVER_ENVIRONMENT}" ] && sailError "SERVER_ENVIRONMENT not defined"
[ -z "${PHP_VERSION}" ] && sailError "PHP_VERSION not defined"
[ -z "${NODE_VERSION}" ] && sailError "NODE_VERSION not defined"
if [ "${SAIL_REDIS,,}" == "true" ]
then
    [ -z "${REDIS_FORWARD_PORT}" ] && sailError "REDIS_FORWARD_PORT not defined"
fi
if [ "${SAIL_MEMCACHED,,}" == "true" ]
then
    [ -z "${MEMCACHED_FORWARD_PORT}" ] && sailError "MEMCACHED_FORWARD_PORT not defined"
fi
if [ "${SAIL_MYSQL,,}" == "true" ]
then
    [ -z "${MYSQL_VERSION}" ] && sailError "MYSQL_VERSION not defined"
    [ -z "${MYSQL_ROOT_PASSWORD}" ] && sailError "MYSQL_ROOT_PASSWORD not defined"
    [ -z "${MYSQL_FORWARD_PORT}" ] && sailError "MYSQL_FORWARD_PORT not defined"
fi
if [ "${SAIL_PGSQL,,}" == "true" ]
then
    [ -z "${PGSQL_VERSION}" ] && sailError "PGSQL_VERSION not defined"
    [ -z "${PGSQL_ROOT_USERNAME}" ] && sailError "PGSQL_ROOT_USERNAME not defined"
    [ -z "${PGSQL_ROOT_PASSWORD}" ] && sailError "PGSQL_ROOT_PASSWORD not defined"
    [ -z "${PGSQL_FORWARD_PORT}" ] && sailError "PGSQL_FORWARD_PORT not defined"
fi
if [ "${SAIL_MAILPIT,,}" == "true" ]
then
    [ -z "${MAILPIT_FORWARD_PORT}" ] && sailError "MAILPIT_FORWARD_PORT not defined"
fi

[ -z "${WWWUSER}" ] && WWWUSER=$(id -u)
[ -z "${WWWGROUP}" ] && WWWGROUP=$(id -g)

[ -z "${SAIL_SERVICE_ASYNC_CONNECTION}" ] && SAIL_SERVICE_ASYNC_CONNECTION="redis"
[ -z "${SAIL_SERVICE_ASYNC_QUEUE}" ] && SAIL_SERVICE_ASYNC_QUEUE=""
[ -z "${SAIL_SERVICE_ASYNC_NUMPROCS}" ] && SAIL_SERVICE_ASYNC_NUMPROCS=""
[ -z "${SAIL_SERVICE_ASYNC_MAX_JOBS}" ] && SAIL_SERVICE_ASYNC_MAX_JOBS=""

export APP_PORT
export UBUNTU_CODENAME
export PHP_VERSION
export NODE_VERSION
export REDIS_FORWARD_PORT
export MEMCACHED_FORWARD_PORT

export MYSQL_VERSION
export MYSQL_ROOT_PASSWORD
export MYSQL_FORWARD_PORT

export PGSQL_VERSION
export PGSQL_ROOT_USERNAME
export PGSQL_ROOT_PASSWORD
export PGSQL_FORWARD_PORT

export MAILPIT_FORWARD_PORT

export WWWUSER
export WWWGROUP

export SAIL_SERVICE_APP="${COMPOSE_PROJECT_NAME}-app"
export SAIL_SERVICE_APP_USER="sail"

export SAIL_SERVICE_ASYNC="${COMPOSE_PROJECT_NAME}-async"
export SAIL_SERVICE_ASYNC_USER="sail"
export SAIL_SERVICE_ASYNC_CONNECTION
export SAIL_SERVICE_ASYNC_QUEUE
export SAIL_SERVICE_ASYNC_NUMPROCS
export SAIL_SERVICE_ASYNC_MAX_JOBS

export SAIL_SERVICE_REDIS="${COMPOSE_PROJECT_NAME}-redis"
export SAIL_SERVICE_MEMCACHED="${COMPOSE_PROJECT_NAME}-memcached"
export SAIL_SERVICE_MYSQL="${COMPOSE_PROJECT_NAME}-mysql"
export SAIL_SERVICE_PGSQL="${COMPOSE_PROJECT_NAME}-pgsql"
export SAIL_SERVICE_MAILPIT="${COMPOSE_PROJECT_NAME}-mailpit"

COMPOSE_CONFIGS="--file docker-compose.yml"
[ "${SAIL_ASYNC,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-async.yml"
[ "${SAIL_REDIS,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-redis.yml"
[ "${SAIL_MEMCACHED,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-memcached.yml"
[ "${SAIL_MYSQL,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-mysql.yml"
[ "${SAIL_PGSQL,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-pgsql.yml"
[ "${SAIL_MAILPIT,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-mailpit.yml"
export COMPOSE_CONFIGS

fi
