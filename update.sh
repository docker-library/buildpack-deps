#!/bin/bash
set -eo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

debian="$(curl -fsSL 'https://raw.githubusercontent.com/docker-library/official-images/master/library/debian')"
ubuntu="$(curl -fsSL 'https://raw.githubusercontent.com/docker-library/official-images/master/library/ubuntu')"

travisEnv=
for version in "${versions[@]}"; do
	if echo "$debian" | grep -qE "\b$version\b"; then
		dist='debian'
	elif echo "$ubuntu" | grep -qE "\b$version\b"; then
		dist='ubuntu'
	else
		echo >&2 "error: cannot determine repo for '$version'"
		exit 1
	fi
	for variant in curl scm ''; do
		src="Dockerfile${variant:+-$variant}.template"
		trg="$version${variant:+/$variant}/Dockerfile"
		mkdir -p "$(dirname "$trg")"
		(
			set -x
			sed \
				-e 's!DIST!'"$dist"'!g' \
				-e 's!SUITE!'"$version"'!g' \
				"$src" > "$trg"
		)
		if [ "$dist" = 'debian' ]; then
			# remove "bzr" from buster and later
			case "$version" in
				wheezy|jessie|stretch) ;;
				*)
					(
						set -x
						sed -i '/bzr/d' "$version/scm/Dockerfile"
					)
					;;
			esac
		fi
	done
	travisEnv+='\n  - VERSION='"$version"
done

travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
