FROM debian:sid

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzr \
		cvs \
		git \
		mercurial \
		subversion \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		openssh-client \
		wget \
	&& rm -rf /var/lib/apt/lists/*
