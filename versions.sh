#!/usr/bin/env bash
set -Eeuo pipefail

distsSuites=( "$@" )
if [ "${#distsSuites[@]}" -eq 0 ]; then
	distsSuites=( */*/ )
	json='{}'
else
	json="$(< versions.json)"
fi
distsSuites=( "${distsSuites[@]%/}" )

for version in "${distsSuites[@]}"; do
	codename="$(basename "$version")"
	dist="$(dirname "$version")"
	doc='{"variants": [ "curl", "scm", "" ]}'
	suite=
	case "$dist" in
		debian)
			# "stable", "oldstable", etc.
			suite="$(
				wget -qO- -o /dev/null "https://deb.debian.org/debian/dists/$codename/Release" \
					| gawk -F ':[[:space:]]+' '$1 == "Suite" { print $2 }'
			)"
			;;
		ubuntu)
			suite="$(
				wget -qO- -o /dev/null "http://archive.ubuntu.com/ubuntu/dists/$codename/Release" \
					| gawk -F ':[[:space:]]+' '$1 == "Version" { print $2 }'
			)"
			;;
	esac
	if [ -n "$suite" ]; then
		export suite
		doc="$(jq <<<"$doc" -c '.suite = env.suite')"
	fi
	export doc version
	json="$(jq <<<"$json" -c --argjson doc "$doc" '.[env.version] = $doc')"
done

jq <<<"$json" -S . > versions.json
