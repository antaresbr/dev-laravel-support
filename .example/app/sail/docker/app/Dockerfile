ARG UBUNTU_CODENAME=none

FROM ubuntu:${UBUNTU_CODENAME}

ARG UBUNTU_CODENAME
ARG PHP_VERSION=none
ARG NODE_VERSION=none
ARG WWW_USERNAME
ARG WWW_GROUPNAME
ARG SAIL_GROUPID
ARG SAIL_USERID
ARG SAIL_USERNAME
ARG SAIL_USERPASS

WORKDIR /var/www/html

ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC
ENV PHP_VERSION=${PHP_VERSION}

LABEL devcontainer.metadata="[{ \"remoteUser\": \"${SAIL_USERID}\" }]"

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update \
    && apt-get install -y \
         curl software-properties-common sudo nginx figlet\
         gnupg gosu ca-certificates zip unzip git supervisor sqlite3 libcap2-bin libpng-dev \
         mysql-client postgresql-client \
    && mkdir -p ~/.gnupg \
    && chmod 600 ~/.gnupg \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E5267A6C \
    && apt-key adv --homedir ~/.gnupg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C300EE8C \
    && echo "deb http://ppa.launchpad.net/ondrej/php/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/ppa_ondrej_php.list \
    && apt-get update \
    && apt-get install -y php${PHP_VERSION}-cli php${PHP_VERSION}-dev php${PHP_VERSION}-fpm \
       php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-gd \
       php${PHP_VERSION}-curl php${PHP_VERSION}-memcached \
       php${PHP_VERSION}-imap php${PHP_VERSION}-mysql php${PHP_VERSION}-mbstring \
       php${PHP_VERSION}-xml php${PHP_VERSION}-zip php${PHP_VERSION}-bcmath php${PHP_VERSION}-soap \
       php${PHP_VERSION}-intl php${PHP_VERSION}-readline php${PHP_VERSION}-pcov \
       php${PHP_VERSION}-msgpack php${PHP_VERSION}-igbinary php${PHP_VERSION}-ldap \
       php${PHP_VERSION}-redis php${PHP_VERSION}-swoole php${PHP_VERSION}-xdebug \
    && php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer \
    && curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list \
    && apt-get update \
    && apt-get install -y yarn \
    && apt-get -y autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-alternatives --set php /usr/bin/php${PHP_VERSION}
RUN setcap "cap_net_bind_service=+ep" /usr/bin/php${PHP_VERSION}

#-- sail
RUN getent group ${SAIL_GROUPID} > /dev/null || groupadd --force --gid ${SAIL_GROUPID} ${SAIL_USERNAME}
RUN getent passwd ${SAIL_USERID} > /dev/null || useradd --create-home --shell /bin/bash --uid ${SAIL_USERID} --gid ${SAIL_GROUPID} ${SAIL_USERNAME}
RUN usermod -aG sudo ${SAIL_USERNAME} \
    && mkdir -p /home/${SAIL_USERNAME}/bin \
    && chown -R ${SAIL_USERID}:${SAIL_GROUPID} /home/${SAIL_USERNAME}
RUN [ -z "${SAIL_USERPASS}" ] || usermod --password "${SAIL_USERPASS}" ${SAIL_USERNAME}

#-- configs
COPY php.ini /etc/php/${PHP_VERSION}/cli/conf.d/99-sail.ini
COPY resources/setup-container.sh /usr/local/bin/
COPY resources/start-container.sh /usr/local/bin/
COPY resources/supervisord-app.conf /etc/supervisor/conf.d/
COPY resources/supervisord-async.conf /etc/supervisor/conf.d/
COPY temp/server.conf /etc/nginx/sites-enabled/

RUN chmod +x /usr/local/bin/start-container.sh \
    && rm /etc/nginx/sites-enabled/default \
    && rm /etc/nginx/sites-available/default

#-- probe
RUN mkdir -p /var/www/probe
COPY probe.index.php /var/www/probe/index.php
RUN chown -R ${SAIL_USERNAME}:${WWWUSERGROUP} /var/www/probe

EXPOSE 80
EXPOSE 81

ENTRYPOINT ["start-container.sh"]
