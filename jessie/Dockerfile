FROM debian:jessie

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update && apt-get install --no-install-recommends -y \
		autoconf \
		build-essential \
		imagemagick \
		libbz2-dev \
		libcurl4-openssl-dev \
		libevent-dev \
		libffi-dev \
		libglib2.0-dev \
		libjpeg-dev \
		libmagickcore-dev \
		libmagickwand-dev \
		libmysqlclient-dev \
		libncurses-dev \
		libpq-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
		libyaml-dev \
		zlib1g-dev \
		bzr \
		cvs \
		git \
		mercurial \
		subversion \
	&& rm -rf \
		/var/lib/apt/lists/* \
		/tmp/* \
		/var/tmp/* \
		/usr/share/man/* \
		/usr/share/info/* \
		/var/cache/man/* \
		/var/cache/apt/* \
		/usr/share/doc/* \
	&& find /usr/share/locale -mindepth 1 -maxdepth 1 ! -name 'en_US' |xargs rm -r
