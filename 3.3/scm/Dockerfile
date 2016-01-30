FROM buildpack-deps:3.3-curl

# procps is very common in build systems, and is a reasonably small package
RUN apk update && apk upgrade && apk add \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		\
		procps \
	&& rm -rf /var/cache/apk/*
