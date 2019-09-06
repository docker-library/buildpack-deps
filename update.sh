#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

travisEnv=
for version in "${versions[@]}"; do
	if bashbrew list "https://github.com/docker-library/official-images/raw/master/library/debian:$version" &> /dev/null; then
		dist='debian'
	elif bashbrew list "https://github.com/docker-library/official-images/raw/master/library/ubuntu:$version" &> /dev/null; then
		dist='ubuntu'
	else
		echo >&2 "error: cannot determine repo for '$version'"
		exit 1
	fi
	echo "$version: $dist"
	for variant in curl scm ''; do
		src="Dockerfile${variant:+-$variant}.template"
		trg="$version${variant:+/$variant}/Dockerfile"
		mkdir -p "$(dirname "$trg")"
		sed \
			-e 's!DIST!'"$dist"'!g' \
			-e 's!SUITE!'"$version"'!g' \
			"$src" > "$trg"
		if [ "$dist" = 'debian' ]; then
			# remove "bzr" from buster and later
			case "$version" in
				jessie|stretch) echo ' - how bizarre (still includes "bzr")' ;;
				*)
					sed -i '/bzr/d' "$version/scm/Dockerfile"
					;;
			esac
			if [ "$version" = 'jessie' ]; then
				sed -i '/libmaxminddb-dev/d' "$version/Dockerfile"
			fi
		fi
	done
	travisEnv+='\n  - VERSION='"$version"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
