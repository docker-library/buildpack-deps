FROM buildpack-deps:jessie-scm

RUN apt-get update && apt-get install -y \
		gcc g++ libc6-dev make pkg-config autoconf \
		--no-install-recommends \
	&& rm -rf /var/lib/apt/lists/*
