# SDIA — Architecture Document

> **ADR = Architecture Decision Record**  
> This document is the source of truth for all technical decisions.

---

## 1. General Architecture Diagram

### 1.1 System Overview

```mermaid
flowchart TD
    USER([👤 Minor — User])

    subgraph BLOCK1["Block 1 · User Interaction & Always-On Control Plane"]
        direction TB

        subgraph FRONTEND["Public Layer — GitHub Pages (free)"]
            GH["Vite + React + TypeScript\nStatic SPA\ngithub.io/[org]/sdia"]
        end

        subgraph APIPLANE["API Layer — Azure Container Apps (scale-to-zero)"]
            API["Node.js Fastify API\nHTTP · Auth · Rate Limiting\nControl Plane Orchestrator"]
            CRON(["⏰ node-cron\nInternal Scheduler\n10:00 AM UTC-6"])
            KV["Azure Key Vault\nManaged Identity\nAll secrets at rest"]
            API -.- KV
        end

        subgraph DATAPLANE["Data Layer — Always Ephemeral"]
            DB[("Cosmos DB Serverless\nCore SQL API\nPartition: /requestId\nTTL: 172800 s")]
            ACS["Azure Comm. Services\nTransactional Email\nOTP + Report delivery"]
        end
    end

    subgraph BLOCK2["Block 2 · Report Generation — Ephemeral IaaS (On-Demand Only)"]
        direction TB

        subgraph PROVISION["Provisioning Layer"]
            BICEP["Bicep IaC\nAzure Dynamic Provisioner\nDeploy → Run → Teardown"]
        end

        subgraph EXECUTION["Execution Layer — Python Container Apps Job"]
            ORCH["Python FastAPI\nReport Orchestrator\nParallel job processing"]
            OSINT["OSINT Module\nMaigret · httpx\nPublic sources only"]
            LLM["Azure OpenAI\ngpt-4o-mini · AI Foundry\nAtomic inference per job"]
            PDF["Report Builder\nJinja2 → WeasyPrint\npikepdf AES-256"]
            BLOB[("Azure Blob Storage\nTemp PDFs\nSAS URL TTL 48 h")]
        end

        subgraph RECONCILE["Reconciliation Layer"]
            RECON["Workflow Reconciliation\nState validation\nBicep teardown trigger"]
        end
    end

    %% ── Flow A · Registration & Email Validation
    USER -->|"① POST /api/jobs\n{email, nickname}"| GH
    GH -->|"POST /api/jobs"| API
    API -->|"Create AuditJob\nstatus: PENDING_EMAIL_VALIDATION"| DB
    API -->|"Send OTP link\nTTL 1h · single-use"| ACS
    ACS -->|"Email: link to GitHub Pages\n?jobId=xxx&token=yyy"| USER
    USER -->|"② Click link → GitHub Pages\nreads query params"| GH
    GH -->|"GET /validate-email?token"| API
    API -->|"status: EMAIL_VALIDATED\nIssue JWT sessionToken 25h"| DB

    %% ── Flow B · Platform Ownership Validation
    USER -->|"③ Select platforms\n④ Place token in public bio\n(loop per platform)"| GH
    GH -->|"POST /platforms/:p/verify\nRepeat until all validated"| API
    API -->|"COLLECTING_PLATFORMS\n→ READY_TO_REPORT"| DB

    %% ── Flow C · Cron Detection & Provisioning
    CRON -->|"⑤ SELECT jobs WHERE\nstatus = READY_TO_REPORT"| DB
    CRON -->|"⑥ N > 0: az deployment\ngroup create"| BICEP
    BICEP -->|"Deploy Container Apps Job\nwith job IDs list"| ORCH

    %% ── Flow D · Report Generation
    ORCH -->|"OSINT: public profiles\n(rate-limited per platform)"| OSINT
    ORCH -->|"build_prompt(findings)\nAtomic inference"| LLM
    LLM -->|"Structured JSON\n(score, risks, social_sim)"| ORCH
    ORCH -->|"Jinja2 render\nWeasyPrint PDF"| PDF
    PDF -->|"pikepdf AES-256\npassword = base62(SHA256(email))[:12]"| BLOB
    BLOB -->|"SAS URL TTL 48h"| ORCH

    %% ── Flow E · Delivery & Reconciliation
    ORCH -->|"⑦ PDF + password\n+ download link"| ACS
    ACS -->|"Report delivered\nto user inbox"| USER
    ORCH -->|"POST /internal/jobs/reconcile\n{jobIds, status: COMPLETE}"| RECON
    RECON -->|"⑧ status: REPORT_READY\nUpdate all completed jobs"| DB
    RECON -->|"az deployment group delete\nDestroy ephemeral infra"| BICEP

    %% ── Node styles
    classDef user     fill:#1D4ED8,stroke:#1E3A8A,color:#fff,font-weight:bold
    classDef frontend fill:#0369A1,stroke:#075985,color:#fff
    classDef backend  fill:#0A2342,stroke:#1E40AF,color:#fff
    classDef data     fill:#6D28D9,stroke:#5B21B6,color:#fff
    classDef comms    fill:#B45309,stroke:#92400E,color:#fff
    classDef cron     fill:#15803D,stroke:#166534,color:#fff,font-weight:bold
    classDef kv       fill:#374151,stroke:#1F2937,color:#fff
    classDef bicep    fill:#991B1B,stroke:#7F1D1D,color:#fff,font-weight:bold
    classDef orch     fill:#7C2D12,stroke:#6C1D12,color:#fff
    classDef process  fill:#9A3412,stroke:#7C2D12,color:#fff
    classDef storage  fill:#4C1D95,stroke:#3B0764,color:#fff
    classDef recon    fill:#1F2937,stroke:#111827,color:#fff

    class USER user
    class GH frontend
    class API,KV backend
    class DB data
    class ACS comms
    class CRON cron
    class BICEP bicep
    class ORCH orch
    class OSINT,LLM,PDF process
    class BLOB storage
    class RECON recon

    linkStyle 0 stroke:#6B7280,stroke-dasharray:4
    linkStyle 1,2,3,4,5,6,7,8 stroke:#0078D4,stroke-width:2px
    linkStyle 9,10,11 stroke:#E85D04,stroke-width:2px
    linkStyle 12,13,14 stroke:#16A34A,stroke-width:2px
    linkStyle 15,16,17,18,19,20 stroke:#DC2626,stroke-width:2px
    linkStyle 21,22 stroke:#7C3AED,stroke-width:2px
    linkStyle 23,24,25 stroke:#6B7280,stroke-width:1.5px
```

### 1.2 Execution Flows

| # | Flow | Trigger | Key transitions |
|---|------|---------|----------------|
| A | Registration & Email Validation | User submits form | `PENDING_EMAIL_VALIDATION` → `EMAIL_VALIDATED` |
| B | Platform Ownership Validation | User action (loop) | `COLLECTING_PLATFORMS` → `READY_TO_REPORT` |
| C | Cron Detection & Provisioning | `node-cron` 10:00 AM UTC-6 | Queries DB · Bicep deploy if N > 0 |
| D | Report Generation Pipeline | Bicep-provisioned Python Job | OSINT → LLM → PDF → Blob |
| E | Delivery & Reconciliation | Orchestrator completion | `REPORT_READY` · Bicep teardown |

### 1.3 Architecture Pattern

This system implements **Serverless Orchestration with Ephemeral IaaS**:

- **Control plane** (Node.js, always-on, scale-to-zero): manages job lifecycle, user auth, and schedules the report generation cycle via an internal `node-cron` scheduler. When jobs are ready, it provisions execution infrastructure using the Azure SDK (`az deployment group create`).
- **Execution plane** (Python, ephemeral): exists only while there is work to do. Each report is processed in an independent flow within the same Container Apps Job. Parallelism is bounded by `OSINT_MAX_CONCURRENT` to control cost.
- **Reconciliation** (Node.js internal endpoint `/internal/jobs/reconcile`): the Python orchestrator calls back to Node.js when all jobs complete. Node.js validates execution, updates Cosmos DB status to `REPORT_READY`, and triggers Bicep teardown via Azure SDK.
- **Zero residual cost**: at rest, only Cosmos DB Serverless (pay-per-RU) and Container Apps (scale-to-zero) incur costs. Estimated idle cost: < $7 USD/month.

## 2. Platform Validation Sequence Diagram

```mermaid
sequenceDiagram
    actor U as User (Minor)
    participant FE as Frontend (GitHub Pages)
    participant API as Backend (Node.js)
    participant DB as Cosmos DB
    participant P as Platform (Instagram, etc.)

    U->>FE: Select platform + enter nickname
    FE->>API: POST /api/jobs/:id/platforms/instagram
    API->>DB: Register PlatformEntry (status: PENDING)
    API-->>FE: { validationToken: "sdia-4f2a8b", instructions: [...] }
    FE-->>U: Show step-by-step guide + code

    Note over U,P: User places "sdia-4f2a8b" in their Instagram bio

    U->>FE: Presses "I placed it, verify"
    FE->>API: POST /api/jobs/:id/platforms/instagram/verify
    API->>P: GET https://instagram.com/{nickname} (public HTTP)
    P-->>API: Profile HTML
    API->>API: Search "sdia-4f2a8b" in the HTML
    alt Token found
        API->>DB: PlatformEntry.status = VALIDATED
        API-->>FE: { status: "VALIDATED" }
        FE-->>U: ✅ Verified. You can remove the code from your bio.
    else Token not found
        API-->>FE: { status: "FAILED", hint: "Code not found..." }
        FE-->>U: ❌ Not found. Help instructions.
    end
```

---

## 3. Report Generation Pipeline

```mermaid
flowchart LR
    A[Cosmos DB Query\nREADY_TO_REPORT jobs] --> B{N > 0?}
    B -->|No| C[Exit. No deploy.]
    B -->|Yes| D[Bicep: deploy ACA\nOrchestrator Job]
    D --> E[Per job\nin parallel]
    E --> F[OSINT: validated\nplatforms of the job]
    F --> G[clean_results\nnormalize findings]
    G --> H[build_prompt\nAtomic Inference]
    H --> I[Azure OpenAI\ngpt-4o-mini]
    I --> J[JSON: score,\nrisks, recommendations]
    J --> K[Jinja2 → HTML\nrender_report]
    K --> L[WeasyPrint\nHTML → PDF]
    L --> M[pikepdf\napply password+permissions]
    M --> N[Blob Storage\nSAS URL TTL 48h]
    N --> O[ACS Email\nPDF + password]
    O --> P[Cosmos DB\nstatus: REPORT_READY]
    P --> Q[Post-run: scale-to-zero]
```

---

## 4. Architecture Decision Records (ADRs)

### ADR-001: Database — Cosmos DB NoSQL vs. Azure SQL

**Context:** The system needs to store `AuditJob` with a variable number of `PlatformEntry` records (from 1 to potentially 50+). It also requires automatic TTL and low-latency isolated writes.

**Options evaluated:**

| Criterion | Azure SQL (PaaS) | Cosmos DB (Serverless) |
|-----------|-----------------|----------------------|
| Variable schema (1..N platforms) | JOIN tables required | Native JSON ✅ |
| Document-level automatic TTL | Not native (requires cron) | Native ✅ |
| Cost at rest | ~$5/month minimum | ~$0 (serverless) ✅ |
| Scale-to-zero | No | Yes ✅ |
| Operational complexity | High (migrations) | Low ✅ |
| Complex queries | Superior | Sufficient for SDIA |

**Decision:** **Azure Cosmos DB Serverless**, Core (SQL) API.

**Rationale:** The `PlatformEntry` schema is inherently variable (the user chooses which platforms to audit). Cosmos DB allows storing the array directly in the job document, eliminating JOINs. Native TTL guarantees auto-purge without additional cron. The Serverless model eliminates the fixed cost (~$0 at rest).

**Consequences:** Cosmos DB does not support complex multi-document transactions, but SDIA does not need them. All operations are on a single `AuditJob` per request.

---

### ADR-002: PDF Format — LLM → Markdown → HTML → PDF vs. DOCX → PDF

**Options evaluated:**

| Criterion | MD → HTML → PDF (WeasyPrint) | DOCX → PDF (LibreOffice) |
|-----------|------------------------------|--------------------------|
| Design control | Total (CSS) ✅ | Limited by Word styles |
| Visual traffic light (colors) | Native CSS ✅ | Complex with python-docx |
| Docker image size | +100MB (WeasyPrint deps) | +500MB (LibreOffice) |
| Native AES-256 password | pikepdf (5KB dep) ✅ | Requires additional step |
| Headless server generation | Pythonic / no GUI ✅ | Requires virtual display |
| Templates (Jinja2) | Standard web ✅ | Complex binary format |

**Decision:** **LLM → JSON → Jinja2 HTML → WeasyPrint PDF → pikepdf password**

**Password derivation algorithm:**
```python
import hashlib

def derive_pdf_password(email: str) -> str:
    """
    Derives the PDF password from the user's email.
    Result: 12 base62 readable characters.
    NEVER stored in the database.
    The password is sent only to the user's email.
    """
    hash_bytes = hashlib.sha256(email.lower().strip().encode('utf-8')).digest()
    b62_chars = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    result = ""
    n = int.from_bytes(hash_bytes[:8], 'big')
    for _ in range(12):
        result += b62_chars[n % 62]
        n //= 62
    return result
# Example: "me@example.com" → "3xK9mP2wR7nQ"
```

**pikepdf permissions configuration:**
```python
from pikepdf import Encryption, Permissions
import os

Encryption(
    user=derive_pdf_password(email),
    owner=os.environ['PDF_OWNER_SECRET'],
    allow=Permissions(
        print_highres=True,      # Printing enabled
        modify_annotation=False,
        modify_assembly=False,
        modify_form=False,
        modify_other=False,
        extract=False,           # No text copying
    ),
    R=6  # AES-256
)
```

---

### ADR-003: Backend Hosting — Azure Container Apps vs. Azure Functions

**Decision:** **Azure Container Apps (Consumption)**

**Rationale:** The Node.js backend needs future WebSocket-readiness (real-time status updates), specific HTTP configuration (CORS, headers), and consistency with the orchestrator (same hosting type). Azure Functions has longer cold starts for Node.js containers and is better suited for short, isolated functions.

---

### ADR-004: Orchestrator Trigger — Internal `node-cron` Scheduler

**Decision:** **Internal `node-cron` scheduler** in the Node.js API (final).

**Rationale:**

- **Simpler architecture**: The scheduler runs inside the always-on API container. No external workflow orchestration needed.
- **Cost**: Zero cost for GitHub Actions (which was consumed by the cron job runner). Scale-to-zero handles idle cost.
- **Transparency**: The schedule is code-managed (see `src/services/cronService.ts`), visible in the repository, and can be modified without workflow YAML changes.
- **Reliability**: Running inside the Node.js process eliminates failure modes from external CI systems. The API naturally restarts on crashes; cron job state is re-evaluated every minute.
- **Future flexibility**: Can easily integrate real-time job detection without external triggers. Planned for v0.2+: WebSocket updates on job status.

**Implementation:**
```typescript
// Backend: src/services/cronService.ts
import cron from 'node-cron';

export function initReportGenerationCron() {
  // Every day at 10:00 AM UTC-6
  cron.schedule('0 10 * * *', async () => {
    const readyJobs = await cosmosService.queryJobsByStatus('READY_TO_REPORT');
    if (readyJobs.length > 0) {
      await provisionOrchestrator(readyJobs.map(j => j.id));
    }
  }, { timezone: 'America/Mexico_City' });
}
```

---

## 5. Required Environment Variables

### Backend (Node.js)
```bash
# Azure
COSMOS_ENDPOINT=https://sdia-cosmos.documents.azure.com:443/
COSMOS_KEY=              # Local dev only; production uses Managed Identity
ACS_CONNECTION_STRING=   # Azure Communication Services
AZURE_KEYVAULT_URL=https://sdia-kv.vault.azure.net/

# App
JWT_SECRET=              # Local dev only; production from Key Vault
NODE_ENV=development|production
PORT=3000
ALLOWED_ORIGINS=https://[org].github.io,http://localhost:5173
RATE_LIMIT_MAX=3
RATE_LIMIT_WINDOW_MS=3600000
```

### Orchestrator (Python)
```bash
# Azure
AZURE_OPENAI_ENDPOINT=https://sdia-aoai.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT=gpt-4o-mini
AZURE_COSMOSDB_ENDPOINT=
BLOB_CONNECTION_STRING=
ACS_CONNECTION_STRING=

# PDF
PDF_OWNER_SECRET=        # Owner password for PDF (not the user password)

# OSINT
OSINT_REQUEST_TIMEOUT_S=15
OSINT_MAX_CONCURRENT=3
```

---

## 6. Detailed Directory Structure

```
self-digital-identity-audit/
├── frontend/
│   ├── src/
│   │   ├── pages/
│   │   │   ├── RegistrationPage.tsx     # F-01: Initial form
│   │   │   ├── ValidationPage.tsx       # F-02: Email link landing
│   │   │   ├── PlatformsPage.tsx        # F-03/F-04: Platforms dashboard
│   │   │   └── CompletePage.tsx         # F-06: Final confirmation
│   │   ├── components/
│   │   │   ├── RegistrationForm/
│   │   │   ├── PlatformCard/
│   │   │   ├── ValidationGuide/         # Step-by-step guides per platform
│   │   │   └── StatusBadge/
│   │   ├── api/
│   │   │   └── sdiaClient.ts            # Typed HTTP client
│   │   ├── hooks/
│   │   └── types/
│   │       └── audit.ts                 # Shared types (AuditJob, PlatformEntry)
│   ├── public/
│   ├── vite.config.ts
│   └── package.json
│
├── backend/
│   ├── src/
│   │   ├── routes/
│   │   │   ├── jobs.ts                  # POST /api/jobs, GET /api/jobs/:id
│   │   │   └── platforms.ts             # POST .../platforms, POST .../verify
│   │   ├── services/
│   │   │   ├── cosmosService.ts
│   │   │   ├── emailService.ts          # ACS integration
│   │   │   ├── tokenService.ts          # OTP + JWT
│   │   │   └── platformVerifier/
│   │   │       ├── index.ts
│   │   │       ├── instagram.ts
│   │   │       ├── tiktok.ts
│   │   │       ├── twitter.ts
│   │   │       ├── youtube.ts
│   │   │       ├── steam.ts
│   │   │       └── roblox.ts
│   │   ├── plugins/
│   │   │   ├── auth.ts                  # JWT verification plugin
│   │   │   ├── rateLimiter.ts
│   │   │   └── cors.ts
│   │   ├── schemas/                     # JSON Schemas for Fastify
│   │   └── server.ts
│   ├── Dockerfile
│   └── package.json
│
├── orchestrator/
│   ├── app/
│   │   ├── main.py                      # FastAPI app + process_jobs()
│   │   ├── osint/
│   │   │   ├── extractor.py             # Orchestrates OSINT per platform
│   │   │   ├── instagram.py
│   │   │   ├── tiktok.py
│   │   │   ├── twitter.py
│   │   │   ├── youtube.py
│   │   │   ├── steam.py
│   │   │   └── roblox.py
│   │   ├── ai/
│   │   │   ├── analyzer.py              # build_prompt + call_azure_openai
│   │   │   └── prompts.py               # Prompt templates
│   │   ├── report/
│   │   │   ├── generator.py             # render_report() orchestrator
│   │   │   └── pdf_protector.py         # pikepdf password + permissions
│   │   ├── storage/
│   │   │   ├── cosmos.py
│   │   │   └── blob.py
│   │   └── models/
│   │       └── schemas.py               # Pydantic models
│   ├── templates/
│   │   └── report.html                  # Jinja2 report template
│   ├── assets/
│   │   └── styles.css
│   ├── tests/
│   ├── Dockerfile
│   └── requirements.txt
│
├── infra/
│   ├── main.bicep
│   ├── modules/
│   │   ├── cosmosdb.bicep
│   │   ├── containerapp.bicep
│   │   ├── containerapp-job.bicep
│   │   ├── storage.bicep
│   │   ├── keyvault.bicep
│   │   └── acr.bicep
│   └── parameters/
│       ├── dev.bicepparam
│       └── prod.bicepparam
│
└── .github/workflows/
    ├── ci.yml
    ├── deploy-frontend.yml
    ├── deploy-backend.yml
    └── report-generator.yml
```
