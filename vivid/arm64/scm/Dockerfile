# GENERATED FROM Dockerfile.template-scm
FROM vicamo/buildpack-deps:vivid-arm64-curl

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		bzr \
		git \
		mercurial \
		openssh-client \
		subversion \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*
