# SDIA — Developer Guide

> **Required prior reading:** [constitution.md](../.specify/memory/constitution.md) and [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 1. Prerequisites

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| Node.js | 20 LTS | Frontend + Backend |
| Python | 3.11 | Orchestrator |
| Docker + Docker Compose | 24+ | Local environment |
| Azure CLI | 2.57+ | Azure deployment |
| GitHub CLI | 2.45+ | CI/CD setup |
| Git | 2.40+ | Version control |

---

## 2. Initial Setup

```bash
# 1. Clone
git clone https://github.com/[org]/self-digital-identity-audit.git
cd self-digital-identity-audit

# 2. Configure local environment variables
cp .env.example .env
# EDIT .env — see section 4 of this document

# 3. Start full local environment
docker compose up -d
# Frontend:     http://localhost:5173
# Backend API:  http://localhost:3000
# Cosmos DB:    http://localhost:8081 (Cosmos DB Emulator)
# Emails:       http://localhost:8025 (Mailhog UI)

# 4. Verify everything is running
curl http://localhost:3000/health
# → { "status": "ok", "version": "0.1.0" }
```

---

## 3. Development by Component

### 3.1 Frontend (Vite + React)

```bash
cd frontend
npm install
npm run dev          # Dev server at localhost:5173
npm run test         # Vitest
npm run typecheck    # tsc --noEmit
npm run lint         # ESLint + Biome
npm run build        # Build for GitHub Pages → dist/
```

**Frontend environment variables (`frontend/.env.local`):**
```bash
VITE_API_URL=http://localhost:3000
```

### 3.2 Backend (Node.js + Fastify)

```bash
cd backend
npm install
npm run dev          # tsx watch → hot reload
npm run test         # Jest
npm run test:watch   # Jest in watch mode
npm run build        # tsc → dist/
```

**Note on Cosmos DB Emulator:** The local emulator uses a self-signed certificate. For development, set:
```bash
NODE_TLS_REJECT_UNAUTHORIZED=0  # LOCAL DEVELOPMENT ONLY
```

### 3.3 Orchestrator (Python FastAPI)

```bash
cd orchestrator
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
pip install -r requirements-dev.txt

uvicorn app.main:app --reload  # Dev server at localhost:8000
pytest                          # All tests
pytest tests/test_report.py -v  # Specific tests
mypy app/                        # Type checking
ruff check .                     # Linting
```

---

## 4. Local Development — Running the Cron Scheduler

The report generation cycle is triggered by an **internal `node-cron` scheduler** running inside the Node.js API container. This section explains how to configure and test it locally.

### 4.1 Understanding the Scheduler

The scheduler:
- Runs within the always-on Node.js API (`src/services/cronService.ts`)
- Fires daily at 10:00 AM UTC-6 (America/Mexico_City timezone)
- Queries Cosmos DB for jobs with status `READY_TO_REPORT`
- If jobs exist, provisions the Python orchestrator via Bicep IaC
- Requires **no external GitHub Actions workflow**

### 4.2 Environment Variables

Configure these in your `.env` file:

```bash
# Cron scheduler configuration
CRON_ENABLED=true                          # Set to false to disable scheduler in dev
CRON_TIMEZONE=America/Mexico_City
CRON_SCHEDULE=0 10 * * *                   # Cron expression: 10:00 AM daily
CRON_LOG_LEVEL=debug                       # Set to 'info' or 'debug' for troubleshooting
```

**Cron expression reference:**
- `0 10 * * *` = 10:00 AM every day
- `*/5 * * * *` = every 5 minutes (useful for testing)
- `0 0 * * *` = midnight (UTC base time, adjusted by timezone)

### 4.3 Manual Trigger for Testing

To manually trigger the report generation cycle without waiting for the cron schedule:

**Via npm script:**
```bash
cd backend
npm run test:cron
```

**Via HTTP API (requires valid sessionToken):**
```bash
# Trigger the cron cycle on demand
curl -X POST http://localhost:3000/api/internal/trigger-report-cycle \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_INTERNAL_TOKEN"
```

**Response:**
```json
{
  "message": "Report generation cycle triggered",
  "jobsFound": 3,
  "provisioned": true,
  "bicepDeploymentId": "uuid-xxx"
}
```

### 4.4 Development vs. Production Configuration

| Setting | Development | Production |
|---------|-------------|-----------|
| `CRON_ENABLED` | `false` (manual trigger only) | `true` |
| `CRON_SCHEDULE` | `*/5 * * * *` (every 5 min) | `0 10 * * *` (10 AM daily) |
| `CRON_LOG_LEVEL` | `debug` | `info` |
| Manual endpoint | Enabled for testing | Disabled (internal only) |

**To disable the scheduler in development (recommended for local testing):**
```bash
# In .env.local or .env
CRON_ENABLED=false
```

Then manually trigger via the curl command above or npm script.

### 4.5 Docker Compose Notes

The scheduler runs inside the backend container. To verify it's active:

```bash
# View scheduler logs
docker compose logs backend | grep cron

# Expected output (if enabled):
# backend | ⏰ Cron scheduler initialized: America/Mexico_City, 0 10 * * *
# backend | 🎯 Next execution: 2026-05-28T10:00:00-06:00
```

If the scheduler is disabled (`CRON_ENABLED=false`), you'll see:
```
backend | ⏰ Cron scheduler disabled (manual trigger only)
```

### 4.6 Scheduler Implementation Reference

The scheduler is initialized in `src/services/cronService.ts`:

```typescript
// backend/src/services/cronService.ts
import cron from 'node-cron';
import { queryReadyJobs, provisionOrchestrator } from './orchestration';

export function initReportGenerationCron() {
  if (process.env.CRON_ENABLED === 'false') {
    console.log('⏰ Cron scheduler disabled (manual trigger only)');
    return;
  }

  const timezone = process.env.CRON_TIMEZONE || 'America/Mexico_City';
  const schedule = process.env.CRON_SCHEDULE || '0 10 * * *';

  const task = cron.schedule(schedule, async () => {
    console.log('🎯 Cron fired: querying READY_TO_REPORT jobs...');
    const jobs = await queryReadyJobs();
    if (jobs.length > 0) {
      console.log(`✅ Found ${jobs.length} jobs. Provisioning orchestrator...`);
      await provisionOrchestrator(jobs.map(j => j.id));
    } else {
      console.log('ℹ️  No jobs ready. Skipping deployment.');
    }
  }, { timezone });

  console.log(`⏰ Cron scheduler initialized: ${timezone}, ${schedule}`);
  return task;
}
```

---

## 5. Adding a New Platform (e.g., Twitch)

**Step 1: Backend — Verifier**
```typescript
// backend/src/services/platformVerifier/twitch.ts
import { httpGet } from '../http';
import type { VerificationResult } from './types';

export async function verifyTwitch(
  nickname: string,
  token: string
): Promise<VerificationResult> {
  const url = `https://www.twitch.tv/${nickname}`;
  const html = await httpGet(url, { timeout: 10_000 });
  const found = html.includes(token);
  return { platform: 'twitch', nickname, found };
}
```

**Step 2: Backend — Register in the map**
```typescript
// backend/src/services/platformVerifier/index.ts
import { verifyTwitch } from './twitch';
export const verifiers = {
  // ... existing
  twitch: verifyTwitch,
};
```

**Step 3: Orchestrator — OSINT Extractor**
```python
# orchestrator/app/osint/twitch.py
import httpx
from app.models import OsintFindings

async def extract_twitch(nickname: str) -> OsintFindings:
    url = f"https://www.twitch.tv/{nickname}"
    async with httpx.AsyncClient(timeout=15.0) as client:
        r = await client.get(url, headers={
            "User-Agent": "SDIA-Educational-Bot/0.1 (+https://github.com/[org]/sdia)"
        })
    # Parse bio, visible follower count, etc.
    ...
```

**Step 4: Update shared types**
```typescript
// Add 'twitch' to PlatformId in constitution.md and types/audit.ts
type PlatformId = ... | 'twitch';
```

**Step 5: Frontend — Validation guide**
```typescript
// frontend/src/components/ValidationGuide/guides.ts
export const validationGuides: Record<PlatformId, ValidationGuide> = {
  // ...
  twitch: {
    fieldName: 'Channel description',
    steps: [
      'Go to twitch.tv and click your avatar → "Channel"',
      'Click "Edit channel"',
      'In "Description", add the code at the beginning',
      'Save and come back here',
    ],
    revertInstructions: 'You can now remove the code from your description.',
  },
};
```

---

## 6. Azure Deployment

### Initial setup (one-time per environment)

```bash
# Login
az login
az account set --subscription "[your-subscription-id]"

# Create resource group
az group create --name rg-sdia-dev --location mexicocentral

# Deploy base infrastructure
az deployment group create \
  --resource-group rg-sdia-dev \
  --template-file infra/main.bicep \
  --parameters infra/parameters/dev.bicepparam

# Configure OIDC for GitHub Actions (no long-lived secrets)
bash scripts/setup-github-oidc.sh --env dev
```

---

## 7. Full PR Workflow

```bash
# 1. Sync with upstream
git checkout develop && git pull upstream develop

# 2. Create branch
git checkout -b feat/us-003-instagram-validation

# 3. Develop + test
# ... write code ...
npm test  # or pytest

# 4. Conventional commit
git add .
git commit -m "feat(backend): add Instagram bio verification endpoint"
git commit -m "test(backend): add Instagram verifier unit tests"

# 5. Push and PR
git push origin feat/us-003-instagram-validation
gh pr create --title "feat(backend): Instagram validation" --body "Closes #12" --base develop

# 6. CI passes → review → merge
```

---

## 8. Troubleshooting

### Error: Cosmos DB connection refused locally
```bash
# Verify the emulator is running
docker ps | grep cosmos
# If not: docker compose up cosmos-emulator
```

### Error: WeasyPrint cannot render PDF
```bash
# Install system dependencies (already in Dockerfile)
# Locally on macOS:
brew install pango cairo gdk-pixbuf libffi
pip install WeasyPrint
```

### Error: Azure OpenAI 429 (rate limit)
- In development, use mock/fixtures instead of the real API
- See `orchestrator/tests/fixtures/openai_response.json`
- Set `USE_LLM_MOCK=true` in `.env` for tests

### Validation email not arriving in local development
```bash
# Use Mailhog (already in docker-compose) to capture emails
# View emails at http://localhost:8025
```
