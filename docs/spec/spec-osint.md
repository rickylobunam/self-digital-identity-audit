# Specification: OSINT Module

> **SDD Artifact:** `spec-osint.md`  
> **Module:** Per-platform OSINT extraction  
> Operates ONLY after ownership has been verified.

---

## 1. Inputs / Outputs

**Input:** `OsintJob` — list of VALIDATED platforms with their nicknames  
**Output:** `OsintReport` — findings per platform

```python
@dataclass
class OsintFindings:
    platform: str
    nickname: str
    profile_exists: bool
    is_public: bool
    bio_text: Optional[str]           # Public bio/description (max 500 chars)
    follower_count: Optional[int]     # If publicly visible
    following_count: Optional[int]
    post_count: Optional[int]
    location_hints: list[str]         # Location mentions in bio/recent posts
    schedule_signals: list[str]       # Inferable routines (e.g. "every Monday")
    personal_info_signals: list[str]  # Detected PII: real name, school, etc.
    external_links: list[str]         # Links in bio (other profiles, etc.)
    lfg_presence: bool                # Is the user in LFG (Looking For Group) spaces?
    recent_activity: Optional[str]    # Last visible activity (date only, no content)
    risk_signals: list[str]           # Detected risk signals
```

---

## 2. Business Rules

### BR-OSINT-01: Public sources only
- The scraper NEVER uses authentication
- Only accesses public URLs (no login required)
- Declarative User-Agent: `SDIA-Educational-Bot/0.1 (+https://github.com/[org]/sdia)`

### BR-OSINT-02: Rate limiting and backoff
```python
PLATFORM_DELAYS = {
    'instagram': 3.0,   # seconds between requests
    'tiktok': 2.0,
    'x_twitter': 2.0,
    'youtube': 1.0,
    'steam': 1.0,
    'roblox': 0.5,      # Has a public API
}
# Exponential backoff: base_delay × 2^attempt (max 3 attempts)
```

### BR-OSINT-03: Data minimization
- Do NOT extract individual posts (only aggregated metadata)
- Do NOT store photos, videos, or multimedia content
- Bio: max 500 characters
- Truncate any field to its defined limits

### BR-OSINT-04: Context isolation
- Each job uses its own HTTP client (no cookie sharing between jobs)
- No persistent connections between audits

### BR-OSINT-05: Error handling
- HTTP 429/503: `risk_signals.append("Platform temporarily unreachable")`; continue with other platforms
- Profile not found: `profile_exists = False`; not a system error
- Timeout (10s): record as unavailable; do not fail the entire job

---

## 3. Acceptance Criteria

```
✅ OSINT runs in parallel (asyncio) for independent platforms
✅ A failure on one platform does not cancel the others
✅ Output contains no more than 500 chars of bio
✅ No session data/cookies shared between jobs
✅ Logs contain no profile content — only platform + requestId
```
