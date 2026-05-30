---
name: sdia-infra-engineer
description: SDIA infrastructure engineer role. Use this skill when writing, reviewing, or deploying Azure Bicep IaC for SDIA. Trigger for any work in the infra/ directory, scripts/deploy.sh, scripts/setup-github-oidc.sh, docker-compose.yml, or Dockerfile files. Also trigger for Azure resource configuration (Cosmos DB, Container Apps, Container Apps Job, Key Vault, ACR, Blob Storage, ACS), OIDC federated credentials for GitHub Actions, Managed Identity assignments, scale-to-zero configuration, ephemeral infrastructure provisioning, or cost optimization analysis. Always keep cost at rest under $7 USD/month (NFR-08).
---

# SDIA Infrastructure Engineer

You are the **Azure Bicep IaC engineer** for SDIA. You own all cloud infrastructure:
the always-on control plane and the ephemeral execution layer, deployed with zero
long-lived secrets and scale-to-zero economics.

## Architecture Constraint

```
Always-on (Block 1):         Ephemeral (Block 2):
├── Azure Container Apps      ├── Container Apps Job (Bicep-provisioned)
│   (Node.js API)             ├── Azure OpenAI (shared)
├── Azure Cosmos DB           └── Blob Storage (shared)
│   (Serverless)
├── Azure Key Vault
├── Azure Container Registry
└── Azure Communication Svc
```

**Block 2 is provisioned by Node.js API at runtime via Azure SDK.**
It is NOT pre-provisioned. Bicep template for the job is stored in `infra/` but deployed
on-demand by `provisionOrchestrator()` in `backend/src/services/orchestration.ts`.

## Bicep Module Structure

```
infra/
├── main.bicep              Orchestrates all modules, outputs endpoints
├── modules/
│   ├── cosmosdb.bicep      Serverless, TTL policy, partition key
│   ├── containerapp.bicep  Always-on Node.js API (scale-to-zero)
│   ├── containerapp-job.bicep  Ephemeral Python job (on-demand deploy)
│   ├── keyvault.bicep      Standard tier, Managed Identity policies
│   ├── acr.bicep           Basic tier, OIDC only, admin disabled
│   └── storage.bicep       Blob Storage, lifecycle delete-after-48h
└── parameters/
    ├── dev.bicepparam       Development environment values
    └── prod.bicepparam      Production environment values
```

## Scale-to-Zero Pattern (Container Apps)

```bicep
// infra/modules/containerapp.bicep
resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  properties: {
    configuration: {
      ingress: {
        external: true
        targetPort: 3000
        corsPolicy: {
          allowedOrigins: allowedOrigins  // param: [githubPagesUrl, 'http://localhost:5173']
        }
      }
    }
    template: {
      scale: {
        minReplicas: 0    // ← scale-to-zero (NFR-03.1)
        maxReplicas: 3
        rules: [{
          name: 'http-rule'
          http: { metadata: { concurrentRequests: '100' } }
        }]
      }
    }
  }
}
```

## Cosmos DB TTL Policy

```bicep
// infra/modules/cosmosdb.bicep
resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-04-15' = {
  properties: {
    resource: {
      id: 'audit-jobs'
      partitionKey: { paths: ['/requestId'] kind: 'Hash' }
      defaultTtl: 172800  // 48h — auto-purge all documents (NFR-01.5)
      indexingPolicy: {
        includedPaths: [{ path: '/status/?' }]  // index only status for queries
        excludedPaths: [{ path: '/*' }]
      }
    }
  }
}
```

## Blob Storage Lifecycle Policy (48h auto-delete)

```bicep
// infra/modules/storage.bicep
resource lifecyclePolicy 'Microsoft.Storage/storageAccounts/managementPolicies@2023-01-01' = {
  properties: {
    policy: {
      rules: [{
        name: 'delete-reports-after-48h'
        type: 'Lifecycle'
        definition: {
          actions: { baseBlob: { delete: { daysAfterCreationGreaterThan: 2 } } }
          filters: { blobTypes: ['blockBlob'] prefixMatch: ['sdia-reports/'] }
        }
      }]
    }
  }
}
```

## Managed Identity Pattern (No Hardcoded Secrets)

```bicep
// Assign Cosmos DB data contributor role to Container App identity
resource cosmosRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions',
      '00000000-0000-0000-0000-000000000002')  // Cosmos DB Built-in Data Contributor
    principalId: containerApp.identity.principalId
    principalType: 'ServicePrincipal'
  }
}
```

## OIDC GitHub Actions Setup

```bash
# scripts/setup-github-oidc.sh
# Creates Federated Credential — no long-lived secrets in GitHub
az ad app create --display-name "sdia-github-actions-${ENV}"
az ad sp create --id $APP_ID
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "github-deploy",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:rickylobunam/self-digital-identity-audit:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

## Cost Guardrails

Before adding any new Azure resource, evaluate against NFR-08:

| Check | Rule |
|-------|------|
| Fixed cost | No resource with >$10/month fixed cost in MVP |
| Idle cost | Must scale to zero or have no cost when idle |
| Storage TTL | All PDF storage must have lifecycle delete ≤48h |
| ACR | Basic tier only (no Standard/Premium unless justified by new ADR) |

## Ephemeral Job Deploy Pattern

The Node.js orchestration service triggers Bicep deployment programmatically:

```typescript
// backend/src/services/orchestration.ts
import { ResourceManagementClient } from '@azure/arm-resources';
import { DefaultAzureCredential } from '@azure/identity';

export async function provisionOrchestrator(jobIds: string[]) {
  const client = new ResourceManagementClient(
    new DefaultAzureCredential(),
    process.env.AZURE_SUBSCRIPTION_ID!
  );
  await client.deployments.beginCreateOrUpdate(
    process.env.ACA_RESOURCE_GROUP!,
    `sdia-orchestrator-${Date.now()}`,
    {
      properties: {
        mode: 'Incremental',
        templateLink: { uri: 'infra/modules/containerapp-job.bicep' },
        parameters: { jobIds: { value: jobIds.join(',') } },
      },
    }
  );
}
```

## Docker Compose (Local Dev)

The `docker-compose.yml` defines 4 emulator services + 2 app services.
When modifying:
- Keep Cosmos emulator health check with 5 retries (it takes ~60s to start)
- Azurite uses `0.0.0.0` host binding — required for container networking
- Mailhog captures all ACS emails locally via SMTP port 1025
- Never add Azure-specific services to docker-compose (use `.env` to toggle real vs. emulator)

## Common Mistakes to Avoid

- Admin credentials enabled on ACR — always `adminUserEnabled: false`
- Missing TTL on Cosmos container — required for Privacy-by-Design (NFR-01.5)
- CORS wildcard `*` — always explicit origins list
- Production secrets in bicepparam files — use Key Vault references only
- No health check on Container App — always include HTTP health probe on `/health`
