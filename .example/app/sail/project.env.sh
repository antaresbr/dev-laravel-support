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
if [ "${SAIL_POSTGRES,,}" == "true" ]
then
    [ -z "${POSTGRES_VERSION}" ] && sailError "POSTGRES_VERSION not defined"
    [ -z "${POSTGRES_ROOT_USERNAME}" ] && sailError "POSTGRES_ROOT_USERNAME not defined"
    [ -z "${POSTGRES_ROOT_PASSWORD}" ] && sailError "POSTGRES_ROOT_PASSWORD not defined"
    [ -z "${POSTGRES_FORWARD_PORT}" ] && sailError "POSTGRES_FORWARD_PORT not defined"
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

export POSTGRES_VERSION
export POSTGRES_ROOT_USERNAME
export POSTGRES_ROOT_PASSWORD
export POSTGRES_FORWARD_PORT

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
export SAIL_SERVICE_POSTGRES="${COMPOSE_PROJECT_NAME}-postgres"

COMPOSE_CONFIGS="--file docker-compose.yml"
[ "${SAIL_ASYNC,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-async.yml"
[ "${SAIL_REDIS,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-redis.yml"
[ "${SAIL_MEMCACHED,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-memcached.yml"
[ "${SAIL_MYSQL,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-mysql.yml"
[ "${SAIL_POSTGRES,,}" == "true" ] && COMPOSE_CONFIGS="${COMPOSE_CONFIGS} --file docker-compose-postgres.yml"
export COMPOSE_CONFIGS

fi
