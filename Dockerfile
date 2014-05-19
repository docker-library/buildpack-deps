FROM debian:jessie

Run apt-get update && apt-get install -y \
		autoconf \
		build-essential \
		imagemagick \
		libbz2-dev \
		libcurl4-openssl-dev \
		libevent-dev \
		libglib2.0-dev \
		libjpeg-dev \
		libmagickcore-dev \
		libmysqlclient-dev \
		libncurses-dev \
		libpq-dev \
		libpq-dev \
		libreadline-dev \
		libssl-dev \
		libxml2-dev \
		libxslt-dev \
		zlib1g-dev
