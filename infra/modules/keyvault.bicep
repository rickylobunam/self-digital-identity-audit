// ── modules/keyvault.bicep ───────────────────────────────────────────

param name string
param location string
param tags object

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true        // RBAC authorization (modern approach)
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    enablePurgeProtection: false         // Allow purge in dev/hackathon
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

output name string = keyVault.name
output uri string = keyVault.properties.vaultUri
