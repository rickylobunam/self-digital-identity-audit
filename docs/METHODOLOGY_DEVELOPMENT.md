## Methodology used for the development of SDIA

SDIA uses two complementary development workflows depending on the complexity of the task:

1. **Linear feature/chore branch workflow** — used for simple or medium-sized development phases.
2. **Worktree-isolated agent workflow with squash integration** — used for complex phases where frontend, backend, orchestrator, infrastructure, or AI-agent-assisted work may happen in parallel.

Both workflows must preserve the project rules defined in this document:

- Spec Driven Development (SDD) before implementation.
- Test Driven Development (TDD) for backend, orchestrator, and critical frontend logic.
- Jidoka stop-at-defect discipline.
- Privacy-by-Design invariants.
- English-only repository content.
- Pull Request review through GitHub before merging into `develop`.
- No direct pushes to protected branches (`main`, `develop`) unless explicitly required for emergency maintenance.

---

### 1. Linear feature/chore branch workflow

Use this workflow when the task can be implemented safely in one branch without parallel worktrees.

This is the default workflow for straightforward tasks such as:

- Adding or updating documentation.
- Creating a scaffold.
- Implementing a small feature.
- Updating a configuration file.
- Adding a single service, component, or test group.
- Completing a phase that does not require multiple isolated agents.

#### 1.1 Start from an updated `develop`

```bash
git switch develop
git pull --ff-only origin develop
```

#### 1.2 Create the official working branch

Use a descriptive branch name.

Recommended branch naming:

```text
chore/p0-bootstrap-scaffolding
chore/p1-infra-foundation
feat/us-001-registration
feat/us-002-email-validation
feat/us-003-instagram-validation
feat/us-010-expiry-purge
fix/privacy-001-email-hash-leak
```

Generic pattern:

```text
<type>/<phase-or-user-story>-descriptive-branch-name
```

Where:

- `chore/` is used for scaffolding, tooling, infrastructure setup, documentation maintenance, CI/CD setup, and non-user-facing work.
- `feat/` is used for User Story or Feature implementation.
- `fix/` is used for bug fixes.
- `docs/` may be used for documentation-only changes.
- `test/` may be used for test-only branches when appropriate.
- `privacy/` or `fix/privacy-*` may be used for urgent privacy fixes.

Create the branch:

```bash
git switch -c chore_or_feature/p#-descriptive-branch-name
```

Example:

```bash
git switch -c chore/p0-bootstrap-scaffolding
```

#### 1.3 Work with logical commits directly on the branch

Commits on the official branch must be logical and reviewable.

For feature branches related to User Stories, follow the official commit sequence:

```text
1. docs: add or update the spec
2. test: add failing RED tests
3. feat: implement the minimal GREEN solution
4. refactor: clean up without changing behavior
5. test: add integration or E2E coverage if applicable
6. docs: update AGENTS.md or related documentation if needed
```

Example:

```bash
git add docs/specs/epic-1-registration/spec-us-001-registration.md
git commit -m "docs: add registration user story spec"

git add backend/src backend/tests
git commit -m "test: add RED tests for registration endpoint"

git add backend/src
git commit -m "feat: implement audit request registration"

git add backend/src
git commit -m "refactor: extract email hash helper"

git add backend/tests
git commit -m "test: add registration integration coverage"

git add AGENTS.md
git commit -m "docs: update agent instructions for next phase"
```

For chore/scaffolding phases, use logical commits such as:

```bash
git commit -m "chore: scaffold frontend workspace"
git commit -m "chore: scaffold backend workspace"
git commit -m "chore: scaffold orchestrator workspace"
git commit -m "chore: add Makefile and local certificate scripts"
git commit -m "ci: add baseline CI workflow"
```

#### 1.4 Run local validation before pushing

At minimum:

```bash
make lint
make test
make build
```

If the task touches Docker, local services, or integration flows:

```bash
make docker-up
make docker-down
```

If the task touches infrastructure:

```bash
make infra-validate
```

If any command fails, apply Jidoka:

```text
Stop.
Fix the defect.
Do not continue to the next task until the current gate is green.
```

#### 1.5 Push the official branch

```bash
git push -u origin chore_or_feature/p#-descriptive-branch-name
```

Example:

```bash
git push -u origin chore/p0-bootstrap-scaffolding
```

#### 1.6 Open a Pull Request into `develop`

Open a PR with:

```text
base: develop
compare: chore_or_feature/p#-descriptive-branch-name
```

The PR must include:

- User Story reference, if applicable.
- Spec reference.
- Summary of implementation.
- Testing summary.
- Privacy-by-Design checklist.
- Any known limitations.
- Confirmation that local gates passed.

For User Stories, the PR must link the GitHub Issue:

```text
Closes #<issue-number>
```

#### 1.7 Wait for GitHub Actions CI

The PR must pass the required CI checks before merge.

Expected gates may include:

- lint
- typecheck
- unit tests
- integration tests
- coverage threshold
- secret scanning
- dependency audit
- build
- infrastructure validation, if applicable

If CI fails, apply Jidoka:

```text
Stop.
Fix the failing check in the same branch.
Push the fix.
Wait for CI again.
```

#### 1.8 Merge the PR into `develop`

For most SDIA branches, use:

```text
Squash and merge
```

This keeps `develop` clean while preserving the PR as the reviewable unit of work.

The squash commit message must be meaningful.

Examples:

```text
chore: bootstrap P0 repository scaffolding
feat: implement audit request registration
feat: implement email ownership validation
fix: enforce email hash privacy invariant
```

#### 1.9 Update local `develop`

After the PR is merged:

```bash
git switch develop
git pull --ff-only origin develop
```

#### 1.10 Delete the local branch

```bash
git branch -d chore_or_feature/p#-descriptive-branch-name
```

If Git refuses because the branch was squash-merged and it cannot detect a normal merge, verify the PR was merged and then delete forcefully:

```bash
git branch -D chore_or_feature/p#-descriptive-branch-name
```

#### 1.11 Delete the remote branch

```bash
git push origin --delete chore_or_feature/p#-descriptive-branch-name
```

Example:

```bash
git push origin --delete chore/p0-bootstrap-scaffolding
```

---

### 2. Worktree-isolated agent workflow with squash integration

Use this workflow for complex phases where multiple isolated tasks may be developed in parallel.

This workflow is recommended when:

- Frontend, backend, and orchestrator work can proceed independently.
- Multiple AI coding agents are used.
- A task is large enough to benefit from isolated workspaces.
- You want to keep temporary commits away from the official GitHub history.
- You need to test multiple approaches without polluting the official branch.
- You want to preserve a clean official feature branch while still allowing messy local experimentation.

This workflow has four levels:

```text
main
└── develop
    └── official feature/chore branch
        ├── local scratch/worktree branch A
        ├── local scratch/worktree branch B
        └── local scratch/worktree branch C
```

Only the official branch is pushed to GitHub.

Scratch branches and worktree branches are local implementation spaces and are normally deleted after their useful changes are squashed into the official branch.

---

### 2.1 Start from updated `develop`

```bash
git switch develop
git pull --ff-only origin develop
```

---

### 2.2 Create the official branch

```bash
git switch -c feat_or_chore/official-branch-name
```

Example:

```bash
git switch -c feat/us-001-registration
```

Push the official branch if you want early CI visibility or a draft PR:

```bash
git push -u origin feat/us-001-registration
```

---

### 2.3 Create isolated worktrees for parallel work

Each worktree must have its own scratch branch.

Example for a complex User Story:

```bash
git worktree add ../sdia-us001-spec -b scratch/us001-spec feat/us-001-registration
git worktree add ../sdia-us001-tests -b scratch/us001-tests feat/us-001-registration
git worktree add ../sdia-us001-api -b scratch/us001-api feat/us-001-registration
```

Example for a phase involving multiple layers:

```bash
git worktree add ../sdia-p0-frontend -b scratch/p0-frontend-scaffold chore/p0-bootstrap-scaffolding
git worktree add ../sdia-p0-backend -b scratch/p0-backend-scaffold chore/p0-bootstrap-scaffolding
git worktree add ../sdia-p0-orchestrator -b scratch/p0-orchestrator-scaffold chore/p0-bootstrap-scaffolding
git worktree add ../sdia-p0-ci -b scratch/p0-ci-baseline chore/p0-bootstrap-scaffolding
```

Each worktree must have a narrow scope.

Example:

```text
Worktree: ../sdia-us001-api
Branch: scratch/us001-api
Allowed files:
- backend/src/routes/jobs.ts
- backend/src/services/cosmosService.ts
- backend/src/services/tokenService.ts
- backend/tests/jobs.test.ts

Forbidden files:
- frontend/
- orchestrator/
- infra/
- docs/ARCHITECTURE.md
```

---

### 2.4 Run the agent or work manually inside each worktree

Move into the worktree:

```bash
cd ../sdia-us001-api
```

Run the selected tool or agent there.

The agent must receive explicit instructions:

```text
Active phase:
P2-BACKEND-REGISTRATION

Objective:
Implement only the backend registration endpoint.

Spec reference:
docs/specs/epic-1-registration/spec-us-001-registration.md

Files to touch:
- backend/src/routes/jobs.ts
- backend/src/services/cosmosService.ts
- backend/src/services/tokenService.ts
- backend/tests/jobs.test.ts

Files not to touch:
- frontend/
- orchestrator/
- infra/
- docs/ARCHITECTURE.md

TDD gate:
RED tests must exist before implementation.

Jidoka stop conditions:
- Stop if email is stored in plaintext.
- Stop if logs contain email or nickname.
- Stop if tests are bypassed or disabled.
```

Agents may create messy local commits inside scratch branches.

That is acceptable as long as:

- The changes stay inside the worktree.
- The scratch branch is not pushed to GitHub.
- The useful result is later squashed into the official branch.
- Privacy and security rules are never violated.

---

### 2.5 Validate each worktree locally

Inside each worktree:

```bash
make lint
make test
make build
```

Or run narrower package-level commands if the Makefile supports them:

```bash
make test-backend
make test-frontend
make test-orchestrator
```

If validation fails, fix the worktree before integration.

Do not squash broken work into the official branch.

---

### 2.6 Squash useful work into the official branch

Return to the main checkout or the checkout containing the official branch:

```bash
cd path/to/self-digital-identity-audit
git switch feat_or_chore/official-branch-name
```

Squash one scratch branch at a time.

Example:

```bash
git merge --squash scratch/us001-spec
git commit -m "docs: add registration user story spec"

git merge --squash scratch/us001-tests
git commit -m "test: add RED tests for registration endpoint"

git merge --squash scratch/us001-api
git commit -m "feat: implement audit request registration"
```

For P0 scaffolding:

```bash
git merge --squash scratch/p0-frontend-scaffold
git commit -m "chore: scaffold frontend workspace"

git merge --squash scratch/p0-backend-scaffold
git commit -m "chore: scaffold backend workspace"

git merge --squash scratch/p0-orchestrator-scaffold
git commit -m "chore: scaffold orchestrator workspace"

git merge --squash scratch/p0-ci-baseline
git commit -m "ci: add baseline CI workflow"
```

The official branch must contain clean, logical commits.

Scratch commits such as the following must not appear in the official branch:

```text
wip
try again
fix lint
temporary test
agent attempt
debug
revert bad import
```

---

### 2.7 Run full validation from the official branch

```bash
make lint
make test
make build
```

If applicable:

```bash
make docker-up
make docker-down
make infra-validate
```

If any command fails, fix it on the official branch or in a new scratch worktree, then squash again.

Do not push the official branch until the local gate is green.

---

### 2.8 Remove completed worktrees

List worktrees:

```bash
git worktree list
```

Remove each completed worktree:

```bash
git worktree remove ../sdia-us001-spec
git worktree remove ../sdia-us001-tests
git worktree remove ../sdia-us001-api
```

Prune stale worktree metadata:

```bash
git worktree prune
```

---

### 2.9 Delete local scratch branches

Because squash merge does not create a normal merge relationship, Git may not know that the scratch branch content was already integrated.

After verifying that the useful work was squashed into the official branch, delete scratch branches:

```bash
git branch -D scratch/us001-spec
git branch -D scratch/us001-tests
git branch -D scratch/us001-api
```

For P0 example:

```bash
git branch -D scratch/p0-frontend-scaffold
git branch -D scratch/p0-backend-scaffold
git branch -D scratch/p0-orchestrator-scaffold
git branch -D scratch/p0-ci-baseline
```

Confirm cleanup:

```bash
git worktree list
git branch --list "scratch/*"
```

---

### 2.10 Push the official branch

```bash
git push origin feat_or_chore/official-branch-name
```

Example:

```bash
git push origin feat/us-001-registration
```

---

### 2.11 Open a Pull Request into `develop`

Open a PR:

```text
base: develop
compare: feat_or_chore/official-branch-name
```

The PR must include:

- User Story reference.
- Spec reference.
- Commit sequence checklist.
- Privacy-by-Design checklist.
- Testing summary.
- Known limitations.
- Any ADR impact.
- Confirmation that scratch branches were not pushed.

---

### 2.12 Let GitHub Actions validate the official branch

Required checks must pass before merge.

If CI fails:

```text
Jidoka applies.
Stop.
Fix the failing check.
Push again.
Wait for CI.
```

---

### 2.13 Merge the PR into `develop`

Recommended strategy:

```text
Squash and merge
```

Use a meaningful squash commit message.

Examples:

```text
feat: implement audit request registration
feat: complete email ownership validation
chore: bootstrap P0 repository scaffolding
```

---

### 2.14 Update local `develop`

```bash
git switch develop
git pull --ff-only origin develop
```

---

### 2.15 Delete the official branch locally and remotely

Delete local branch:

```bash
git branch -d feat_or_chore/official-branch-name
```

If the branch was squash-merged and Git cannot detect the merge:

```bash
git branch -D feat_or_chore/official-branch-name
```

Delete remote branch:

```bash
git push origin --delete feat_or_chore/official-branch-name
```

---

## Branch retention policy

### Permanent branches

These branches are never deleted:

```text
main
develop
```

### Official feature/chore branches

These branches are deleted after their PR is merged into `develop`:

```text
chore/p0-bootstrap-scaffolding
feat/us-001-registration
feat/us-002-email-validation
feat/us-010-expiry-purge
```

### Local scratch/worktree branches

These branches are deleted after their useful work is squashed into the official branch:

```text
scratch/p0-frontend-scaffold
scratch/us001-tests
scratch/us001-api
```

Scratch branches should normally never be pushed to GitHub.

---

## History cleanliness model

SDIA uses a layered history model.

### `main`

`main` contains release-level history.

It should receive only stable changes from `develop` when preparing a release.

Tags such as `v0.1.0`, `v0.2.0`, and `v1.0.0` point to commits on `main`.

### `develop`

`develop` contains clean integration history.

It receives completed work through PRs.

Recommended merge strategy:

```text
Squash and merge
```

### Official feature/chore branches

Official branches contain logical technical history.

They should show meaningful commits such as:

```text
docs: add spec
test: add RED tests
feat: implement feature
refactor: simplify service
test: add integration coverage
docs: update AGENTS.md
```

### Local scratch/worktree branches

Scratch branches may contain temporary or noisy commits.

Examples:

```text
wip
debug
fix lint
try again
agent attempt
```

These commits must be squashed into meaningful commits before entering the official branch.

---

## Golden rule

Do not hide important engineering decisions.

Do hide local implementation noise.

The purpose of scratch branches and worktrees is to keep experimentation isolated, not to bypass quality gates.

Every change that matters must eventually appear in one of the following forms:

- a spec file,
- a test,
- a meaningful commit,
- a PR description,
- an AGENTS.md update,
- a CHANGELOG entry,
- or an ADR update when architecture changes.

The official path is always:

```text
local scratch/worktree work
→ squash into official feature/chore branch
→ local validation
→ push official branch
→ Pull Request into develop
→ GitHub Actions CI
→ squash merge into develop
→ delete completed branches
```

### 2.2 Working Constraints

- **Single developer (H0), eight skills:** Ricardo holds all roles in H0, but each working
  session is entered from a specific **skill perspective** (see table below). This prevents
  context overload by limiting the cognitive surface to one domain at a time.
  Time-boxing per session to **90 minutes maximum** is mandatory; switch skills or stop.
  A session always begins by reading `AGENTS.md` + `constitution.md` to restore context.

| Skill ID | Role / Perspective | Primary Layer | When to activate |
|---|---|---|---|
| `sdia-architect` | System design, ADRs, cross-component | All | New flow design, ADR proposal, cross-boundary impact |
| `sdia-backend-engineer` | Node.js Fastify TypeScript API | `backend/` | Any route, service, plugin, or Jest test |
| `sdia-frontend-engineer` | Vite React TypeScript SPA | `frontend/` | Any page, component, MSW mock, or Vitest test |
| `sdia-orchestrator-engineer` | Python OSINT + LLM + PDF pipeline | `orchestrator/` | Any extractor, AI analysis, PDF gen, or pytest |
| `sdia-infra-engineer` | Azure Bicep IaC + Docker Compose | `infra/` | Any Bicep module, deploy script, or cost review |
| `sdia-security-privacy` | Security review + Privacy-by-Design | All | Pre-merge checklist, any token/auth/secret work |
| `sdia-tdd-coach` | TDD discipline + Jidoka enforcement | All | Session start, stuck test, coverage gap, Jidoka stop |
| `sdia-tech-writer` | Specs, AGENTS.md, CHANGELOG, README | `docs/` | Phase boundary, new US, AGENTS.md update |

  Skills are stored in `.claude/skills/` and packaged as `.skill` files (Claude.ai) per
  the standard in `docs/skills/README.md`. Load only the skill relevant to the current task.
