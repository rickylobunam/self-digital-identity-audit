# SDIA — Agent Instructions

> **Read this file at the start of every AI-assisted development session.**
>
> Repository language rule: all repository code, comments, documentation, configuration, commit messages, and CI/CD files must be written in English.
>
> Conversation with the human developer may happen in Spanish, but all files created or modified in the repository must remain in English.

---

## Active Phase

**P0-BOOTSTRAP — Bootstrap Scaffolding**

Official branch:

```text
chore/p0-bootstrap-scaffolding
```

This phase prepares the repository so future SDIA development can follow the official methodology:

```text
Spec Driven Development → Test Driven Development → Jidoka → Pull Request → CI → Merge
```

This phase is not intended to implement business features yet. It creates the minimum professional foundation required to develop frontend, backend, orchestrator, local tooling, CI, and HTTPS local development in a controlled and reproducible way.

---

## Human-in-the-Loop Rule

This phase must be completed task by task with the human developer actively approving each step.

The agent must not attempt to complete the entire phase in one large uncontrolled change.

The expected operating model is:

```text
1. Human selects the next task.
2. Agent proposes the exact CLI commands and files to create or modify.
3. Human runs or approves the commands.
4. Agent reviews the output or error.
5. Agent proposes the next minimal fix or next step.
6. Human approves before moving forward.
```

The agent must prefer terminal and CLI-based workflows using the frameworks and tools defined for SDIA.

Do not silently create broad changes.
Do not infer missing architectural decisions.
Do not bypass the human developer.

---

## Current Objective

Complete the P0 bootstrap foundation by creating and validating the following items:

- Minimal `frontend/`, `backend/`, and `orchestrator/` scaffolds.
- Initial root `Makefile` with standard development targets.
- Local HTTPS certificate scripts for Linux/macOS and Windows PowerShell.
- GitHub Pull Request template.
- Baseline GitHub Actions CI workflow for frontend, backend, and orchestrator.
- Local validation using `docker-compose up -d` and a backend health endpoint.

---

## Source of Truth

Before making changes, the agent must align with these repository documents:

```text
docs/specs/IMPLEMENTATION_STRATEGY.md
docs/ARCHITECTURE.md
docs/FEATURES.md
docs/TESTING_STRATEGY.md
docs/BRANCHING_STRATEGY.md
docs/DEVELOPER_GUIDE.md
docs/design/THEME.md
```

For this phase, the most important source is:

```text
docs/specs/IMPLEMENTATION_STRATEGY.md
```

This phase maps to:

```text
Phase 0 — Bootstrap (P0)
```

---

## Phase Tasks

### Task 1 — Create minimal application scaffolds

Create the following top-level directories if they do not exist:

```text
frontend/
backend/
orchestrator/
```

Each scaffold must be minimal but executable.

Expected baseline:

```text
frontend/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── index.html
└── src/
    ├── main.tsx
    └── App.tsx

backend/
├── package.json
├── tsconfig.json
├── Dockerfile
└── src/
    ├── server.ts
    └── routes/
        └── health.ts

orchestrator/
├── requirements.txt
├── Dockerfile
├── app/
│   └── main.py
└── tests/
    └── test_health.py
```

Minimum expected behavior:

- Frontend can build successfully.
- Backend can start and expose a health endpoint.
- Orchestrator can run tests successfully.

Backend health endpoint target:

```http
GET /health
```

Expected response:

```json
{ "status": "ok" }
```

---

### Task 2 — Create initial Makefile

Create a root-level `Makefile`.

Required initial targets:

```text
help
install
lint
test
build
dev
clean
```

Recommended additional targets if they can be safely added during P0:

```text
certs
docker-up
docker-down
health
```

The Makefile must be the main developer entry point.

The following commands should eventually work from the repository root:

```bash
make help
make install
make lint
make test
make build
make dev
make clean
```

If a package is still empty or intentionally minimal, the Makefile may use safe no-op placeholders, but they must be explicit and documented.

Do not hide failures with unconditional `|| true` unless the no-op behavior is intentional and documented.

---

### Task 3 — Create local HTTPS certificate scripts

Create:

```text
scripts/certs/cer.sh
scripts/certs/cer.ps1
```

Purpose:

- Support local HTTPS development.
- Make local frontend/backend callback testing easier.
- Support future auth, email validation links, and browser APIs requiring secure contexts.

Recommended output directory:

```text
.certs/
```

The scripts should prefer `mkcert` if available.

If `mkcert` is not available, the scripts may provide a documented fallback using OpenSSL or OS-specific certificate generation.

The scripts must not commit generated certificates.

Ensure `.gitignore` includes:

```gitignore
.certs/
*.pem
*.key
*.crt
*.pfx
```

Security requirements:

- Never generate or commit production certificates.
- Never store secrets in the repository.
- Make it explicit that the generated certificates are local-development only.

---

### Task 4 — Create Pull Request template

Create:

```text
.github/PULL_REQUEST_TEMPLATE.md
```

The PR template must include at least:

- User Story or phase reference.
- Spec reference.
- Summary of changes.
- Commit sequence checklist.
- Privacy-by-Design checklist.
- Testing summary.
- CI status reminder.
- Breaking changes section.

The template must support both User Story branches and chore/bootstrap branches.

---

### Task 5 — Create baseline CI workflow

Create:

```text
.github/workflows/ci.yml
```

The baseline CI must include independent jobs for:

```text
frontend
backend
orchestrator
```

The initial CI should validate at minimum:

Frontend:

```text
install
lint or no-op lint placeholder
build
test or no-op test placeholder
```

Backend:

```text
install
lint or no-op lint placeholder
build
test or no-op test placeholder
```

Orchestrator:

```text
install Python dependencies
lint or no-op lint placeholder
pytest
```

CI should trigger on:

```yaml
on:
  pull_request:
    branches:
      - develop
      - main
  push:
    branches:
      - develop
      - main
```

Do not configure production deployment in this baseline CI workflow.

Deployment workflows belong to later phases.

---

### Task 6 — Validate docker-compose and backend health endpoint

Validate the local development environment.

Expected command:

```bash
docker-compose up -d
```

or, if using the modern Docker plugin:

```bash
docker compose up -d
```

Then validate the backend health endpoint:

```bash
curl http://localhost:3000/health
```

Expected result:

```json
{ "status": "ok" }
```

If Docker Compose does not yet include backend/frontend/orchestrator services correctly, update it minimally during this phase.

Do not add production-only services during P0.

---

## Preferred CLI-First Workflow

The agent must prioritize CLI-based setup and validation.

Recommended command sequence for this phase:

```bash
git switch develop
git pull --ff-only origin develop
git switch -c chore/p0-bootstrap-scaffolding
```

Then proceed task by task.

At the end of each meaningful task:

```bash
git status
make lint
make test
make build
```

Commit only logical units of work.

Recommended P0 commit sequence:

```text
docs: add P0 bootstrap agent instructions
chore: scaffold frontend workspace
chore: scaffold backend workspace
chore: scaffold orchestrator workspace
chore: add initial Makefile
chore: add local HTTPS certificate scripts
chore: add pull request template
ci: add baseline CI workflow
chore: validate docker compose health check
```

---

## TDD Gate

State for this phase:

```text
P0 bootstrap foundation — minimal testable scaffolds
```

P0 does not implement business User Stories yet, but it must still create testable foundations.

Minimum testing expectations:

- Backend must expose a testable `/health` endpoint.
- Orchestrator must have at least one minimal pytest test.
- Frontend must be able to build.
- CI must be able to run all baseline jobs.

No User Story implementation should begin in this phase.

Do not implement:

- Registration flow.
- Email validation flow.
- Platform verification flow.
- Report generation flow.
- OSINT extraction.
- LLM analysis.
- PDF generation.

Those belong to later phases.

---

## Jidoka Stop Conditions

The agent must stop immediately and ask the human developer before continuing if any of the following occur:

- A command fails and the cause is not obvious.
- The scaffold requires a major architectural decision not already defined in the documentation.
- Docker Compose cannot start cleanly after a minimal fix attempt.
- The backend health endpoint cannot be reached locally.
- CI requires secrets that should not be available in P0.
- A generated file may expose secrets, tokens, certificates, or local machine paths.
- A proposed change modifies protected documents without explicit human approval.
- A proposed change expands the scope into business functionality.
- An agent attempts to touch files outside the approved task scope.
- Any code path stores or logs email, nickname, token, or PII unnecessarily.

Jidoka means:

```text
Stop the line.
Surface the issue.
Explain the blocker.
Propose the smallest safe next step.
Wait for human approval.
```

---

## Files to Touch During P0

The following files and folders may be created or modified during this phase:

```text
AGENTS.md
Makefile
.gitignore
.env.example
README.md
DEVELOPER_GUIDE.md

docker-compose.yml

frontend/
backend/
orchestrator/

scripts/certs/cer.sh
scripts/certs/cer.ps1
scripts/deploy.sh
scripts/setup-github-oidc.sh

.github/PULL_REQUEST_TEMPLATE.md
.github/workflows/ci.yml
```

Only touch `scripts/deploy.sh` or `scripts/setup-github-oidc.sh` if the human developer explicitly selects an infra/tooling task.

Only update `README.md` or `DEVELOPER_GUIDE.md` if required to document a completed P0 setup step.

---

## Files Not to Touch Without Explicit Approval

Do not modify the following files unless the human developer explicitly asks:

```text
docs/ARCHITECTURE.md
docs/FEATURES.md
docs/REQUIREMENTS.md
docs/TESTING_STRATEGY.md
docs/BRANCHING_STRATEGY.md
docs/specs/IMPLEMENTATION_STRATEGY.md
docs/design/THEME.md
infra/main.bicep
infra/modules/*.bicep
infra/parameters/*.bicepparam
CHANGELOG.md
LICENSE
SECURITY.md
CODE_OF_CONDUCT.md
CONTRIBUTING.md
```

These are source-of-truth or governance files and should not be edited casually during scaffolding.

---

## Framework and Tooling Preferences

Use the project architecture as the guiding framework selection.

### Frontend

Preferred stack:

```text
Vite + React + TypeScript
```

Minimum expected tooling:

```text
npm
TypeScript
Vite
Vitest or placeholder test command
ESLint/Biome or placeholder lint command
```

### Backend

Preferred stack:

```text
Node.js + Fastify + TypeScript
```

Minimum expected tooling:

```text
npm
TypeScript
tsx or ts-node-dev for local development
Jest or Vitest for tests
Fastify health route
```

### Orchestrator

Preferred stack:

```text
Python + FastAPI + pytest
```

Minimum expected tooling:

```text
python
pip
FastAPI
pytest
ruff or placeholder lint command
```

### Local services

Preferred local service orchestration:

```text
docker-compose.yml
```

Required services may include, depending on current repository state:

```text
backend
frontend
orchestrator
azurite
mailhog
cosmos-emulator or documented substitute
```

Do not overbuild local infrastructure during P0.

---

## Development Boundaries

P0 is successful when the repository can be cloned, installed, built, tested, and validated locally with predictable commands.

P0 is not successful if it starts implementing user-facing product flows before the scaffold and CI are stable.

Do not implement future phase logic early.

The correct goal is:

```text
A clean, reproducible, testable development foundation.
```

Not:

```text
A partially implemented MVP feature.
```

---

## Validation Checklist

Before opening the PR for `chore/p0-bootstrap-scaffolding`, verify:

```text
[ ] frontend/ exists and has a minimal working scaffold.
[ ] backend/ exists and exposes GET /health.
[ ] orchestrator/ exists and has a minimal pytest test.
[ ] Makefile exists and includes help, install, lint, test, build, dev, clean.
[ ] scripts/certs/cer.sh exists.
[ ] scripts/certs/cer.ps1 exists.
[ ] Generated certificates are ignored by Git.
[ ] .github/PULL_REQUEST_TEMPLATE.md exists.
[ ] .github/workflows/ci.yml exists.
[ ] docker-compose up -d starts required local services or fails with a documented blocker.
[ ] curl http://localhost:3000/health returns { "status": "ok" }.
[ ] make lint passes or documented safe placeholders exist.
[ ] make test passes.
[ ] make build passes.
[ ] No secrets, generated certificates, local absolute paths, or PII are committed.
[ ] No business User Story implementation was added in P0.
```

---

## PR Requirements

The Pull Request for this phase must target:

```text
develop
```

PR title recommendation:

```text
chore: bootstrap P0 repository scaffolding
```

PR description must include:

```text
Phase: P0-BOOTSTRAP
Branch: chore/p0-bootstrap-scaffolding
Source: docs/specs/IMPLEMENTATION_STRATEGY.md
```

The PR must summarize:

- What scaffolds were created.
- What Makefile targets were added.
- What certificate scripts were added.
- What CI jobs were added.
- How Docker Compose and `/health` were validated.
- Any known limitations or deferred items.

The PR must not claim that business functionality is implemented.

---

## Expected Final P0 Gate

P0 is complete when:

```text
1. The official branch chore/p0-bootstrap-scaffolding is pushed.
2. A Pull Request into develop is opened.
3. GitHub Actions CI passes.
4. Local validation commands pass.
5. The PR is squash-merged into develop.
6. The local and remote P0 branch are deleted.
7. AGENTS.md is ready for the next phase.
```

After merge:

```bash
git switch develop
git pull --ff-only origin develop
git branch -d chore/p0-bootstrap-scaffolding
git push origin --delete chore/p0-bootstrap-scaffolding
```

If Git cannot delete the local branch because the PR was squash-merged, verify the PR was merged and then run:

```bash
git branch -D chore/p0-bootstrap-scaffolding
```

---

## Output Convention for Agents

When assisting during this phase, the agent must respond using this structure:

```text
1. Current task
2. Proposed files to create or modify
3. Exact CLI commands
4. Expected output
5. Validation command
6. Jidoka stop condition for this step
7. Ask for human approval before proceeding
```

Do not proceed to the next task without human approval.

---