#!/bin/bash
set -eou pipefail

# This script has been generated automatically by '/partials/build.sh' script.
# Don't modify anything here. Make your desired change in the partial scripts.
# Then, run '/partials/build.sh' script to generate this script with the changes.

CATALOGS=(
    stash-postgres
)

PG_CATALOG_VERSIONS=(
    9.6
    10.2
    10.6
    11.1
    11.2
)
OS=""
ARCH=""
DOWNLOAD_URL=""
DOWNLOAD_DIR=""
TEMP_DIRS=()

HELM=""
HELM_VALUES=()

CATALOG_VARIANT="all"
CATALOG_VERSION=""

APPSCODE_ENV=${APPSCODE_ENV:-prod}
APPSCODE_CHART_REGISTRY=${APPSCODE_CHART_REGISTRY:-"appscode"}
APPSCODE_CHART_REGISTRY_URL=${APPSCODE_CHART_REGISTRY_URL:-"https://charts.appscode.com/stable"}

DOCKER_REGISTRY=${REGISTRY:-stashed}
DOCKER_IMAGE=""
DOCKER_TAG=""

ENABLE_PROMETHEUS_METRICS=true
METRICS_LABELS=""

PG_BACKUP_ARGS=""
PG_RESTORE_ARGS=""

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
    echo "    --docker-registry                  specify the docker registry to use to pull respective catalog images. default value: 'appscode'.   "
    echo "    --image                            specify the name of the docker image to use for respective catalogs."
    echo "    --image-tag                        specify the tag of the docker image to use for respective catalog."
    echo "    --metrics-enabled                  specify whether to send prometheus metrics after a backup or restore session. default value: 'true'."
    echo "    --metrics-labels                   specify the labels to apply to the prometheus metrics sent for a backup or restore process. format: '--metrics-labels=\"k1=v1\,k2=v2\" '."
    echo "    --pg-backup-args                   specify optional arguments to pass to 'pgdump' command during backup."
    echo "    --pg-restore-args                  specify optional arguments to pass to 'psql' command during  restore."
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

if [[ $ENABLE_PROMETHEUS_METRICS == "false" ]]; then
    HELM_VALUES+=("--set metrics.enabled=$ENABLE_PROMETHEUS_METRICS")
fi

if [[ $METRICS_LABELS != "" ]]; then
    HELM_VALUES+=("--set metrics.labels='$METRICS_LABELS'")
fi

# ========== catalog specific values =================
if [[ $PG_BACKUP_ARGS != "" ]]; then
    HELM_VALUES+=("--set backup.pgArgs=$PG_BACKUP_ARGS")
fi
if [[ $PG_RESTORE_ARGS != "" ]]; then
    HELM_VALUES+=("--set restore.pgArgs=$PG_RESTORE_ARGS")
fi
# create a temporary directory to store charts files
TEMP_CHART_DIR="$(mktemp -dt appscode-XXXXXX)"
TEMP_DIRS+=(${TEMP_CHART_DIR})

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
  *)
    echo "Unrecognized catalog: ${catalog}"
    exit 1
    ;;
  esac

  # install/uninstall this catalog
  handle_catalog "${catalog}" catalog_versions
done
