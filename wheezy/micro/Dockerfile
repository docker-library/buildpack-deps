FROM debian:wheezy

RUN apt-get update && apt-get install -y \
		bzr \
		cvs \
		git \
		mercurial \
		subversion \
	&& rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
		curl \
		wget \
	&& rm -rf /var/lib/apt/lists/*
