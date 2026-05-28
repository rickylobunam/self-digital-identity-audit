// ═══════════════════════════════════════════════════════════════════════
// SDIA — Azure Infrastructure (Bicep)
// main.bicep: Módulo raíz de infraestructura
// Despliega: ACR, ACA Environment, Cosmos DB, Storage, Key Vault, ACS
// ═══════════════════════════════════════════════════════════════════════

targetScope = 'resourceGroup'

@description('Deployment environment')
@allowed(['dev', 'staging', 'prod'])
param environment string = 'dev'

@description('Azure region')
param location string = resourceGroup().location

@description('Prefix for resource names')
param resourcePrefix string = 'sdia'

@description('Orchestrator image tag in ACR')
param orchestratorImageTag string = 'latest'

@description('Deploy the orchestrator (Container App Job)')
param deployOrchestrator bool = false

var tags = {
  project: 'SDIA'
  environment: environment
  managedBy: 'Bicep'
  license: 'MIT'
}

// ── Azure Container Registry ──────────────────────────────────────────
module acr './modules/acr.bicep' = {
  name: 'acr-${environment}'
  params: {
    name: '${resourcePrefix}acr${environment}'
    location: location
    tags: tags
  }
}

// ── Log Analytics Workspace (for ACA) ────────────────────────────────
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: '${resourcePrefix}-logs-${environment}'
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
  }
}

// ── Azure Container Apps Environment ─────────────────────────────────
resource acaEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: '${resourcePrefix}-env-${environment}'
  location: location
  tags: tags
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

// ── Azure Key Vault ───────────────────────────────────────────────────
module keyVault './modules/keyvault.bicep' = {
  name: 'kv-${environment}'
  params: {
    name: '${resourcePrefix}-kv-${environment}'
    location: location
    tags: tags
  }
}

// ── Azure Cosmos DB (Serverless) ──────────────────────────────────────
module cosmosDb './modules/cosmosdb.bicep' = {
  name: 'cosmos-${environment}'
  params: {
    accountName: '${resourcePrefix}-cosmos-${environment}'
    location: location
    tags: tags
    databaseName: 'sdia'
    containerName: 'audit-jobs'
    partitionKeyPath: '/requestId'
    defaultTtl: 172800  // 48 horas en segundos
  }
}

// ── Azure Storage Account (Blob for temporary PDFs) ──────────────────
module storage './modules/storage.bicep' = {
  name: 'storage-${environment}'
  params: {
    accountName: '${resourcePrefix}stor${environment}'
    location: location
    tags: tags
    containerName: 'sdia-reports'
  }
}

// ── Azure Communication Services ─────────────────────────────────────
resource acs 'Microsoft.Communication/communicationServices@2023-04-01' = {
  name: '${resourcePrefix}-acs-${environment}'
  location: 'global'
  tags: tags
  properties: {
    dataLocation: 'United States'
  }
}

// ── Backend API — Azure Container App (always-on, scale-to-zero) ─────────────────────────────────
module backendApp './modules/containerapp.bicep' = {
  name: 'backend-${environment}'
  params: {
    name: '${resourcePrefix}-api-${environment}'
    location: location
    tags: tags
    environmentId: acaEnvironment.id
    imageName: '${acr.outputs.loginServer}/sdia-backend:latest'
    minReplicas: 0
    maxReplicas: 3
    targetPort: 3000
    keyVaultName: keyVault.outputs.name
    envVars: [
      { name: 'NODE_ENV', value: 'production' }
      { name: 'PORT', value: '3000' }
      { name: 'COSMOS_ENDPOINT', value: cosmosDb.outputs.endpoint }
      { name: 'COSMOS_DB_NAME', value: 'sdia' }
      { name: 'COSMOS_CONTAINER', value: 'audit-jobs' }
      // Secrets via Key Vault references (Managed Identity)
      { name: 'JWT_SECRET', secretRef: 'jwt-secret' }
      { name: 'ACS_CONNECTION_STRING', secretRef: 'acs-connection-string' }
    ]
  }
}

// ── Orchestrator — Azure Container App JOB (ephemeral, on-demand) ────────
module orchestratorJob './modules/containerapp-job.bicep' = if (deployOrchestrator) {
  name: 'orchestrator-job-${environment}'
  params: {
    name: '${resourcePrefix}-orchestrator-job-${environment}'
    location: location
    tags: tags
    environmentId: acaEnvironment.id
    imageName: '${acr.outputs.loginServer}/sdia-orchestrator:${orchestratorImageTag}'
    keyVaultName: keyVault.outputs.name
    envVars: [
      { name: 'COSMOS_ENDPOINT', value: cosmosDb.outputs.endpoint }
      { name: 'COSMOS_DB_NAME', value: 'sdia' }
      { name: 'COSMOS_CONTAINER', value: 'audit-jobs' }
      { name: 'BLOB_CONTAINER_NAME', value: 'sdia-reports' }
      { name: 'OSINT_MAX_CONCURRENT', value: '3' }
      // Secrets via Key Vault references
      { name: 'AZURE_OPENAI_ENDPOINT', secretRef: 'aoai-endpoint' }
      { name: 'AZURE_OPENAI_API_KEY', secretRef: 'aoai-key' }
      { name: 'BLOB_CONNECTION_STRING', secretRef: 'blob-connection-string' }
      { name: 'ACS_CONNECTION_STRING', secretRef: 'acs-connection-string' }
      { name: 'PDF_OWNER_SECRET', secretRef: 'pdf-owner-secret' }
    ]
  }
}

// ── Outputs ────────────────────────────────────────────────────────────
output backendUrl string = backendApp.outputs.fqdn
output acrLoginServer string = acr.outputs.loginServer
output cosmosEndpoint string = cosmosDb.outputs.endpoint
output keyVaultName string = keyVault.outputs.name
