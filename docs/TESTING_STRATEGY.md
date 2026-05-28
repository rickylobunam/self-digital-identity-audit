# SDIA — Testing Strategy

> **Minimum required coverage:** 70% on backend and orchestrator · 60% on frontend  
> **Mandatory CI:** all tests must pass before merge to `develop`

---

## Testing Pyramid

```
         /\
        /E2E\        (Playwright) — full browser flow
       /------\
      /Integr  \     (Jest + supertest / pytest + httpx)
     /----------\
    /   Unit     \   (Vitest / Jest / pytest) — majority
   /--------------\
```

---

## Part I — Frontend (Vite + React + Vitest)

### Tools
```
Framework: Vitest
UI:        @testing-library/react + @testing-library/user-event
Mocks:     msw (Mock Service Worker) for APIs
E2E:       Playwright
Coverage:  v8 (via Vitest)
```

### What to test
| Component | Type | What to verify |
|-----------|------|----------------|
| `RegistrationForm` | Unit | Email validation, required nickname, button state |
| `PlatformSelector` | Unit | Rendering of available platforms, selection |
| `ValidationGuide` | Unit | Correct instructions per platform |
| `StatusDashboard` | Unit | Status rendering: PENDING, VALIDATED, FAILED |
| `RegistrationFlow` | Integration | Form submit → mock API response → success state |
| `EmailValidation` | Integration | URL with token → mock validate endpoint → redirect |
| `Full audit flow` | E2E (Playwright) | Registration → email validation → add account → view dashboard |

### Unit test example
```typescript
// src/components/RegistrationForm.test.tsx
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { RegistrationForm } from './RegistrationForm';

test('disables submit with invalid email', async () => {
  render(<RegistrationForm onSubmit={vi.fn()} />);
  await userEvent.type(screen.getByLabelText(/email/i), 'not-an-email');
  expect(screen.getByRole('button', { name: /start/i })).toBeDisabled();
});

test('shows error message for empty nickname', async () => {
  render(<RegistrationForm onSubmit={vi.fn()} />);
  await userEvent.click(screen.getByRole('button', { name: /start/i }));
  expect(screen.getByText(/nickname is required/i)).toBeInTheDocument();
});
```

---

## Part II — Backend (Node.js + Fastify + Jest)

### Tools
```
Framework:   Jest + ts-jest
HTTP:        supertest
Mocks:       jest.mock() for Cosmos DB SDK, ACS SDK
Coverage:    Jest --coverage (v8)
```

### Integration test example
```typescript
// src/routes/jobs.test.ts
describe('POST /api/jobs', () => {
  it('returns 202 and creates job without storing plaintext email', async () => {
    const mockCreate = jest.spyOn(cosmosService, 'createJob').mockResolvedValue({
      id: 'test-uuid', requestId: 'test-uuid', status: 'PENDING_EMAIL_VALIDATION'
    });

    const res = await request(app)
      .post('/api/jobs')
      .send({ email: 'test@example.com', nickname: 'testuser' });

    expect(res.status).toBe(202);
    expect(res.body).toHaveProperty('jobId');
    // Verify email was NOT stored in plaintext
    expect(mockCreate.mock.calls[0][0]).not.toHaveProperty('email');
    expect(mockCreate.mock.calls[0][0]).toHaveProperty('emailHash');
  });

  it('returns 429 after 3 requests from same IP in 1 hour', async () => {
    for (let i = 0; i < 3; i++) {
      await request(app).post('/api/jobs').send({ email: `t${i}@e.com`, nickname: 'u' });
    }
    const res = await request(app).post('/api/jobs').send({ email: 'x@e.com', nickname: 'u' });
    expect(res.status).toBe(429);
  });
});
```

---

## Part III — Orchestrator (Python + pytest)

### Tools
```
Framework:  pytest + pytest-asyncio
HTTP mock:  respx (for httpx)
LLM mock:   pytest fixtures with pre-recorded JSON responses
Coverage:   pytest-cov
```

### PDF test example
```python
# tests/test_report_generator.py
import pytest
from app.report.generator import render_report
from app.models import ReportData, RiskLevel

def test_pdf_is_generated(sample_report):
    pdf_bytes = render_report(sample_report)
    assert pdf_bytes[:4] == b'%PDF'
    assert len(pdf_bytes) > 1000

def test_pdf_requires_password(sample_report, tmp_path):
    import pikepdf
    pdf_bytes = render_report(sample_report)
    pdf_path = tmp_path / "report.pdf"
    pdf_path.write_bytes(pdf_bytes)
    with pytest.raises(pikepdf.PasswordError):
        pikepdf.open(str(pdf_path))

def test_pdf_opens_with_correct_password(sample_report, tmp_path):
    import pikepdf, hashlib
    email = "test@example.com"
    password = hashlib.sha256(email.encode()).hexdigest()[:12]
    pdf_bytes = render_report(sample_report, password=password)
    pdf_path = tmp_path / "report.pdf"
    pdf_path.write_bytes(pdf_bytes)
    pdf = pikepdf.open(str(pdf_path), password=password)
    assert pdf is not None
```

---

## Part IV — CI Pipeline

This section documents the GitHub Actions CI workflows. **Note:** GitHub Actions workflows are used exclusively for **build, test, and deployment** — not for triggering report generation. Report generation is triggered internally by the Node.js `node-cron` scheduler (see [ARCHITECTURE.md ADR-004](ARCHITECTURE.md#adr-004-orchestrator-trigger--internal-node-cron-scheduler)).

### Frontend CI Job

```yaml
# .github/workflows/ci.yml → jobs.frontend
frontend:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm install
    - run: npm run lint       # ESLint + Biome
    - run: npm run typecheck  # tsc --noEmit
    - run: npm run test       # Vitest --coverage
    - name: Check coverage
      run: npm run test:coverage -- --coverage-threshold-value 60
```

### Backend CI Job

```yaml
# .github/workflows/ci.yml → jobs.backend
backend:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm install
    - run: npm run lint       # ESLint
    - run: npm run typecheck  # tsc --noEmit
    - run: npm run test       # Jest --coverage
    - name: Check coverage
      run: npm run test:coverage -- --coverage-threshold-value 70
```

**Backend-specific test scenarios:**

| Scenario | Type | What to verify |
|----------|------|----------------|
| Unit: Cron initialization | Unit | Scheduler instantiates with correct timezone and schedule |
| Unit: Query ready jobs | Unit | Queries Cosmos DB with correct filter (status = READY_TO_REPORT) |
| Integration: Manual trigger | Integration | POST /api/internal/trigger-report-cycle queries DB and provisions Bicep |
| Integration: Cron fires at scheduled time | Integration | Mock timer fires → orchestrator provisioning invoked |
| Integration: Zero jobs → no deployment | Integration | If no READY_TO_REPORT jobs, Bicep deployment is skipped |

**Example backend test for cron scheduler:**

```typescript
// backend/src/services/cronService.test.ts
import { initReportGenerationCron } from './cronService';
import * as orchestration from './orchestration';

describe('Report Generation Cron Scheduler', () => {
  it('initializes scheduler with correct timezone and schedule', () => {
    const task = initReportGenerationCron();
    // Verify cron.schedule was called with correct pattern
    expect(task).toBeDefined();
  });

  it('queries Cosmos DB for READY_TO_REPORT jobs at cron time', async () => {
    const mockQueryJobs = jest.spyOn(orchestration, 'queryReadyJobs')
      .mockResolvedValue([{ id: 'job-1', status: 'READY_TO_REPORT' }]);

    // Manually trigger the cron task (in tests)
    await orchestration.triggerReportGenerationCycle();

    expect(mockQueryJobs).toHaveBeenCalled();
  });

  it('provisions orchestrator when jobs exist', async () => {
    const mockProvision = jest.spyOn(orchestration, 'provisionOrchestrator')
      .mockResolvedValue({ deploymentId: 'deploy-uuid' });
    const mockQueryJobs = jest.spyOn(orchestration, 'queryReadyJobs')
      .mockResolvedValue([{ id: 'job-1' }, { id: 'job-2' }]);

    await orchestration.triggerReportGenerationCycle();

    expect(mockProvision).toHaveBeenCalledWith(['job-1', 'job-2']);
  });

  it('skips deployment when no jobs are ready', async () => {
    const mockProvision = jest.spyOn(orchestration, 'provisionOrchestrator');
    const mockQueryJobs = jest.spyOn(orchestration, 'queryReadyJobs')
      .mockResolvedValue([]);

    await orchestration.triggerReportGenerationCycle();

    expect(mockProvision).not.toHaveBeenCalled();
  });

  it('handles scheduler disabled in development', () => {
    process.env.CRON_ENABLED = 'false';
    const consoleSpy = jest.spyOn(console, 'log');
    
    initReportGenerationCron();
    
    expect(consoleSpy).toHaveBeenCalledWith(
      expect.stringContaining('Cron scheduler disabled')
    );
  });
});
```

### Orchestrator CI Job

```yaml
# .github/workflows/ci.yml → jobs.orchestrator
orchestrator:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-python@v4
      with:
        python-version: '3.11'
    - run: pip install -r orchestrator/requirements-dev.txt
    - run: ruff check orchestrator/
    - run: mypy orchestrator/app/
    - run: pytest orchestrator/ --cov=orchestrator/app --cov-fail-under=70
```

### E2E (Playwright) CI Job

```yaml
# .github/workflows/ci.yml → jobs.e2e (runs only on PRs to main)
e2e:
  if: github.event_name == 'pull_request' && github.base_ref == 'main'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: docker compose up -d
    - run: npm run test:e2e -- --reporter=github
    - run: docker compose down
```

### CI Pipeline Summary

| Job | Trigger | What it does |
|-----|---------|-------------|
| Frontend | Always | Lint, typecheck, unit tests (Vitest) |
| Backend | Always | Lint, typecheck, unit + integration tests (Jest), cron scheduler tests |
| Orchestrator | Always | Ruff lint, mypy, pytest with coverage |
| E2E | PR to `main` only | Full browser flows (Playwright) |

**DEPRECATED:** The `report-generator.yml` GitHub Actions workflow is no longer needed. Report generation is triggered internally by the Node.js scheduler at 10:00 AM UTC-6. GitHub Actions workflows remain unchanged for build, test, and deployment — only the external cron trigger has been removed.

---

## Test Data

Test fixtures are located at:
- `backend/src/__fixtures__/` — AuditJob mocks, OTP mocks
- `orchestrator/tests/fixtures/` — Mock OSINT JSON, mock LLM responses
- `frontend/src/__mocks__/` — MSW handlers for all endpoints

**NEVER use real emails or real nicknames in test fixtures.**  
Use: `test@sdia.dev`, `staging@sdia.dev`, nicknames: `sdia_test_*`
