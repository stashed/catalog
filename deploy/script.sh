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

# This script has been generated automatically by '/partials/build.sh' script.
# Don't modify anything here. Make your desired change in the partial scripts.
# Then, run '/partials/build.sh' script to generate this script with the changes.

CATALOGS=(
    stash-postgres
    stash-mongodb
    stash-elasticsearch
    stash-mysql
    stash-percona-xtradb
)

PG_CATALOG_VERSIONS=(
    9.6
    10.2
    10.6
    11.1
    11.2
)

MGO_CATALOG_VERSIONS=(
    3.4
    3.4.17
    3.4.22
    3.6
    3.6.8
    3.6.13
    4.0
    4.0.3
    4.0.5
    4.0.11
    4.1
    4.1.4
    4.1.7
    4.1.13
)

ES_CATALOG_VERSIONS=(
    5.6
    5.6.4
    6.2
    6.2.4
    6.3
    6.3.0
    6.4
    6.4.0
    6.5
    6.5.3
    6.8
    6.8.0
    7.2
    7.2.0
    7.3
    7.3.2
)

MY_CATALOG_VERSIONS=(
    5.7.25
    8.0.3
    8.0.14
)

XTRADB_CATALOG_VERSIONS=(
    5.7
)
OS=""
ARCH=""
DOWNLOAD_URL=""
DOWNLOAD_DIR=""
TEMP_DIRS=()

HELM=""
HELM_HOME=$HOME/.helm
HELM_VALUES=()

CATALOG_VARIANT="all"
CATALOG_VERSION=""

APPSCODE_ENV=${APPSCODE_ENV:-prod}
APPSCODE_CHART_REGISTRY=${APPSCODE_CHART_REGISTRY:-"appscode"}
APPSCODE_CHART_REGISTRY_URL=${APPSCODE_CHART_REGISTRY_URL:-"https://charts.appscode.com/stable"}

DOCKER_REGISTRY=${REGISTRY:-stashed}
DOCKER_IMAGE=""
DOCKER_TAG=""

PG_BACKUP_ARGS=""
PG_RESTORE_ARGS=""
MGO_BACKUP_ARGS=""
MGO_RESTORE_ARGS=""
ES_BACKUP_ARGS=""
ES_RESTORE_ARGS=""
MY_BACKUP_ARGS=""
MY_RESTORE_ARGS=""
XTRADB_BACKUP_ARGS=""
XTRADB_RESTORE_ARGS=""

UNINSTALL=0

function cleanup() {
    # remove temporary directories
    for dir in "${TEMP_DIRS[@]}"; do
        rm -rf "${dir}"
    done
}

# detect operating system
function detectOS() {
    OS=$(echo $(uname) | tr '[:upper:]' '[:lower:]')

    case "$OS" in
        # Minimalist GNU for Windows
        cygwin* | mingw* | msys*) OS='windows' ;;
    esac
}

# detect machine architecture
function detectArch() {
    ARCH=$(uname -m)
    case $ARCH in
        armv5*) ARCH="armv5" ;;
        armv6*) ARCH="armv6" ;;
        armv7*) ARCH="arm" ;;
        aarch64) ARCH="arm64" ;;
        x86) ARCH="386" ;;
        x86_64) ARCH="amd64" ;;
        i686) ARCH="386" ;;
        i386) ARCH="386" ;;
    esac
}

detectOS
detectArch

# download file pointed by DOWNLOAD_URL variable
# store download file to the directory pointed by DOWNLOAD_DIR variable
# you have to sent the output file name as argument. i.e. downloadFile myfile.tar.gz
function downloadFile() {
    if curl --output /dev/null --silent --head --fail "${DOWNLOAD_URL}"; then
        curl -fsSL ${DOWNLOAD_URL} -o ${DOWNLOAD_DIR}/$1
    else
        echo "File does not exist"
        exit 1
    fi
}

function array_contains() {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array}"; do
        if [[ $element == $seeking ]]; then
            in=0
            break
        fi
    done
    return $in
}

function catalog_version_supported() {
    local catalog_variant=$1
    local version=$2

    case "$catalog_variant" in
        "stash-postgres")
            if array_contains PG_CATALOG_VERSIONS $version; then
                return 0
            else
                return 1
            fi
            ;;
        "stash-mongodb")
            if array_contains MGO_CATALOG_VERSIONS $version; then
                return 0
            else
                return 1
            fi
            ;;
        "stash-elasticsearch")
            if array_contains ES_CATALOG_VERSIONS $version; then
                return 0
            else
                return 1
            fi
            ;;
        "stash-mysql")
            if array_contains MY_CATALOG_VERSIONS $version; then
                return 0
            else
                return 1
            fi
            ;;
        "stash-percona-xtradb")
            if array_contains XTRADB_CATALOG_VERSIONS $version; then
                return 0
            else
                return 1
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

trap cleanup EXIT

show_help() {
    echo "setup.sh - install catalog for stash"
    echo " "
    echo "setup.sh [options]"
    echo " "
    echo "options:"
    echo "-h, --help                             show brief help"
    echo "    --catalog                          specify a specific catalog variant to install."
    echo "    --version                          specify a specific version of a specific catalog to install. use it along with '--catalog' flag."
    echo "    --docker-registry                  specify the docker registry to use to pull respective catalog images. default value: 'stashed'.   "
    echo "    --image                            specify the name of the docker image to use for respective catalogs."
    echo "    --image-tag                        specify the tag of the docker image to use for respective catalog."
    echo "    --pg-backup-args                   specify optional arguments to pass to 'pgdump' command during backup."
    echo "    --pg-restore-args                  specify optional arguments to pass to 'psql' command during  restore."
    echo "    --mg-backup-args                   specify optional arguments to pass to 'mongodump' command during backup."
    echo "    --mg-restore-args                  specify optional arguments to pass to 'mongorestore' command during  restore."
    echo "    --es-backup-args                   specify optional arguments to pass to 'multielasticdump' command during backup."
    echo "    --es-restore-args                  specify optional arguments to pass to 'multielasticdump' command during  restore."
    echo "    --my-backup-args                   specify optional arguments to pass to 'mysqldump' command during backup."
    echo "    --my-restore-args                  specify optional arguments to pass to 'mysql' command during  restore."
    echo "    --xtradb-backup-args               specify optional arguments to pass to 'xtrabackup' command during backup."
    echo "    --xtradb-restore-args              specify optional arguments to pass to 'xtrabackup' command during  restore."
    echo "    --uninstall                        uninstall specific or all catalogs."
}

while test $# -gt 0; do
    case "$1" in
        -h | --help)
            show_help
            exit 0
            ;;
        --catalog*)
            variant=$(echo $1 | sed -e 's/^[^=]*=//g')
            CATALOG_VARIANT=$variant
            shift
            ;;
        --version*)
            version=$(echo $1 | sed -e 's/^[^=]*=//g')
            CATALOG_VERSION=$version
            shift
            ;;
        --docker-registry*)
            DOCKER_REGISTRY=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --image-tag*)
            DOCKER_TAG=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --image*)
            DOCKER_IMAGE=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --pg-backup-args*)
            PG_BACKUP_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --pg-restore-args*)
            PG_RESTORE_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --mg-backup-args*)
            MGO_BACKUP_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --mg-restore-args*)
            MGO_RESTORE_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --es-backup-args*)
            ES_BACKUP_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --es-restore-args*)
            ES_RESTORE_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --my-backup-args*)
            MY_BACKUP_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --my-restore-args*)
            MY_RESTORE_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --xtradb-backup-args*)
            XTRADB_BACKUP_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --xtradb-restore-args*)
            XTRADB_RESTORE_ARGS=$(echo $1 | sed -e 's/^[^=]*=//g')
            shift
            ;;
        --uninstall*)
            UNINSTALL=1
            shift
            ;;
        *)
            echo "unknown flag: $1"
            echo " "
            show_help
            exit 1
            ;;
    esac
done

# check whether catalog variant is supported or not
if [[ $CATALOG_VARIANT != "all" ]]; then
    if ! array_contains CATALOGS $CATALOG_VARIANT; then
        echo "Catalog $CATALOG_VARIANT is not supported"
        exit 1
    else
        CATALOGS=($CATALOG_VARIANT)
    fi
fi

# check whether specified version is supported for respective catalog variant
if [[ $CATALOG_VERSION != "" ]]; then
    if ! catalog_version_supported $CATALOG_VARIANT $CATALOG_VERSION; then
        echo "Catalog $CATALOG_VARIANT does not have version $CATALOG_VERSION"
        exit 1
    fi
fi

# Download helm if the desried version is not installed
function ensure_helm() {
    HELM_VERSION="$1"

    # if the desrired version is already installed then use it
    if [ -x "$(command -v helm)" ]; then
        installed_version="$(helm version --short | head -c2)" # take only the major part of the version
        desired_version="$(echo $HELM_VERSION | head -c2)"     # take only the major part of the version
        if [[ "${installed_version}" == "${desired_version}" ]]; then
            HELM=helm
            return # desired version is present. so, no need to download.
        fi
    fi

    echo "Helm $HELM_VERSION is not installed!. Downloading....."
    ARTIFACT="https://get.helm.sh"
    HELM_BIN=helm
    HELM_DIST=${HELM_BIN}-${HELM_VERSION}-${OS}-${ARCH}.tar.gz

    case "$OS" in
        cygwin* | mingw* | msys*)
            HELM_BIN=${HELM_BIN}.exe
            ;;
    esac

    DOWNLOAD_URL=${ARTIFACT}/${HELM_DIST}
    DOWNLOAD_DIR="$(mktemp -dt helm-XXXXXX)"
    TEMP_DIRS+=($DOWNLOAD_DIR)
    downloadFile ${HELM_DIST}

    tar xf ${DOWNLOAD_DIR}/${HELM_DIST} -C ${DOWNLOAD_DIR}
    HELM=${DOWNLOAD_DIR}/${OS}-${ARCH}/${HELM_BIN}
    chmod +x $HELM

    # Set HELM_HOME to a temporary directory
    export HELM_HOME=$DOWNLOAD_DIR/.helm
}

# generate values flags with provided input
# ========== common values =================
if [[ $DOCKER_REGISTRY != "" ]]; then
    HELM_VALUES+=("--set docker.registry=$DOCKER_REGISTRY")
fi

if [[ $DOCKER_IMAGE != "" ]]; then
    HELM_VALUES+=("--set docker.image=$DOCKER_IMAGE")
fi

if [[ $DOCKER_TAG != "" ]]; then
    HELM_VALUES+=("--set docker.tag=$DOCKER_TAG")
fi

# ========== catalog specific values =================
if [[ $PG_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.pgArgs=$PG_BACKUP_ARGS")
fi
if [[ $PG_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.pgArgs=$PG_RESTORE_ARGS")
fi

if [[ $MGO_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.mgArgs=$MGO_BACKUP_ARGS")
fi
if [[ $MGO_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.mgArgs=$MGO_RESTORE_ARGS")
fi

if [[ $ES_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.esArgs=$ES_BACKUP_ARGS")
fi
if [[ $ES_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.esArgs=$ES_RESTORE_ARGS")
fi

if [[ $MY_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.myArgs=$MY_BACKUP_ARGS")
fi
if [[ $MY_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.myArgs=$MY_RESTORE_ARGS")
fi

if [[ $XTRADB_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.xtradbArgs=$XTRADB_BACKUP_ARGS")
fi
if [[ $XTRADB_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.xtradbArgs=$XTRADB_RESTORE_ARGS")
fi
# create a temporary directory to store charts files
TEMP_CHART_DIR="$(mktemp -dt appscode-XXXXXX)"
TEMP_DIRS+=(${TEMP_CHART_DIR})

# Ensure Helm binary
ensure_helm "v3.0.2"

# Add AppsCode chart registry
$HELM repo add "${APPSCODE_CHART_REGISTRY}" "${APPSCODE_CHART_REGISTRY_URL}"
$HELM repo update

function install_catalog() {
    local catalog="$1"
    local version="$2"

    # render template then pipe to "kubectl apply" command
    $HELM template "${TEMP_CHART_DIR}"/"${catalog}" ${HELM_VALUES[@]} |
        kubectl apply -f -
}

function uninstall_catalog() {
    local catalog="$1"
    local version="$2"

    # render template then pipe to "kubectl delete" command
    $HELM template "${TEMP_CHART_DIR}"/"${catalog}" |
        kubectl delete -f -
}

function handle_catalog() {
    local catalog="$1"
    local -n versions="$2"

    for version in "${versions[@]}"; do
        # download chart from remote repository and extract into the temporary directory we have created earlier
        $HELM fetch --untar "${APPSCODE_CHART_REGISTRY}"/"${catalog}" \
            --untardir "${TEMP_CHART_DIR}" \
            --version="${version}"

        if [[ "${UNINSTALL}" == "1" ]]; then
            uninstall_catalog "${catalog}" "${version}"
        else
            install_catalog "${catalog}" "${version}"
        fi

        # remove the chart so that new version of this chart can be downloaded
        rm -rf ${TEMP_CHART_DIR}/${catalog}
    done
}

catalog_versions=()
for catalog in "${CATALOGS[@]}"; do
    case "${catalog}" in
        "stash-postgres")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${PG_CATALOG_VERSIONS[@]})
            fi
            ;;
        "stash-mongodb")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${MGO_CATALOG_VERSIONS[@]})
            fi
            ;;
        "stash-elasticsearch")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${ES_CATALOG_VERSIONS[@]})
            fi
            ;;
        "stash-mysql")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${MY_CATALOG_VERSIONS[@]})
            fi
            ;;
        "stash-percona-xtradb")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${XTRADB_CATALOG_VERSIONS[@]})
            fi
            ;;
        *)
            echo "Unrecognized catalog: ${catalog}"
            exit 1
            ;;
    esac

    # install/uninstall this catalog
    handle_catalog "${catalog}" catalog_versions
done
