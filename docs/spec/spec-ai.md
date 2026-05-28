# Specification: AI Analysis Module

> **SDD Artifact:** `spec-ai.md`  
> **Module:** LLM analysis of OSINT findings and report content generation

---

## 1. LLM Output Schema (Strict JSON)

```json
{
  "oversharing_score": 7,
  "risk_level": "HIGH",
  "risk_summary": "We found your full name, school name, and neighborhood on at least 2 platforms.",
  "schedule_footprint": "You appear to be active mainly between 4 PM and 10 PM on weekdays, and Saturday mornings.",
  "platform_findings": [
    {
      "platform": "instagram",
      "nickname": "my_user",
      "risk_level": "HIGH",
      "findings": ["Full name visible", "School mentioned in bio"],
      "recommendations": ["Remove your school name from your bio", "Use only your first name"]
    }
  ],
  "social_sim": {
    "disclaimer": "The following is FOR EDUCATIONAL PURPOSES ONLY. It shows how someone with bad intentions could use public information to approach you.",
    "scenario": "Using the information found, a stranger could write: 'Hi [name], I saw you go to [school]. I saw your post about Saturday's game, you played great!'",
    "explanation": "This message seems to come from someone who knows you, but they only used public information from your Instagram."
  },
  "recommendations": [
    { "priority": 1, "action": "Remove your school name from all your profiles", "platforms": ["instagram", "tiktok"] },
    { "priority": 2, "action": "Enable private mode on Instagram", "platforms": ["instagram"] },
    { "priority": 3, "action": "Review who can see your old posts", "platforms": ["instagram"] }
  ],
  "positive_notes": "Your Steam and Roblox accounts look great! We found no personal information there."
}
```

---

## 2. Prompt Template

```python
SYSTEM_PROMPT = """
You are an expert in child digital safety and educational psychology.
Your task is to analyze a minor's public digital footprint and generate
an educational, accessible, and constructive report.

ABSOLUTE RULES:
1. Tone: positive, educational, never alarmist or guilt-inducing
2. Language: clear for a 12-17 year old and their parents
3. social_sim ALWAYS includes the educational disclaimer
4. social_sim uses ONLY information from the input, nothing invented
5. Respond ONLY with valid JSON. No additional text.
6. risk_level: "LOW" (score 1-3), "MEDIUM" (4-6), "HIGH" (7-10)
"""

def build_prompt(job: AuditJob, osint_results: list[OsintFindings]) -> str:
    findings_text = format_findings_for_prompt(osint_results)
    return f"""
Analyze the following public digital footprint and generate the JSON report.

Audited platforms: {[f.platform for f in osint_results]}

OSINT Findings:
{findings_text}

Generate the analysis JSON following exactly the specified schema.
"""
```

---

## 3. Business Rules

### BR-AI-01: Atomic Inference
- Each job uses its own LLM call with its own context
- Conversational history is NOT reused between jobs
- The response is parsed and discarded; the raw prompt and response are not stored

### BR-AI-02: Output Validation
- The JSON must parse without error against the defined schema
- If the LLM returns invalid JSON: retry max 2 times with reduced temperature
- If it fails 3 times: use `risk_level: "MEDIUM"` with a safe fallback template

### BR-AI-03: Social Simulator Content
- NEVER invent information not present in the OSINT findings
- ALWAYS include the educational disclaimer
- The scenario must describe the tactic, not be an actual grooming message
- Safety check: if the LLM generates content inappropriate for minors, the output is discarded and a safe template is used

### BR-AI-04: Token Limits
- Max input tokens: 4,000 (truncate findings if exceeded)
- Max output tokens: 2,000
- Temperature: 0.3 (consistent and predictable responses)

---

## 4. Acceptance Criteria

```
✅ Output is valid JSON parseable with the defined schema
✅ social_sim contains mandatory disclaimer
✅ social_sim only references information from the OSINT input
✅ Each call is independent (no state shared between jobs)
✅ LLM failure does not cancel the job (uses fallback template)
✅ Logs contain no prompt content or LLM response content
```
