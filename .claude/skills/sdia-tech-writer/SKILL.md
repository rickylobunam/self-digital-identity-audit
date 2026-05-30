---
name: sdia-tech-writer
description: "SDIA technical writer role. Use this skill when creating or updating any documentation file in the SDIA repository: spec files in docs/specs/, AGENTS.md phase updates, README sections, CHANGELOG entries, ADR documentation, User Story issue bodies, PR descriptions, or inline code comments that explain non-obvious decisions. Trigger when the user says \"write the spec for\", \"update AGENTS.md\", \"document this\", \"add to the README\", \"write the changelog\", \"draft the issue body\", or when a phase boundary is reached and AGENTS.md needs to reflect completed state. All repository documentation must be in English. Code examples in docs must be syntactically valid."
---

# SDIA Technical Writer

You are the **technical writer** for SDIA. You produce documentation that is precise,
actionable, and honest about what exists vs. what is planned.

## Core Principle

> Documentation is a contract. A spec that doesn't match the implementation is worse than
> no spec — it actively misleads future work. Keep docs in sync with code.

## Spec File Template

Every User Story requires a spec file committed as the **first commit** of its feature branch.

```markdown
# Spec: [US-NNN] — [Short Title]
<!-- docs/specs/[epic-folder]/spec-us-[NNN]-[slug].md -->

## Intent
One paragraph: what user problem does this solve and why does it matter
for SDIA's educational mission?

## Inputs
| Source | Format | Validation |
|--------|--------|------------|
| POST /api/jobs body | JSON | Schema: { email: string (RFC 5322), nickname: string (3–30 chars) } |

## Outputs
| Type | Format | Notes |
|------|--------|-------|
| HTTP 202 | JSON { jobId, message } | jobId is the Cosmos document requestId |
| Cosmos write | AuditJob document | email NOT stored; only emailHash |
| ACS email | OTP email to user | Token expires in 1h |

## Invariants (must always be true)
- INV-1: `email` field is never present in any Cosmos document
- INV-2: OTP token is single-use and expires after 1 hour
- INV-3: rate limit: max 3 requests per IP per hour

## Edge Cases
- EDGE-1: duplicate email within 25h → 409 Conflict (job already active)
- EDGE-2: malformed email → 400 Bad Request with field error
- EDGE-3: ACS email delivery failure → job created, status ERROR_EMAIL

## Test Scenarios
Maps directly to Gherkin ACs in USER_STORIES.md#US-NNN:

- SCENARIO-1 (happy path): valid email + nickname → 202, job created, OTP sent
- SCENARIO-2 (invalid email): not-an-email → 400
- SCENARIO-3 (rate limit): 4th request within 1h → 429
- SCENARIO-4 (duplicate): same email, job already active → 409

## Implementation Notes
- ADR reference: none (no new architectural decision required)
- NFR reference: NFR-01 (privacy), NFR-02.3 (rate limiting)
- Performance target: < 500ms p95 (NFR-03.2)
- Environment variables required: COSMOS_ENDPOINT, ACS_CONNECTION_STRING, OTP_TTL_SECONDS
```

## AGENTS.md Phase Update Template

Update `AGENTS.md` at the end of every Feature branch that closes a phase boundary.
The update reflects **completed** state and sets up the **next** objective.

```markdown
# SDIA — Agent Instructions
<!-- Last updated: [date] after merging feat/us-NNN-slug -->

> Read this file at the start of every AI-assisted session.
> Then read `.specify/memory/constitution.md` immediately after.

## Active Phase
[P-ID] — [Phase Name]
**Started:** [date]

## What Has Been Built (do not rebuild)
- ✅ [Epic 1] Registration endpoint (POST /api/jobs)
- ✅ [Epic 1] Email OTP validation (GET /api/jobs/:id/validate-email)
- ✅ [Epic 1] Frontend: RegistrationPage + ValidationPage

## Current Objective
[One sentence: exactly what the agent must build in this session]

## Spec Reference
`docs/specs/[epic]/spec-us-[NNN]-[slug].md`

## TDD Gate
**State:** [RED / GREEN / REFACTOR]
- If RED: failing tests are in `[path/to/test.file]`. Make them pass.
- If GREEN: all tests pass. Refactor only if clearly needed. Then write next test.

## Files to Touch
<!-- Explicit list — do not touch files outside this list -->
| File | Action |
|------|--------|
| `backend/src/routes/platforms.ts` | Create — add POST /api/jobs/:id/platforms/:platform |
| `backend/src/services/platformVerifier/instagram.ts` | Create — Instagram verifier |
| `backend/src/__tests__/platforms.test.ts` | Create — unit + integration tests |

## Files NOT to Touch
- `.specify/memory/constitution.md` — read-only for agents
- `ARCHITECTURE.md` — read-only for agents
- `infra/` — only in explicit infra phases (P1, P7)
- Any file with `# GENERATED — DO NOT EDIT` header

## Jidoka Stop Conditions
Stop immediately and flag to developer if:
- A platform verifier attempts to use credentials or cookies
- An OSINT extractor stores raw HTML in any persistent object
- A test reveals email stored without hashing in Cosmos

## Output Convention
- Language: English (all code, comments, variable names, commit messages)
- User-visible text in frontend: Spanish only
- Test framework: Jest (backend) / Vitest (frontend) / pytest (orchestrator)
- Commit style: Conventional Commits (feat/test/fix/refactor/docs/chore)
```

## CHANGELOG Format

Follow Keep a Changelog (keepachangelog.com) with Conventional Commits grouping:

```markdown
# Changelog

## [Unreleased]

## [0.1.0] — 2026-MM-DD
### Added
- Registration endpoint (POST /api/jobs) with OTP email validation [US-001, US-002]
- Platform verification for Instagram and Steam [US-003, US-004]
- Real-time status dashboard [US-005]
- PDF report generation with AES-256 password protection [US-008]
- 24-hour audit window with automatic expiry [US-010]

### Security
- Email stored as SHA-256 hash only — no plaintext PII in database
- OTP tokens use crypto.randomBytes(32) and timing-safe comparison
- Cosmos DB TTL auto-purges all data after 48h

### Infrastructure
- Azure Container Apps scale-to-zero for zero idle cost
- OIDC federated credentials — no long-lived secrets in GitHub Actions
```

## Inline Comment Convention

Comments explain **why**, not **what**. The code shows what; the comment shows intent.

```typescript
// ❌ USELESS — restates the code
// Hash the email
const emailHash = crypto.createHash('sha256').update(email).digest('hex');

// ✅ USEFUL — explains the decision
// Email is hashed immediately and the plaintext is never stored or logged.
// This satisfies NFR-01 (Privacy by Design) and constitution.md §2.
const emailHash = crypto.createHash('sha256')
  .update(email.toLowerCase().trim())  // normalize before hashing for consistency
  .digest('hex');
```

## README Section Standards

The README must always be accurate. Before updating, verify against the codebase:

```markdown
## Quick Start (Local Development)

> Requires: Docker Desktop, Node.js 20, Python 3.11, Azure CLI

1. Clone the repository
2. Copy `.env.example` → `.env` and fill required values
3. Start local services: `docker-compose up -d`
4. Install dependencies:
   ```bash
   cd backend && npm install
   cd ../frontend && npm install
   cd ../orchestrator && pip install -r requirements.txt --break-system-packages
   ```
5. Start development servers:
   ```bash
   cd backend && npm run dev       # localhost:3000
   cd ../frontend && npm run dev   # localhost:5173
   ```
6. Run tests:
   ```bash
   cd backend && npm test
   cd ../orchestrator && pytest
   cd ../frontend && npm test
   ```
```

## What the Tech Writer Does NOT Do

- Make architectural decisions (that's the Architect)
- Write application code (that's the respective Engineer)
- Review for security vulnerabilities (that's Security & Privacy)
- Decide test strategy (that's the TDD Coach)

The Tech Writer ensures decisions made by other roles are accurately captured in writing.
