<!--
SPDX-FileCopyrightText: 2020 Aaron Raimist
SPDX-FileCopyrightText: 2020 Chris van Dijk
SPDX-FileCopyrightText: 2020 Dominik Zajac
SPDX-FileCopyrightText: 2020 Mickaël Cornière
SPDX-FileCopyrightText: 2020-2024 MDAD project contributors
SPDX-FileCopyrightText: 2020-2024 Slavi Pantaleev
SPDX-FileCopyrightText: 2022 François Darveau
SPDX-FileCopyrightText: 2022 Julian Foad
SPDX-FileCopyrightText: 2022 Warren Bailey
SPDX-FileCopyrightText: 2023 Antonis Christofides
SPDX-FileCopyrightText: 2023 Felix Stupp
SPDX-FileCopyrightText: 2023 Julian-Samuel Gebühr
SPDX-FileCopyrightText: 2023 Pierre 'McFly' Marty
SPDX-FileCopyrightText: 2024 Thomas Miceli
SPDX-FileCopyrightText: 2024-2026 Suguru Hirahara

SPDX-License-Identifier: AGPL-3.0-or-later
-->

# Setting up Mobilizon

This is an [Ansible](https://www.ansible.com/) role which installs [Mobilizon](https://github.com/getmobilizon/mobilizon) to run as a [Docker](https://www.docker.com/) container wrapped in a systemd service.

Mobilizon is a feedback portal for feature requests and suggestions.

See the project's [documentation](https://docs.mobilizon.io/) to learn what Mobilizon does and why it might be useful to you.

## Prerequisites

To run a Mobilizon instance it is necessary to prepare a [Postgres](https://www.postgresql.org/) database server.

If you are looking for an Ansible role for Postgres, you can check out [ansible-role-postgres](https://github.com/mother-of-all-self-hosting/ansible-role-postgres) maintained by the [Mother-of-All-Self-Hosting (MASH)](https://github.com/mother-of-all-self-hosting) team.

## Adjusting the playbook configuration

To enable Mobilizon with this role, add the following configuration to your `vars.yml` file.

**Note**: the path should be something like `inventory/host_vars/mash.example.com/vars.yml` if you use the [MASH Ansible playbook](https://github.com/mother-of-all-self-hosting/mash-playbook).

```yaml
########################################################################
#                                                                      #
# mobilizon                                                            #
#                                                                      #
########################################################################

mobilizon_enabled: true

########################################################################
#                                                                      #
# /mobilizon                                                           #
#                                                                      #
########################################################################
```

### Set the hostname

To enable Mobilizon you need to set the hostname as well. To do so, add the following configuration to your `vars.yml` file. Make sure to replace `example.com` with your own value.

```yaml
mobilizon_hostname: "example.com"
```

After adjusting the hostname, make sure to adjust your DNS records to point the domain to your server.

**Note**: hosting Mobilizon under a subpath (by configuring the `mobilizon_path_prefix` variable) does not seem to be possible due to Mobilizon's technical limitations.

### Set variables for the database server

To have the Mobilizon instance connect to your Postgres server, add the following configuration to your `vars.yml` file.

```yaml
mobilizon_database_hostname: YOUR_POSTGRES_SERVER_HOSTNAME_HERE
mobilizon_database_port: 5432
mobilizon_database_username: YOUR_POSTGRES_SERVER_USERNAME_HERE
mobilizon_database_password: YOUR_POSTGRES_SERVER_PASSWORD_HERE
mobilizon_database_name: YOUR_POSTGRES_SERVER_DATABASE_NAME_HERE
```

Make sure to replace the placeholders with your own values.

### Set a random string

You also need to set a random secure string. To do so, add the following configuration to your `vars.yml` file. The value can be generated with `pwgen -s 64 1` or in another way.

```yaml
mobilizon_environment_variables_jwt_secret: YOUR_SECRET_KEY_HERE
```

### Configure the mailer

It is also necessary to configure a mailer to enable email functions such as creating the first administrator user. For the mailer you can use a SMTP server, Mailgun, or Amazon SES (Simple Email Service).

To specify the email address from which messages will be sent, add the following configuration to your `vars.yml` file:

```yaml
mobilizon_environment_variables_email_noreply: YOUR_EMAIL_ADDRESS_HERE
```

To configure a SMTP server, add the following configuration to your `vars.yml` file as below (adapt to your needs):

```yaml
# Control if SMTP server is enabled as the email sender
mobilizon_mailer_smtp_enabled: true

# Specify SMTP server hostname
mobilizon_environment_variables_email_smtp_host: ""

# Specify SMTP server port
mobilizon_environment_variables_email_smtp_port: 587

# Specify SMTP server username
mobilizon_environment_variables_email_smtp_username: ""

# Specify SMTP server password
mobilizon_environment_variables_email_smtp_password: ""

# Set `true` to enable STARTTLS
mobilizon_environment_variables_email_smtp_enable_starttls: ""
```

See [this section](https://docs.mobilizon.io/hosting-instance/#installing-and-running) on the official documentation for details about how to configure the mailer for Railgun or Amazon SES.

>[!WARNING]
> Without setting an authentication method such as DKIM, SPF, and DMARC for your hostname, emails are most likely to be quarantined as spam at recipient's mail servers. The worst scenario is that your server's IP address or hostname will be included in the spam list such as the one managed by [Spamhaus](https://www.spamhaus.org/). If you have set up a mail server with the [MASH project's exim-relay Ansible role](https://github.com/mother-of-all-self-hosting/ansible-role-exim-relay), you can enable DKIM signing with it. Refer [its documentation](https://github.com/mother-of-all-self-hosting/ansible-role-exim-relay/blob/main/docs/configuring-exim-relay.md#enable-dkim-support-optional) for details.

### Integrating with Prometheus (optional)

Mobilizon can natively expose metrics to Prometheus.

If you are looking for an integration, you can check out the MASH playbook. See [this section of the documentation on the playbook](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/services/mobilizon.md#integrating-with-prometheus-optional) for more information.

### Extending the configuration

There are some additional things you may wish to configure about the service.

Take a look at:

- [`defaults/main.yml`](../defaults/main.yml) for some variables that you can customize via your `vars.yml` file. You can override settings (even those that don't have dedicated playbook variables) using the `mobilizon_environment_variables_additional_variables` variable

See [this page](https://docs.mobilizon.io/hosting-instance/) on the official documentation for a complete list of Mobilizon's config options that you could put in `mobilizon_environment_variables_additional_variables`.

## Installing

After configuring the playbook, run the installation command of your playbook as below:

```sh
ansible-playbook -i inventory/hosts setup.yml --tags=setup-all,start
```

If you use the MASH playbook, the shortcut commands with the [`just` program](https://github.com/mother-of-all-self-hosting/mash-playbook/blob/main/docs/just.md) are also available: `just install-all` or `just setup-all`

## Usage

After running the command for installation, Mobilizon becomes available at the specified hostname like `https://example.com`.

To get started, open the URL with a web browser, and register the account. **Note that the first registered user becomes an administrator automatically.**

## Troubleshooting

### Check the service's logs

You can find the logs in [systemd-journald](https://www.freedesktop.org/software/systemd/man/systemd-journald.service.html) by logging in to the server with SSH and running `journalctl -fu mobilizon` (or how you/your playbook named the service, e.g. `mash-mobilizon`).
