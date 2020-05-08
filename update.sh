#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */*/ )
fi
versions=( "${versions[@]%/}" )

for version in "${versions[@]}"; do
	suite="$(basename "$version")"
	dist="$(dirname "$version")"
	dist="$(basename "$dist")"
	echo "$version"
	for variant in curl scm ''; do
		src="Dockerfile${variant:+-$variant}.template"
		trg="$version${variant:+/$variant}/Dockerfile"
		mkdir -p "$(dirname "$trg")"
		sed \
			-e 's!DIST!'"$dist"'!g' \
			-e 's!SUITE!'"$suite"'!g' \
			"$src" > "$trg"
		if [ "$dist" = 'debian' ]; then
			# remove "bzr" from buster and later
			case "$suite" in
				jessie | stretch)
					echo ' - how bizarre (still includes "bzr")'
					;;
				*)
					sed -i '/bzr/d' "$version/scm/Dockerfile"
					;;
			esac
			if [ "$suite" = 'jessie' ]; then
				sed -i '/libmaxminddb-dev/d' "$version/Dockerfile"
			fi
		fi
	done
done
