# Refactoring Strategy — Node-Cron & Query-Params Implementation

**Status**: In Progress  
**Last Updated**: 2026-05-27

---

## 🎯 Two Key Decisions

1. **Cron interno en Node.js** — Use `node-cron` scheduler internally within the API instead of relying on GitHub Actions or external services.
2. **Sin mini-app en correo** — Email only sends a link with query params (`https://[org].github.io/sdia?jobId=xxx&token=yyy`). GitHub Pages SPA handles all query param parsing and flow continuation.

---

## ✅ Completed Commits

### Commit 1: `fix(docs): ADR-004 - clarify node-cron internal scheduler`
**Files**: `docs/ARCHITECTURE.md`
- Rewrote ADR-004 decision from "GitHub Actions (MVP)" to "node-cron internal scheduler (final)"
- Documented full rationale: simpler architecture, zero CI cost, code transparency, reliability
- Added TypeScript implementation example showing scheduler in `src/services/cronService.ts`
- **Commit**: `3f7f68d`

### Commit 2: `fix(docs): update README architecture diagrams for node-cron scheduler`
**Files**: `README.md`
- Refactored architecture diagram showing node-cron as internal component
- Clarified Block 1 (always-on control plane) vs Block 2 (ephemeral IaaS)
- Updated email flow to show query params only approach
- Enhanced flow legend with better color coding
- **Commit**: `48a6bae`

---

## 📋 Planned Refactoring (Remaining Commits)

### Commit 3: `fix(docs): REQUIREMENTS.md - align functional specs with node-cron`
**File**: `docs/REQUIREMENTS.md`
**Changes**:
- **FR-06**: Update "FR-06 — Report Generation Process" 
  - Change trigger from "GitHub Actions cron" to "Internal Node.js scheduler"
  - Confirm payload: `node-cron` (no external dependency)
- Remove any references to GitHub Actions workflow triggers
- Update timing descriptions (10:00 AM UTC-6 still valid, just internal)
- Verify all performance requirements (NFR-04.5) still apply

**Lines to modify**: ~70-90 (FR-06 section)

**Commit message**:
```
fix(docs): REQUIREMENTS.md - align specs with internal node-cron scheduler

- Update FR-06: trigger now internal node-cron (10:00 AM UTC-6)
- Remove GitHub Actions trigger references
- Clarify scheduler runs within always-on Node.js API container
- Timing guarantees remain: ±1 min precision, daily batch processing
```

---

### Commit 4: `fix(docs): DEVELOPER_GUIDE.md - add node-cron setup instructions`
**File**: `docs/DEVELOPER_GUIDE.md`
**Changes**:
- Add section: "## Local Development — Running the Cron Scheduler"
  - Explain how `node-cron` is initialized in `src/services/cronService.ts`
  - Document environment variables: `CRON_TIMEZONE=America/Mexico_City`, `CRON_SCHEDULE=0 10 * * *`
  - Show how to test cron manually (via npm script or direct API call)
  - Example: `npm run test:cron` or `curl -X POST http://localhost:3000/api/internal/trigger-report-cycle`
- Update docker-compose setup if needed
- Document how to disable/enable cron in dev vs production

**Commit message**:
```
fix(docs): DEVELOPER_GUIDE.md - document internal cron scheduler setup

- Add node-cron initialization guide (src/services/cronService.ts)
- Document environment variables for timezone and schedule
- Include manual trigger endpoint for testing: POST /api/internal/trigger-report-cycle
- Update docker-compose notes for local cron testing
```

---

### Commit 5: `chore(docs): TESTING_STRATEGY.md - update CI/CD pipeline section`
**File**: `docs/TESTING_STRATEGY.md`
**Changes**:
- **Part IV — CI Pipeline**: Remove or clarify GitHub Actions cron job
  - Delete/comment-out any workflow references to "report-generator.yml"
  - Document that Node.js backend is tested for cron functionality (unit + integration)
  - Add test scenario: "When cron fires at 10 AM, it should query Cosmos DB for READY_TO_REPORT jobs"
- Keep frontend, backend, orchestrator, e2e testing as-is
- If there's a GitHub Actions workflow for CI/CD deployments, it remains unchanged (only cron triggering is removed)

**Lines to modify**: ~150-180 (CI Pipeline section)

**Commit message**:
```
chore(docs): TESTING_STRATEGY.md - remove GitHub Actions cron references

- Remove report-generator.yml workflow from pipeline docs
- Update backend tests: add cron scheduler unit tests
- Document cron integration test: verify scheduler queries Cosmos DB at scheduled time
- Keep CI/CD deployment workflows intact (GitHub Actions still used for build/deploy)
```

---

### Commit 6: `docs(constitution): self-digital-identity-audit - finalize cron decision`
**File**: `.specify/memory/constitution.md` (or similar)
**Changes**:
- **Section 3.5 — Report Orchestrator**: Update trigger from GitHub Actions to internal
  ```
  Trigger:     Internal node-cron (10:00 AM UTC-6)
  Runtime:     Node.js Fastify (always-on, scale-to-zero)
  ```
- Add note: "Initial MVP considered GitHub Actions; moved to internal cron for simplicity."
- Update any timeline/roadmap that references "v0.2 Azure Function Timer"

**Commit message**:
```
docs(constitution): finalize tech stack for internal cron scheduler

- Update canonical tech stack: Trigger = node-cron (internal, not GitHub Actions)
- Remove timeline note about "v0.2 migration to Azure Function Timer"
- Clarify: single Node.js Fastify instance runs both API and scheduler
```

---

### Commit 7: `chore(infra): remove or document report-generator workflow`
**File**: `.github/workflows/report-generator.yml` (if exists)
**Changes**:
- Option A: **Delete** `report-generator.yml` (if no longer needed)
  ```bash
  git rm .github/workflows/report-generator.yml
  ```
- Option B: **Archive** with deprecation notice (if other workflows depend on it)
  ```yaml
  # .github/workflows/report-generator.yml
  # DEPRECATED: Cron triggering moved to internal node-cron scheduler
  # This file is kept for reference only. Delete after confirming no dependencies.
  ```

**Commit message**:
```
chore(infra): remove GitHub Actions report-generator workflow

- Cron triggering now handled by internal node-cron in Node.js API
- No longer need GitHub Actions workflow for daily report scheduling
- Deployment workflows (CI/CD) remain unchanged
```

---

## 📊 Commit Summary

| # | File | Type | Status | Description |
|----|------|------|--------|-------------|
| 1 | ARCHITECTURE.md | fix(docs) | ✅ Done | ADR-004 final decision |
| 2 | README.md | fix(docs) | ✅ Done | Diagram alignment |
| 3 | REQUIREMENTS.md | fix(docs) | ⏳ Next | FR-06 update |
| 4 | DEVELOPER_GUIDE.md | fix(docs) | ⏳ Planned | Cron setup guide |
| 5 | TESTING_STRATEGY.md | chore(docs) | ⏳ Planned | Remove GA refs |
| 6 | constitution.md | docs | ⏳ Planned | Finalize tech stack |
| 7 | .github/workflows/ | chore(infra) | ⏳ Planned | Remove cron workflow |

---

## 🚀 Next Steps

1. **Now**: ARCHITECTURE.md ✅ + README.md ✅
2. **Next**: Run `git log --oneline | head -5` to confirm commits
3. **Then**: Open REQUIREMENTS.md → Commit 3
4. Continue with Commits 4–7 following the same pattern

---

## 📝 Notes

- All commits should be **atomic** (one logical change per commit)
- Use **`fix(docs)`** for documentation corrections aligning with code decisions
- Use **`chore(docs)`** for non-functional doc updates (removal, reorganization)
- Use **`chore(infra)`** for infrastructure file changes
- Each commit should be independently understandable and buildable
