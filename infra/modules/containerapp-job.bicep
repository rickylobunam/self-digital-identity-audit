// ── modules/containerapp-job.bicep ───────────────────────────────────
// Azure Container App JOB for the Python Orchestrator (ephemeral, on-demand)
// Unlike a regular Container App, the Job:
// - Runs once and terminates (no persistence)
// - Has no HTTP ingress
// - Triggered manually from GitHub Actions
// - Cost: only the seconds it is running

param name string
param location string
param tags object
param environmentId string
param imageName string
param keyVaultName string
param envVars array = []

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${name}-identity'
  location: location
  tags: tags
}

resource orchestratorJob 'Microsoft.App/jobs@2023-05-01' = {
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
      triggerType: 'Manual'     // Triggered from GitHub Actions via CLI
      replicaTimeout: 1800      // 30 minutes maximum
      replicaRetryLimit: 1      // No auto-retries (GitHub Actions handles retry)
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
          name: 'orchestrator'
          image: imageName
          resources: {
            cpu: json('1.0')    // More CPU for parallel OSINT processing
            memory: '2Gi'
          }
          env: envVars
        }
      ]
    }
  }
}

output jobName string = orchestratorJob.name
output identityPrincipalId string = identity.properties.principalId
