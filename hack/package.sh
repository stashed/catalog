#!/bin/bash

# Copyright The Stash Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -eou pipefail

SCRIPT_ROOT=$(dirname "${BASH_SOURCE[0]}")/..
CHART_REPO_ROOT=${CHART_REPO_ROOT:-$HOME/go/src/github.com/appscode/charts}

source $SCRIPT_ROOT/partials/catalogs.sh

function package() {
    local catalog="$1"
    local -n versions="$2"

    # directory where the charts will be stored
    package_dir="$CHART_REPO_ROOT/stable/$catalog/"
    # temporary directory to clone the source repo
    repo_dir="$(mktemp -dt stashed-XXXXXX)"
    # remove "stash-" prefix from catalog name to extract the repo name
    repo=${catalog#"stash-"}

    echo "using chart repository dir: $package_dir"
    mkdir -p $package_dir

    pushd $repo_dir
    echo "========= Packaging helm charts for $repo  ========="
    git clone "git@github.com:stashed/$repo.git"

    cd $repo

    for version in "${versions[@]}"; do
        git checkout $version
        helm package charts/$catalog
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
        "stash-percona-xtradb")
            catalog_versions=(${XTRADB_CATALOG_VERSIONS[@]})
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
pushd $CHART_REPO_ROOT

epoch=$(date +%s)
current_branch=$(git rev-parse --abbrev-ref HEAD)
new_branch="charts-$epoch"

git add .
git checkout -b $new_branch
git commit -s -m "Update Stash addons charts"
git push origin $new_branch

# switch to original branch
git checkout $current_branch
popd
