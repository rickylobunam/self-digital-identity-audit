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

## 4. Adding a New Platform (e.g., Twitch)

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

## 5. Azure Deployment

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

## 6. Full PR Workflow

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

## 7. Troubleshooting

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
