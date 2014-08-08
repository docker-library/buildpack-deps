FROM debian:jessie

RUN apt-get update && apt-get install -y \
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
		libpq-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
		zlib1g-dev \
	&& apt-get clean && rm -rf /var/lib/apt/lists/

RUN apt-get update && apt-get install -y \
		bzr \
		cvs \
		git \
		mercurial \
		subversion \
	&& apt-get clean && rm -rf /var/lib/apt/lists/
