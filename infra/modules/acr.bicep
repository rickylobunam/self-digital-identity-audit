// ── modules/acr.bicep ───────────────────────────────────────────────

param name string
param location string
param tags object

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  tags: tags
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false  // Use Managed Identity, not admin user
    publicNetworkAccess: 'Enabled'
  }
}

output loginServer string = registry.properties.loginServer
output name string = registry.name
