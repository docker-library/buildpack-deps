FROM vicamo/buildpack-deps:wheezy-s390-curl

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*
