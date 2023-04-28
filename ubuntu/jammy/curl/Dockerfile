#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM ubuntu:jammy

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		gnupg \
		netbase \
		wget \
# https://bugs.debian.org/929417
		tzdata \
	; \
	rm -rf /var/lib/apt/lists/*
