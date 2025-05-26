#!/bin/bash

# Define Helm charts in orden de dependencia
CHARTS_CRITICAL=("zipkin" "discovery" "cloud-config")
CHARTS_REST=("proxy-client" "api-gateway" "order-service" "payment-service" "product-service" "shipping-service" "user-service" "favourite-service")

NAMESPACE="default"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../manifests" && pwd)"

# Función que espera hasta que el deployment esté listo
wait_until_ready() {
  local deployment=$1
  echo "⏳ Waiting for deployment $deployment to be ready..."
  kubectl rollout status deployment/"$deployment" --namespace "$NAMESPACE" --timeout=180s || {
    echo "❌ Deployment $deployment failed to become ready"
    exit 1
  }
}

# Primero los servicios críticos
for CHART in "${CHARTS_CRITICAL[@]}"; do
  echo "🚀 Installing critical chart: $CHART..."
  helm upgrade --install "$CHART" "$BASE_DIR/$CHART" --namespace "$NAMESPACE"
  wait_until_ready "$CHART"
done

# Luego los demás
for CHART in "${CHARTS_REST[@]}"; do
  echo "🚀 Installing chart: $CHART..."
  helm upgrade --install "$CHART" "$BASE_DIR/$CHART" --namespace "$NAMESPACE"
done

echo "✅ All charts installed in order with readiness checks."
