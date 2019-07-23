[![Slack](https://slack.appscode.com/badge.svg)](https://slack.appscode.com)
[![Twitter](https://img.shields.io/twitter/follow/appscodehq.svg?style=social&logo=twitter&label=Follow)](https://twitter.com/intent/follow?screen_name=AppsCodeHQ)

# Stash Catalog

[stashed/catalog](https://github.com/stashed/catalog) is a collection of plugins for [Stash by AppsCode](https://appscode.com/products/stash/). This installs necessary `Function` and `Task` definitions that enable Stash to backup various targets such as databases, cluster resources, etc.

## Available Catalogs

| Catalog                                               | Usage                   | Available Versions          |
| ----------------------------------------------------- | ----------------------- | --------------------------- |
| [postgres-stash](https://github.com/stashed/postgres) | Stash PostgreSQL plugin | 9.6, 10.2, 10.6, 11.1, 11.2 |

## Install

This repository provides two installation scripts. You can use them to install individual catalog as a Helm chart release or you can create the YAMLs of the respective catalog if you don't prefer Helm.

### Install as chart release

Use [chart.sh](https://github.com/stashed/catalog/blob/master/deploy/chart.sh) script to install the individual catalogs as a chart release.

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash
```

The above installation script will install all the versions of all available catalogs. You can install only a specific version of a specific catalog which has been shown in [Customizing installation](#customizing-installation) section.

### Install only YAMLs

If you don't prefer Helm, use [setup.sh](https://github.com/stashed/catalog/blob/master/deploy/script.sh) script to create only the YAMLs of the respective catalogs.

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/script.sh | bash
```

> This script will still use Helm to render the YAMLs. It will download helm if it is not installed in your machine. However, it will not install helm in your machine and it does not require tiller to perform its operation.

### Customizing installation

You can use `--catalog` and `--version` flag to choose which catalog and which version to install. These flags are available in both scripts.

**Install all versions of a specific catalog:**

If you want to install all available versions of a specific catalog, use `--catalog` flag to specify the desired catalog.

Following command install all the available versions of `postgres-stash` catalog:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --catalog=postgres-stash
```

**Install a specific version of a specific catalog:**

If you want to install a specific version of a specific catalog, use `--version` flag along with `--catalog` flag to specify the desired version of the desired catalog.

Following command install only version `10.2` of `postgres-stash` catalog:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --catalog=postgres-stash --version=10.2
```

## Uninstall

Use `--uninstall` flag with any of the installation scripts to uninstall the respective resources created by that script.

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall
```

To uninstall all version of a specific catalog, use `--catalog` flag along with `--uninstall` flag. For example:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall --catalog=postgres-stash
```

To uninstall a specific version of a specific catalog, use `--version` flag along with `--uninstall` and `--catalog` flags. For example:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall --catalog=postgres-stash --version=10.2
```

## Configuration Options

You can configure the respective catalog using the following flags:

| Flag                | Usage                                                                                                                                  |
| ------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `--catalog`         | Specify a specific catalog variant to install.                                                                                         |
| `--version`         | Specify a specific version of a specific catalog to install. Use it along with `--catalog` flag.                                       |
| `--docker-registry` | Specify the docker registry to use to pull respective catalog images. Default Value: `appscode`.                                       |
| `--image`           | Specify the name of the docker image to use for respective catalogs.                                                                   |
| `--image-tag`       | Specify the tag of the docker image to use for respective catalog.                                                                     |
| `--metrics-enabled` | Specify whether to send prometheus metrics after a backup or restore session. Default Value: `true`.                                   |
| `--metrics-labels`  | Specify the labels to apply to the prometheus metrics sent for a backup or restore process. Format: `--metrics-labels="k1=v1\,k2=v2"`. |
| `--pg-backup-args`  | Specify optional arguments to pass to `pgdump` command during backup.                                                                  |
| `--pg-restore-args` | Specify optional arguments to pass to `psql` command during restore.                                                                   |
| `--uninstall`       | Uninstall specific or all catalogs.                                                                                                    |

## Contribution guidelines

Want to help improve Stash? Please start [here](https://appscode.com/products/stash/0.8.3/welcome/contributing).

## Support

We use Slack for public discussions. To chit chat with us or the rest of the community, join us in the [AppsCode Slack team](https://appscode.slack.com/messages/C8NCX6N23/details/) channel `#stash`. To sign up, use our [Slack inviter](https://slack.appscode.com/).

If you have found a bug with Stash or want to request for new features, please [file an issue](https://github.com/stashed/stash/issues/new).
