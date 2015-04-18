FROM vicamo/debian:squeeze-powerpc

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*
