#!/usr/bin/env bash
set -Eeuo pipefail

declare -A aliases=(
	#[stretch]='latest'
	# ("latest" determined automatically below)
)

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( */ )
versions=( "${versions[@]%/}" )

# get the most recent commit which modified any of "$@"
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# get the most recent commit which modified "$1/Dockerfile" or any file COPY'd from "$1/Dockerfile"
dirCommit() {
	local dir="$1"; shift
	(
		cd "$dir"
		fileCommit \
			Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++) {
						print $i
					}
				}
			')
	)
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -A -g parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches 'buildpack-deps'

cat <<-EOH
# this file is generated via https://github.com/docker-library/buildpack-deps/blob/$(fileCommit "$self")/$self

Maintainers: Tianon Gravi <admwiggin@gmail.com> (@tianon),
             Joseph Ferguson <yosifkit@gmail.com> (@yosifkit)
GitRepo: https://github.com/docker-library/buildpack-deps.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

for version in "${versions[@]}"; do
	versionAliases=( $version ${aliases[$version]:-} )

	if debianSuite="$(
		wget -qO- -o /dev/null "https://deb.debian.org/debian/dists/$version/Release" \
			| gawk -F ':[[:space:]]+' '$1 == "Suite" { print $2 }'
	)" && [ -n "$debianSuite" ]; then
		# "stable", "oldstable", etc.
		versionAliases+=( "$debianSuite" )
		if [ "$debianSuite" = 'stable' ]; then
			versionAliases+=( latest )
		fi
	elif ubuntuVersion="$(
		wget -qO- -o /dev/null "http://archive.ubuntu.com/ubuntu/dists/$version/Release" \
			| gawk -F ':[[:space:]]+' '$1 == "Version" { print $2 }'
	)" && [ -n "$ubuntuVersion" ]; then
		versionAliases+=( "$ubuntuVersion" )
	fi

	parent="$(awk 'toupper($1) == "FROM" { print $2 }' "$version/curl/Dockerfile")"
	arches="${parentRepoToArches[$parent]}"

	for variant in curl scm; do
		commit="$(dirCommit "$version/$variant")"

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $arches)
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done

	commit="$(dirCommit "$version")"

	echo
	cat <<-EOE
		Tags: $(join ', ' "${versionAliases[@]}")
		Architectures: $(join ', ' $arches)
		GitCommit: $commit
		Directory: $version
	EOE
done
