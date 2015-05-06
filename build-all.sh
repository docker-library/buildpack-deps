#!/bin/bash

#DRYRUN=echo

set -x

cd $(dirname ${BASH_SOURCE})

for d in `find . -mindepth 2 -maxdepth 2 -type d | cut -d/ -f2,3 | grep -v .git`; do
  suite=${d%%/*};
  arch=${d##*/};

  echo "########## Processing $suite-$arch ##########";
  ${DRYRUN} docker build --no-cache=true -t vicamo/buildpack-deps:$suite-$arch-curl $suite/$arch/curl \
    && ([ x$arch = xamd64 ] && ${DRYRUN} docker tag -f vicamo/buildpack-deps:$suite-$arch-curl vicamo/buildpack-deps:$suite-curl || true) \
    && ${DRYRUN} docker build --no-cache=true -t vicamo/buildpack-deps:$suite-$arch-scm $suite/$arch/scm \
    && ([ x$arch = xamd64 ] && ${DRYRUN} docker tag -f vicamo/buildpack-deps:$suite-$arch-scm vicamo/buildpack-deps:$suite-scm || true) \
    && ${DRYRUN} docker build --no-cache=true -t vicamo/buildpack-deps:$suite-$arch $suite/$arch \
    && ([ x$arch = xamd64 ] && ${DRYRUN} docker tag -f vicamo/buildpack-deps:$suite-$arch vicamo/buildpack-deps:$suite || true) \
    || echo "##### FAILED #####"
done
