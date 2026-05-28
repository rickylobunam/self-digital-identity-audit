// ── modules/cosmosdb.bicep ──────────────────────────────────────────

param accountName string
param location string
param tags object
param databaseName string
param containerName string
param partitionKeyPath string
param defaultTtl int = 172800

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2023-09-15' = {
  name: accountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    capabilities: [
      { name: 'EnableServerless' }  // Serverless — no fixed cost
    ]
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      { locationName: location, failoverPriority: 0 }
    ]
    enableFreeTier: false
    publicNetworkAccess: 'Enabled'
    networkAclBypass: 'AzureServices'
  }
}

resource database 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-09-15' = {
  parent: cosmosAccount
  name: databaseName
  properties: {
    resource: { id: databaseName }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-09-15' = {
  parent: database
  name: containerName
  properties: {
    resource: {
      id: containerName
      partitionKey: {
        paths: [ partitionKeyPath ]
        kind: 'Hash'
        version: 2
      }
      defaultTtl: defaultTtl  // 48h auto-purge
      indexingPolicy: {
        indexingMode: 'consistent'
        includedPaths: [
          { path: '/status/?' }
          { path: '/createdAt/?' }
          { path: '/emailHash/?' }
        ]
        excludedPaths: [
          { path: '/platforms/*' }  // Do not index OSINT findings
          { path: '/"_etag"/?' }
        ]
      }
    }
  }
}

output endpoint string = cosmosAccount.properties.documentEndpoint
output accountName string = cosmosAccount.name
