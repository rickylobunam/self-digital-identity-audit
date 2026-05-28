# SDIA — TCO Analysis, Funding Strategy, and Break-Even

> **Date:** April 2026 · Azure Pay-As-You-Go prices (East US / Mexico Central)  
> **Exchange rate reference:** 1 USD ≈ 17.20 MXN

---

## Part I — Cost Breakdown by Service

### 1.1 Always-On Services (monthly baseline)

| Service | Tier | Cost/month (USD) | Notes |
|---------|------|------------------|-------|
| **Azure Cosmos DB** | Serverless | ~$0.25 / M RUs | ~1,000 RU per complete job. 100 users = $0.025 |
| **Azure Container Apps** (Node.js API) | Consumption | ~$0–3 | Scale-to-zero; only charged when requests arrive. Free grant: 180K vCPU-s/month |
| **Azure Container Registry** (ACR) | Basic | $5.00 fixed | Docker image storage |
| **Azure Communication Services** (email) | Pay-per-use | $0.00025/email | 300 emails = $0.075 |
| **Azure Key Vault** | Standard | $0.03/10K ops | Minimal operational ~$0.10 |
| **GitHub** (Actions + Pages) | Free tier | $0 | 2,000 min/month free for public repos |
| **Domain** (sdia.app or similar) | Namecheap | ~$1.00/month | If custom domain is desired |

**Baseline subtotal (at rest, 0 users):** ~$6–7 USD/month

---

### 1.2 Variable Cost Per Generated Report

| Component | Unit cost | Calculation basis |
|-----------|-----------|------------------|
| **Azure OpenAI gpt-4o-mini** | ~$0.05 | ~5K input tokens + 2K output × $0.15/$0.60 per M tokens |
| **Azure Container Apps** (Python Orchestrator) | ~$0.02 | ~3 min CPU × $0.000024/vCPU-s |
| **Azure Blob Storage** (PDF temp 48h) | ~$0.0001 | 500KB × $0.0184/GB-month × 2 days |
| **OSINT via Maigret** (compute only) | included above | No additional API cost |
| **ACS Email** (2 emails: validation + report) | $0.0005 | 2 × $0.00025 |
| **Cosmos DB** (job operations) | ~$0.0003 | ~1,000 RUs × $0.25/M |

**Total cost per generated report:** ~$0.07–0.10 USD (~$1.20–1.72 MXN)

---

### 1.3 Projections by Scale

| Scenario | Reports/month | Variable cost | Fixed cost | **Total/month USD** | **Total/month MXN** |
|----------|--------------|--------------|-----------|---------------------|---------------------|
| **Hackathon demo** | 5 | $0.50 | $6.50 | **~$7** | **~$120** |
| **Early stage** | 50 | $5 | $6.50 | **~$12** | **~$206** |
| **Low growth** | 200 | $20 | $7 | **~$27** | **~$464** |
| **Medium growth** | 1,000 | $100 | $8 | **~$108** | **~$1,858** |
| **High growth** | 5,000 | $500 | $15 | **~$515** | **~$8,858** |
| **Educational scale** | 20,000 | $2,000 | $30 | **~$2,030** | **~$34,916** |

> 💡 **Key insight:** Azure's scale-to-zero model is ideal for SDIA. At 0 users, monthly cost is < $7 USD. The project can "sleep" at minimal cost for months and wake up instantly.

---

## Part II — Break-Even Analysis

### 2.1 Free + Patreon Scenario (Open Source)

SDIA can operate **completely free** for end users and sustain itself through community support via Patreon.

| Usage volume | Monthly cost | Patrons needed (at $5 USD) | Patrons needed (at $10 USD) |
|-------------|-------------|----------------------------|------------------------------|
| 50 reports/month | $12 | **3 patrons** | 2 patrons |
| 200 reports/month | $27 | **6 patrons** | 3 patrons |
| 1,000 reports/month | $108 | **22 patrons** | 11 patrons |
| 5,000 reports/month | $515 | **103 patrons** | 52 patrons |

**Conclusion:** With just **10–20 Patreon supporters**, SDIA can operate sustainably at hundreds of reports per month.

---

### 2.2 Suggested Patreon Tier Structure

| Tier | Price/month | Benefits | Target supporters |
|------|-------------|---------|-------------------|
| ☕ **Digital Coffee** | $3 USD | Name in README "Supporters" | 20 |
| 🛡️ **Digital Guardian** | $10 USD | Access to private updates, badge | 15 |
| 🏫 **Education Ally** | $25 USD | Logo on site, social media mention | 5 |
| 🏛️ **Institutional Sponsor** | $100 USD | For schools/NGOs, monthly impact report | 2 |

**Realistic initial target:** 15 × $3 + 5 × $10 + 1 × $25 = **$95 USD/month**  
→ Covers operations up to ~900 reports/month with margin.

---

### 2.3 Freemium Model (future v1.0, optional)

If monetization is decided in the future without abandoning open source:

| Tier | Price | Includes |
|------|-------|---------|
| **Free** | $0 | 1 report / 30 days · max 3 platforms · basic PDF |
| **Family** | $0.17 USD/report | Unlimited reports · all platforms · premium PDF with comparison |
| **School** | $17.40 USD/month | Up to 100 reports/month · institutional dashboard · anonymized aggregated reports |

**Price per report:** $0.17 USD  
**Margin per report:** $0.17 − $0.09 (cost) = **$0.08 USD (~47% margin)**

---

## Part III — Can it be profitable?

### Direct answer: Yes, but not as a primary business.

**Conservative scenario (Patreon + Freemium, Year 1):**
- 500 reports/month at $0.17 USD = $85 USD
- 10 patrons at $10 USD = $100 USD
- **Monthly revenue: ~$185 USD (~$3,182 MXN)**
- **Operating cost: ~$50 USD**
- **Margin: ~$135 USD/month (~$2,322 MXN/month)**

**Optimistic scenario (school partnerships, Year 2):**
- 5 schools at $17.40 USD/month = $87 USD
- 200 individual reports = $34 USD
- **Monthly revenue: ~$121 USD (~$2,081 MXN)**
- **Operating cost: ~$40 USD ($688 MXN)**
- **Margin: ~$81 USD/month (~$1,393 MXN/month)**

### Real impact potential:
- Mexico has ~42 million internet users aged 6–17 (ENDUTIH 2023)
- If 0.01% use SDIA annually = **4,200 reports/year = 350/month**
- At that volume, cost = ~$38 USD/month → sustainable with few patrons

> 🎯 **Strategic recommendation:** Keep SDIA free and open source in the MVP/hackathon. Capture first users and credibility. Introduce the freemium model only when demand is validated. The primary objective is **social impact**, not profitability.

---

## Part IV — Cost Reduction Strategy

### Optimizations built into the design:
1. **Scale-to-zero**: no cost when there is no activity
2. **gpt-4o-mini** instead of GPT-4o: 15x cheaper, sufficient for educational reports
3. **Cosmos DB Serverless** instead of Provisioned: ideal for variable loads
4. **Automatic TTL**: no long-term storage cost
5. **GitHub Pages + Actions** free: $0 for frontend and CI/CD
6. **Ephemeral orchestrator**: only exists during report generation

### Future optimizations (v0.2):
- **Phi-3-mini** on Azure Container Apps (Consumption CPU) to eliminate Azure OpenAI cost
- **Adaptive chunking**: analyze optimal parallelism to minimize compute time and cost
- **Azure Spot Containers**: up to 60% discount for the batch orchestrator

---

## Part V — Hackathon Budget

| Item | Estimated cost |
|------|---------------|
| Azure Free Trial (new users) | **$0** (with $200 free credit) |
| Azure for Students / Startups | **$0** (with $100 credit) |
| GitHub Pages + Actions | **$0** (public repo) |
| **Total hackathon (live demo)** | **$0–5 USD** |

> ✅ The hackathon can run entirely within Azure's free tier using Azure for Students or a new trial account.
