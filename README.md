[![Slack](https://slack.appscode.com/badge.svg)](https://slack.appscode.com)
[![Twitter](https://img.shields.io/twitter/follow/appscodehq.svg?style=social&logo=twitter&label=Follow)](https://twitter.com/intent/follow?screen_name=AppsCodeHQ)

# Stash Catalog

[stashed/catalog](https://github.com/stashed/catalog) by AppsCode - A collection of charts that act as plugins for [Stash](https://github.com/stashed/). It holds [Function](https://appscode.com/products/stash/0.8.3/concepts/crds/function/) and [Task](https://appscode.com/products/stash/0.8.3/concepts/crds/task/) definition that are necessary to backup databases, cluster, standalone pvc etc.

## Installation

At first, add AppsCode chart repository and run `helm repo update`.

```console
helm repo add appscode https://charts.appscode.com/stable/
helm repo update
```

Now, install desired catalog by flollowing the instruction give below.

### Install `postgres-catalog`

```console
helm install appscode/postgres-catalog --name postgres-catalog
```

View configurable parameters for **postgres-catalog** chart in `values.yaml` file at `chart/postgres-catalog/` directory of [stashed/catalog](https://github.com/stashed/catalog) repository.

>In order to install all the catalog simultaneously, please follow the guide [here](https://github.com/stashed/installer/tree/master/chart/stash-catalog).

## Test Chart Locally

In order to check the charts locally, we will deploy a chart server locally.

**Deploy a Local Chart Repo:**

```console
# create a directory where we will store the charts
$ mkdir local-repo

# run chart server
$ docker run --rm -it \
  -p 8080:8080 \
  -v $HOME/local-repo:/charts \
  -e STORAGE=local \
  -e STORAGE_LOCAL_ROOTDIR=/charts \
  chartmuseum/chartmuseum
```

**Publish Chart to Local Repository:**

An example of publishing `postgres-stash` chart for [stashed/postgres](https://github.com/stashed/postgres) repository is shown below.

```console
helm package chart/postgres-stash
mv ./postgres-stash-11.tgz $HOME/local-repo/
helm repo index $HOME/local-repo/
```

Run the commands at the root of the respetive repository.

**Use Chart:**

```console
$ helm repo add appscode http://localhost:8080
"appscode" has been added to your repositories

# update dependency of the parent chart
$ helm dependency update chart/postgres-catalog/

# install postgres-catalog chart
$ helm install chart/postgres-catalog --name=postgres-catalog
```

>**Warning:** Repository name must be `appscode`. Otherwise, parent chart will fail to discover the dependencies.

## Contribution guidelines

Want to help improve Stash? Please start [here](https://appscode.com/products/stash/0.8.3/welcome/contributing).

## Support

We use Slack for public discussions. To chit chat with us or the rest of the community, join us in the [AppsCode Slack team](https://appscode.slack.com/messages/C8NCX6N23/details/) channel `#stash`. To sign up, use our [Slack inviter](https://slack.appscode.com/).

If you have found a bug with Stash or want to request for new features, please [file an issue](https://github.com/stashed/stash/issues/new).
