#!/bin/bash
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

args=( "$@" )
if [ ${#args[@]} -eq 0 ]; then
	args=( */ )
fi

versions=()
for arg in "${args[@]}"; do
	arg=${arg%/}
	arch=$(echo $arg | cut -d / -f 2)
	version=$(echo $arg | cut -d / -f 1)
	if [ "$arch" == "$version" ]; then
		arch=
	fi

	if [ -z "`echo ${versions[@]} | grep $version`" ]; then
		versions+=( $version )
	fi

	name=arches_$version
	if [ "$arch" ]; then
		eval arches=\( \${${name}[@]} \)
		if [ ${#arches[@]} -ne 0 ]; then
			if [ -z "`echo ${arches[@]} | grep $arch`" ]; then
				eval $name+=\( "$arch" \)
			fi
		else
			eval $name=\( "$arch" \)
		fi
	else
		arches=( $version/*/ )
		arches=( "${arches[@]%/}" )
		arches=( "${arches[@]#$version/}" )
		if [ ${#arches[@]} -lt 0 -o "${arches[0]}" != "*" ]; then
			eval $name=\( ${arches[@]} \)
		fi
	fi

	#echo "arch: $arch, version: $version"
	#echo "versions: ${versions[@]}"
	#eval echo "$name: \${${name}[@]}"
	#echo
done

tasks=()
for version in "${versions[@]}"; do
	name=arches_$version
	eval arches=\( \${${name}[@]} \)
	for arch in "${arches[@]}"; do
		dir="$(readlink -f "$version/$arch")"
		tasks+=( $version/$arch )
	done
done

debian="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/debian')"
ubuntu="$(curl -fsSL 'https://github.com/docker-library/official-images/blob/master/library/ubuntu-debootstrap')"

for task in "${tasks[@]}"; do
	version=$(echo $task | cut -d / -f 1)
	arch=$(echo $task | cut -d / -f 2)
	dir="$(readlink -f "$task")"

	if echo "$debian" | grep -q "$version:"; then
		dist='debian'
	elif echo "$ubuntu" | grep -q "$version:"; then
		dist='ubuntu-debootstrap'
	else
		echo >&2 "error: cannot determine repo for '$version'"
		exit 1
	fi
	for variant in curl scm ''; do
		trg="$version/$arch${variant:+/$variant}/Dockerfile"
		mkdir -p "$(dirname "$trg")"
		if [ "$arch" = "amd64" ]; then
			( set -x && echo "FROM buildpack-deps:$version${variant:+-$variant}" > "$trg" )
		else
			src="Dockerfile.template${variant:+-$variant}"
			( set -x && sed '
				s!DIST!'"$dist"'!g;
				s!SUITE!'"$version"'!g;
				s!ARCH!'"$arch"'!g;
			' "$src" > "$trg" )
		fi
	done
done
