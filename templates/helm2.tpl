# Ensure Helm binary
ensure_helm "v2.16.12"
$HELM init --client-only

# Add AppsCode chart registry
$HELM repo add "${APPSCODE_CHART_REGISTRY}" "${APPSCODE_CHART_REGISTRY_URL}"
$HELM repo update

function install_catalog() {
    local catalog="$1"
    local version="$2"
    $HELM install "${APPSCODE_CHART_REGISTRY}"/"${catalog}" --name "${catalog}-${version}" --version "${version}" ${HELM_VALUES[@]}
}

function uninstall_catalog() {
    local catalog="$1"
    local version="$2"
    $HELM delete "${catalog}-${version}" --purge
}

function handle_catalog() {
    local catalog="$1"
    local -n versions="$2"

    for version in "${versions[@]}"; do
        if [[ "${UNINSTALL}" == "1" ]]; then
            uninstall_catalog "${catalog}" "${version}"
        else
            install_catalog "${catalog}" "${version}"
        fi
    done
}

catalog_versions=()
for catalog in "${CATALOGS[@]}"; do
    case "${catalog}" in
        "stash-postgres")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${POSTGRES_VERSIONS[@]})
            fi
            ;;
        "stash-mongodb")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${MONGODB_VERSIONS[@]})
            fi
            ;;
        "stash-elasticsearch")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${ELASTICSEARCH_VERSIONS[@]})
            fi
            ;;
        "stash-mysql")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${MYSQL_VERSIONS[@]})
            fi
            ;;
        "stash-percona-xtradb")
            if [[ "${CATALOG_VERSION}" != "" ]]; then
                catalog_versions=("${CATALOG_VERSION}")
            else
                catalog_versions=(${PERCONA_XTRADB_VERSIONS[@]})
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
