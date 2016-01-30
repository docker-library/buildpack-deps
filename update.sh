#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

debian="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/debian')"
ubuntu="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/ubuntu')"
alpine="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/alpine')"

travisEnv=
for version in "${versions[@]}"; do
    if [ "$version" == "templates" ]; then
	    continue;
	elif echo "$debian" | grep -q "$version:"; then
		dist='debian'
	elif echo "$ubuntu" | grep -q "$version:"; then
		dist='ubuntu'
	elif echo "$alpine" | grep -q "$version:"; then
	    dist='alpine'
	else
		echo >&2 "error: cannot determine repo for '$version'"
		exit 1
	fi
	for variant in curl scm ''; do
		src="Dockerfile-$dist.template${variant:+-$variant}"
		trg="$version${variant:+/$variant}/Dockerfile"
		mkdir -p "$(dirname "$trg")"
		( set -x && sed '
			s!DIST!'"$dist"'!g;
			s!SUITE!'"$version"'!g;
		' "templates/$src" > "$trg" )
	done
	travisEnv+='\n  - VERSION='"$version"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
