#!/bin/bash
set -eou pipefail

GOPATH=$(go env GOPATH)
STASH_ROOT=$GOPATH/src/stash.appscode.dev

source $STASH_ROOT/catalog/partials/catalogs.sh

epoch=$(date +%s)
current_branch=$(git rev-parse --abbrev-ref HEAD)
new_branch="charts-$epoch"
# create new branch where the chart will be stored
git checkout -b $new_branch

function package() {
    local catalog="$1"
    local -n versions="$2"

    # directory where the charts will be stored
    package_dir="$STASH_ROOT/catalog/charts/$catalog/"
    # temporary directory to clone the source repo
    repo_dir="$(mktemp -dt stashed-XXXXXX)"
    # remove "stash-" prefix from catalog name to extract the repo name
    repo=${catalog#"stash-"}

    mkdir -p $package_dir

    pushd $repo_dir
    echo "========= Packaging helm charts for $repo  ========="
    git clone "git@github.com:stashed/$repo.git"

    cd $repo

    for version in "${versions[@]}"; do
        git checkout $version
        helm package chart/$catalog
        mv ./*.tgz $package_dir
    done

    echo "========= Successfullly packaged helm charts for $repo  ========="
    echo
    rm -rf $repo_dir
    popd
}

catalog_versions=()
for catalog in "${CATALOGS[@]}"; do
    case "${catalog}" in
    "stash-postgres")
        catalog_versions=(${PG_CATALOG_VERSIONS[@]})
        ;;
    "stash-mongodb")
        catalog_versions=(${MGO_CATALOG_VERSIONS[@]})
        ;;
    "stash-elasticsearch")
        catalog_versions=(${ES_CATALOG_VERSIONS[@]})
        ;;
    "stash-mysql")
        catalog_versions=(${MY_CATALOG_VERSIONS[@]})
        ;;
    *)
        echo "Unrecognized catalog: ${catalog}"
        exit 1
        ;;
    esac

    # package the chart for this catalog
    package "${catalog}" catalog_versions
done

# push chart into new branch
git add .
git commit -m "Auto package catalog charts"
git push origin $new_branch
# switch to original branch
git checkout $current_branch
