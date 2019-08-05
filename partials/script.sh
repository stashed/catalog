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
  *)
    echo "Unrecognized catalog: ${catalog}"
    exit 1
    ;;
  esac

  # install/uninstall this catalog
  handle_catalog "${catalog}" catalog_versions
done
