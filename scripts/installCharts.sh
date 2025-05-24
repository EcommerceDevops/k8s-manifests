#!/bin/bash

# Get the absolute path to the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$SCRIPT_DIR/manifests"

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

NAMESPACE="default"

for CHART in "${CHARTS[@]}"; do
  echo "🚀 Installing or upgrading Helm chart: $CHART..."
  helm upgrade --install "$CHART" "$BASE_DIR/$CHART" --namespace "$NAMESPACE"
  echo ""
done

echo "✅ All Helm charts have been successfully installed or upgraded."
