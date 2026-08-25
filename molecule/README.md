<!--
SPDX-FileCopyrightText: 2018-2025 Slavi Pantaleev
SPDX-FileCopyrightText: 2019-2022 Aaron Raimist
SPDX-FileCopyrightText: 2019-2023 MDAD project contributors
SPDX-FileCopyrightText: 2023 QEDeD
SPDX-FileCopyrightText: 2024 Fabio Bonelli
SPDX-FileCopyrightText: 2024 Nikita Chernyi
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara
SPDX-FileCopyrightText: 2026 spatterlight

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Molecule Testing

This role supports [Molecule](https://docs.ansible.com/projects/molecule/), an Ansible testing framework designed for developing and testing Ansible collections, playbooks, and roles.

## Prerequisites

To utilize Molecule you need to prepare several requirements:

- **x86** computer running one of these operating systems that make use of [systemd](https://systemd.io/):
  - **Archlinux**
  - **CentOS**, **Rocky Linux**, **AlmaLinux**, or possibly other RHEL alternatives (although your mileage may vary)
  - **Debian** (10/Buster or newer)
  - **Ubuntu** (18.04 or newer, although [20.04 may be problematic](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/ansible.md#supported-ansible-versions) if you run the Ansible playbook on it)
- `root` access on the computer which Molecule runs against
- [Ansible](http://ansible.com/) program
- [Python](https://www.python.org/)
  - Most distributions install Python by default, but some don't (e.g. Ubuntu 18.04) and require manual installation (something like `apt-get install python3`)
- [Docker](https://www.docker.com)
  - Access to Docker UNIX socket (`/var/run/docker.sock`) is required by default

## Installation

To set up the environment for using Molecule, run the command below on the terminal:

```bash
python3 -m venv ./molecule/venv
source ./molecule/venv/bin/activate
pip3 install -r ./molecule/requirements.txt
```

## Scenarios

Currently there is one testing scenario available.

### `default`

Tests a standard Mobilizon installation against a [PostGIS](https://github.com/mother-of-all-self-hosting/ansible-role-postgis) database.

Besides installing the role, the scenario exercises the deployment end to end:

- it runs Mobilizon on a port the container image does not listen on by default, so that an HTTP response is proof that `mobilizon_container_http_port` reached the process rather than being decorative
- it asserts that the version reported over `nodeinfo` and over the GraphQL API is the `mobilizon_version` that [`defaults/main.yml`](../defaults/main.yml) ships (the container image's `org.opencontainers.image.version` label is empty, so it cannot be used for this)
- it asserts that the instance name and the registration policy the role rendered into the `env` file are what Mobilizon actually runs with — an unconfigured image would report the name `Mobilizon` instead
- it creates an administrator through the role's own `mobilizon_ctl users.new` code path, logs in over GraphQL, creates a profile, a group and an event with a physical address, and reads the group and the event back anonymously
- it then reads those records straight out of the PostGIS container with `psql`, using `ST_X()`, `ST_Y()`, `GeometryType()` and `PostGIS_Lib_Version()` — functions which do not exist without the PostGIS extension, so the query proves both that the database this role wired up is the one Mobilizon writes to, and that it really is PostGIS-enabled

An unconfigured Mobilizon container never serves HTTP at all: its entrypoint loops on `pg_isready` until a database answers, runs the Ecto migrations, and only then starts serving. `Restart=always` nevertheless keeps the systemd unit `active` the whole time, which is why the scenario treats `systemctl is-active` as a smoke gate only.

## Running

By default it is configured to run the scenarios on Ubuntu 26.04.

```bash
molecule test --scenario-name default
```

You can utilize other distributions by setting one to the `MOLECULE_DISTRO` environment variable:

```bash
# Ubuntu 24.04
MOLECULE_DISTRO=ubuntu2404 molecule test --scenario-name default

# Debian 13
MOLECULE_DISTRO=debian13 molecule test --scenario-name default

# Debian 12
MOLECULE_DISTRO=debian12 molecule test --scenario-name default
```
