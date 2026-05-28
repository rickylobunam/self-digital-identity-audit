# Specification: Report Generation Module

> **SDD Artifact:** `spec-report.md`  
> **Module:** Protected PDF generation

---

## 1. Report PDF Structure

### Sections (in order)

1. **Cover** — SDIA logo, title "Your Digital Footprint", audited nickname, date
2. **Welcome message** — 2 educational paragraphs, friendly tone
3. **Risk Traffic Light** — Large visual (Red/Yellow/Green) + executive summary
4. **Oversharing Score** — Visual bar 1-10 with gauge, explanation
5. **Findings by Platform** — One card per platform (individual traffic light + findings list)
6. **Your Activity Pattern** — Section on inferable activity patterns
7. **Educational Simulator** — With prominent disclaimer, pedagogical scenario
8. **Action Plan** — Prioritized, actionable checklist
9. **What you did well** — Positive notes (positive_notes from LLM)
10. **Footer** — SDIA legal disclaimer, ethical stance, support resources

---

## 2. PDF Technical Specifications

```python
# Generation pipeline
def generate_report(ai_output: dict, email: str) -> bytes:
    # 1. Render HTML with Jinja2
    html = render_jinja2_template("report.html", ai_output)

    # 2. HTML → PDF with WeasyPrint
    pdf_bytes = HTML(string=html, base_url=ASSETS_BASE_URL).write_pdf()

    # 3. Apply protection with pikepdf
    password = derive_pdf_password(email)  # See ADR-002
    protected_pdf = apply_protection(pdf_bytes, password)

    return protected_pdf

# pikepdf permission configuration
PERMISSIONS = Permissions(
    print_highres=True,      # ✅ Can print
    modify_annotation=False, # ❌
    modify_assembly=False,   # ❌
    modify_form=False,       # ❌
    modify_other=False,      # ❌
    extract=False,           # ❌ No text copying
)
ENCRYPTION = R=6  # AES-256
```

---

## 3. Color Palette (Traffic Light)

```css
:root {
  --risk-high:   #DC2626;   /* Red    — HIGH   */
  --risk-medium: #D97706;   /* Amber  — MEDIUM */
  --risk-low:    #16A34A;   /* Green  — LOW    */
  --sdia-blue:   #1D4ED8;   /* Brand  */
  --sdia-dark:   #1E293B;   /* Text   */
  --bg-light:    #F8FAFC;   /* Background */
}
```

---

## 4. Business Rules

### BR-REPORT-01: Size and Format
- Format: A4 (210 × 297 mm)
- Orientation: Portrait
- Margins: 15mm all sides
- Primary font: Inter or Helvetica (embedded in PDF)
- Minimum font size: 11pt (accessibility)

### BR-REPORT-02: Delivery
- Upload to Azure Blob Storage with SAS URL (TTL 48h)
- The SAS link is NOT stored in Cosmos DB (only sent by email to the owner)
- The email includes: password + link + instructions for opening it

### BR-REPORT-03: Fallback if LLM fails
- If the AI module fails, the report is generated with a generic template
- Fallback template: raw OSINT data only with standard per-platform recommendations

---

## 5. Acceptance Criteria

```
✅ Generated PDF begins with "%PDF-1.7" or higher
✅ PDF requires a password to open
✅ PDF does not allow copying text (verify: pikepdf.Permissions.extract == False)
✅ PDF allows printing
✅ PDF generated in < 30 seconds per job
✅ PDF size: between 100KB and 2MB
✅ Educational simulator disclaimer is visible and prominent
✅ SAS URL has TTL of exactly 48h
```
