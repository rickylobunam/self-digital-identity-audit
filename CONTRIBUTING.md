# Contributing to SDIA

Thank you for wanting to contribute to Safe Digital Identity Audit! 🎉

This project exists to protect the digital identity of minors through education. Every contribution, no matter how small, has real impact.

---

## Code of Conduct

This project adopts the [Contributor Covenant v2.1](CODE_OF_CONDUCT.md). By contributing, you commit to maintaining a respectful and inclusive environment.

---

## How to contribute?

### 🐛 Report a bug
1. Check that it does not already exist in [Issues](https://github.com/[org]/self-digital-identity-audit/issues)
2. Use the **Bug Report** template
3. Include: steps to reproduce, expected vs. actual behavior, environment (OS, Node version, etc.)

### 💡 Propose a new feature
1. Open a **Feature Request** before writing code
2. Describe the use case from the user's perspective (minor or family)
3. Verify it does not contradict the ethical stance of the [SDIA Manifesto](README.md#sdia-ethical-manifesto)

### 🔧 Contribute code

```bash
# 1. Fork + clone your fork
git clone https://github.com/YOUR_USERNAME/self-digital-identity-audit.git

# 2. Add upstream
git remote add upstream https://github.com/[org]/self-digital-identity-audit.git

# 3. Create branch from develop
git checkout develop && git pull upstream develop
git checkout -b feat/short-description

# 4. Develop, test, commit
npm test  # or pytest
git commit -m "feat(backend): conventional description"

# 5. PR to upstream develop
gh pr create --base develop
```

---

## Contribution Restrictions (NON-negotiable)

The following rules apply to **all** contributions without exception:

| ❌ Never include | ✅ Instead |
|-----------------|-----------|
| Scraping with authentication or credentials | Public profiles only, no login |
| WAF evasion, rate limit bypass, or anti-blocking techniques | Respect platform limits |
| Persistent storage of PII | Use TTL, hashing, ephemeral data |
| Code that audits third-party accounts without verified ownership | Always after possession validation |
| Dependencies with restrictive licenses (GPL-3, AGPL) | MIT, Apache 2.0, BSD only |

Any PR that violates these principles will be rejected regardless of technical quality.

---

## Code Standards

- **TypeScript:** strict mode, no `any`, JSDoc on public functions
- **Python:** full type hints, docstrings on public functions, mypy clean
- **Tests:** all new functionality requires tests. Minimum coverage: 70% backend/orchestrator
- **Commits:** [Conventional Commits](https://www.conventionalcommits.org/)
- **PR size:** prefer small, focused PRs (< 400 lines of change)
- **Language:** all repository files must be 100% in English

---

## Adding a new platform

Want to add support for Discord, Twitch, Minecraft, or another platform? Read the [Adding a new platform](docs/DEVELOPER_GUIDE.md#adding-a-new-platform-eg-twitch) section in the Developer Guide.

Minimum criteria for accepting a new platform:
- Has a public profile scrapeable without authentication
- Has a field (bio, description, status) where the user can place the token
- Step-by-step validation guide is documented in English

---

## Funding and Recognition

SDIA is open source and free. If this project is useful to you, consider supporting it on [Patreon](https://patreon.com/sdia) — even $3/month makes a difference to cover Azure costs.

All contributors are recognized in the README under "Contributors". ❤️
