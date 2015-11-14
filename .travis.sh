#!/bin/bash
set -e

set -x

[[ "$(head -n1 curl/Dockerfile)" == 'FROM debian:'* || "$(head -n1 curl/Dockerfile)" == 'FROM ubuntu'*':'* ]]
[ "$(head -n1 scm/Dockerfile)" = "FROM $image-curl" ]
[ "$(head -n1 Dockerfile)" = "FROM $image-scm" ]
