# SDIA — Implementation Strategy
<!-- docs/specs/IMPLEMENTATION_STRATEGY.md -->
> **Master development guide** — must be read before starting any Epic, Feature, or User Story.
> This document governs the complete lifecycle of the project from the first line of code to production.

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Date** | May 2026 |
| **Author** | rickylobunam |
| **Status** | Active — Baseline |
| **Related** | `constitution.md`, `ARCHITECTURE.md`, `FEATURES.md`, `USER_STORIES.md`, `BRANCHING_STRATEGY.md`, `TESTING_STRATEGY.md` |

---

## Table of Contents

1. [Purpose and Scope](#1-purpose-and-scope)
2. [Development Philosophy](#2-development-philosophy)
3. [Methodology: TDD + Jidoka + SDD](#3-methodology-tdd--jidoka--sdd)
4. [Project Decomposition](#4-project-decomposition)
5. [Epic Structure and GitHub Projects](#5-epic-structure-and-github-projects)
6. [Feature Branches and Git Workflow](#6-feature-branches-and-git-workflow)
7. [Issue Structure per User Story](#7-issue-structure-per-user-story)
8. [AGENTS.md — Agent Instructions Protocol](#8-agentsmd--agent-instructions-protocol)
9. [Phase-by-Phase Development Roadmap](#9-phase-by-phase-development-roadmap)
10. [Definition of Done (DoD)](#10-definition-of-done-dod)
11. [CI/CD Integration](#11-cicd-integration)
12. [Risk Register and Mitigation](#12-risk-register-and-mitigation)
13. [Glossary](#13-glossary)

---

## 1. Purpose and Scope

This document is the single source of truth for **how** SDIA is built — not what it builds
(that is `FEATURES.md` and `USER_STORIES.md`) nor how it is architected (that is `ARCHITECTURE.md`).

It answers:
- How are Features decomposed into implementable work units?
- What methodology governs each code-writing session?
- How do GitHub Projects, branches, and issues map to Features and User Stories?
- How does an AI agent receive its instructions per task?
- In what order do we build things, and what gates must be passed?

**Scope:** all work on the `rickylobunam/self-digital-identity-audit` repository, from
bootstrapping local infrastructure through production release `v1.0.0`.

---

## 2. Development Philosophy

### 2.1 Core Principles

**Education over surveillance. Consent before inspection. Quality before speed.**

SDIA is an educational tool for minors. Every technical decision carries an ethical weight.
These principles are non-negotiable and precede any delivery pressure:

| Principle | Implication for development |
|-----------|----------------------------|
| Privacy by Design | No PII survives beyond the TTL window. Tests must verify deletion, not just creation. |
| Consent First | The ownership validation gate (FR-04) is never bypassed, even in tests. |
| Correctness over Coverage | A 70% test suite that verifies the right invariants beats 95% that tests trivialities. |
| Atomic, auditable changes | Every PR must be traceable to a single User Story Issue. |
| Fail visibly | Jidoka: a defect detected mid-step stops the line. No "we'll fix it later." |

### 2.2 Working Constraints

- **Single developer (H0):** all roles (R01–R04) are held by one person. Time-boxing per
  session is mandatory to prevent context overload.
- **Public open-source repo:** every commit, test, and comment is visible. Write accordingly.
- **100% English in the repository:** all code, comments, docs, config, commit messages,
  CI/CD, and spec files must be in English. Conversations with the developer may be in Spanish.
- **Hackathon origin, production intent:** the MVP targets the 404 Hackathon deadline, but the
  architecture and code quality must sustain `v1.0.0` without a full rewrite.

---

## 3. Methodology: TDD + Jidoka + SDD

SDIA is built using a three-layer methodology where each layer reinforces the others.

### 3.1 Spec Driven Development (SDD)

Before any code is written for a User Story, a **Specification** file must exist under
`docs/specs/`. This spec is the contract between intent (the US) and implementation.

```
docs/specs/
├── IMPLEMENTATION_STRATEGY.md     ← this file (project-level spec)
├── epic-1-registration/
│   ├── spec-us-001-registration.md
│   └── spec-us-002-email-validation.md
├── epic-2-platform-validation/
│   ├── spec-us-003-instagram.md
│   ├── spec-us-004-steam.md
│   ├── spec-us-005-status-dashboard.md
│   └── spec-us-006-mark-ready.md
├── epic-3-report/
│   ├── spec-us-007-report-email.md
│   ├── spec-us-008-pdf-open.md
│   └── spec-us-009-traffic-light.md
└── epic-4-administration/
    └── spec-us-010-expiry.md
```

Each spec file follows this template (see Section 7 for the full Issue template which
embeds the spec inline):

```markdown
# Spec: [US-ID] — [Short Title]

## Intent
One paragraph: what user problem does this solve?

## Inputs
List of all inputs (HTTP requests, user actions, scheduled triggers).

## Outputs
List of all outputs (HTTP responses, DB writes, emails sent, side effects).

## Invariants (MUST always be true)
- INV-1: ...
- INV-2: ...

## Edge Cases
- EDGE-1: what happens if ...
- EDGE-2: what happens if ...

## Test Scenarios (maps to Acceptance Criteria in USER_STORIES.md)
- SCENARIO-1: Happy path
- SCENARIO-2: ...

## Implementation Notes
Technical constraints, ADR references, performance targets.
```

The spec is written **before** the `AGENTS.md` is updated and **before** any code is touched.

### 3.2 Test Driven Development (TDD)

TDD is applied at the **unit and integration level** for all backend and orchestrator code.
For the frontend, TDD applies to form validation logic and API client functions; UI rendering
tests follow a "write component, then test" pattern using Testing Library.

**TDD Cycle per task:**

```
RED   → Write failing test that encodes one spec invariant or scenario
GREEN → Write the minimal code that makes the test pass
REFACTOR → Clean up without breaking the test
COMMIT → Conventional commit (feat/test/refactor)
```

**Non-negotiable TDD rules:**
- Tests are committed in the same PR as the code they test. No "I'll add tests later" PRs.
- A `feat:` commit without an accompanying `test:` commit in the same branch will fail code
  review (self-review in H0 context: do not merge your own PR without checking this).
- Coverage thresholds from `TESTING_STRATEGY.md` are enforced by CI: 70% backend,
  70% orchestrator, 60% frontend. CI blocks merge if thresholds are not met.

### 3.3 Jidoka (Stop-at-Defect)

Jidoka is the Lean/TPS principle of building in quality at each step and stopping the
production line when a defect is detected. Applied to SDIA development:

**When to stop:**
- Any CI job fails → do not proceed to the next task. Fix it first.
- A Privacy-by-Design invariant is discovered to be violated (e.g., email stored in plaintext
  in a log) → stop, raise a `fix:` branch, and merge before continuing the Epic.
- An ADR is found to conflict with new implementation details → stop, update the ADR (with
  `docs:` commit), get mental approval, then resume.
- A test reveals a security hole in the OTP flow → treat as P0. Block all other work.

**Jidoka does NOT mean:**
- Stopping for cosmetic issues (fix them in a `chore:` commit at end of session).
- Stopping because a non-critical E2E test is flaky in CI (file an issue, mark as known-flaky,
  continue — but fix it before the next release tag).

**Jidoka in AI-assisted sessions:**
When an AI agent is driving implementation, the agent must stop and surface a blocking issue
to the developer rather than working around it silently. The `AGENTS.md` for each phase must
explicitly state what constitutes a stop-condition for that phase.

### 3.4 Methodology Interaction

```
SDD ──→ Spec written ──→ TDD starts ──→ Red test ──→ Green code
                                           │
                               Defect? ──→ Jidoka STOP ──→ Fix
                                           │
                               No defect ──→ Refactor ──→ Commit
                                                          │
                                                    CI passes? ──→ Yes: PR merge
                                                          │
                                                         No: Jidoka STOP
```

---

## 4. Project Decomposition

### 4.1 Hierarchy

```
Project (SDIA)
└── Release (v0.1.0 MVP · v0.2.0 · v1.0.0)
    └── Epic (GitHub Project Dashboard)
        └── Feature (Git branch: feat/[us-id]-[slug] merged to develop)
            └── User Story (GitHub Issue in the Epic's Project)
                └── Tasks (checklist items inside the Issue)
                    └── Specs (docs/specs/epic-N/spec-us-NNN.md)
```

### 4.2 Mapping Rules

| Level | GitHub Entity | Branch | Naming |
|-------|--------------|--------|--------|
| Epic | GitHub Project (Board) | N/A (container) | `Epic N — [Name]` |
| Feature | Feature branch | `feat/us-NNN-slug` | Named after its primary US |
| User Story | GitHub Issue | (linked to branch) | `[US-NNN] Short title` |
| Task | Issue checklist item | (within branch) | `[ ] Task description` |
| Bug fix | `fix/` branch | `fix/NNN-slug` | Linked to original Issue |

**One Feature = One User Story** for MVP scope. Complex v0.2+ features (F-12 to F-17) that
span multiple User Stories may use a single branch named after the Feature ID (e.g.,
`feat/f-12-offline-mode`) with multiple linked Issues.

### 4.3 Release Scope

| Release | Epics | Features | User Stories | Target |
|---------|-------|----------|--------------|--------|
| **v0.1.0 MVP** | E1, E2, E3, E4 | F-01 to F-11 | US-001 to US-010 | Hackathon 404 |
| **v0.2.0** | E5 + E2 ext | F-12, F-13, F-14, F-17 | US-011, US-013 | Post-hackathon |
| **v1.0.0** | All | F-15, F-16 | US-012 | Stable release |

---

## 5. Epic Structure and GitHub Projects

Each Epic maps 1:1 to a **GitHub Project (Board)** in the `rickylobunam` account.
The board uses a Kanban-style layout with these columns:

```
Backlog | Spec Ready | In Progress | Review | Done
```

### 5.1 Epic Definitions

#### Epic 1 — Registration and Access
**GitHub Project:** `[SDIA] Epic 1 — Registration and Access`
**Scope:** F-01 (Registration), F-02 (Email Validation)
**User Stories:** US-001, US-002
**Layer:** Frontend + Backend
**Dependency:** None (first to implement)

| Feature ID | US | Branch | Description |
|------------|-----|--------|-------------|
| F-01 | US-001 | `feat/us-001-registration` | Email + nickname form → AuditJob creation |
| F-02 | US-002 | `feat/us-002-email-validation` | OTP email → validate-email endpoint |

---

#### Epic 2 — Platform Validation
**GitHub Project:** `[SDIA] Epic 2 — Platform Validation`
**Scope:** F-03 (Platform Registration + Verification), F-04 (Status Dashboard), F-06 (Mark Ready)
**User Stories:** US-003, US-004, US-005, US-006
**Layer:** Frontend + Backend (platform verifiers)
**Dependency:** Epic 1 must be in `develop` (sessionToken required)

| Feature ID | US | Branch | Description |
|------------|-----|--------|-------------|
| F-03a | US-003 | `feat/us-003-instagram-validation` | Instagram ownership proof-of-possession |
| F-03b | US-004 | `feat/us-004-steam-validation` | Steam ownership proof-of-possession |
| F-03c | — | `feat/f03-remaining-platforms` | TikTok, X/Twitter, YouTube, Roblox verifiers |
| F-04 | US-005 | `feat/us-005-status-dashboard` | Real-time platform status UI |
| F-05b | US-006 | `feat/us-006-mark-ready` | Finalize audit → READY_TO_REPORT |

**Note on F-03c:** TikTok, X/Twitter, YouTube, and Roblox are implemented in a single branch
to avoid excessive PR overhead for nearly identical verifier structure. Each platform still
has its own spec, test file, and Issue checklist item.

---

#### Epic 3 — Report Generation and Delivery
**GitHub Project:** `[SDIA] Epic 3 — Report Generation and Delivery`
**Scope:** F-05 (PDF Generation), F-06 (Email Delivery), F-07 to F-10 (Report Sections)
**User Stories:** US-007, US-008, US-009
**Layer:** Python Orchestrator + Infrastructure (Bicep)
**Dependency:** Epic 1 complete; Epic 2 partially complete (at least 1 verifier working)

| Feature ID | US | Branch | Description |
|------------|-----|--------|-------------|
| F-05 | — | `feat/f05-orchestrator-core` | Cron trigger → Bicep deploy → Python job scaffold |
| F-05 (OSINT) | — | `feat/f05-osint-module` | Maigret + httpx extractors per platform |
| F-05 (LLM) | — | `feat/f05-llm-analysis` | Azure OpenAI integration + prompt engineering |
| F-05 (PDF) | US-008 | `feat/f05-pdf-generation` | Jinja2 → WeasyPrint → pikepdf |
| F-06 | US-007 | `feat/us-007-report-delivery` | ACS email with password + SAS URL |
| F-07+F-08 | US-009 | `feat/us-009-traffic-light` | Risk traffic light + Oversharing Score |
| F-09+F-10 | — | `feat/f09-f10-report-sections` | Social engineering sim + remediation plan |

---

#### Epic 4 — Administration and Expiry
**GitHub Project:** `[SDIA] Epic 4 — Administration and Expiry`
**Scope:** F-11 (Expiry + Purge)
**User Stories:** US-010
**Layer:** Backend (status transitions) + Cosmos DB TTL verification
**Dependency:** Epics 1 and 2

| Feature ID | US | Branch | Description |
|------------|-----|--------|-------------|
| F-11 | US-010 | `feat/us-010-expiry-purge` | 24h window enforcement + Cosmos TTL integration test |

---

#### Epic 5 — Extended Features (v0.2+)
**GitHub Project:** `[SDIA] Epic 5 — Extended Features`
**Scope:** F-12 to F-17
**User Stories:** US-011 to US-013
**Dependency:** v0.1.0 tagged and stable

(Detailed breakdown deferred to post-hackathon planning session.)

---

### 5.2 GitHub Project Board Setup

For each Epic, create the project via GitHub UI or CLI:

```bash
# Create project (requires GH CLI with Projects extension)
gh project create --owner rickylobunam --title "[SDIA] Epic 1 — Registration and Access"

# Add custom fields
# Status: Backlog | Spec Ready | In Progress | Review | Done
# Priority: P0 | P1 | P2
# Layer: Frontend | Backend | Orchestrator | Infra | Full-stack
# US Reference: free text (e.g., "US-001")
```

All Issues for a given Epic must be linked to that Epic's GitHub Project. The board is the
single view for Epic progress — do not track status elsewhere.

---

## 6. Feature Branches and Git Workflow

All development follows the `BRANCHING_STRATEGY.md` with these additions specific to
the TDD+Jidoka+SDD methodology:

### 6.1 Branch Lifecycle

```
develop (integration) ─────────────────────────────────────────────────→
         │                          ↑ PR merge (squash)
         │ git checkout -b          │
         └──→ feat/us-001-registration
                 │
                 │ Commit sequence:
                 │  1. docs: add spec-us-001-registration.md
                 │  2. test: add failing unit tests (RED)
                 │  3. feat: implement registration endpoint (GREEN)
                 │  4. refactor: extract emailHash helper
                 │  5. test: add integration test POST /api/jobs
                 │  6. docs: update AGENTS.md for next phase
                 │
                 └──→ PR to develop
```

### 6.2 Commit Order Convention

Every Feature branch must follow this commit sequence (enforced by self-review checklist):

| Order | Type | Description |
|-------|------|-------------|
| 1st | `docs:` | Spec file for this US (`docs/specs/...`) |
| 2nd | `test:` | Failing unit tests (RED state — must fail in CI at this point) |
| 3rd | `feat:` or `fix:` | Implementation code (GREEN state — tests now pass) |
| 4th | `refactor:` | Cleanup (optional, only if needed) |
| 5th | `test:` | Integration tests (if applicable) |
| 6th | `docs:` | Update `AGENTS.md` with phase instructions (see Section 8) |

This sequence is not enforced by tooling (yet) but is verified during PR self-review.
A PR that skips step 1 (no spec) or step 2 (no failing tests before implementation) must be
rejected and re-submitted.

### 6.3 PR Template

Create `.github/PULL_REQUEST_TEMPLATE.md` with:

```markdown
## User Story
<!-- Link to the GitHub Issue: Closes #NNN -->
Closes #

## Spec Reference
<!-- Link to the spec file committed in this PR -->
`docs/specs/[epic]/spec-us-[id].md`

## Commit Sequence Checklist
- [ ] `docs:` Spec file committed first
- [ ] `test:` Failing tests committed before implementation
- [ ] `feat:`/`fix:` Implementation committed after tests
- [ ] All tests pass locally (`npm test` / `pytest`)
- [ ] Coverage thresholds met (70% backend, 70% orchestrator, 60% frontend)
- [ ] No plaintext PII in tests or fixtures
- [ ] `AGENTS.md` updated if this branch closes a phase boundary

## Privacy-by-Design Checklist
- [ ] No email stored in plaintext in any new code path
- [ ] No profile content persisted beyond function scope
- [ ] Logs contain only `requestId`, never email/nickname
- [ ] New environment variables documented in `.env.example`

## Testing Summary
<!-- Briefly describe what was tested and what was not -->

## Breaking Changes
<!-- Any changes to the canonical data model or flows from constitution.md? -->
- [ ] No breaking changes
- [ ] YES — ADR updated and linked: [ADR-XXX]
```

---

## 7. Issue Structure per User Story

Each User Story from `USER_STORIES.md` becomes a GitHub Issue in its Epic's Project.

### 7.1 Issue Title Format

```
[US-NNN] Short action title  (P0/P1/P2 · Layer)
```

Examples:
- `[US-001] Audit request registration  (P0 · Frontend + Backend)`
- `[US-003] Add Instagram account  (P0 · Backend)`
- `[US-007] Receive report email  (P0 · Orchestrator + Backend)`

### 7.2 Issue Body Template

```markdown
## User Story
As [actor], I want [action] so that [benefit].

> Source: USER_STORIES.md#[US-NNN]

---

## Acceptance Criteria
<!-- Copy verbatim from USER_STORIES.md (Gherkin scenarios) -->

```gherkin
Scenario: [Happy path]
  Given ...
  When ...
  Then ...
```

---

## Spec File
`docs/specs/[epic-folder]/spec-us-[NNN]-[slug].md`
<!-- Created as the first commit of the feature branch -->

---

## Technical Constraints
<!-- Key references from constitution.md, ARCHITECTURE.md, REQUIREMENTS.md -->
- **FR reference:** FR-XX
- **NFR reference:** NFR-XX.X
- **ADR reference:** ADR-XXX (if applicable)

---

## Implementation Tasks

### Phase 1 — Spec and Tests (RED)
- [ ] Write `docs/specs/[epic]/spec-us-[NNN].md`
- [ ] Write failing unit tests that encode the acceptance criteria
- [ ] Verify tests fail in CI before proceeding

### Phase 2 — Implementation (GREEN)
- [ ] [Specific implementation task 1]
- [ ] [Specific implementation task 2]
- [ ] [Specific implementation task 3]
- [ ] Verify all tests pass

### Phase 3 — Integration and Cleanup
- [ ] Write integration test(s)
- [ ] Refactor if needed
- [ ] Update `AGENTS.md` phase instructions
- [ ] Update `.env.example` if new env vars added
- [ ] Open PR to `develop`

---

## AGENTS.md Phase
<!-- Which AGENTS.md phase governs this task? -->
Phase: [e.g., "Phase 2 — Backend Core — Registration Endpoint"]

---

## Definition of Done
- [ ] All acceptance criteria implemented and verified by tests
- [ ] CI passes (lint + typecheck + tests + coverage threshold)
- [ ] Spec file committed
- [ ] PR merged to `develop`
- [ ] Issue closed and moved to "Done" on the Project board
```

### 7.3 Labels

Create these repository labels for Issue management:

| Label | Color | Use |
|-------|-------|-----|
| `epic:1` through `epic:5` | Blue shades | Epic membership |
| `p0` / `p1` / `p2` | Red / Orange / Yellow | Priority |
| `layer:frontend` | Sky blue | |
| `layer:backend` | Navy | |
| `layer:orchestrator` | Dark orange | |
| `layer:infra` | Gray | |
| `tdd:red` | Red | Branch is in RED (tests written, failing) |
| `tdd:green` | Green | Branch is in GREEN (tests passing) |
| `jidoka:blocked` | Dark red | Work stopped due to defect |
| `privacy` | Purple | Privacy-by-Design concern |
| `hackathon-mvp` | Gold | In scope for v0.1.0 |

---

## 8. AGENTS.md — Agent Instructions Protocol

`AGENTS.md` lives at the repository root and contains **phase-specific instructions for
AI agents** (Claude or any coding agent). It is updated with a `docs:` commit at the end
of every Feature branch that closes a development phase boundary.

### 8.1 AGENTS.md Structure

```markdown
# SDIA — Agent Instructions

> **Read this file at the start of every AI-assisted session.**
> Read `constitution.md` immediately after this file.

## Active Phase
[Phase ID] — [Phase Name]

## What Has Been Built (do not rebuild)
- [List of completed Features/modules]

## Current Objective
[One sentence: what the agent must build in this session]

## Spec Reference
[Link to the relevant spec file in docs/specs/]

## TDD Gate
State: [RED / GREEN / REFACTOR]
- If RED: failing tests are in [path]. Make them pass.
- If GREEN: tests pass. Refactor only if clearly needed.

## Jidoka Stop Conditions
Stop immediately and surface to developer if:
- [Condition specific to this phase]
- Any Privacy-by-Design invariant is violated
- A test reveals a data model inconsistency with constitution.md §4

## Files to Touch
<!-- Explicit list — do not touch files outside this list without developer approval -->
- `[file path]` — [what to do]
- `[file path]` — [what to do]

## Files NOT to Touch
- `constitution.md` — never modified by agents
- `ARCHITECTURE.md` — read-only for agents
- `infra/` — only modified in explicit infra phases
- Any file with `# DO NOT EDIT` header

## Output Convention
- Language: English (all code, comments, variable names)
- Test framework: [Jest / pytest / Vitest] depending on component
- Commit message style: Conventional Commits
```

### 8.2 Phase Sequence

The following phases define the progression of `AGENTS.md` updates throughout the project:

| Phase | ID | Description | Closes Epic |
|-------|----|-------------|-------------|
| 0 | `P0-BOOTSTRAP` | Repo scaffolding, docker-compose validation, CI baseline | — |
| 1 | `P1-INFRA-BASE` | Bicep base infrastructure (Cosmos DB, ACA, KV, ACS, ACR) | — |
| 2 | `P2-BACKEND-REGISTRATION` | FR-01, FR-02: POST /api/jobs + email validation | E1 partial |
| 3 | `P3-FRONTEND-REGISTRATION` | Registration form + email validation UI | E1 complete |
| 4 | `P4-BACKEND-PLATFORM` | FR-03, FR-04: platform verifiers (all 6 MVP platforms) | E2 partial |
| 5 | `P5-FRONTEND-PLATFORM` | Platform selection UI + ValidationGuide + Status Dashboard | E2 partial |
| 6 | `P6-MARK-READY` | FR-05: PUT /api/jobs/:id/ready + UI finalization | E2 complete |
| 7 | `P7-ORCHESTRATOR-SCAFFOLD` | Python FastAPI job + Bicep Container Apps Job deploy | E3 partial |
| 8 | `P8-OSINT-MODULE` | OSINT extractors (Maigret + httpx) for all 6 platforms | E3 partial |
| 9 | `P9-LLM-ANALYSIS` | Azure OpenAI integration + prompt templates | E3 partial |
| 10 | `P10-PDF-GENERATION` | Jinja2 template + WeasyPrint + pikepdf | E3 partial |
| 11 | `P11-DELIVERY` | ACS report email + reconciliation endpoint | E3 complete |
| 12 | `P12-EXPIRY` | FR-08: 24h window enforcement + Cosmos TTL integration | E4 complete |
| 13 | `P13-E2E-HARDENING` | Playwright E2E suite + security review + load test | All MVP |
| 14 | `P14-MVP-RELEASE` | Versioning, CHANGELOG, production deploy, smoke test | v0.1.0 |

### 8.3 AGENTS.md Update Rule

`AGENTS.md` must be updated at the **end** of each Feature branch, not the beginning.
The update reflects the completed state and sets up the next phase's objective.
This ensures a future agent (or the same agent in a new session) always finds current
instructions without needing to infer state from the commit history.

---

## 9. Phase-by-Phase Development Roadmap

### Phase 0 — Bootstrap (P0)

**Objective:** Verify the local development environment is fully operational and CI runs green
on a clean repository with no application code.

**Tasks:**
1. Verify `docker-compose up -d` starts all 4 services (cosmos-emulator, azurite, mailhog, backend, frontend).
2. Verify `curl localhost:3000/health` returns `{ "status": "ok" }`.
3. Verify CI workflow `.github/workflows/ci.yml` runs all 3 jobs (frontend, backend, orchestrator)
   and passes on empty test suites with coverage 0% (expected: threshold checks skip on empty).
4. Verify `frontend/` and `backend/` scaffolds exist with correct package.json and TypeScript config.
5. Verify `orchestrator/` has `requirements.txt`, `app/main.py`, and `pytest` runs with no errors.
6. Create and push Phase 0 AGENTS.md.

**Gate:** `git push origin develop` triggers CI → all jobs green → P0 complete.

---

### Phase 1 — Infrastructure Base (P1)

**Objective:** Deploy base Azure infrastructure (non-ephemeral services) to the `dev`
environment so that subsequent phases can connect to real Azure services in staging.

**Tasks (Bicep modules):**
1. `infra/modules/cosmosdb.bicep` — Cosmos DB Serverless, `sdia` database, `audit-jobs` container,
   TTL policy, partition key `/requestId`.
2. `infra/modules/keyvault.bicep` — Key Vault Standard, access policies for Container Apps
   Managed Identity.
3. `infra/modules/acr.bicep` — Azure Container Registry Basic, admin disabled,
   OIDC Federated Credential for GitHub Actions.
4. `infra/modules/containerapp.bicep` — Always-on Node.js API: Consumption, scale-to-zero,
   `minReplicas: 0`, `maxReplicas: 3`, Managed Identity assigned.
5. `infra/modules/storage.bicep` — Blob Storage account, `sdia-reports` container,
   lifecycle policy: delete after 48h.
6. `infra/main.bicep` — Orchestrates modules, outputs endpoint values.
7. `scripts/deploy.sh` — Calls `az deployment group create` with `dev.bicepparam`.
8. `scripts/setup-github-oidc.sh` — Configures Federated Credentials for OIDC.

**Gate:** `az deployment group create ... --what-if` reports no errors.
`bash scripts/deploy.sh --env dev` deploys successfully.
All resource endpoints are captured in GitHub Actions secrets.

---

### Phase 2 — Backend Registration (P2)

**Epics:** E1 (partial) | **User Stories:** US-001, US-002

**Spec files to create:**
- `docs/specs/epic-1-registration/spec-us-001-registration.md`
- `docs/specs/epic-1-registration/spec-us-002-email-validation.md`

**Implementation targets:**
- `backend/src/routes/jobs.ts` — `POST /api/jobs`, `GET /api/jobs/:id`
- `backend/src/routes/validation.ts` — `GET /api/jobs/:id/validate-email`
- `backend/src/services/cosmosService.ts` — `createJob()`, `getJob()`, `updateJobStatus()`
- `backend/src/services/emailService.ts` — ACS OTP email
- `backend/src/services/tokenService.ts` — OTP generation, JWT issuance
- `backend/src/plugins/rateLimiter.ts` — 3 req/h per IP on `/api/jobs`

**TDD targets:**
- Unit: `tokenService` — OTP generation uniqueness, JWT sign/verify, timing-safe comparison
- Unit: `cosmosService` — email never stored as plaintext (verify `emailHash` field only)
- Integration: `POST /api/jobs` → 202, job created, email sent (Mailhog mock)
- Integration: `GET validate-email` → valid token → 200 + JWT; expired token → 410;
  reused token → 409; rate limit → 429

**Privacy-by-Design gate (Jidoka):** Test `POST /api/jobs` and assert that
`mockCreate.mock.calls[0][0]` has `emailHash` and NOT `email`. If this assertion fails,
stop the phase.

---

### Phase 3 — Frontend Registration (P3)

**Epics:** E1 (completes) | **User Stories:** US-001, US-002

**Spec files:** (extend Phase 2 specs with UI-specific sections)

**Implementation targets:**
- `frontend/src/pages/RegistrationPage.tsx`
- `frontend/src/pages/ValidationPage.tsx`
- `frontend/src/api/sdiaClient.ts` — typed HTTP client for `/api/jobs`
- `frontend/src/components/RegistrationForm/`

**TDD targets (Vitest + Testing Library):**
- `RegistrationForm`: disable submit on invalid email, show error for empty nickname
- `ValidationPage`: reads `?token=` from URL, calls validate-email, redirects on success
- `sdiaClient`: mock fetch, verify request shape

**E2E (Playwright, preliminary):** Registration form → submit → landing on ValidationPage.

**Gate:** E1 all Issues closed. `develop` builds and deploys to GitHub Pages staging URL.
Navigation from registration form to validation page works end-to-end in local docker-compose.

---

### Phase 4 — Backend Platform Verification (P4)

**Epics:** E2 (partial) | **User Stories:** US-003, US-004

**Spec files:**
- `docs/specs/epic-2-platform-validation/spec-us-003-instagram.md`
- `docs/specs/epic-2-platform-validation/spec-us-004-steam.md`
- `docs/specs/epic-2-platform-validation/spec-f03-remaining-platforms.md`

**Implementation targets:**
- `backend/src/routes/platforms.ts` — `POST /api/jobs/:id/platforms/:platform`,
  `POST /api/jobs/:id/platforms/:platform/verify`
- `backend/src/services/platformVerifier/` — one file per platform: `instagram.ts`,
  `tiktok.ts`, `twitter.ts`, `youtube.ts`, `steam.ts`, `roblox.ts`
- `backend/src/services/platformVerifier/index.ts` — verifier map

**TDD targets:**
- Unit per verifier: token found → VALIDATED; token not found → FAILED;
  profile not public → specific message; nickname not found → 404 message
- Integration: mock platform HTTP responses with `nock`/`jest.mock`

**Jidoka stop conditions:**
- Any verifier that makes authenticated requests to a platform → stop, never implement.
- Any verifier that stores the full HTML response in Cosmos DB → stop, fix to store only
  `validatedAt` timestamp.

---

### Phase 5 — Frontend Platform Validation (P5)

**Epics:** E2 (partial) | **User Stories:** US-003, US-004, US-005

**Implementation targets:**
- `frontend/src/pages/PlatformsPage.tsx`
- `frontend/src/components/PlatformCard/`
- `frontend/src/components/ValidationGuide/` — platform-specific step-by-step guides
- `frontend/src/components/StatusBadge/`

**UX requirements from NFR-07:**
- Mobile-first (viewport 375px minimum)
- WCAG 2.1 AA on all interactive elements
- ValidationGuide must display clear, friendly instructions in Spanish

---

### Phase 6 — Mark Ready (P6)

**Epics:** E2 (completes) | **User Stories:** US-005, US-006

**Implementation targets:**
- `PUT /api/jobs/:id/ready` — status transition to `READY_TO_REPORT`
- `frontend/src/pages/PlatformsPage.tsx` — "Done! Generate my report" button
- `frontend/src/pages/CompletePage.tsx` — confirmation screen

**Gate:** E2 all Issues closed. At least 1 platform can be validated end-to-end in
docker-compose: form → email → validate → add platform → mark ready → job in
`READY_TO_REPORT` state in Cosmos DB emulator.

---

### Phase 7 — Orchestrator Scaffold (P7)

**Epics:** E3 (partial)

**Implementation targets:**
- `backend/src/services/cronService.ts` — `node-cron` scheduler with timezone support,
  env-driven enable/disable, manual trigger endpoint
- `backend/src/services/orchestration.ts` — `queryReadyJobs()`, `provisionOrchestrator()`
- `infra/modules/containerapp-job.bicep` — ephemeral Python Container Apps Job
- `orchestrator/app/main.py` — FastAPI app + `process_jobs()` entry point
- `orchestrator/app/models/schemas.py` — Pydantic models for `OsintFindings`, `ReportData`

**TDD targets (from TESTING_STRATEGY.md):**
- Scheduler initializes with correct timezone
- `queryReadyJobs()` filters by `READY_TO_REPORT` status
- Cron fires → `queryReadyJobs` called → if jobs exist, `provisionOrchestrator` called
- If 0 jobs → `provisionOrchestrator` NOT called (critical Jidoka gate)
- Bicep deployment mock: verify job IDs are passed correctly

---

### Phase 8 — OSINT Module (P8)

**Epics:** E3 (partial)

**Implementation targets:**
- `orchestrator/app/osint/extractor.py` — async orchestrator, rate-limited
- `orchestrator/app/osint/[platform].py` — one extractor per platform (6 files)

**TDD targets (pytest + respx):**
- Mock HTTP responses for each platform → verify `OsintFindings` structure
- Verify `OSINT_USER_AGENT` header is sent (bot identification requirement)
- Verify timeout handling: 15s → raise structured exception, not unhandled error
- Verify `OSINT_MAX_CONCURRENT` is respected (semaphore-based test)

**Jidoka stop conditions:**
- Any extractor that persists raw HTML to Cosmos DB → stop.
- Any extractor that uses credentials → stop immediately.
- Any extractor that disables SSL verification → stop.

---

### Phase 9 — LLM Analysis (P9)

**Epics:** E3 (partial)

**Implementation targets:**
- `orchestrator/app/ai/analyzer.py` — `build_prompt()`, `call_azure_openai()`
- `orchestrator/app/ai/prompts.py` — prompt templates for risk analysis,
  social engineering simulator (with mandatory educational disclaimer),
  remediation plan

**TDD targets:**
- Use `USE_LLM_MOCK=true` + fixture JSON responses for all tests
- Verify `build_prompt()` does not include PII beyond nicknames
- Verify JSON response parsing handles missing fields gracefully
- Verify 120s timeout results in job status `ERROR`, not unhandled exception
- Verify educational disclaimer is always present in social engineering section

---

### Phase 10 — PDF Generation (P10)

**Epics:** E3 (partial) | **User Stories:** US-008

**Implementation targets:**
- `orchestrator/app/report/generator.py` — `render_report()`
- `orchestrator/app/report/pdf_protector.py` — `apply_password()` with ADR-002 algorithm
- `orchestrator/templates/report.html` — Jinja2 template with traffic light, score, sections
- `orchestrator/assets/styles.css`

**TDD targets (pytest):**
- `test_pdf_is_generated`: output starts with `%PDF`
- `test_pdf_requires_password`: `pikepdf.open()` without password raises `PasswordError`
- `test_pdf_opens_with_correct_password`: derived password opens successfully
- `test_pdf_editing_disabled`: `Permissions.modify_other == False`
- `test_pdf_printing_enabled`: `Permissions.print_highres == True`
- `test_traffic_light_red`: when risk_level == HIGH → red element present in HTML
- `test_disclaimer_present`: social engineering section always contains disclaimer text

---

### Phase 11 — Delivery and Reconciliation (P11)

**Epics:** E3 (completes) | **User Stories:** US-007

**Implementation targets:**
- `orchestrator/app/storage/blob.py` — upload PDF, generate SAS URL (TTL 48h)
- `orchestrator/app/storage/cosmos.py` — update job status to `REPORT_READY`
- `backend/src/routes/internal.ts` — `POST /internal/jobs/reconcile` endpoint
- ACS email template for report delivery (password + link + 48h reminder)

**Gate:** E3 all Issues closed. End-to-end smoke test in dev Azure environment:
trigger cron manually → job reaches `REPORT_READY` → email received in Mailhog
(local) or ACS dev (Azure) → PDF opens with derived password.

---

### Phase 12 — Expiry and Purge (P12)

**Epics:** E4 (completes) | **User Stories:** US-010

**Implementation targets:**
- Backend: detect jobs stuck in `COLLECTING_PLATFORMS` past 24h → update to `EXPIRED`
  (triggered by cron or reconcile endpoint, not an additional external scheduler)
- Integration test: create job → advance time mock → verify `EXPIRED` status
- Cosmos DB emulator test: verify TTL document auto-deletion at 48h (integration test
  using `sleep` or mocked time)

---

### Phase 13 — E2E Hardening (P13)

**Objective:** Production readiness for v0.1.0.

**Tasks:**
1. Playwright E2E suite covering the complete audit flow (registration → report received).
2. Security review checklist:
   - No hardcoded secrets in any committed file (use `gitleaks` scan)
   - All NFR-02 requirements verified by tests or manual check
   - CORS headers correct in production Bicep config
3. Load test: simulate 10 concurrent users going through registration (not report generation).
4. OWASP Top 10 spot check on the Node.js API (rate limiting, input validation, JWT).
5. Accessibility audit: WCAG 2.1 AA on RegistrationPage and PlatformsPage (automated
   with `axe-core` Playwright plugin).

---

### Phase 14 — MVP Release (P14)

**Objective:** Tag `v0.1.0`, deploy to production, and validate.

**Tasks:**
1. Update `CHANGELOG.md` with all merged PRs since initial commit.
2. Final review of `README.md` for accuracy (quick start, environment setup).
3. Production Bicep deploy: `bash scripts/deploy.sh --env prod`.
4. Deploy frontend to GitHub Pages (production URL).
5. Deploy backend to Azure Container Apps (production).
6. Build and push Docker images to ACR.
7. Smoke test production: complete registration flow → mark ready → wait for next 10AM cron.
8. Tag: `git tag v0.1.0 && git push origin v0.1.0`.
9. GitHub Release: draft with CHANGELOG.md entries.
10. Update `AGENTS.md` to reflect v0.1.0 complete and set Phase 0 of v0.2.0 scope.

---

## 10. Definition of Done (DoD)

### 10.1 Task DoD

A task checklist item inside an Issue is Done when:
- [ ] The code change is committed in the feature branch
- [ ] The test for this specific task passes

### 10.2 User Story DoD

A User Story Issue is Done when:
- [ ] All Task checklist items are Done
- [ ] All Gherkin Acceptance Criteria from `USER_STORIES.md` have a corresponding test
- [ ] The spec file `docs/specs/[epic]/spec-us-[NNN].md` is committed
- [ ] CI passes on the feature branch (all jobs: lint + typecheck + test + coverage)
- [ ] PR is opened to `develop` with the PR template fully filled
- [ ] Self-review completed (commit sequence verified, privacy checklist verified)
- [ ] PR merged to `develop`
- [ ] Issue moved to "Done" on the Epic's GitHub Project board

### 10.3 Epic DoD

An Epic is Done when:
- [ ] All User Story Issues in the Epic's Project board are in "Done"
- [ ] `develop` CI is green after all Feature merges
- [ ] No open `jidoka:blocked` issues in the Epic
- [ ] Integration test covering the Epic's primary flow passes in docker-compose environment
- [ ] `AGENTS.md` updated to reflect the next phase

### 10.4 Release DoD

A release (`v0.1.0`, etc.) is Done when:
- [ ] All Epics in scope are Done
- [ ] E2E Playwright suite passes in CI (PR to `main`)
- [ ] `main` CI is green
- [ ] Production deploy successful (smoke test passed)
- [ ] `CHANGELOG.md` updated
- [ ] Git tag created and pushed
- [ ] GitHub Release published

---

## 11. CI/CD Integration

### 11.1 CI Pipeline (existing in `.github/workflows/ci.yml`)

| Job | Trigger | Enforces |
|-----|---------|----------|
| `frontend` | push/PR to `develop`, `main` | ESLint, Biome, tsc, Vitest ≥60% |
| `backend` | push/PR to `develop`, `main` | ESLint, tsc, Jest ≥70%, cron tests |
| `orchestrator` | push/PR to `develop`, `main` | ruff, mypy, pytest ≥70% |
| `e2e` | PR to `main` only | Playwright full flow |

### 11.2 Additional CI Gates (to add during development)

| Gate | Implementation | Phase |
|------|---------------|-------|
| Conventional Commits | `commitlint` action on PR | P0 |
| Secret scanning | `gitleaks` action on push | P0 |
| Dependency audit | `npm audit` + `safety check` (Python) | P0 |
| Coverage badge | `codecov` or `coveralls` | P2 |
| WCAG accessibility | `axe-core` Playwright plugin in E2E job | P13 |

### 11.3 Deploy Pipelines (existing)

- `deploy-frontend.yml` → GitHub Pages on push to `main`
- `deploy-backend.yml` → Azure Container Apps on push to `main` (OIDC, no long-lived secrets)
- No `report-generator.yml` for cron trigger (deprecated per ADR-004; internal node-cron used)

---

## 12. Risk Register and Mitigation

| ID | Risk | Probability | Impact | Mitigation |
|----|------|-------------|--------|------------|
| R-01 | Platform changes bio scraping structure | High | Medium | Version-locked HTTP mock fixtures; add `nock` recording mode for quick fixture refresh |
| R-02 | Azure OpenAI quota exceeded during demo | Medium | High | `USE_LLM_MOCK=true` fallback; pre-warm quota; cache fixture for hackathon demo |
| R-03 | Cosmos DB Emulator memory issues in CI | Medium | Low | Increase GitHub Actions runner RAM; use `--health-retries 10` |
| R-04 | WeasyPrint system dependencies missing in Container Apps | Medium | High | Lock Alpine base image; pre-test `Dockerfile` locally before P10 |
| R-05 | TDD discipline slips under time pressure | High (H0) | High | Jidoka rule: if a PR has no `test:` commit, it is not merged — no exceptions |
| R-06 | Privacy violation discovered post-merge | Low | Critical | Immediate `jidoka:blocked` label, `fix/privacy-NNN` hotfix branch, re-verify all privacy tests |
| R-07 | OSINT rate limiting by platform during demo | High | Medium | Use pre-recorded OSINT fixtures for hackathon demo; document as known limitation |
| R-08 | Agent context drift over long sessions | Medium | Medium | AGENTS.md refresh at session start; inject `constitution.md` always; use session time-boxing (90 min max) |

---

## 13. Glossary

| Term | Definition |
|------|------------|
| **Epic** | A major feature group, mapped 1:1 to a GitHub Projects board |
| **Feature** | An implementable capability, mapped to a Git branch `feat/us-NNN-slug` |
| **User Story (US)** | A value unit expressed from the user's perspective, mapped to a GitHub Issue |
| **Spec** | A structured pre-implementation contract in `docs/specs/`, committed before code |
| **TDD** | Test Driven Development: RED → GREEN → REFACTOR cycle for every task |
| **Jidoka** | Lean principle: build in quality, stop the line on defect detection |
| **SDD** | Spec Driven Development: spec precedes implementation, spec governs correctness |
| **AGENTS.md** | AI agent instruction file at repo root, updated per phase |
| **Phase** | A named development step in the roadmap (P0–P14) |
| **DoD** | Definition of Done: checklist that must be satisfied to close a task/story/epic/release |
| **AuditJob** | The canonical Cosmos DB document representing one user's audit request (see `constitution.md §4`) |
| **Proof-of-Possession** | The validation token placed in a public profile bio to verify account ownership |
| **Ephemeral IaaS** | Infrastructure that exists only while report generation is running, then is destroyed |
| **Privacy by Design** | Architectural principle: privacy protection is built in, not added on |
| **TTL** | Time-To-Live: Cosmos DB auto-deletion mechanism, set to 172800s (48h) |
| **H0** | Horizonte 0: solo developer operational mode |
| **ADR** | Architecture Decision Record: documented rationale for a technical choice |
| **INV** | Invariant: a condition that must always be true regardless of input |

---

*IMPLEMENTATION_STRATEGY.md v1.0 — May 2026 — SDIA · MIT License*
*This document is the master development guide. All Epics, Features, User Stories, and AI agent sessions operate under its governance.*
