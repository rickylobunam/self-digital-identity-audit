#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════
# scripts/deploy.sh — Initial SDIA deployment to Azure
# Usage: bash scripts/deploy.sh --env dev|prod
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Colors ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; NC='\033[0m'

info()    { echo -e "${BLUE}ℹ️  $*${NC}"; }
success() { echo -e "${GREEN}✅ $*${NC}"; }
warn()    { echo -e "${YELLOW}⚠️  $*${NC}"; }
error()   { echo -e "${RED}❌ $*${NC}"; exit 1; }

# ── Arguments ─────────────────────────────────────────────────────
ENV="dev"
while [[ $# -gt 0 ]]; do
  case $1 in
    --env) ENV="$2"; shift 2 ;;
    *) error "Unknown argument: $1" ;;
  esac
done

[[ "$ENV" == "dev" || "$ENV" == "prod" ]] || error "ENV must be 'dev' or 'prod'"

# ── Config ────────────────────────────────────────────────────────
RESOURCE_GROUP="rg-sdia-${ENV}"
LOCATION="mexicocentral"
BICEP_FILE="infra/main.bicep"
PARAMS_FILE="infra/parameters/${ENV}.bicepparam"
DEPLOYMENT_NAME="sdia-${ENV}-$(date +%Y%m%d-%H%M)"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║        SDIA — Deploy Script                                  ║"
echo "║        Environment: ${ENV}                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Verify prerequisites ──────────────────────────────────────────
info "Verifying prerequisites..."
command -v az >/dev/null 2>&1 || error "Azure CLI not installed. See: https://docs.microsoft.com/cli/azure/install-azure-cli"
command -v docker >/dev/null 2>&1 || error "Docker not installed."

# Verify login
az account show >/dev/null 2>&1 || error "Not logged in to Azure. Run: az login"
SUBSCRIPTION=$(az account show --query name --output tsv)
info "Active subscription: ${SUBSCRIPTION}"

# ── Create Resource Group ─────────────────────────────────────────
info "Creating resource group: ${RESOURCE_GROUP}..."
az group create \
  --name "${RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --tags project=SDIA environment="${ENV}" \
  --output none
success "Resource group ready: ${RESOURCE_GROUP}"

# ── Deploy infrastructure with Bicep ─────────────────────────────
info "Deploying infrastructure (Bicep)..."
info "Template: ${BICEP_FILE}"
info "Parameters: ${PARAMS_FILE}"

OUTPUTS=$(az deployment group create \
  --resource-group "${RESOURCE_GROUP}" \
  --template-file "${BICEP_FILE}" \
  --parameters "${PARAMS_FILE}" \
  --name "${DEPLOYMENT_NAME}" \
  --query "properties.outputs" \
  --output json)

ACR_SERVER=$(echo "$OUTPUTS" | python3 -c "import json,sys; print(json.load(sys.stdin)['acrLoginServer']['value'])")
BACKEND_URL=$(echo "$OUTPUTS" | python3 -c "import json,sys; print(json.load(sys.stdin)['backendUrl']['value'])" 2>/dev/null || echo "pending")

success "Infrastructure deployed"
info "ACR Login Server: ${ACR_SERVER}"

# ── Build and push images ─────────────────────────────────────────
info "Building and pushing backend image to ACR..."
az acr build \
  --registry "${ACR_SERVER%.*}" \
  --image "sdia-backend:latest" \
  --file backend/Dockerfile \
  backend/
success "Backend image pushed"

# ── Setup OIDC for GitHub Actions ────────────────────────────────
if [ -f "scripts/setup-github-oidc.sh" ]; then
  info "Setting up OIDC for GitHub Actions..."
  bash scripts/setup-github-oidc.sh --env "${ENV}" --resource-group "${RESOURCE_GROUP}"
fi

# ── Summary ───────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎉 Deployment complete                                      ║"
echo "╠══════════════════════════════════════════════════════════════╣"
printf "║  %-30s %-29s ║\n" "Resource Group:" "${RESOURCE_GROUP}"
printf "║  %-30s %-29s ║\n" "ACR:" "${ACR_SERVER}"
printf "║  %-30s %-29s ║\n" "Backend URL:" "${BACKEND_URL}"
printf "║  %-30s %-29s ║\n" "Frontend:" "GitHub Pages (see docs)"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
warn "Next steps:"
echo "  1. Add secrets to GitHub: AZURE_CLIENT_ID, AZURE_TENANT_ID, etc."
echo "  2. Configure secrets in Azure Key Vault (JWT_SECRET, ACS_CONNECTION_STRING)"
echo "  3. Enable GitHub Pages in Settings → Pages → Source: GitHub Actions"
echo "  4. Push to main to trigger the frontend deploy"
echo ""
