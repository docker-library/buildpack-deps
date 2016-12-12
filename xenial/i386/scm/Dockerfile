# GENERATED FROM Dockerfile.template-scm
FROM vicamo/buildpack-deps:xenial-i386-curl

# procps is very common in build systems, and is a reasonably small package
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
		\
		procps \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*
