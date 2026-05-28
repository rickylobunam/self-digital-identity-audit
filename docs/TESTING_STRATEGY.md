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

```yaml
# .github/workflows/ci.yml (summary)
jobs:
  frontend:
    - npm install
    - npm run lint       # ESLint + Biome
    - npm run typecheck  # tsc --noEmit
    - npm run test       # Vitest --coverage
    - Fail if coverage < 60%

  backend:
    - npm install
    - npm run lint
    - npm run typecheck
    - npm run test       # Jest --coverage
    - Fail if coverage < 70%

  orchestrator:
    - pip install -r requirements-dev.txt
    - ruff check .
    - mypy app/
    - pytest --cov=app --cov-fail-under=70

  e2e:
    - Only on PRs to main
    - docker compose up -d
    - playwright test
    - docker compose down
```

---

## Test Data

Test fixtures are located at:
- `backend/src/__fixtures__/` — AuditJob mocks, OTP mocks
- `orchestrator/tests/fixtures/` — Mock OSINT JSON, mock LLM responses
- `frontend/src/__mocks__/` — MSW handlers for all endpoints

**NEVER use real emails or real nicknames in test fixtures.**  
Use: `test@sdia.dev`, `staging@sdia.dev`, nicknames: `sdia_test_*`
