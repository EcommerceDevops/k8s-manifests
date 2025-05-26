#!/bin/bash

# ============================================
# uninstall-charts.sh
# ============================================
# Description:
#   Uninstalls Helm charts for all defined microservices.
#   Cleans up their associated Kubernetes resources.
#
# Usage:
#   chmod +x uninstall-charts.sh
#   ./uninstall-charts.sh
#
# Notes:
#   - Customize the NAMESPACE variable as needed.
#   - Ensure Helm and kubectl are installed and configured.
# ============================================

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../manifests"

# List of charts to uninstall
CHARTS=(
  "zipkin"
  "discovery"
  "cloud-config"
  "proxy-client"
  "api-gateway"
  "order-service"
  "payment-service"
  "product-service"
  "shipping-service"
  "user-service"
  "favourite-service"
)

# Namespace in which the charts are installed
NAMESPACE="default"

echo "🚮 Starting Helm charts uninstallation process..."

for CHART in "${CHARTS[@]}"; do
  echo "🗑️ Uninstalling Helm release: $CHART..."
  helm uninstall "$CHART" --namespace "$NAMESPACE"

  if [[ $? -eq 0 ]]; then
    echo "✅ Successfully uninstalled $CHART"
  else
    echo "⚠️ Failed to uninstall $CHART or it was not installed"
  fi

  echo "-------------------------------------------"
done

echo "🏁 Uninstallation process completed for all Helm charts."
