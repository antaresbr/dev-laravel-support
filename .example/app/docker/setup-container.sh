#!/usr/bin/env bash

function log() {
    echo "$(date '+%Y-%m-%d %T,%3N') $@"
}

function logInfo() {
    log "INFO | $@"
}

function logError() {
    log "ERROR | $@"
    exit 1
}

[ "${BASH_SOURCE[0]}" -ef "$0" ] && logError "$(basename "$0") | This file must be sourced, not executed"

function addWorkerParam() {
    while [ $# -gt 0 ]
    do
        local param="$1" && shift
        if [ -n "${param}" ]
        then
            [ -z "${WORKER_PARAMS}" ] || WORKER_PARAMS="${WORKER_PARAMS} "
            WORKER_PARAMS="${WORKER_PARAMS}${param}"
        fi
    done
}


function banner() {
    logLabel="${SERVER_LABEL}"
    [ -n "${logLabel}" ] || logLabel="${SERVER_MODE}"
    echo ""
    figlet -w 150 "${logLabel}"
    logInfo "Starting in ${SERVER_MODE} mode"
    echo ""
}


function validate() {
    logInfo "setup-container | validate(): begin"

    [ -z "${ENVIRONMENT}" ] && [ -n "${SERVER_ENVIRONMENT}" ] && ENVIRONMENT="${SERVER_ENVIRONMENT}"
    [ -z "${ENVIRONMENT}" ] && logError "Variable ENVIRONMENT not defined"

    [ -z "${PHP_VERSION}" ] && logError "Variable PHP_VERSION not defined"

    if [ "${SERVER_MODE}" == "async" ]
    then
        [ -n "${WORKER_CONNECTION}" ] || logError "Variable WORKER_CONNECTION not defined"
    fi

    if [ "${SERVER_STACK,,}" == "true" ]
    then
        [ -z "${SHARE_APP_ENV}" ] && logError "Variable SHARE_APP_ENV not defined"
        [ -z "${SHARE_APP_STORAGE}" ] && logError "Variable SHARE_APP_STORAGE not defined"

        [ ! -d "${SHARE_APP_ENV}" ] && logError "Caminho não encontrado ${SHARE_APP_ENV}"
        [ ! -d "${SHARE_APP_STORAGE}" ] && logError "Caminho não encontrado ${SHARE_APP_STORAGE}"
    fi

    logInfo "setup-container | validate(): end"
}


function init() {
    logInfo "setup-container | init(): begin"

    [ -z "${WWWUSER}" ] || usermod -u ${WWWUSER} sail

    [ -d /.composer ] || mkdir /.composer
    chmod -R ugo+rw /.composer

    [ -n "${PHP_VERSION}" ] || PHP_VERSION="8.2"
    [ -n "${APP_HOME}" ] || APP_HOME="/var/www/html"
    [ -n "${APP_LOG_FILE}" ] || APP_LOG_FILE="${APP_HOME}/storage/logs/laravel.log"
    [ -n "${WORKER_NAME}" ] || WORKER_NAME="$(hostname)"

    export ENVIRONMENT
    export PHP_VERSION
    export APP_HOME
    export APP_LOG_FILE
    export WORKER_NAME

    if [ "${SERVER_MODE}" == "async" ]
    then
        [ -n "${WORKER_ENV}" ] || WORKER_ENV=".env"
        [ -n "${WORKER_CMD}" ] || WORKER_CMD="queue:worker"

        if [ -z "${WORKER_PARAMS}" ]
        then
            [ -n "${WORKER_QUEUE}" ] || WORKER_QUEUE="default"
            addWorkerParam "--queue=${WORKER_QUEUE}"
            [ "${WORKER_ONCE,,}" == "true" ] && addWorkerParam "--once"
            [ -z "${WORKER_MAX_JOBS}" ] || addWorkerParam "--max-jobs=${WORKER_MAX_JOBS}"
            [ -z "${WORKER_MEMORY}" ] || addWorkerParam "--memory=${WORKER_MEMORY}"
            [ -z "${WORKER_SLEEP}" ] || addWorkerParam "--sleep=${WORKER_SLEEP}"
            [ -z "${WORKER_RESP}" ] || addWorkerParam "--rest=${WORKER_RESP}"
        fi

        [ -n "${ASYNC_USER}" ] || ASYNC_USER=www-data
        [ -n "${ASYNC_GROUP}" ] || ASYNC_GROUP=www-data
        [ -n "${ASYNC_NUMPROCS}" ] || ASYNC_NUMPROCS=3
        [ -n "${ASYNC_STARTRETRIES}" ] || ASYNC_STARTRETRIES=5

        export WORKER_ENV
        export WORKER_CMD
        export WORKER_CONNECTION
        export WORKER_PARAMS
        export ASYNC_USER
        export ASYNC_GROUP
        export ASYNC_NUMPROCS
        export ASYNC_STARTRETRIES
    fi

    logInfo "setup-container | init(): end"
}


function init_stack() {
    logInfo "setup-container | init_stack(): begin"

    sudo --user=sail ln -s ${SHARE_APP_ENV} ${APP_HOME}/env
    sudo --user=sail ln -s ${SHARE_APP_STORAGE} ${APP_HOME}/storage

    local target=legacy/tcpdf/cache
    [ -d "${APP_HOME}/${target}" ] && rm -rf ${APP_HOME}/${target}
    [ ! -d "${APP_HOME}/storage/${target}" ] && sudo --user sail --group www-data mkdir -p ${APP_HOME}/storage/${target}
    sudo --user sail --group www-data ln -s ../../storage/${target} ${APP_HOME}/${target}

    local target=legacy/tcpdf/temp
    [ -d "${APP_HOME}/${target}" ] && rm -rf ${APP_HOME}/${target}
    [ ! -d "${APP_HOME}/storage/${target}" ] && sudo --user sail --group www-data mkdir -p ${APP_HOME}/storage/${target}
    sudo --user sail --group www-data ln -s ../../storage/${target} ${APP_HOME}/${target}

    sudo --user sail --group www-data echo "{ \"ENVIRONMENT\": \"${ENVIRONMENT}\" }" > ${APP_HOME}/ENVIRONMENT.json

    logInfo "setup-container | init_stack(): end"
}


[ "${SERVER_MODE}" == "app" ] || [ "${SERVER_MODE}" == "async" ] || logError "Variable SERVER_MODE not defined or invalid: '${SERVER_MODE}'"

banner
validate
init
[ "${SERVER_STACK}" != "true" ] || init_stack
