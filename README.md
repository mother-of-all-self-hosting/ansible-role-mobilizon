<!--
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2025, 2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Mobilizon Ansible role

This is an [Ansible](https://www.ansible.com/) role which installs [Mobilizon](https://joinmobilizon.org/en/) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

>[!NOTE]
> The project has been transferred from Framasoft to Kaihuri Association. See [this page](https://framablog.org/2023/12/05/mobilizon-v4-letape-de-la-maturite/) for details.

This role *implicitly* depends on:

- [`com.devture.ansible.role.playbook_help`](https://github.com/devture/com.devture.ansible.role.playbook_help)
- [`com.devture.ansible.role.systemd_docker_base`](https://github.com/devture/com.devture.ansible.role.systemd_docker_base)

Check [`defaults/main.yml`](defaults/main.yml) for the full list of supported options. Refer to [this page](docs/configuring-mobilizon.md) for details about setting up the service with this role.

💡 For an Ansible playbook which integrates this role and makes it easier to use, see the [Mother-of-All-Self-Hosting Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

## Development

### pre-commit

You can optionally install a Git pre-commit hook (via [mise](https://mise.jdx.dev/) + [prek](https://prek.j178.dev/)) that runs formatting and linting checks before each commit. See [`.pre-commit-config.yaml`](./.pre-commit-config.yaml) for which hooks are to be executed.

To install the hook, run the [`just`](https://github.com/casey/just) command below:

```sh
just prek-install-git-pre-commit-hook
```

### Molecule

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

Refer to [this page](./molecule/README.md) for details about how to utilize it.

### Releases

Releases are tagged automatically by [`.github/workflows/autotag.yml`](.github/workflows/autotag.yml), which runs [`bin/compute-next-tag.sh`](bin/compute-next-tag.sh) on every push to the main branch.

The tag is derived from the repository's state — the `mobilizon_version` value in [`defaults/main.yml`](defaults/main.yml) and the tags that already exist — rather than from commit messages:

- when `mobilizon_version` names a version that has never been released, the release counter restarts at `0` (e.g. `v5.2.5-0`)
- otherwise the counter is incremented (e.g. `v5.2.5-1`), but only when something under `defaults/`, `meta/`, `tasks/` or `templates/` has changed since the previous release — a documentation or CI-only commit does not create churn in the playbooks which consume this role

Because the result depends only on the state of the branch, it does not matter in which order pull requests get merged, and any change to the role releases itself without a human tagging.

[`bin/test-compute-next-tag.sh`](bin/test-compute-next-tag.sh) exercises the computation against throwaway repositories. It runs as a pre-commit hook whenever the tagger or `defaults/main.yml` changes.

Mobilizon's own version is deliberately **not** automerged by Renovate: the container image's entrypoint runs `mobilizon_ctl migrate` on every start, and Mobilizon's patch releases do add Ecto migrations, so a version bump wants a human to look at it before it reaches a production database. See [`.github/renovate.json`](.github/renovate.json).
