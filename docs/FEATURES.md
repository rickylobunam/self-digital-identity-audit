# SDIA — Features

> **Reference version:** v0.1 (MVP Hackathon) · v0.2 · v1.0  
> Classification: `[MVP]` = v0.1 · `[v0.2]` = second iteration · `[v1.0]` = stable release

---

## F-01 — Report Request Registration `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-01 |
| **Name** | Audit request registration |
| **Actor** | Minor (family accompaniment recommended) |
| **Description** | The user enters their email and a primary nickname in the public GitHub Pages form. The system creates an `AuditJob` in Cosmos DB and sends a validation email. |
| **Exit criteria** | Job created with `status: PENDING_EMAIL_VALIDATION`, email sent in <30s |

---

## F-02 — Email Ownership Validation `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-02 |
| **Description** | The sent email contains a unique single-use OTP link (TTL 1h) directing to the audit mini-app. Clicking it validates the token and updates the job to `EMAIL_VALIDATED`. |
| **Security** | Token `crypto.randomBytes(32)`, invalidated after use, 1h TTL |
| **Fallback** | "Resend email" button available up to 3 times |

---

## F-03 — Platform Registration and Validation `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-03 |
| **Description** | The user adds social/gaming accounts one by one. For each account, SDIA generates a unique `validationToken` (6-word passphrase or alphanumeric code), displays a platform-specific step-by-step guide to place the token in their public profile, then automatically verifies the token is visible. |
| **MVP Platforms** | Instagram, TikTok, X/Twitter, YouTube, Steam, Roblox |
| **Verification** | Public GET to the profile → search for token in bio/description text |
| **Post-validation** | Immediate notification: "You can now revert your bio to normal" |
| **Window** | 24h from `EMAIL_VALIDATED` to complete all validations |

### Validation Strategy by Platform (MVP)

| Platform | Validation field | Public URL | Method |
|----------|-----------------|-----------|--------|
| **Instagram** | Profile bio/description | `instagram.com/{nickname}` | HTML scraping of meta description |
| **TikTok** | Profile bio | `tiktok.com/@{nickname}` | HTML scraping |
| **X / Twitter** | Profile bio | `twitter.com/{nickname}` | HTML scraping (nitter.net as fallback) |
| **YouTube** | Channel description | `youtube.com/@{nickname}/about` | HTML scraping |
| **Steam** | Profile summary (public) | `steamcommunity.com/id/{nickname}` | HTML scraping |
| **Roblox** | Profile description | `roblox.com/users/search?keyword={nickname}` | Public JSON API |

---

## F-04 — Audit Status Dashboard `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-04 |
| **Description** | The mini-app shows real-time status for each registered platform (Pending / Validated / Failed) and the overall job status. Includes instructions and retry button for failed validations. |

---

## F-05 — PDF Report Generation `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-05 |
| **Description** | Daily batch process (10:00 AM UTC-6) that processes all jobs in `READY_TO_REPORT`. Per job: OSINT per platform → LLM analysis → HTML report → password-protected PDF. |
| **Infrastructure** | Ephemeral (Bicep on-demand deploy, destroyed post-run) |
| **Parallel flows** | Each job is processed in an independent flow |
| **PDF protection** | Password = first 12 characters of base62(SHA-256(email)) |
| **PDF permissions** | Read and print only. No text copying, no editing. |

---

## F-06 — Report Delivery by Email `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-06 |
| **Description** | Upon report completion, the system sends an email with: (1) the PDF password, (2) a direct SAS download URL (TTL 48h), and (3) a brief guide for reviewing the report with a trusted adult. |

---

## F-07 — Report: Risk Traffic Light `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-07 |
| **Description** | The report includes a visual traffic light (Green/Yellow/Red) based on the aggregated detected risk level. Each platform has its own individual traffic light. |

---

## F-08 — Report: Oversharing Score `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-08 |
| **Description** | Score from 1 to 10 measuring the level of personal information overexposure (location, school, routines, family). Includes accessible textual explanation for the minor and their parents. |

---

## F-09 — Report: Social Engineering Pedagogical Simulator `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-09 |
| **Description** | Educational section showing how a malicious actor could use the found public information to attempt contact with the minor. Includes an explicit disclaimer that this is a pedagogical exercise. Uses only evidence found during the audit. |

---

## F-10 — Report: Remediation Plan `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-10 |
| **Description** | Actionable checklist with platform-specific steps to reduce exposure: configure privacy settings, review followers, remove sensitive information, enable MFA. Written in a positive, educational tone. |

---

## F-11 — Automatic Expiry and Purge `[MVP]`

| Field | Detail |
|-------|--------|
| **ID** | F-11 |
| **Description** | If the user does not complete the process within 24h of email validation, the job moves to `EXPIRED`. Cosmos DB TTL guarantees complete deletion of all data at 48h from creation, without manual intervention. |

---

## F-12 — Offline Mode / Phi-3-mini Local `[v0.2]`

| Field | Detail |
|-------|--------|
| **ID** | F-12 |
| **Description** | Alternative to Azure OpenAI using Phi-3-mini running on Azure Container Apps (CPU Consumption, scale-to-zero). "No third-party" mode for users who prefer analysis to stay within their own infrastructure. |

---

## F-13 — Extended Platform Coverage `[v0.2]`

| Field | Detail |
|-------|--------|
| **ID** | F-13 |
| **Description** | Expand to: Discord, Twitch, Minecraft, Fortnite (Epic Games), BeReal, Snapchat (public profile). |

---

## F-14 — Age-Adapted Report Language `[v0.2]`

| Field | Detail |
|-------|--------|
| **ID** | F-14 |
| **Description** | The report adapts language and recommendations to the voluntarily indicated age range (8–10 years, 11–13 years, 14–17 years). |

---

## F-15 — Follow-up Audits `[v1.0]`

| Field | Detail |
|-------|--------|
| **ID** | F-15 |
| **Description** | Ability to repeat the audit with the same email in a new 24h cycle to verify whether remediation plan improvements were implemented. Compares metrics between audits. |

---

## F-16 — Educational Portal and School Resources `[v1.0]`

| Field | Detail |
|-------|--------|
| **ID** | F-16 |
| **Description** | Complementary educational site with downloadable resources for teachers, digital footprint workshops, and digital safety training modules. |

---

## F-17 — Data Breach Detection `[v0.2]`

| Field | Detail |
|-------|--------|
| **ID** | F-17 |
| **Description** | Optional query to authorized services (HaveIBeenPwned API) to alert if the email appeared in leaked databases. Only if the user explicitly authorizes. |
