# syntax=docker/dockerfile:1

FROM ghcr.io/linuxserver/baseimage-alpine-nginx:3.18

ARG BUILD_DATE
ARG VERSION
ARG GRAV_RELEASE
LABEL build_version="Linuxserver.io version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="TheSpad"

RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    busybox-suid \
    php82-dom \
    php82-gd \
    php82-intl \
    php82-ldap \
    php82-opcache \
    php82-pecl-apcu \
    php82-pecl-yaml \
    php82-redis \
    php82-tokenizer && \
  echo "**** configure php-fpm to pass env vars ****" && \
  sed -E -i 's/^;?clear_env ?=.*$/clear_env = no/g' /etc/php82/php-fpm.d/www.conf && \
  grep -qxF 'clear_env = no' /etc/php82/php-fpm.d/www.conf || echo 'clear_env = no' >> /etc/php82/php-fpm.d/www.conf && \
  echo "env[PATH] = /usr/local/bin:/usr/bin:/bin" >> /etc/php82/php-fpm.conf && \
  echo "**** setup php opcache ****" && \
  { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=2'; \
    echo 'opcache.enable_cli=1'; \
  } > /etc/php82/conf.d/php-opcache.ini && \
  if [ -z ${GRAV_RELEASE+x} ]; then \
    GRAV_RELEASE=$(curl -sX GET "https://api.github.com/repos/getgrav/grav/releases/latest" \
    | awk '/tag_name/{print $4;exit}' FS='[""]'); \
  fi && \
  echo "*** Installing Grav ***" && \
  mkdir -p \
    /app/www/public && \
  curl -o \
    /tmp/grav.zip -L \
    "https://github.com/getgrav/grav/releases/download/${GRAV_RELEASE}/grav-admin-v${GRAV_RELEASE}.zip" && \
  unzip -q \
    /tmp/grav.zip -d /tmp/grav && \
  mv /tmp/grav/grav-admin/* /app/www/public/ && \
  echo "**** cleanup ****" && \
  rm -rf \
    /tmp/* \
    $HOME/.cache \
    $HOME/.composer

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443

VOLUME /config

VOLUME /app/www/public
