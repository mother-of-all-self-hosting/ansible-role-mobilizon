#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Exercises bin/compute-next-tag.sh against throwaway git repositories.
#
# Usage: bin/test-compute-next-tag.sh
#
# Every scenario creates a repository in a temporary directory, gives it role
# files and a release history, and then replays a series of merges through the
# real script, tagging as it goes just like the autotag workflow does. This
# repository is never touched and no network access is needed.

set -euo pipefail

script_under_test="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/compute-next-tag.sh"

failures=0
workdir=''

cleanup() {
	cd /
	if [ -n "$workdir" ]; then
		rm -rf "$workdir"
		workdir=''
	fi
}

trap cleanup EXIT

# Starts a scenario with a repository at Mobilizon 5.2.4 which has already seen
# two releases of it (v5.2.4-0 and v5.2.4-1), preceded by the five releases of
# 5.2.3 and the three of 3.1.0 that this repository really carries.
#
# The defaults file deliberately carries the traps this role's real one has: the
# Renovate annotation that decorates the version, a commented-out example of the
# version variable, and two variables derived from it (the image tag and the
# self-build repository version). None of them may be picked up as the version,
# and the annotation is present so that a refactor which starts reading the
# version off the annotation line instead of off the leaf literal fails here.
scenario() {
	echo "$1"

	cleanup
	workdir="$(mktemp -d)"

	mkdir -p "$workdir/bin" "$workdir/defaults" "$workdir/tasks" "$workdir/templates"
	cp "$script_under_test" "$workdir/bin/"
	cd "$workdir"

	git init -q -b main .
	git config user.email 'test@example.com'
	git config user.name 'Test'
	git config commit.gpgsign false

	cat > defaults/main.yml <<-'YAML'
		# mobilizon_version: 9.9.9
		# renovate: datasource=docker depName=kaihuri/mobilizon versioning=semver
		mobilizon_version: 5.2.4
		mobilizon_container_image_tag: "{{ mobilizon_version }}"
		mobilizon_container_image_self_build_repo_version: "{{ mobilizon_version if mobilizon_version != 'latest' else 'main' }}"
	YAML
	printf 'placeholder\n' > tasks/main.yml
	printf 'placeholder\n' > templates/env.j2
	printf 'placeholder\n' > README.md

	git add -A
	git commit -qm 'Initial commit'

	local tag
	for tag in v3.1.0-0 v3.1.0-1 v3.1.0-2 v5.2.3-0 v5.2.3-1 v5.2.3-2 v5.2.3-3 v5.2.3-4 v5.2.4-0 v5.2.4-1; do
		git tag "$tag"
	done
}

# Applies a change, commits it, and tags whatever the script says it should be.
# Prints the tag, or nothing when the script decided against a release.
merge() {
	local change="$1" tag

	eval "$change"
	git add -A
	git commit -qm 'Merge'

	tag="$(bin/compute-next-tag.sh 2>/dev/null)"

	if [ -n "$tag" ]; then
		git tag "$tag"
	fi

	printf '%s' "$tag"
}

expect() {
	local description="$1" expected="$2" actual="$3"

	if [ "$actual" = "$expected" ]; then
		printf '  ok   | %s -> %s\n' "$description" "${actual:-no release}"
	else
		printf '  FAIL | %s -> expected %s, got %s\n' "$description" "${expected:-no release}" "${actual:-no release}"
		failures=$((failures + 1))
	fi
}

bump_version="sed -i 's|^mobilizon_version: 5.2.4|mobilizon_version: 5.2.5|' defaults/main.yml"
revert_version="sed -i 's|^mobilizon_version: 5.2.5|mobilizon_version: 5.2.4|' defaults/main.yml"
edit_task="printf 'a task\n' >> tasks/main.yml"
edit_template="printf 'a line\n' >> templates/env.j2"
edit_readme="printf 'documentation\n' >> README.md"
edit_script="printf '# a comment\n' >> bin/compute-next-tag.sh"

# The two merge orders below apply the same updates and must each end up with
# every update released exactly once, whichever order they arrive in.

scenario 'A version bump merged before other role changes'
expect 'version bump' v5.2.5-0 "$(merge "$bump_version")"
expect 'task edit'    v5.2.5-1 "$(merge "$edit_task")"
expect 'template'     v5.2.5-2 "$(merge "$edit_template")"

scenario 'A version bump merged after other role changes'
expect 'task edit'    v5.2.4-2 "$(merge "$edit_task")"
expect 'version bump' v5.2.5-0 "$(merge "$bump_version")"

# Upstream also publishes arch-flavoured tags (5.2.4-amd64, 5.2.4-arm64). Should
# one ever land in defaults/main.yml, the release counter must not be read off
# the flavour suffix - a `v5.2.4-amd64` version would produce the prefix
# `v5.2.4-amd64-`, which matches no existing tag, and so restart at 0 rather
# than silently colliding with the `-N` release counter of 5.2.4.
scenario 'An arch-flavoured upstream tag in defaults'
expect 'flavoured version' v5.2.4-amd64-0 "$(merge "sed -i 's|^mobilizon_version: 5.2.4|mobilizon_version: 5.2.4-amd64|' defaults/main.yml")"

# Releases of an older version must not be counted as releases of the current
# one: 5.2.3 saw five of them, and the counter for 5.2.4 continues from 5.2.4's
# own two, not from those.
scenario 'Releases of an older version'
expect 'a task' v5.2.4-2 "$(merge "$edit_task")"

scenario 'Commits that do not affect the role'
expect 'README'   ''        "$(merge "$edit_readme")"
expect 'a script' ''        "$(merge "$edit_script")"
expect 'a task'   v5.2.4-2  "$(merge "$edit_task")"

scenario 'Release numbers past 9'
for release_number in 2 3 4 5 6 7 8 9 10; do
	git tag "v5.2.4-$release_number"
done
expect 'a task' v5.2.4-11 "$(merge "$edit_task")"

scenario 'Reverting to an already released version'
merge "$bump_version" > /dev/null
# The role is now identical to what v5.2.4-1 already published, so there is
# nothing new to release.
expect 'a revert' ''        "$(merge "$revert_version")"

scenario 'Reverting to an already released version, with a change'
merge "$bump_version" > /dev/null
expect 'a revert' v5.2.4-2 "$(merge "$revert_version && $edit_task")"

if [ "$failures" -gt 0 ]; then
	echo >&2 "$failures scenario(s) behaved unexpectedly"
	exit 1
fi

echo 'All scenarios behaved as expected'
