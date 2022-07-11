FROM buildpack-deps:{{ env.codename }}-curl

# procps is very common in build systems, and is a reasonably small package
RUN apt-get update && apt-get install -y --no-install-recommends \
{{
if [
	"bionic", "focal", "groovy", "xenial"
] | index(env.codename) then (
-}}
		bzr \
{{ ) else "" end -}}
		git \
		mercurial \
		openssh-client \
		subversion \
		\
		procps \
	&& rm -rf /var/lib/apt/lists/*
