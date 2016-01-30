FROM alpine:3.3

RUN apk update && apk upgrade && apk add \
		ca-certificates \
		curl \
		wget \
	&& rm -rf /var/cache/apk/*
