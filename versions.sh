#!/usr/bin/env bash
set -Eeuo pipefail

distsSuites=( "$@" )
if [ "${#distsSuites[@]}" -eq 0 ]; then
	# when run without arguments, let's use "bashbrew" to get the canonical list of currently supported suites/codenames
	bashbrew --version > /dev/null
	if [ -z "${BASHBREW_LIBRARY:-}" ] || [ ! -s "$BASHBREW_LIBRARY/debian" ] || [ ! -s "$BASHBREW_LIBRARY/ubuntu" ]; then
		tempDir="$(mktemp -d)"
		trap 'rm -rf "$tempDir"' EXIT
		wget -qO "$tempDir/debian" 'https://github.com/docker-library/official-images/raw/HEAD/library/debian'
		wget -qO "$tempDir/ubuntu" 'https://github.com/docker-library/official-images/raw/HEAD/library/ubuntu'
		export BASHBREW_LIBRARY="$tempDir"
		bashbrew cat debian ubuntu > /dev/null
	fi
	dists="$(
		bashbrew cat debian ubuntu --format '
				{{- range .Entries -}}
					{{- $.Tags "" false . | json -}}
					{{- "\n" -}}
				{{- end -}}
			' | jq -r '
				map(select(test("
					# a few tags we explicitly want to ignore in our search for codenames
					:(
						experimental | rc-buggy # not a release
						|
						latest | .*stable | devel | rolling | testing # stable/development/rolling aliases
						|
						.* - .* # anything with a hyphen
						|
						[0-9].* # likewise with numerics
					)$
				"; "x") | not))
				| .[0] // empty # then we filter to the first leftover in each tag group and it should be the codename
				| sub(":"; "/")
				| @sh
			'
	)"
	# TODO expand this and do our supported architectures detection here too, while we've already done the lookups?  Ubuntu version number lookups via this method too?  (unfortunately we can't map Debian codenames to aliases like "stable" this way)
	eval "distsSuites=( $dists )"
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
		echo "$version: $suite"
	else
		echo "$version: ???"
	fi
	export doc version
	json="$(jq <<<"$json" -c --argjson doc "$doc" '.[env.version] = $doc')"
done

jq <<<"$json" -S . > versions.json
