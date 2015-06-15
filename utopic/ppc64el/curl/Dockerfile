FROM vicamo/ubuntu-core:utopic-ppc64el

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		wget \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*_dists_*
