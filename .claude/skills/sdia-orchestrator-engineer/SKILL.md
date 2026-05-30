---
name: sdia-orchestrator-engineer
description: "SDIA orchestrator engineer role. Use this skill when writing, reviewing, or debugging Python 3.11 FastAPI code for the SDIA report orchestrator. Trigger for any work in the orchestrator/ directory: OSINT extractors, Azure OpenAI integration, Jinja2 report template, WeasyPrint PDF generation, pikepdf password protection, Pydantic models, or pytest tests. Also trigger when working on report sections (traffic light, Oversharing Score, social engineering simulator, remediation plan), prompt engineering for gpt-4o-mini, or any async httpx scraping logic. Always apply TDD with pytest + respx mocks. Never implement authenticated scraping or WAF evasion."
---

# SDIA Orchestrator Engineer

You are the **Python 3.11 FastAPI orchestrator engineer** for SDIA. You own the ephemeral
report-generation engine: OSINT extraction → LLM analysis → PDF generation → delivery.

## Stack Reference

```
Runtime:    Python 3.11
Framework:  FastAPI
OSINT:      httpx (async) + Maigret
LLM:        Azure OpenAI (gpt-4o-mini) via openai SDK
Templates:  Jinja2
PDF:        WeasyPrint → pikepdf (AES-256)
Storage:    azure-storage-blob
DB:         azure-cosmos
Tests:      pytest + pytest-asyncio + respx
Linting:    ruff + mypy
```

## TDD Discipline

```python
# RED first — write the test before the function exists
@pytest.mark.asyncio
async def test_instagram_extractor_returns_findings(respx_mock):
    respx_mock.get("https://www.instagram.com/testuser/").mock(
        return_value=httpx.Response(200, text="<html>bio text</html>")
    )
    result = await extract_instagram("testuser")
    assert isinstance(result, OsintFindings)
    assert result.platform == "instagram"

# GREEN — implement extract_instagram to make it pass
```

## OSINT Extractor Pattern

```python
# orchestrator/app/osint/instagram.py
import httpx
from app.models.schemas import OsintFindings
from app.config import settings

async def extract_instagram(nickname: str) -> OsintFindings:
    """Extract public profile data from Instagram bio."""
    url = f"https://www.instagram.com/{nickname}/"
    async with httpx.AsyncClient(timeout=settings.OSINT_REQUEST_TIMEOUT_S) as client:
        response = await client.get(url, headers={
            "User-Agent": settings.OSINT_USER_AGENT,
            "Accept-Language": "es-MX,es;q=0.9,en;q=0.8",
        })
    response.raise_for_status()
    # Parse ONLY what is needed — do NOT store raw HTML
    findings = _parse_instagram_html(response.text, nickname)
    return findings

def _parse_instagram_html(html: str, nickname: str) -> OsintFindings:
    """Extract only relevant fields — never return full HTML."""
    # ... targeted parsing, return structured OsintFindings
```

## Privacy Invariants in OSINT

```python
# ✅ CORRECT — return only structured findings, discard HTML
return OsintFindings(
    platform="instagram",
    nickname=nickname,
    bio_text=extracted_bio,       # max 500 chars
    follower_count=follower_count,
    is_public=True,
    detected_pii=[],              # list of PiiSignal enums
    risk_signals=[],
)

# ❌ WRONG — never do this
return OsintFindings(raw_html=html, ...)   # blocks merge
# ❌ WRONG — never log nicknames
logger.info(f"Extracted profile for {nickname}")  # blocks merge
# ✅ CORRECT — log only job context
logger.info(f"OSINT complete for job {job_id}, platform instagram")
```

## LLM Integration Pattern

```python
# orchestrator/app/ai/analyzer.py
from openai import AsyncAzureOpenAI
from app.ai.prompts import build_risk_prompt
from app.models.schemas import ReportAnalysis

async def analyze_findings(job_id: str, findings: list[OsintFindings]) -> ReportAnalysis:
    """Atomic LLM inference — one call per job, structured JSON output."""
    client = AsyncAzureOpenAI(
        azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
        api_version="2024-02-01",
        timeout=120.0,  # NFR-04.4: must complete within 5 min total
    )
    prompt = build_risk_prompt(findings)
    response = await client.chat.completions.create(
        model=settings.AZURE_OPENAI_DEPLOYMENT,
        messages=[
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": prompt},
        ],
        response_format={"type": "json_object"},
        temperature=0.2,  # Low temp for consistent, factual analysis
    )
    return ReportAnalysis.model_validate_json(response.choices[0].message.content)
```

## PDF Generation Pattern (ADR-002)

```python
# orchestrator/app/report/pdf_protector.py
import hashlib
import pikepdf
from pikepdf import Encryption, Permissions

def derive_pdf_password(email: str) -> str:
    """Derive 12-char base62 password from email. NEVER stored in DB."""
    hash_bytes = hashlib.sha256(email.lower().strip().encode('utf-8')).digest()
    b62 = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    result, n = "", int.from_bytes(hash_bytes[:8], 'big')
    for _ in range(12):
        result += b62[n % 62]
        n //= 62
    return result

def apply_password(pdf_bytes: bytes, email: str) -> bytes:
    """Apply AES-256 password + permissions. Print allowed, edit/copy disabled."""
    import io, os
    user_pwd = derive_pdf_password(email)
    owner_pwd = os.environ['PDF_OWNER_SECRET']
    with pikepdf.open(io.BytesIO(pdf_bytes)) as pdf:
        enc = Encryption(
            user=user_pwd, owner=owner_pwd,
            allow=Permissions(
                print_highres=True,
                modify_annotation=False, modify_assembly=False,
                modify_form=False, modify_other=False, extract=False,
            ),
            R=6  # AES-256
        )
        output = io.BytesIO()
        pdf.save(output, encryption=enc)
    return output.getvalue()
```

## Social Engineering Simulator — Mandatory Disclaimer

The simulator section of the report MUST always include this disclaimer, in Spanish,
prominently before any content:

```python
SIMULATOR_DISCLAIMER = """
⚠️ EJERCICIO EDUCATIVO — SIMULACIÓN FICTICIA

Lo que lees a continuación es un ejemplo educativo de cómo podría actuar
alguien con malas intenciones usando la información pública que encontramos.
ESTA ES UNA SIMULACIÓN, no una amenaza real. Nadie te contactó realmente.
El objetivo es que veas por qué cierta información puede ser riesgosa.
"""
```

A PDF that renders without this disclaimer in the simulator section blocks the release.

## Prompt Engineering Conventions

```python
# orchestrator/app/ai/prompts.py
SYSTEM_PROMPT = """You are a child digital safety analyst. You analyze public social media
data to generate educational reports for minors and their families.
Your analysis must be:
- Educational, not alarmist
- Specific to the evidence found, never speculative
- Written in Spanish, accessible to a 12-year-old
- Structured as valid JSON matching the ReportAnalysis schema
Never fabricate data. Only reference what was found in the OSINT results."""
```

## Common Mistakes to Avoid

- Sync `httpx` — always use `AsyncClient` with `async with`
- Missing type hints — mypy must pass cleanly; no `# type: ignore` without explanation
- Storing raw HTML in any model — only structured findings
- LLM call without timeout — always set `timeout=120.0`
- `print()` for logging — use `logging.getLogger(__name__)`
- Testing against real Azure OpenAI — always use `USE_LLM_MOCK=true` fixtures in tests

## File Map

```
orchestrator/app/
├── main.py                    FastAPI app entry point
├── osint/   extractor.py · instagram.py · tiktok.py · twitter.py
│            youtube.py · steam.py · roblox.py
├── ai/      analyzer.py · prompts.py
├── report/  generator.py · pdf_protector.py
├── storage/ cosmos.py · blob.py
└── models/  schemas.py (Pydantic v2)
```
