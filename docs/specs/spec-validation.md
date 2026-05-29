# Specification: Validation Module

> **SDD Artifact:** `spec-validation.md`  
> **Module:** Registration, email validation, and platform ownership verification  
> **SDLC Phase:** F1 — Analysis and Specification

---

## 1. Module Description

The Validation module manages the complete lifecycle of an `AuditJob` from creation to ready-for-report. It is the core of SDIA's consent and account ownership proof flow.

---

## 2. Inputs / Outputs

### Endpoint: `POST /api/jobs`
**Input:**
```typescript
{
  email: string;    // RFC 5322 valid, max 254 chars
  nickname: string; // 1-50 chars, alphanumeric + hyphens/dots/underscores
}
```
**Output (202 Accepted):**
```typescript
{ jobId: string; message: string; }
```
**Errors:** 400 (validation), 429 (rate limit), 500 (internal error)

### Endpoint: `GET /api/jobs/:id/validate-email`
**Query:** `?token=<64-char-hex>`  
**Output (200):**
```typescript
{
  sessionToken: string;  // JWT, exp 25h
  jobId: string;
  redirectUrl: string;   // Mini-app URL with sessionToken
}
```
**Errors:** 400 (invalid token), 410 (expired), 409 (already used)

### Endpoint: `POST /api/jobs/:id/platforms/:platform`
**Headers:** `Authorization: Bearer <sessionToken>`  
**Input:**
```typescript
{ nickname: string; }
```
**Output (201):**
```typescript
{
  validationToken: string;    // "sdia-" + 6 BIP39 words or 8-char alphanumeric
  instructions: ValidationStep[];
  revertInstructions: string;
}
```

### Endpoint: `POST /api/jobs/:id/platforms/:platform/verify`
**Headers:** `Authorization: Bearer <sessionToken>`  
**Output (200):**
```typescript
{
  status: 'VALIDATED' | 'FAILED';
  message: string;
  hint?: string;  // If FAILED, suggested action
}
```

### Endpoint: `PUT /api/jobs/:id/ready`
**Headers:** `Authorization: Bearer <sessionToken>`  
**Output (200):**
```typescript
{ message: string; estimatedReportTime: string; }
```

---

## 3. Business Rules

### BR-VAL-01: Email Hashing
- The email is NEVER persisted in plaintext
- Calculate `emailHash = SHA-256(email.toLowerCase().trim())`
- Only `emailHash` is stored in Cosmos DB
- Email plaintext lives only in memory during the creation request

### BR-VAL-02: OTP Token
- `token = crypto.randomBytes(32).toString('hex')` → 64 hex chars
- Only `tokenHash = SHA-256(token)` is stored in Cosmos DB
- Comparison: `crypto.timingSafeEqual(SHA-256(incoming), storedHash)`
- TTL: 1 hour from issuance
- Single-use: marked `used: true` immediately upon validation

### BR-VAL-03: Platform Validation Token
- Format: `sdia-` + `crypto.randomBytes(3).toString('hex')` → e.g., "sdia-4f2a8b"
- Unique per (jobId, platform)
- Does not expire during the process (only expires with the job at 48h)

### BR-VAL-04: Validation Window
- User has exactly 24 hours from `EMAIL_VALIDATED` to complete platform validation
- After 24h: job moves to `EXPIRED`
- EXCEPTION: if ≥1 platform is VALIDATED at expiry time, system auto-moves to `READY_TO_REPORT`

### BR-VAL-05: Platform Verification
- Rate limit per job: max 10 verification calls per hour (prevents scraping abuse)
- HTTP verification timeout: 10 seconds
- If platform returns 429/503: respond `{ status: 'FAILED', hint: 'Platform not responding. Try again in a few minutes.' }`
- If profile is private: detect signal and show guide to temporarily make it public

### BR-VAL-06: Verification Idempotency
- Multiple verification calls with same token and job do NOT create duplicate entries
- If already VALIDATED, return the same result without re-verifying

---

## 4. Input Validations

| Field | Validation |
|-------|-----------|
| `email` | RFC 5322, max 254 chars, no mailing lists (@group.*) |
| `nickname` | `^[a-zA-Z0-9_\.\-]{1,50}$` |
| `platform` | Enum: instagram, tiktok, x_twitter, youtube, steam, roblox |
| `platform.nickname` | Platform-specific format validation (see FEATURES.md F-03 table) |
| `sessionToken` | Valid JWT, not expired, sub = jobId from path param |

---

## 5. Acceptance Criteria

```gherkin
FEATURE: Request registration
  ✅ Job created with status PENDING_EMAIL_VALIDATION in < 2s
  ✅ Email sent in < 30s
  ✅ emailHash stored, not email plaintext
  ✅ 429 after 3 requests/hour/IP

FEATURE: Email validation
  ✅ Valid + unused + unexpired token → 200 + sessionToken + status EMAIL_VALIDATED
  ✅ Expired token → 410
  ✅ Already used token → 409
  ✅ Incorrect token → 401 (without revealing whether it exists)

FEATURE: Platform verification
  ✅ Token in bio → VALIDATED, revert notification
  ✅ Token not in bio → FAILED with hint
  ✅ Profile not found → FAILED with hint "Verify the nickname is correct"
  ✅ Platform down → FAILED with hint "Try again later"

FEATURE: Data protection
  ✅ No endpoint returns the user's email
  ✅ Logs contain no email, nicknames, or profile content — only requestId
  ✅ 48h TTL verifiable in Cosmos DB
```
