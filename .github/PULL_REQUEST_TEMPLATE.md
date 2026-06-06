## User Story or Phase Reference

<!-- For User Story: Closes #NNN (link to GitHub Issue) -->
<!-- For chore/bootstrap: Closes #NNN or Phase: P0-BOOTSTRAP -->

Closes #

---

## Spec Reference

<!-- Link to the spec file committed in this PR, if applicable -->
<!-- Example: docs/specs/epic-1-registration/spec-us-001-registration.md -->
<!-- For chore phases, can be "N/A - Infrastructure/Tooling task" -->

`docs/specs/...` or N/A

---

## Summary of Changes

<!-- Briefly describe what this PR implements or fixes -->
<!-- 2-3 sentences maximum -->

---

## Commit Sequence Checklist

*Verify commits follow the prescribed order before merging.*

- [ ] `docs:` Spec file committed first (if applicable)
- [ ] `test:` Failing tests committed before implementation (RED state)
- [ ] `feat:` or `fix:` Implementation committed after tests (GREEN state)
- [ ] `refactor:` or `chore:` Cleanup commits (if applicable)
- [ ] All tests pass locally:
  - [ ] `npm test` (frontend/backend) or `make test` (all)
  - [ ] `uv run pytest tests/ -v` (orchestrator only) or `make test`
- [ ] Coverage thresholds met (if applicable):
  - [ ] Frontend: ≥60%
  - [ ] Backend: ≥70%
  - [ ] Orchestrator: ≥70%

---

## Privacy-by-Design Checklist

*No exceptions — verify all items before requesting review.*

- [ ] No email stored in plaintext in any new code path
- [ ] No profile content persisted beyond function scope
- [ ] Logs contain only `requestId` or `jobId`, never PII (email, nickname, token)
- [ ] No new environment variables store secrets directly (use Key Vault reference)
- [ ] `.env.example` updated if new env vars added
- [ ] No hardcoded production URLs, real secrets, IPs, or local machine-specific paths in committed code

---

## Testing Summary

<!-- Describe what was tested and what was not, if intentional -->

**What was tested:**
- [ ] Unit tests
- [ ] Integration tests
- [ ] E2E tests (Playwright)
- [ ] Manual testing

**What was not tested (if any) and why:**
<!-- If intentionally skipping test coverage for this PR, document why -->

**Tested in environment:**
- [ ] Local (docker-compose / dev servers)
- [ ] CI pipeline

---

## CI Status Reminder

<!-- DO NOT MERGE until CI is green -->

- [ ] All GitHub Actions jobs pass (frontend, backend, orchestrator)
- [ ] No lint errors
- [ ] No TypeScript errors
- [ ] No test failures
- [ ] Coverage thresholds enforced

If CI is red, please run locally and troubleshoot:
```bash
make lint
make test
make build
```

---

## Breaking Changes

<!-- Any changes to the canonical data model, API contract, or flows from constitution.md? -->

- [ ] No breaking changes
- [ ] YES — breaking change(s):
  - Describe: ...
  - ADR reference: [ADR-XXX] (if applicable)
  - Migration plan: ...

---

## Additional Notes

<!-- Optional: any caveats, known limitations, or future work -->

---

## Reviewer Checklist

*For reviewer (maintainer) use only.*

- [ ] Spec file present and coherent with implementation (if applicable)
- [ ] Commits follow conventional commit format
- [ ] Commit sequence: spec → test (RED) → impl (GREEN) → refactor
- [ ] Privacy-by-Design checklist verified (spot check logs, env vars)
- [ ] No console.log, print, or debug statements left in code
- [ ] `AGENTS.md` updated if this PR closes a phase boundary
- [ ] No unrelated formatting or cosmetic changes mixed with logic changes
- [ ] All acceptance criteria from User Story satisfied

---

*Generated from `.github/PULL_REQUEST_TEMPLATE.md` — SDIA P0 Bootstrap*
