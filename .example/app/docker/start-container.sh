#!/usr/bin/env bash

source /usr/local/bin/setup-container.sh || exit 1

if [ $# -gt 0 ]
then
    exec gosu ${WWWUSER} "$@"
else
    if [ "${SERVER_MODE}" == "app" ]
    then
        logInfo "php-fpm"
        logInfo "   PHP_VERSION  : ${PHP_VERSION}"
        logInfo "   APP_HOME     : ${APP_HOME}"
        logInfo "   APP_LOG_FILE : ${APP_LOG_FILE}"
        logInfo "   WORKER_NAME  : ${WORKER_NAME}"
    fi

    if [ "${SERVER_MODE}" == "async" ]
    then
        logInfo "${WORKER_CMD}"
        logInfo "   PHP_VERSION        : ${PHP_VERSION}"
        logInfo "   APP_HOME           : ${APP_HOME}"
        logInfo "   APP_LOG_FILE       : ${APP_LOG_FILE}"
        logInfo "   WORKER_ENV         : ${WORKER_ENV}"
        logInfo "   WORKER_NAME        : ${WORKER_NAME}"
        logInfo "   WORKER_CONNECTION  : ${WORKER_CONNECTION}"
        logInfo "   WORKER_PARAMS      : ${WORKER_PARAMS}"
        logInfo "   ASYNC_USER         : ${ASYNC_USER}"
        logInfo "   ASYNC_GROUP        : ${ASYNC_GROUP}"
        logInfo "   ASYNC_NUMPROCS     : ${ASYNC_NUMPROCS}"
        logInfo "   ASYNC_STARTRETRIES : ${ASYNC_STARTRETRIES}"
    fi

    /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord-${SERVER_MODE}.conf
fi
