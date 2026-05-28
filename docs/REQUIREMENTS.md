# SDIA — Functional and Non-Functional Requirements

> **Version:** 1.0 · April 2026  
> Classification: `[MVP]` = v0.1 · `[v0.2]` · `[v1.0]`

---

## Part I — Functional Requirements

### FR-01 — Request Registration
```
GIVEN   a minor visits the form on GitHub Pages
WHEN    they submit a valid email (RFC 5322) and a nickname
THEN    the system must:
  - Validate email format (without verifying existence yet)
  - Create an AuditJob in Cosmos DB with status PENDING_EMAIL_VALIDATION
  - Generate a 64-byte hex OTP (crypto.randomBytes(32))
  - Send a validation email in < 30 seconds via ACS
  - Respond HTTP 202 Accepted with { jobId, message }
  - NOT store the email in plaintext (store only SHA-256 hash)
```

### FR-02 — Email Validation
```
GIVEN   the user receives the validation email
WHEN    they click the link (GET /api/jobs/:id/validate-email?token=xxx)
THEN    the system must:
  - Verify the token matches the stored hash (constant-time comparison)
  - Verify the token has not expired (1h TTL from issuance)
  - Verify the token has not been previously used
  - Update status to EMAIL_VALIDATED
  - Invalidate the token (non-reusable)
  - Return a JWT sessionToken (HS256, exp 25h) with { jobId }
  - Redirect the user to the mini-app with the sessionToken
```

### FR-03 — Platform Management (Add)
```
GIVEN   the user is authenticated (valid sessionToken)
WHEN    they select a platform and provide their nickname on that platform
THEN    the system must:
  - Validate the platform is one of the supported ones
  - Validate the nickname meets that platform's format rules
  - Generate a unique validationToken (6 BIP-39 words or 8-char code)
  - Return step-by-step instructions specific to that platform
  - Register the PlatformEntry in the AuditJob with status PENDING
```

### FR-04 — Account Ownership Verification
```
GIVEN   the user indicates they have placed the token in their profile
WHEN    they call POST /api/jobs/:id/platforms/:platform/verify
THEN    the system must:
  - Make an HTTP GET request to the platform's public profile
  - Search for the validationToken in the bio/description content
  - If found: update PlatformEntry.status = VALIDATED, record timestamp
  - If not found: return FAILED with a help message
  - Notify (email or push) that they can revert their bio
  - Not store the full profile content
```

### FR-05 — Ready for Report Activation
```
GIVEN   the user has at least 1 VALIDATED platform
WHEN    they call PUT /api/jobs/:id/ready
THEN    the system must:
  - Update status to READY_TO_REPORT
  - This status is irreversible (no more platforms can be added)
```

### FR-06 — Report Generation Process (Batch)
```
GIVEN   it is 10:00 AM UTC-6
WHEN    the internal node-cron scheduler (running in the Node.js API container) executes
THEN    the orchestrator must:
  - Query Cosmos DB for jobs with status READY_TO_REPORT
  - If N = 0: terminate without deploying infrastructure
  - If N > 0: deploy ACA via Bicep with a Container Apps Job
  - Per job in parallel (configurable max concurrency):
    - Run OSINT per VALIDATED platform of the job
    - Build prompt with findings (atomic inference)
    - Call Azure OpenAI with 120s timeout
    - Generate HTML with Jinja2
    - Convert to PDF with WeasyPrint
    - Apply protection with pikepdf (password + permissions)
    - Upload to Blob Storage (SAS URL, TTL 48h)
    - Send email with password and link
    - Update status to REPORT_READY
```

**Timing guarantee**: The scheduler maintains ±1 min precision and runs daily as a batch process within the always-on Node.js API container. No external CI/CD pipeline or GitHub Actions workflow is involved.

### FR-07 — PDF Protection
```
The generated PDF must:
  - Require a password to open (user_password = first 12 chars of base62(SHA-256(email)))
  - Have a different owner password (managed internally, not exposed)
  - Permissions: read and print ONLY
  - DISABLED permissions: content copy, editing, page extraction
  - Encryption: AES-256
  - Metadata: Author="SDIA", Creator="SDIA v0.1", Keywords="CONFIDENTIAL"
```

### FR-08 — Expiry and Purge
```
  - Cosmos DB job TTL: 172800 seconds (48h) from createdAt
  - If status is not REPORT_READY after 24h from EMAIL_VALIDATED: mark EXPIRED
  - Blob Storage: TTL configured to 48h from generation
  - No reminder sent; the initial email informs the 24h window
```

---

## Part II — Non-Functional Requirements

### NFR-01 — Privacy by Design
| ID | Requirement |
|----|-------------|
| NFR-01.1 | The user's email MUST NEVER be stored in plaintext in any persistent layer |
| NFR-01.2 | System logs MUST NEVER contain email, nicknames, or profile content |
| NFR-01.3 | OSINT findings are stored only during report generation, in memory |
| NFR-01.4 | The PDF password is not stored in any database |
| NFR-01.5 | Cosmos DB TTL guarantees auto-purge at 48h without manual intervention |

### NFR-02 — Security
| ID | Requirement |
|----|-------------|
| NFR-02.1 | OTP tokens: `crypto.randomBytes(32)` (256 bits), hex-encoded, single-use |
| NFR-02.2 | sessionToken JWT: HS256, exp 25h, signed with Azure Key Vault secret |
| NFR-02.3 | Token comparison: `crypto.timingSafeEqual` (prevents timing attacks) |
| NFR-02.4 | No secrets in source code; all secrets in Azure Key Vault |
| NFR-02.5 | Managed Identity for Key Vault access from Container Apps |
| NFR-02.6 | HTTPS mandatory on all endpoints (TLS 1.2+) |
| NFR-02.7 | Rate limiting: max 3 requests/hour per IP on the registration endpoint |
| NFR-02.8 | Rate limiting: max 5 verification attempts per platform per job |
| NFR-02.9 | CORS: allowed origins only (GitHub Pages URL + localhost:5173) |
| NFR-02.10 | Input validation on all endpoints with JSON Schema (Fastify) |

### NFR-03 — Availability and Scalability
| ID | Requirement |
|----|-------------|
| NFR-03.1 | Node.js API: scale-to-zero (minReplicas: 0), scales to 1 replica on first request |
| NFR-03.2 | Python Orchestrator: ephemeral, deployed only when jobs are pending |
| NFR-03.3 | Cosmos DB Serverless: auto-scales with load |
| NFR-03.4 | Frontend GitHub Pages: 99.9% SLA (GitHub) |
| NFR-03.5 | API startup time (cold start): < 5 seconds |

### NFR-04 — Performance
| ID | Requirement |
|----|-------------|
| NFR-04.1 | Request registration (POST /api/jobs): < 2s p95 |
| NFR-04.2 | Email validation (GET validate-email): < 500ms p95 |
| NFR-04.3 | Platform verification (POST verify): < 10s p95 (depends on external platform) |
| NFR-04.4 | Full report generation: < 5 min per job (OSINT + LLM + PDF) |
| NFR-04.5 | Total delivery time from READY_TO_REPORT: < 30 min (wait for 10AM cron) |

### NFR-05 — Code Quality
| ID | Requirement |
|----|-------------|
| NFR-05.1 | TypeScript strict mode on frontend and backend (`noImplicitAny: true`) |
| NFR-05.2 | Python full type hints, mypy error-free |
| NFR-05.3 | Test coverage: ≥ 70% on backend and orchestrator |
| NFR-05.4 | Lint warnings-free in CI (ESLint + Biome for TS, ruff for Python) |
| NFR-05.5 | All PRs pass CI before merge to `develop` |

### NFR-06 — Maintainability and Open Source
| ID | Requirement |
|----|-------------|
| NFR-06.1 | Each component (frontend, backend, orchestrator, infra) deployable independently |
| NFR-06.2 | Environment variables documented in `.env.example` with description |
| NFR-06.3 | `docker-compose.yml` for complete local development environment |
| NFR-06.4 | Conventional Commits enforced in CI |
| NFR-06.5 | CHANGELOG.md updated on each release |
| NFR-06.6 | All repository files in English (code, comments, docs, configs) |

### NFR-07 — Accessibility and UX
| ID | Requirement |
|----|-------------|
| NFR-07.1 | Frontend: WCAG 2.1 AA on critical validation flow elements |
| NFR-07.2 | Platform validation guides: clear language with screenshots or GIFs |
| NFR-07.3 | The PDF report must be readable by a 12-year-old without technical assistance |
| NFR-07.4 | Primary language: Spanish (user-facing content); English: all repository files |
| NFR-07.5 | Responsive design (mobile-first): flow must work on mobile |

### NFR-08 — Cost (Design constraint)
| ID | Requirement |
|----|-------------|
| NFR-08.1 | Infrastructure cost at rest (0 users): < $2 USD/month |
| NFR-08.2 | Cost per generated report: < $0.15 USD (including LLM, compute, storage) |
| NFR-08.3 | No services with monthly fixed cost > $10 USD in MVP |
| NFR-08.4 | Scale-to-zero mandatory on all compute services |

### NFR-09 — Ethical / Legal
| ID | Requirement |
|----|-------------|
| NFR-09.1 | The system MUST NOT accept requests to audit third-party accounts |
| NFR-09.2 | Ownership validation must be completed before any OSINT |
| NFR-09.3 | OSINT content is limited to publicly visible information |
| NFR-09.4 | The social engineering simulator must include a mandatory educational disclaimer |
| NFR-09.5 | No WAF evasion techniques or authenticated scraping |
