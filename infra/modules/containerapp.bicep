// ── modules/containerapp.bicep ───────────────────────────────────────
// Azure Container App for the Backend API (always-on, scale-to-zero)

param name string
param location string
param tags object
param environmentId string
param imageName string
param minReplicas int = 0
param maxReplicas int = 3
param targetPort int = 3000
param keyVaultName string
param envVars array = []

// User-assigned Managed Identity for Key Vault and ACR access
resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-identity'
  location: location
  tags: tags
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identity.id}': {}
    }
  }
  properties: {
    environmentId: environmentId
    configuration: {
      ingress: {
        external: true
        targetPort: targetPort
        transport: 'http'
        corsPolicy: {
          allowedOrigins: ['https://*.github.io', 'http://localhost:5173']
          allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']
          allowedHeaders: ['Authorization', 'Content-Type']
          maxAge: 3600
        }
      }
      registries: [
        {
          server: split(imageName, '/')[0]
          identity: identity.id
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: imageName
          resources: {
            cpu: json('0.25')
            memory: '0.5Gi'
          }
          env: envVars
          probes: [
            {
              type: 'Liveness'
              httpGet: {
                path: '/health'
                port: targetPort
              }
              initialDelaySeconds: 10
              periodSeconds: 30
            }
          ]
        }
      ]
      scale: {
        minReplicas: minReplicas   // 0 = scale-to-zero (no cost at rest)
        maxReplicas: maxReplicas
        rules: [
          {
            name: 'http-scaling'
            http: {
              metadata: {
                concurrentRequests: '10'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = 'https://${containerApp.properties.configuration.ingress.fqdn}'
output identityId string = identity.id
output identityPrincipalId string = identity.properties.principalId
