# SDIA — Branching Strategy

> Based on **GitHub Flow** simplified with `main` protection.  
> Designed for a small team (1–4 developers) + open source contributors.

---

## Main Branches

```
main        → Production. Always deployable. Protected (no direct push).
develop     → Integration. Target for feature/fix PRs. Deploys to staging.
```

## Working Branches

```
feat/[ticket-id]-short-description     → New functionality
fix/[ticket-id]-short-description      → Bug fix
docs/short-description                 → Documentation only
chore/short-description                → Config, dependencies, IaC
test/short-description                 → Tests only
```

### Examples

```bash
feat/us-003-instagram-validation
fix/us-002-otp-expiry-check
docs/update-developer-guide
chore/update-bicep-cosmos-module
test/add-pdf-generation-tests
```

---

## Workflow

```
1. Create branch from develop
   git checkout develop && git pull
   git checkout -b feat/us-003-instagram-validation

2. Develop with conventional commits:
   feat: add Instagram bio verification endpoint
   test: add Instagram verification unit tests
   fix: handle private Instagram profiles gracefully

3. Open Pull Request → develop
   - Title: conventional (feat: / fix: / docs: etc.)
   - Description: use the PR template
   - Linked issue/story
   - At least 1 review required

4. CI must pass (lint + tests + build)

5. Merge with Squash & Merge (clean history on develop)

6. Release to main:
   PR develop → main (no squash, merge commit)
   Tag: v0.1.0, v0.1.1, v0.2.0 (semver)
```

---

## Branch Protection Rules

### `main`
- ✅ Require PR (no direct push)
- ✅ Require status checks: `ci / test`, `ci / lint`, `ci / build`
- ✅ Require 1 approving review
- ✅ Dismiss stale reviews on new commits
- ✅ Require signed commits (recommended)
- ✅ Restrict who can merge: maintainers only

### `develop`
- ✅ Require PR
- ✅ Require status checks: `ci / test`, `ci / lint`
- ❌ Approving review not required (MVP with 1 developer)

---

## Conventional Commits

```
feat:     new feature
fix:      bug fix
docs:     documentation changes
test:     add or modify tests
chore:    maintenance tasks (deps, config, IaC)
refactor: refactoring without behavior change
perf:     performance improvement
ci:       CI/CD workflow changes
```

### Full examples
```
feat(backend): add email OTP validation endpoint (#12)
fix(orchestrator): handle Azure OpenAI timeout gracefully (#18)
docs(spec): update spec-osint with Steam validation strategy
chore(infra): add Key Vault module to main.bicep
test(backend): add rate limit integration tests
```

---

## Tag Naming (SemVer)

```
v0.1.0   → MVP Hackathon (first functional version)
v0.1.x   → Post-hackathon hotfixes
v0.2.0   → Phi-3-mini + additional platforms
v1.0.0   → Stable release with educational portal
```

---

## For External Contributors (Open Source)

```
1. Fork the repository
2. Create a branch in your fork: feat/description
3. PR to upstream develop
4. Maintainers will review and merge
5. PRs directly to main are NOT accepted
```
