# 🔍 Self Digital Identity Audit (SDIA)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Hackathon](https://img.shields.io/badge/Hackathon-404%3A%20Threat%20Not%20Found%202026-orange)](https://github.com/[org]/self-digital-identity-audit)
[![Azure](https://img.shields.io/badge/Powered%20by-Azure-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![Open Source](https://img.shields.io/badge/Open%20Source-%E2%9D%A4-red)](CONTRIBUTING.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> **Education over surveillance. Consent before inspection.**

SDIA is an open-source tool that generates an **educational and actionable report** about a minor's digital footprint across social networks and gaming platforms. The minor audits their **own** accounts with family accompaniment, receives a password-protected PDF, and learns to manage their digital identity safely.

---

## ✨ What does SDIA do?

1. **The minor registers** their email and primary nickname → receives a validation link
2. **Verifies ownership** of each account they want to audit (proof-of-possession, no credentials)
3. **SDIA analyzes** their digital footprint on public platforms using ethical OSINT
4. **Generates a PDF report** with a risk traffic light, Oversharing Score, and pedagogical social engineering simulator
5. **The PDF is delivered by email**, password-protected and ready to review with their family

---

## 🏗️ Architecture

```mermaid
flowchart TD
    A[GitHub Pages\nVite + React] -->|POST /api/jobs| B[Node.js API\nAzure Container Apps]
    B -->|Create job| C[(Cosmos DB\nServerless)]
    B -->|Send OTP email| D[Azure Communication\nServices]
    D -->|Validation email| E[User — Minor]
    E -->|Validates ownership| B
    B -->|status: READY_TO_REPORT| C

    F[Cron 10AM\nGitHub Actions] -->|Query jobs| C
    F -->|If jobs exist: Bicep deploy| G[Azure Container Apps Job\nPython FastAPI Orchestrator]
    G -->|OSINT per platform| H[Maigret + httpx]
    G -->|LLM analysis| I[Azure OpenAI\ngpt-4o-mini]
    I --> G
    G -->|HTML → PDF + password| J[WeasyPrint + pikepdf]
    J -->|Temp upload| K[Azure Blob Storage\nTTL 48h]
    K -->|SAS URL| G
    G -->|Email with PDF + password| D
```

---

## 🚀 Quick Start

### Prerequisites
- Node.js 20 LTS
- Python 3.11
- Azure CLI (`az login`)
- GitHub CLI (`gh auth login`)

### 1. Clone and configure
```bash
git clone https://github.com/[org]/self-digital-identity-audit.git
cd self-digital-identity-audit
cp .env.example .env
# Edit .env with your values
```

### 2. Local development (Docker Compose)
```bash
docker compose up -d
# Frontend: http://localhost:5173
# API:      http://localhost:3000
# Emails:   http://localhost:8025 (Mailhog)
```

### 3. Deploy to Azure
```bash
az login
bash scripts/deploy.sh --env dev
```

See [DEVELOPER_GUIDE.md](docs/DEVELOPER_GUIDE.md) for detailed instructions.

---

## 📁 Repository Structure

```
self-digital-identity-audit/
├── .specify/memory/constitution.md    # SDD Constitution (read first)
├── frontend/                          # Vite + React + TypeScript
│   ├── src/
│   │   ├── pages/                     # Step-by-step validation flow
│   │   ├── components/
│   │   └── api/                       # Typed HTTP client
│   └── vite.config.ts
├── backend/                           # Node.js + Fastify + TypeScript
│   ├── src/
│   │   ├── routes/                    # /api/jobs, /api/platforms
│   │   ├── services/                  # CosmosDB, ACS, validation
│   │   └── plugins/                   # Auth, schema validation
│   └── Dockerfile
├── orchestrator/                      # Python 3.11 + FastAPI
│   ├── app/
│   │   ├── osint/                     # Maigret + httpx extractors
│   │   ├── ai/                        # Azure OpenAI integration
│   │   └── report/                    # Jinja2 → WeasyPrint → pikepdf
│   ├── templates/report.html
│   └── Dockerfile
├── infra/                             # Azure Bicep IaC
│   ├── main.bicep
│   ├── modules/
│   └── parameters/
├── docs/                              # Technical documentation
│   ├── ARCHITECTURE.md
│   ├── DEVELOPER_GUIDE.md
│   ├── FEATURES.md
│   ├── REQUIREMENTS.md
│   ├── USER_STORIES.md
│   ├── BRANCHING_STRATEGY.md
│   ├── TESTING_STRATEGY.md
│   ├── TCO_ANALYSIS.md
│   └── spec/
├── .github/workflows/
│   ├── ci.yml
│   ├── deploy-frontend.yml
│   ├── deploy-backend.yml
│   └── report-generator.yml           # Daily cron + on-demand Bicep deploy
├── CONTRIBUTING.md
├── SECURITY.md
├── CODE_OF_CONDUCT.md
└── docker-compose.yml
```

---

## 🛡️ SDIA Ethical Manifesto

SDIA operates under non-negotiable principles:

- **Consent**: only the minor can initiate their own audit
- **Verified ownership**: SDIA confirms the minor *owns* each account before auditing it
- **Privacy by design**: ephemeral processing, 48h TTL on all data
- **Public sources only**: only publicly visible information on each platform
- **No parental surveillance**: parents accompany, they do not control the process
- **Open source**: auditable, improvable, adoptable by educational institutions

---

## 🤝 Contributing

Read [CONTRIBUTING.md](CONTRIBUTING.md). Any contribution that extends the OSINT engine **must maintain** the public/authorized sources stance.

## 📄 License

MIT — see [LICENSE](LICENSE)

## 🙏 Credits

Developed for the **Hackathon 404: Threat Not Found — Child Digital Safety 2026**  
Organized by IIJ-UNAM and the U.S. Embassy (StartupLab)
