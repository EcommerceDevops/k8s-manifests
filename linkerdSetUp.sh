#!/bin/bash
#
# deploy_linkerd.sh
#
# Description:
#   This script automates the full setup of Linkerd in a multi-cluster
#   environment. It performs the following actions:
#   1. For each defined profile (devops, staging):
#      - Switches kubectl context.
#      - Deploys Linkerd CRDs, control-plane, and Zipkin via Helmfile.
#      - Installs the Linkerd multicluster control plane components.
#      - Runs a health check to ensure the cluster is ready.
#   2. After all clusters are set up, it links the 'staging' cluster to
#      the 'devops' cluster to enable cross-cluster communication.
#
# Dependencies:
#   - kubectl, helmfile, linkerd CLI
#   - Minikube profiles ('devops', 'staging') must already exist.
#
# Usage:
#   ./deploy_linkerd.sh
#

# --- Configuration ---
set -e # Exit immediately if a command fails.

# Clusters profiles creation process
minikube start --profile staging --memory=4g --cpus=2 --network=minikube --driver=docker 

minikube start --profile devops --memory=4g --cpus=2 --network=minikube --driver=docker
#With service-cluster-ip-range we define the pods ip range to avoid conflicts with the default minikube range, that is 10.96.0.0/12

# Define the profiles to be processed.
PROFILES=("devops" "staging")

# Define the source and target for the multi-cluster link.
# We are linking FROM staging TO devops.
LINK_SOURCE_PROFILE="staging"
LINK_TARGET_PROFILE="devops"

# Color codes for clearer output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# --- Part 1: Install and Check Components on Each Cluster ---
echo -e "${YELLOW}### PART 1: SETTING UP INDIVIDUAL CLUSTERS ###${NC}"

for profile in "${PROFILES[@]}"; do
  echo -e "\n${BLUE}==================================================${NC}"
  echo -e "${BLUE}🚀 Processing cluster for profile: ${GREEN}${profile}${NC}"
  echo -e "${BLUE}==================================================${NC}"

  # Switch kubectl context
  echo "Switching kubectl context to '${profile}'..."
  kubectl config use-context "${profile}"
  echo -e "✅ Context successfully set to: $(kubectl config current-context)\n"

  # Apply Helmfile charts
  echo "Applying Linkerd CRDs..."
  helmfile -e development -l name=linkerd-crds apply
  echo "Deploying Linkerd Control Plane..."
  helmfile -e development -l name=linkerd-control-plane apply
  echo "Deploying Zipkin..."
  helmfile -e development -l name=zipkin apply

  # Install Linkerd multicluster components
  echo -e "\nInstalling Linkerd Multicluster components..."
  linkerd multicluster install | kubectl apply -f -
  echo "✅ Linkerd Multicluster components applied."

  # Run health check on the cluster
  echo -e "\nRunning health check on '${profile}'..."
  linkerd check
  echo -e "✅ Health check passed for '${profile}'."
done

echo -e "\n${GREEN}### PART 1 COMPLETE: All clusters are individually configured. ###${NC}"


# --- Part 2: Link the Clusters ---
echo -e "\n${YELLOW}### PART 2: LINKING CLUSTERS ###${NC}"
echo -e "\n${BLUE}==================================================${NC}"
echo -e "${BLUE}🔗 Linking cluster ${GREEN}${LINK_SOURCE_PROFILE}${NC} --> ${GREEN}${LINK_TARGET_PROFILE}${NC}"
echo -e "${BLUE}==================================================${NC}"

echo "Generating credentials from '${LINK_TARGET_PROFILE}' and applying to '${LINK_SOURCE_PROFILE}'..."


# Tunnels to allow profiles multicluster communication linking.

#minikube -p "${LINK_SOURCE_PROFILE}" tunnel &
#minikube -p "${LINK_TARGET_PROFILE}" tunnel &
<
sleep 15

# The link command gets credentials from the target and applies them as a secret to the source.
linkerd --context="${LINK_TARGET_PROFILE}" multicluster link --cluster-name "${LINK_TARGET_PROFILE}" | kubectl --context="${LINK_SOURCE_PROFILE}" apply -f -

echo -e "\n✅ Link command executed."
echo "Running a final check on '${LINK_SOURCE_PROFILE}' to verify the link is active..."

# Switch context to the source cluster to verify the link from its perspective
kubectl config use-context "${LINK_SOURCE_PROFILE}"
linkerd check

echo -e "\n🎉 ${GREEN}All clusters configured and linked successfully!${NC}"





