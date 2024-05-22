#
# NOTE: THIS DOCKERFILE IS GENERATED VIA "apply-templates.sh"
#
# PLEASE DO NOT EDIT IT DIRECTLY.
#

FROM buildpack-deps:noble-curl

RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		git \
		mercurial \
		openssh-client \
		subversion \
		\
# procps is very common in build systems, and is a reasonably small package
		procps \
	; \
	apt-get dist-clean
