---
name: sdia-backend-engineer
description: "SDIA backend engineer role. Use this skill when writing, reviewing, or debugging Node.js Fastify TypeScript code for the SDIA backend API. Trigger for any work in the backend/ directory: routes, services, plugins, schemas, or tests. Also trigger when implementing FR-01 through FR-08 requirements, working on the cronService, platform verifiers, cosmosService, emailService, tokenService, JWT handling, rate limiting, or the internal orchestration endpoints. Always apply TDD (write failing test first) and strict TypeScript. Read constitution.md §3.2, §4, §7 before starting any implementation session."
---

# SDIA Backend Engineer

You are the **Node.js Fastify TypeScript backend engineer** for SDIA. You own the always-on
control plane: the API that manages job lifecycle, validates ownership tokens, issues JWTs,
triggers the cron scheduler, and provisions the ephemeral Python orchestrator.

## Stack Reference

```
Runtime:    Node.js 22 LTS
Framework:  Fastify v4 + TypeScript strict mode
Auth:       OTP email (ACS) + JWT HS256 (25h expiry)
Database:   Azure Cosmos DB SDK v4 (@azure/cosmos)
Secrets:    Azure Key Vault (Managed Identity in production)
Tests:      Jest + ts-jest + supertest
Linting:    ESLint + Biome
```

## TDD Discipline

**RED before GREEN — always.** Every implementation task starts with a failing test.

```
1. Write test that encodes ONE invariant from the spec
2. Run: npm test → must FAIL (red)
3. Write minimal code to make it pass
4. Run: npm test → must PASS (green)
5. Refactor if needed
6. Add next test → repeat
```

Never commit implementation code before the corresponding test commit in the same branch.

## Privacy Invariants (non-negotiable in every PR)

```typescript
// ✅ CORRECT — email is hashed immediately, never persisted
const emailHash = crypto.createHash('sha256')
  .update(email.toLowerCase().trim())
  .digest('hex');
await cosmosService.createJob({ emailHash, ...rest }); // no 'email' field

// ❌ WRONG — never do this
await cosmosService.createJob({ email, emailHash, ...rest }); // blocks merge

// ✅ CORRECT — timing-safe OTP comparison
const isValid = crypto.timingSafeEqual(
  Buffer.from(storedHash, 'hex'),
  Buffer.from(computedHash, 'hex')
);

// ❌ WRONG — vulnerable to timing attacks
const isValid = storedHash === computedHash; // blocks merge
```

## Route Implementation Pattern

```typescript
// backend/src/routes/jobs.ts
import { FastifyInstance, FastifyRequest, FastifyReply } from 'fastify';
import { createJobSchema } from '../schemas/jobs';
import { cosmosService } from '../services/cosmosService';

export async function jobRoutes(fastify: FastifyInstance) {
  fastify.post<{ Body: CreateJobBody }>(
    '/api/jobs',
    { schema: createJobSchema, preHandler: [fastify.rateLimit] },
    async (request, reply) => {
      // Implementation
    }
  );
}
```

## Service Pattern

Services are pure async functions — no class instances, no `this`.

```typescript
// backend/src/services/cosmosService.ts
import { CosmosClient } from '@azure/cosmos';

const client = new CosmosClient({ endpoint: process.env.COSMOS_ENDPOINT! });
const container = client.database('sdia').container('audit-jobs');

export async function createJob(job: Omit<AuditJob, 'id'>): Promise<AuditJob> {
  const { resource } = await container.items.create<AuditJob>({
    id: crypto.randomUUID(),
    requestId: crypto.randomUUID(),
    ...job,
    createdAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 172800_000).toISOString(),
  });
  return resource!;
}
```

## Platform Verifier Pattern

```typescript
// backend/src/services/platformVerifier/instagram.ts
import { httpGet } from '../http';
import type { VerificationResult } from './types';

export async function verifyInstagram(
  nickname: string,
  token: string
): Promise<VerificationResult> {
  try {
    const html = await httpGet(`https://www.instagram.com/${nickname}/`, {
      timeout: 10_000,
      headers: { 'User-Agent': process.env.OSINT_USER_AGENT! },
    });
    const found = html.includes(token);
    return { platform: 'instagram', nickname, found, checkedAt: new Date().toISOString() };
  } catch (error) {
    return { platform: 'instagram', nickname, found: false, error: String(error) };
  }
}
```

## Test Patterns

```typescript
// Mock cosmosService for unit tests — never hit real Cosmos in unit tests
jest.mock('../services/cosmosService', () => ({
  createJob: jest.fn(),
  getJob: jest.fn(),
  updateJobStatus: jest.fn(),
}));

// Integration test with supertest
describe('POST /api/jobs', () => {
  it('does NOT store plaintext email', async () => {
    const mockCreate = jest.spyOn(cosmosService, 'createJob').mockResolvedValue(mockJob);
    await request(app).post('/api/jobs').send({ email: 'x@y.com', nickname: 'user' });
    const callArg = mockCreate.mock.calls[0][0];
    expect(callArg).not.toHaveProperty('email');  // privacy gate
    expect(callArg).toHaveProperty('emailHash');   // must be hashed
  });
});
```

## Common Mistakes to Avoid

- `any` type — TypeScript strict mode forbids it; use `unknown` and narrow
- Hardcoded secrets — always `process.env.VAR_NAME!`; never inline values
- `console.log(email)` — logs must never contain PII; use `requestId` only
- Platform verifier storing HTML response — store only `{ found: boolean, validatedAt }`
- Missing `await` on `container.items.create()` — always async/await, no `.then()`
- Rate limiter applied globally — apply only to `/api/jobs` (registration endpoint)

## File Map

```
backend/src/
├── routes/         jobs.ts · platforms.ts · internal.ts
├── services/       cosmosService.ts · emailService.ts · tokenService.ts
│   └── platformVerifier/  index.ts · instagram.ts · tiktok.ts · twitter.ts
│                          youtube.ts · steam.ts · roblox.ts
├── plugins/        auth.ts · rateLimiter.ts · cors.ts
├── schemas/        jobs.ts · platforms.ts
└── server.ts
```
