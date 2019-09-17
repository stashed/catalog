[![Slack](https://slack.appscode.com/badge.svg)](https://slack.appscode.com)
[![Twitter](https://img.shields.io/twitter/follow/appscodehq.svg?style=social&logo=twitter&label=Follow)](https://twitter.com/intent/follow?screen_name=AppsCodeHQ)

# Stash Catalog

[stashed/catalog](https://github.com/stashed/catalog) is a collection of plugins for [Stash by AppsCode](https://appscode.com/products/stash/). This installs necessary `Function` and `Task` definitions that enable Stash to backup various targets such as databases, cluster resources, etc.

## Available Catalogs

| Catalog                                                         | Usage                      | Available Versions                      |
| --------------------------------------------------------------- | -------------------------- | --------------------------------------- |
| [stash-postgres](https://github.com/stashed/postgres)           | Stash PostgreSQL plugin    | 11.2<!--, 11.1, 10.6, 10.2, 9.6-->      |
| [stash-mongodb](https://github.com/stashed/mongodb)             | Stash MongoDB plugin       | 3.6<!--, 4.1, 4.0,  3.4-->              |
| [stash-elasticsearch](https://github.com/stashed/elasticsearch) | Stash Elasticsearch plugin | 6.3<!--,7.2, 6.8, 6.5, 6.4, 6.2, 5.6--> |
| [stash-mysql](https://github.com/stashed/postgres)              | Stash MySQL plugin         | 8.0.14<!--, 5.7-->                      |

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

Following command install all the available versions of `stash-postgres` catalog:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --catalog=stash-postgres
```

**Install a specific version of a specific catalog:**

If you want to install a specific version of a specific catalog, use `--version` flag along with `--catalog` flag to specify the desired version of the desired catalog.

Following command install only version `10.2` of `stash-postgres` catalog:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --catalog=stash-postgres --version=10.2
```

## Uninstall

Use `--uninstall` flag with any of the installation scripts to uninstall the respective resources created by that script.

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall
```

To uninstall all version of a specific catalog, use `--catalog` flag along with `--uninstall` flag. For example:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall --catalog=stash-postgres
```

To uninstall a specific version of a specific catalog, use `--version` flag along with `--uninstall` and `--catalog` flags. For example:

```console
curl -fsSL https://github.com/stashed/catalog/raw/master/deploy/chart.sh | bash -s -- --uninstall --catalog=stash-postgres --version=10.2
```

## Configuration Options

You can configure the respective catalog using the following flags:

| Flag                   | Usage                                                                                                                                       |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `--catalog`            | Specify a specific catalog variant to install.                                                                                              |
| `--version`            | Specify a specific version of a specific catalog to install. Use it along with `--catalog` flag.                                            |
| `--docker-registry`    | Specify the docker registry to use to pull respective catalog images. Default Value: `stashed`.                                             |
| `--image`              | Specify the name of the docker image to use for respective catalogs.                                                                        |
| `--image-tag`          | Specify the tag of the docker image to use for respective catalog.                                                                          |
|                        |
| `--pg-backup-args`     | Specify optional arguments to pass to `pgdump` command during backup.                                                                       |
| `--pg-restore-args`    | Specify optional arguments to pass to `psql` command during restore.                                                                        |
| `--mg-backup-args`     | Specify optional arguments to pass to `mongodump` command during backup.                                                                    |
| `--mg-restore-args`    | Specify optional arguments to pass to `mongorestore` command during restore.                                                                |
| `--es-backup-args`     | Specify optional arguments to pass to `multielaticdump` command during backup.                                                              |
| `--es-restore-args`    | Specify optional arguments to pass to `multielastic` command during restore.                                                                |
| `--my-backup-args`     | Specify optional arguments to pass to `mysqldump` command during backup.                                                                    |
| `--my-restore-args`    | Specify optional arguments to pass to `mysql` command during restore.                                                                       |
| `--enable-persistence` | Specify whether to use persistent volume to store the backup/restore data temporarily before uploading to backend or injecting into target. |
| `--pvc`                | Specify name of an existing PVC to use as persistent volume to store data temporarily.                                                      |
| `--pvc-size`           | Specify size of a PVC to be created to use as persistent volume to store data temporarily.                                                  |
| `--pvc-namespace`      | Specify the namespace of the PVC.                                                                                                           |
| `--storageclass`       | Specify the storage class for the PVC.                                                                                                      |
| `--access-mode`        | Specify the access mode for the PVC.                                                                                                        |
| `--uninstall`          | Uninstall specific or all catalogs.                                                                                                         |

## Contribution guidelines

Want to help improve Stash? Please start [here](https://appscode.com/products/stash/0.8.3/welcome/contributing).

## Support

We use Slack for public discussions. To chit chat with us or the rest of the community, join us in the [AppsCode Slack team](https://appscode.slack.com/messages/C8NCX6N23/details/) channel `#stash`. To sign up, use our [Slack inviter](https://slack.appscode.com/).

If you have found a bug with Stash or want to request for new features, please [file an issue](https://github.com/stashed/stash/issues/new).
