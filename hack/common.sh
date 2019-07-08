#!/bin/bash
set -eou pipefail

GOPATH=$(go env GOPATH)
REPO_ROOT=$GOPATH/src/stash.appscode.dev/catalog

OS=""
ARCH=""
DOWNLOAD_URL=""
DOWNLOAD_DIR=""
TEMP_DIRS=()

HELM=""
CHART_LOCATION="chart"

CATALOG_VARIANT="all"
CATALOG_VERSION=""

APPSCODE_ENV=${APPSCODE_ENV:-prod}

DOCKER_REGISTRY=${REGISTRY:-appscode}
DOCKER_IMAGE=""
DOCKER_TAG=""

ENABLE_PROMETHEUS_METRICS=true
METRICS_LABELS=""

PG_BACKUP_ARGS=""
PG_RESTORE_ARGS=""

UNINSTALL=0

# source ./hack/catalogs.sh
source "$REPO_ROOT/hack/catalogs.sh"

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

array_contains() {
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

catalog_version_supported() {
    local catalog_variant=$1
    local version=$2

    case "$catalog_variant" in
    "postgres-stash")
        if array_contains PG_CATALOG_VERSIONS $version; then
            return 0
        else
            return 1
        fi
        ;;
    esac
}

trap cleanup EXIT

show_help() {
    echo "setup.sh - install stash-catalog for stash"
    echo " "
    echo "setup.sh [options]"
    echo " "
    echo "options:"
    echo "-h, --help                             show brief help"
    echo "    --catalog                          specify specific catalog variant to install"
    echo "    --version                          specify specific catalog version to install"
    echo "    --docker-registry                  docker registry used to pull postgres-stash images (default: appscode)"
    echo "    --image-tag                        specify tag of the docker image to use for a specific catalog"
    echo "    --image                            specify name of the docker image to use for a specific catalog"
    echo "    --metrics-enabled                  specify whether to send prometheus metrics during backup or restore (default: true)"
    echo "    --metrics-labels                   labels to apply to prometheus metrics for backup or restore process (format: k1=v1,k2=v2)"
    echo "    --pg-backup-args                   optional arguments to pass to pgdump command during backup"
    echo "    --pg-restore-args                  optional arguments to pass to psql command during restore"
    echo "    --uninstall                        uninstall postgres-stash catalog"
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
    --metrics-enabled*)
        val=$(echo $1 | sed -e 's/^[^=]*=//g')
        if [[ "$val" == "false" ]]; then
            ENABLE_PROMETHEUS_METRICS=false
        fi
        shift
        ;;
    --metrics-labels*)
        METRICS_LABELS=$(echo $1 | sed -e 's/^[^=]*=//g')
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
    --uninstall)
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
    fi
fi

# check whether specified version is supported for respective catalog variant
if [[ $CATALOG_VERSION != "" ]]; then
    if ! catalog_version_supported $CATALOG_VARIANT $CATALOG_VERSION; then
        echo "Catalog $CATALOG_VARIANT does not have version $CATALOG_VERSION"
    fi
fi

# Download helm if already not installed
if [ -x "$(command -v helm)" ]; then
    HELM=helm
else
    echo "Helm is not installed!. Downloading Helm."
    ARTIFACT="https://get.helm.sh"
    HELM_VERSION="v2.14.1"
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
fi
