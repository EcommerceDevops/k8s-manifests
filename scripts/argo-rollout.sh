#!/bin/bash

# --- Script para instalar y configurar Argo Rollouts y sus dependencias ---
#
# set -e: Salir inmediatamente si un comando falla.
# set -u: Tratar las variables no definidas como un error.
# set -o pipefail: El código de salida de un pipeline es el del último comando que falló.
set -euo pipefail

echo "➡️  Paso 1: Creando el namespace 'argo-rollouts' (si no existe)..."
# El '|| true' asegura que el script no falle si el namespace ya existe.
kubectl create namespace argo-rollouts || true
echo "✅ Namespace 'argo-rollouts' asegurado."
echo "" # Línea en blanco para separar visualmente

echo "➡️  Paso 2: Aplicando el manifiesto de instalación principal de Argo Rollouts..."
# Este comando instala el controlador, los CRDs, el ServiceAccount, etc.
kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml
echo "✅ Manifiesto principal de Argo Rollouts aplicado."
echo ""

echo "➡️  Paso 3: Aplicando la configuración del plugin Gateway API..."
# Este comando configura el ConfigMap para que el controlador pueda usar el plugin.
# Asume que el archivo está en la ruta relativa ./argo-rollouts/gateway-plugin.yaml
kubectl apply -n argo-rollouts -f ../argo-rollouts/gateway-plugin.yaml
echo "✅ Configuración del plugin aplicada."
echo ""

echo "➡️  Paso 4: Aplicando los permisos RBAC para los namespaces de las aplicaciones..."
# ¡IMPORTANTE! Este comando se ejecuta SIN el flag '-n argo-rollouts' a propósito.
# Esto es para que kubectl respete el 'namespace: default' que está definido dentro del archivo rbac.yaml.
kubectl apply -f ../argo-rollouts/rbac.yaml
echo "✅ Permisos RBAC aplicados en el namespace 'default'."
echo ""

echo "🚀 ¡Instalación y configuración de Argo Rollouts completada!"