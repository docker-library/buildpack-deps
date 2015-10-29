FROM buildpack-deps:precise-curl

RUN apt-get update && apt-get install -y --no-install-recommends \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		nano \
	&& rm -rf /var/lib/apt/lists/*
