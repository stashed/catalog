#!/bin/bash
set -eou pipefail

source ./common.sh

if [[ "$APPSCODE_ENV" == "dev" ]]; then
  CHART_LOCATION="chart"
else
  # download chart from remove repository and extract into a temporary directory
  CHART_LOCATION="$(mktemp -dt appscode-XXXXXX)"
  TEMP_DIRS+=(${CHART_LOCATION})
  TEMP_INSTALLER_REPO="${CHART_NAME}-installer"
  $HELM repo add "${TEMP_INSTALLER_REPO}" "https://charts.appscode.com/stable"
  $HELM fetch --untar --untardir ${CHART_LOCATION} "${TEMP_INSTALLER_REPO}/${CHART_NAME}"
  $HELM repo remove "${TEMP_INSTALLER_REPO}"
fi

if [ "$UNINSTALL" -eq 1 ]; then
  $HELM template ${CHART_LOCATION}/${CHART_NAME} \
  | kubectl delete -f -
  
  echo " "
  echo "Successfully uninstalled ${CHART_NAME}"
else
# render the helm template and apply the resulting YAML
$HELM template ${CHART_LOCATION}/${CHART_NAME} \
  --set global.registry=${DOCKER_REGISTRY} \
  --set global.backup.pgArgs=${PG_BACKUP_ARGS} \
  --set global.restore.pgArgs=${PG_RESTORE_ARGS} \
  --set global.metrics.enabled=${ENABLE_PROMETHEUS_METRICS} \
  --set global.metrics.labels=${METRICS_LABELS} \
| kubectl apply -f -

echo " "
echo "Successfully installed ${CHART_NAME}"
fi
