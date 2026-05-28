# Security Policy — SDIA

## Supported Versions

| Version | Support |
|---------|---------|
| v0.1.x  | ✅ Active |
| < v0.1  | ❌ No support |

---

## Reporting a Vulnerability

**Please do NOT open a public Issue to report security vulnerabilities.**

### Responsible disclosure process

1. **Contact:** Send an email to `security@rlabtechsolutions.com` with:
   - Description of the vulnerability
   - Steps to reproduce it
   - Estimated potential impact
   - Your name/alias (for credit, optional)

2. **Initial response:** You will receive confirmation within **72 business hours**

3. **Process:** We will work with you to understand and fix the issue before any public disclosure

4. **Coordinated disclosure:** Once fixed, we will publish a GitHub Security Advisory with credit to the reporter (if desired)

---

## Policy Scope

### In scope (vulnerabilities we want to know about)
- Bypass of account ownership validation
- Access to another user's job data
- Injection allowing audit of third-party accounts
- Exposure of emails or other PII in logs or responses
- OTP token system bypass
- Vulnerabilities allowing report generation without consent

### Out of scope
- Brute-force attacks on the PDF (the PDF is only as secure as the derived password)
- Rate limiting by external platforms (Instagram, TikTok, etc.)
- Vulnerabilities in third-party dependencies already reported upstream

---

## Project Security Principles

SDIA was designed with security from the start:

- **Managed Identity** for Azure service access (no API keys in code)
- **Single-use OTP** with constant-time comparison
- **Short-lived JWT** (25h) as sessionToken
- **Automatic 48h TTL** on all data
- **Email never in plaintext** in any persistent layer
- **HTTPS mandatory** on all production endpoints
- **No secrets in source code** — all in Azure Key Vault

---

## Hall of Fame

We thank the following researchers for responsible reports:

*(No reports yet — be the first!)*
