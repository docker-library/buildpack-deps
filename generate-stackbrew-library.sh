#!/usr/bin/env bash
set -Eeuo pipefail

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

if [ "$#" -eq 0 ]; then
	versions="$(jq -r 'keys | map(@sh) | join(" ")' versions.json)"
	eval "set -- $versions"
fi

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
	local officialImagesBase="${BASHBREW_LIBRARY:-https://github.com/docker-library/official-images/raw/HEAD/library}/"

	local parentRepoToArchesStr
	parentRepoToArchesStr="$(
		find -name 'Dockerfile' -exec awk -v officialImagesBase="$officialImagesBase" '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|.*\/.*)(:|$)/ {
					printf "%s%s\n", officialImagesBase, $2
				}
			' '{}' + \
			| sort -u \
			| xargs -r bashbrew cat --format '["{{ .RepoName }}:{{ .TagName }}"]="{{ join " " .TagEntry.Architectures }}"'
	)"
	eval "declare -g -A parentRepoToArches=( $parentRepoToArchesStr )"
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

for version; do
	export version
	# buster, bullseye, focal, etc
	codename="$(basename "$version")"
	# debian, ubuntu
	dist="$(dirname "$version")"

	versionAliases=( "$codename" )
	suite="$(jq -r '.[env.version].suite // empty' versions.json)"
	if [ -n "$suite" ]; then
		versionAliases+=( "$suite" )
	fi

	if [ "$suite" = 'stable' ]; then
		versionAliases+=( latest )
	fi

	parent="$(awk 'toupper($1) == "FROM" { print $2 }' "$version/curl/Dockerfile")"
	arches="${parentRepoToArches[$parent]}"

	variants="$(jq -r '.[env.version].variants | map(@sh) | join(" ")' versions.json)"
	eval "variants=( $variants )"
	for variant in "${variants[@]}"; do
		commit="$(dirCommit "$version/$variant")"

		variantAliases=( "${versionAliases[@]/%/${variant:+-$variant}}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		variantArches="$arches"

		# https://github.com/docker-library/official-images/pull/19581#issuecomment-3161255023 - Ubuntu 25.10+ ("questing") has updated their riscv64 baseline to RVA23 which is unsupported by DOI (and ... the entire public hardware ecosystem ATM)
		case "$version" in
			ubuntu/jammy | ubuntu/noble | ubuntu/plucky) ;; # pre-25.10 releases which can keep riscv64 support
			ubuntu/*) variantArches="$(sed <<<" $variantArches " -e 's/ riscv64 / /g')" ;;
		esac

		echo
		cat <<-EOE
			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $version${variant:+/$variant}
		EOE
	done
done
