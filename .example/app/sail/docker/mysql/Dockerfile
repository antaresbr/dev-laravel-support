ARG MYSQL_VERSION=none

FROM mysql:${MYSQL_VERSION}

COPY custom.cnf /etc/mysql/conf.d/
RUN chmod 664 /etc/mysql/conf.d/custom.cnf

