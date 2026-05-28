# SDIA — Constitution v1.0
> **Spec Driven Development · GitHub Spec Kit**  
> `.specify/memory/constitution.md` · Must be injected at the start of EVERY session, no exceptions.

---

## 1. Project Identity

| Field | Value |
|-------|-------|
| **Official name** | Safe Digital Identity Audit (SDIA) |
| **Repository** | `github.com/[org]/self-digital-identity-audit` |
| **License** | MIT |
| **Type** | Open Source · Child digital safety education tool |
| **Hackathon** | 404: Threat Not Found — Child Digital Safety 2026 (IIJ-UNAM / US Embassy) |
| **Constitution version** | 1.0 — April 2026 |

---

## 2. Mission and Ethical Stance (NON-NEGOTIABLE)

> **"Education over surveillance. Consent before inspection. Design before remediation."**

- The report owner is **always the minor** who registers the request.
- Parents/guardians are **recommended companions**, never the process owners.
- SDIA **does not store** credentials, passwords, or authentication tokens.
- Account ownership validation uses **ephemeral proof-of-possession** (token in public bio/status), never direct access.
- The PDF report is **for the minor**, protected with their email as the password.
- **Zero-footprint**: all audit data is auto-purged at 48h via TTL.

---

## 3. Canonical Tech Stack

### 3.1 Frontend
```
Runtime:     GitHub Pages (static hosting, free)
Framework:   Vite + React 18 + TypeScript
UI:          Tailwind CSS + shadcn/ui
Email App:   React embedded in email (AMP for Email or fallback HTML link)
Build:       Vite → dist/ → GitHub Pages via Actions
```

### 3.2 Backend API (always-on)
```
Runtime:     Node.js 20 LTS
Framework:   Fastify v4 + TypeScript
Hosting:     Azure Container Apps (Consumption, scale-to-zero)
Auth:        Azure Communication Services (OTP email)
Secrets:     Managed Identity → Azure Key Vault (no hardcoded secrets)
```

### 3.3 Database
```
Service:     Azure Cosmos DB (NoSQL, Serverless)
API:         Core (SQL) API
Container:   audit-jobs — partition key: /requestId
TTL:         172800 s (48 hours) — auto-purge of all PII
Schema:      Variable (1..N platforms per request)
```

### 3.4 Email
```
Service:     Azure Communication Services (ACS) — Email
Templates:   HTML + plain text fallback
Trigger:     Node.js API → ACS SDK
```

### 3.5 Report Orchestrator (ephemeral, on-demand)
```
Trigger:     GitHub Actions cron (10:00 AM UTC-6 / Mexico) OR Azure Function timer
Runtime:     Python 3.11
Framework:   FastAPI
OSINT:       Maigret + httpx (public authorized scraping)
LLM:         Azure OpenAI (gpt-4o-mini) via Azure AI Foundry
PDF:         Markdown → HTML (Jinja2) → PDF (WeasyPrint) → password (pikepdf)
Hosting:     Azure Container Apps Job — deployed by Bicep, destroyed post-run
```

### 3.6 Infrastructure as Code
```
IaC:         Azure Bicep (modular)
Registry:    Azure Container Registry (ACR)
Secrets:     Azure Key Vault (Managed Identity, no secrets in env vars)
Storage:     Azure Blob Storage (temp PDFs, TTL 48h, SAS URL)
CI/CD:       GitHub Actions (OIDC Federated — no long-lived secrets)
```

---

## 4. Canonical Data Model

### AuditJob (Cosmos DB)
```typescript
interface AuditJob {
  id: string;                    // UUID v4
  requestId: string;             // partition key, == id
  emailHash: string;             // SHA-256(email) — never plaintext
  status: AuditJobStatus;
  platforms: PlatformEntry[];
  createdAt: ISO8601;
  expiresAt: ISO8601;            // +48h from createdAt (TTL)
  reportUrl?: string;            // Temp SAS URL for PDF download
  reportGeneratedAt?: ISO8601;
}

type AuditJobStatus =
  | 'PENDING_EMAIL_VALIDATION'  // job created, validation email sent
  | 'EMAIL_VALIDATED'           // user confirmed email ownership
  | 'COLLECTING_PLATFORMS'      // user adding accounts
  | 'READY_TO_REPORT'           // ≥1 platform validated, ready for batch
  | 'REPORT_IN_PROGRESS'        // orchestrator running
  | 'REPORT_READY'              // PDF available, email sent
  | 'EXPIRED'                   // 24h window elapsed
  | 'ERROR';

interface PlatformEntry {
  platform: PlatformId;
  nickname: string;
  validationToken: string;       // SDIA-generated passphrase
  validationStatus: 'PENDING' | 'VALIDATED' | 'FAILED';
  validatedAt?: ISO8601;
  osintFindings?: OsintFindings; // populated by orchestrator only
}

type PlatformId =
  | 'instagram' | 'tiktok' | 'x_twitter' | 'youtube'
  | 'steam' | 'roblox' | 'discord' | 'twitch';
```

---

## 5. Canonical Flows

### Flow A — Registration and Validation (Frontend + Node.js API)
```
1. User submits email + primary nickname → POST /api/jobs
2. API creates AuditJob (status: PENDING_EMAIL_VALIDATION) → sends OTP email
3. Email embeds mini-app link (GitHub Pages URL with jobId)
4. User opens app → GET /api/jobs/:id/validate-email?token=xxx
5. API updates status: EMAIL_VALIDATED → returns jobId and sessionToken (JWT, 25h)
6. User adds platforms one by one:
   a. Selects platform → SDIA generates unique validationToken
   b. SDIA shows step-by-step guide to place token in public profile
   c. User confirms → POST /api/jobs/:id/platforms/:platform/verify
   d. API checks token in public profile (lightweight OSINT) → VALIDATED or FAILED
   e. If VALIDATED: notify user they can revert their profile
7. User marks "done" → PUT /api/jobs/:id/ready {status: READY_TO_REPORT}
8. 24h window from EMAIL_VALIDATED; after that: status EXPIRED, auto-purge
```

### Flow B — Report Generation (Python Orchestrator, daily batch)
```
1. Cron trigger 10:00 AM → query Cosmos DB: jobs with status READY_TO_REPORT
2. If 0 jobs: exit (no infrastructure deployed)
3. If N jobs: Bicep deploys ACA + required resources
4. Per job (independent flow):
   a. OSINT per platform (Maigret + httpx)
   b. Build LLM prompt with findings (atomic inference)
   c. Azure OpenAI → structured JSON analysis
   d. Jinja2 HTML render → WeasyPrint → PDF
   e. pikepdf applies password = base62(SHA-256(email))[:12]
   f. Upload to Azure Blob Storage (SAS URL, TTL 48h)
   g. ACS sends email with password and download link
   h. Cosmos DB: status REPORT_READY
5. Post-run: scale-to-zero or Bicep teardown
```

---

## 6. AI Agent Session Rules

### MAY do without human approval:
- Generate code, SDD artifacts, tests, Bicep IaC, Dockerfiles
- Refactor existing code for clarity or security
- Suggest technical alternatives and flag risks
- Generate documentation content

### REQUIRES Founder (R03) approval before executing:
- Changes to the canonical data model (§4)
- Changes to canonical flows (§5)
- Tech stack changes
- Changes to the ethical stance (§2)
- Any new external service integration

### MUST NEVER do:
- Generate code that persists PII beyond the 48h TTL
- Implement auth other than OTP-email + ephemeral sessionToken
- Add scraping with credentials or WAF evasion
- Modify the PDF password logic without approval
- Ignore the atomic inference principle in the orchestrator

---

## 7. Code Conventions

```
Frontend language:    TypeScript strict mode, no `any`
Backend language:     TypeScript strict mode, Fastify schemas, no `any`
Orchestrator:         Python 3.11, full type hints, mypy clean
Frontend tests:       Vitest + Testing Library
Backend tests:        Jest + supertest
Orchestrator tests:   pytest + httpx
Linting:              ESLint (TS), Biome, ruff (Python)
Commits:              Conventional Commits (feat/fix/docs/chore/test)
Branches:             See BRANCHING_STRATEGY.md
Secrets:              NEVER in code; always Azure Key Vault or GitHub Secrets
Repository language:  100% English — all files, comments, docs, configs
```

---

## 8. Privacy by Design — Implementation

1. **Minimization**: collect only email and nicknames. Nothing else.
2. **Ephemeral**: Cosmos DB TTL 48h. Blob Storage SAS TTL 48h.
3. **No PII logging**: logs contain requestId only, never email or nicknames.
4. **Hashed email**: only `emailHash` stored in Cosmos (SHA-256). Email plaintext lives only in memory during the creation request.
5. **Validation tokens**: generated with `crypto.randomBytes(16)`, single-use, marked consumed post-validation.
6. **Protected PDF**: password derived from email (not stored in SDIA), delivered only by email to the owner.
7. **OSINT data**: stored as `osintFindings` in the job only during report generation; purged with the job via TTL.

---

*Constitution v1.0 — April 2026 — SDIA · MIT License*
