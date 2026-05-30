# SDIA Theme Guide

**Project:** Self Digital Identity Audit (SDIA)  
**Theme Name:** Guardian Teal & Trust Navy  
**Version:** 1.0.1  
**Status:** Approved baseline theme with accessibility refinements  
**Audience:** Product, frontend, documentation, design, and implementation contributors  
**Recommended target path:** `docs/design/THEME.md`

---

## 1. Theme Purpose

The **Guardian Teal & Trust Navy** theme defines the visual identity for **Self Digital Identity Audit (SDIA)**.

SDIA is an educational digital safety project designed to help minors understand and manage their own digital footprint with family accompaniment. The visual system must communicate:

- Trust without surveillance
- Safety without fear
- Education without punishment
- Clarity without oversimplification
- Family accompaniment without infantilizing the experience
- Accessibility by default

The theme should support SDIA’s core principle:

> Education over surveillance. Consent before inspection.

This theme is intended to be used across:

- GitHub Pages frontend
- Product documentation
- Reports and generated PDFs
- Educational explanations
- Risk indicators
- Contributor-facing design references

---

## 2. Brand Personality

SDIA should feel:

- **Safe** — the user understands that their data and experience are handled carefully.
- **Calm** — the interface should reduce anxiety, especially when discussing risk.
- **Ethical** — the product must avoid any visual language that suggests spying, punishment, or coercive monitoring.
- **Educational** — the experience should guide minors and families toward learning and practical remediation.
- **Professional** — the project should be credible for families, schools, cybersecurity communities, NGOs, and public-sector stakeholders.
- **Human** — the visual system should include warmth and empathy, not only technical security cues.
- **Accessible** — the experience should remain usable through keyboard navigation, assistive technologies, sufficient contrast, and non-color indicators.

Avoid visual styles that feel:

- Aggressively “hacker-like”
- Fear-based
- Overly dark
- Surveillance-oriented
- Infantilized
- Alarmist
- Punitive

---

## 3. Color Palette

### 3.1 Core Palette

| Token | Name | Hex | Purpose |
|---|---|---:|---|
| `--sdia-primary` | Trust Navy | `#0F2742` | Primary brand color, headers, navigation, strong titles |
| `--sdia-secondary` | Guardian Teal | `#0F766E` | Primary actions, progress states, protective UI elements |
| `--sdia-secondary-hover` | Guardian Teal Hover | `#115E59` | Primary button hover state |
| `--sdia-secondary-active` | Guardian Teal Active | `#0D4F4A` | Primary button pressed/active state |
| `--sdia-accent` | Learning Mint | `#2DD4BF` | Highlights, educational badges, positive microinteractions |
| `--sdia-background` | Soft Cloud | `#F8FAFC` | Main app background |
| `--sdia-surface` | White Surface | `#FFFFFF` | Cards, panels, forms, report blocks |
| `--sdia-surface-warm` | Family Sand | `#F5EFE6` | Family guidance cards, educational notes, warm content sections |
| `--sdia-surface-warm-border` | Warm Sand Border | `#E8D5C4` | Borders for warm family/accompaniment cards |
| `--sdia-text-primary` | Deep Slate | `#111827` | Main readable text |
| `--sdia-text-secondary` | Slate Gray | `#475569` | Supporting text, captions, helper copy |
| `--sdia-text-inverse` | White | `#FFFFFF` | Text on dark brand backgrounds |
| `--sdia-border` | Soft Border | `#CBD5E1` | Borders, dividers, input outlines |
| `--sdia-muted` | Muted Cloud | `#E2E8F0` | Disabled areas, subtle backgrounds, skeleton states |

---

### 3.2 Interactive State Palette

| Token | Value | Purpose |
|---|---:|---|
| `--sdia-focus` | `#0F766E` | Keyboard focus color and focus-visible outlines |
| `--sdia-focus-ring` | `0 0 0 3px rgba(15, 118, 110, 0.35)` | Standard accessible focus ring |
| `--sdia-overlay` | `rgba(15, 39, 66, 0.48)` | Modal, drawer, and blocking-overlay backdrop |
| `--sdia-transition` | `200ms ease` | Standard transition duration and easing |

Focus states are mandatory for keyboard accessibility. Every interactive element must expose a visible `:focus-visible` state.

Recommended baseline:

```css
:focus-visible {
  outline: 2px solid var(--sdia-focus);
  outline-offset: 2px;
  box-shadow: var(--sdia-focus-ring);
}
```

---

### 3.3 Semantic Palette

Semantic colors must be used consistently and must not rely on color alone. Always pair semantic color with text, labels, and preferably icons.

| Token | Name | Hex | Meaning |
|---|---|---:|---|
| `--sdia-success` | Safe Green | `#16A34A` | Verified, completed, low risk, positive improvement |
| `--sdia-success-light` | Safe Green Light | `#DCFCE7` | Subtle success banner/card background |
| `--sdia-info` | Info Blue | `#2563EB` | Educational information, neutral explanation, learn more |
| `--sdia-info-light` | Info Blue Light | `#DBEAFE` | Subtle informational banner/card background |
| `--sdia-warning` | Care Amber | `#F59E0B` | Medium risk, review recommended, attention needed |
| `--sdia-warning-light` | Care Amber Light | `#FEF3C7` | Subtle warning banner/card background |
| `--sdia-danger` | Coral Red | `#DC2626` | High risk, urgent remediation, critical error |
| `--sdia-danger-light` | Coral Red Light | `#FEE2E2` | Subtle high-risk or error banner/card background |

> Note: `--sdia-danger` intentionally remains `#DC2626` for the baseline because it is clear, familiar, and effective for critical states. A warmer coral alternative such as `#E03E3E` or `#E55050` may be evaluated in a future brand iteration if the product needs a softer emotional tone.

---

## 4. Color Psychology Rationale

### 4.1 Trust Navy

**Trust Navy** (`#0F2742`) is the anchor of the visual identity. It communicates seriousness, digital trust, institutional credibility, and calm authority.

It should be used for:

- Primary navigation
- Main headings
- Footer areas
- Executive documentation
- Strong UI hierarchy

It should not dominate the entire interface. SDIA should not feel like a dark cybersecurity operations dashboard.

### 4.2 Guardian Teal

**Guardian Teal** (`#0F766E`) combines the calmness of blue with the safety and growth associations of green.

It should be used for:

- Primary buttons
- Step progress indicators
- Safe action prompts
- Account verification progress
- Protective visual cues
- Keyboard focus states

This color represents guided action: calm, responsible, and safe.

### 4.3 Learning Mint

**Learning Mint** (`#2DD4BF`) introduces freshness and educational energy.

It should be used sparingly for:

- Educational badges
- Positive feedback accents
- Small highlights
- Soft progress accents
- Success-adjacent microinteractions

It should not replace Guardian Teal as the primary action color.

**Accessibility warning:** Learning Mint must not be used as normal text on light backgrounds such as `#FFFFFF`, `#F8FAFC`, or `#F5EFE6`. Its contrast against white is too low for body text and most UI labels. Use it as a decorative accent, icon background, highlight, or large non-critical visual accent only. If text must appear near or on Learning Mint, validate the final foreground/background contrast before implementation.

### 4.4 Family Sand

**Family Sand** (`#F5EFE6`) adds warmth to the experience.

It should be used for:

- Family discussion prompts
- Parent/minor review sections
- Educational side notes
- Report interpretation areas
- Remediation guidance blocks

This color helps prevent SDIA from feeling purely technical or investigative.

Use `--sdia-surface-warm-border` (`#E8D5C4`) instead of the default cool border when creating warm family/accompaniment cards.

### 4.5 Semantic Risk Colors

Risk colors must be calm and actionable, not alarmist.

- **Safe Green** means: “You are doing well. Maintain these habits.”
- **Care Amber** means: “Review this area and take a recommended action.”
- **Coral Red** means: “This requires priority attention.”
- **Info Blue** means: “This is educational or explanatory.”

Use light semantic variants for banners and subtle cards. Use solid semantic colors for icons, labels, badges, and high-emphasis state indicators.

---

## 5. Risk Traffic Light System

The SDIA report and dashboard may include a risk traffic light system.

Recommended mapping:

| Risk Level | Color Token | Light Token | Icon / Shape | User-Facing Tone |
|---|---|---|---|---|
| Low | `--sdia-success` | `--sdia-success-light` | Check mark / circle: `✓` | Positive and reinforcing |
| Medium | `--sdia-warning` | `--sdia-warning-light` | Exclamation / triangle: `!` | Calm, careful, and actionable |
| High | `--sdia-danger` | `--sdia-danger-light` | Cross / octagon: `✕` | Clear, urgent, but not frightening |
| Informational | `--sdia-info` | `--sdia-info-light` | Info / rounded square: `i` | Educational and neutral |

### 5.1 Non-Color Differentiation Requirement

Risk states must never depend on color alone.

Every traffic-light indicator must include at least three channels of meaning:

1. **Color** — green, amber, red, or blue.
2. **Icon or shape** — for example, `✓`, `!`, `✕`, or `i`.
3. **Text label** — for example, “Low Risk”, “Medium Risk”, “High Risk”, or “Informational”.

Recommended accessible examples:

```text
✓ Low Risk — Good digital safety habits detected.
! Medium Risk — Some information may need review.
✕ High Risk — Priority action recommended.
i Informational — Learn why this matters.
```

Generated PDFs should remain understandable when printed in grayscale. Use labels, icons, and section titles in addition to color.

### 5.2 Risk Copy Guidelines

Do not use labels that shame, blame, or scare the minor.

Avoid:

- “Dangerous behavior”
- “You failed”
- “Critical exposure detected” without explanation
- “Your account is unsafe” as a standalone statement

Prefer:

- “This may increase your exposure.”
- “Review this with your family.”
- “Here is one step you can take today.”
- “This information may be visible to people you do not know.”

---

## 6. Accessibility Requirements

The theme must support accessibility from the beginning.

Minimum requirements:

- Body text should meet at least WCAG AA contrast expectations.
- Do not communicate state through color alone.
- Use icons, labels, helper text, and structured hierarchy together with color.
- Interactive focus states must be visible.
- Error states must include text and not only red outlines.
- Risk indicators must include readable labels and icons/shapes.
- Generated reports should remain understandable when printed in grayscale.
- Loading states must not remove context or trap keyboard focus.
- Disabled states must remain understandable and should include an explanation when the reason is not obvious.

Recommended design patterns:

- Use `Deep Slate` text on `Soft Cloud`, `White Surface`, or `Family Sand`.
- Use white text on `Trust Navy` and `Guardian Teal`.
- Avoid using `Learning Mint` as a background for small white text.
- Avoid using `Learning Mint` as text on light backgrounds.
- Avoid amber, mint, or light semantic colors as body text colors on light backgrounds.
- Validate final color combinations before production release.

---

## 7. Typography

### 7.1 Frontend Typography

Recommended frontend font stack:

```css
font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
```

Inter should be the primary web font for the GitHub Pages frontend and any browser-based UI.

### 7.2 Documentation, Word, and PDF Typography

Recommended documentation font stack for browser-rendered documentation:

```css
font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif;
```

Aptos may be used only in Microsoft Office contexts, such as Word documents, internal planning documents, or PDF exports where the font is available or embedded.

Recommended Microsoft Office / Word style:

```text
Aptos, Inter, Segoe UI, Arial, sans-serif
```

Do not assume Aptos is available in browsers or on GitHub Pages.

### 7.3 Font Usage

| Element | Recommended Weight | Notes |
|---|---:|---|
| Page title | 700 | Strong but calm |
| Section title | 600 | Clear hierarchy |
| Body text | 400 | High readability |
| Helper text | 400 | Use secondary text color |
| Buttons | 600 | Clear action affordance |
| Badges | 600 | Short labels only |

---

## 8. UI Style Guidelines

### 8.1 Layout

Use a clean, spacious, card-based layout.

Recommended values:

- Border radius: `16px` to `24px`
- Card padding: `24px`
- Section spacing: `32px` to `48px`
- Button height: `44px` to `48px`
- Button horizontal padding: `24px`
- Button vertical padding: `12px`
- Input height: `44px` to `48px`
- Standard transition: `var(--sdia-transition)`

### 8.2 Cards

Cards should feel calm and readable.

Recommended default card style:

```css
background: var(--sdia-surface);
border: 1px solid var(--sdia-border);
border-radius: var(--sdia-radius-lg);
box-shadow: var(--sdia-shadow-soft);
```

Recommended warm family/accompaniment card style:

```css
background: var(--sdia-surface-warm);
border: 1px solid var(--sdia-surface-warm-border);
border-radius: var(--sdia-radius-lg);
box-shadow: var(--sdia-shadow-soft);
```

### 8.3 Buttons

Primary button:

```css
.sdia-button-primary {
  min-height: 44px;
  padding: 12px 24px;
  background: var(--sdia-secondary);
  color: var(--sdia-text-inverse);
  border: 1px solid transparent;
  border-radius: 14px;
  font-weight: 600;
  transition: background var(--sdia-transition), box-shadow var(--sdia-transition), opacity var(--sdia-transition);
}
```

Primary button hover:

```css
.sdia-button-primary:hover {
  background: var(--sdia-secondary-hover);
}
```

Primary button active:

```css
.sdia-button-primary:active {
  background: var(--sdia-secondary-active);
}
```

Primary button focus-visible:

```css
.sdia-button-primary:focus-visible {
  outline: 2px solid var(--sdia-focus);
  outline-offset: 2px;
  box-shadow: var(--sdia-focus-ring);
}
```

Primary button disabled:

```css
.sdia-button-primary:disabled,
.sdia-button-primary[aria-disabled="true"] {
  opacity: 0.45;
  cursor: not-allowed;
}
```

Primary button loading:

```css
.sdia-button-primary[data-loading="true"] {
  cursor: wait;
}

.sdia-button-primary[data-loading="true"] .sdia-spinner {
  display: inline-block;
}
```

Secondary button:

```css
.sdia-button-secondary {
  min-height: 44px;
  padding: 12px 24px;
  background: var(--sdia-surface);
  color: var(--sdia-primary);
  border: 1px solid var(--sdia-border);
  border-radius: 14px;
  font-weight: 600;
  transition: background var(--sdia-transition), box-shadow var(--sdia-transition), border-color var(--sdia-transition);
}
```

Danger button should be rare and used only for destructive or high-risk actions:

```css
.sdia-button-danger {
  min-height: 44px;
  padding: 12px 24px;
  background: var(--sdia-danger);
  color: var(--sdia-text-inverse);
  border: 1px solid transparent;
  border-radius: 14px;
  font-weight: 600;
}
```

### 8.4 Forms

Forms should feel safe and guided.

Use:

- Clear labels
- Helper text
- Validation messages written in calm language
- Step-by-step structure for minors and families
- Visible `:focus-visible` styles
- Explicit error text with icons

Avoid:

- Dense forms
- Hidden consent language
- Technical jargon without explanation
- Red-only validation states
- Placeholder-only labels

Recommended input focus style:

```css
.sdia-input:focus-visible {
  border-color: var(--sdia-focus);
  outline: 2px solid transparent;
  box-shadow: var(--sdia-focus-ring);
}
```

### 8.5 Banners and Alerts

Use light semantic tokens for banners and alert backgrounds.

Success banner:

```css
background: var(--sdia-success-light);
color: var(--sdia-text-primary);
border-left: 4px solid var(--sdia-success);
```

Warning banner:

```css
background: var(--sdia-warning-light);
color: var(--sdia-text-primary);
border-left: 4px solid var(--sdia-warning);
```

Danger banner:

```css
background: var(--sdia-danger-light);
color: var(--sdia-text-primary);
border-left: 4px solid var(--sdia-danger);
```

Info banner:

```css
background: var(--sdia-info-light);
color: var(--sdia-text-primary);
border-left: 4px solid var(--sdia-info);
```

---

## 9. Iconography

Recommended icon style:

- Line icons
- Rounded stroke endings
- Consistent stroke width
- Friendly but professional
- Distinct shapes for semantic states

Recommended icon concepts:

- Shield for protection
- Compass for guidance
- Check circle for verified steps
- Eye-off or privacy icon for reduced exposure
- Book or lightbulb for education
- Family/group icon for accompaniment
- Triangle/exclamation for review-needed states
- Octagon or cross for high-risk states
- Info circle for explanatory content

Avoid:

- Spy icons
- Crosshair or target icons
- Skull icons
- Aggressive hacker symbols
- Police-like surveillance symbols

---

## 10. Illustration Direction

Illustrations, if used, should feel:

- Human
- Calm
- Educational
- Inclusive
- Non-threatening

Recommended visual metaphors:

- A compass guiding a safe path
- A shield protecting a profile
- A family reviewing a checklist together
- A digital footprint turning into a learning map
- A lighthouse guiding safe digital decisions

Avoid visual metaphors that suggest:

- Punishment
- Exposure or shame
- Hacking into accounts
- Spying on minors
- Fear-driven cybersecurity

---

## 11. Voice and Tone Alignment

The visual identity must match SDIA’s tone of voice.

SDIA should say:

- “Let’s review this together.”
- “This may be visible to others.”
- “Here is a safer option.”
- “You are learning to manage your digital identity.”
- “Your privacy choices matter.”

SDIA should not say:

- “You are at fault.”
- “You are being watched.”
- “Your family will monitor everything.”
- “This is dangerous” without context.
- “You failed the audit.”

---

## 12. CSS Custom Properties

The following CSS variables may be used as the baseline theme tokens.

```css
:root {
  /* Brand */
  --sdia-primary: #0F2742;
  --sdia-secondary: #0F766E;
  --sdia-secondary-hover: #115E59;
  --sdia-secondary-active: #0D4F4A;
  --sdia-accent: #2DD4BF;

  /* Backgrounds and surfaces */
  --sdia-background: #F8FAFC;
  --sdia-surface: #FFFFFF;
  --sdia-surface-warm: #F5EFE6;
  --sdia-surface-warm-border: #E8D5C4;
  --sdia-muted: #E2E8F0;
  --sdia-border: #CBD5E1;

  /* Text */
  --sdia-text-primary: #111827;
  --sdia-text-secondary: #475569;
  --sdia-text-inverse: #FFFFFF;

  /* Interactive states */
  --sdia-focus: #0F766E;
  --sdia-focus-ring: 0 0 0 3px rgba(15, 118, 110, 0.35);

  /* Semantic */
  --sdia-success: #16A34A;
  --sdia-success-light: #DCFCE7;
  --sdia-info: #2563EB;
  --sdia-info-light: #DBEAFE;
  --sdia-warning: #F59E0B;
  --sdia-warning-light: #FEF3C7;
  --sdia-danger: #DC2626;
  --sdia-danger-light: #FEE2E2;

  /* Effects */
  --sdia-shadow-soft: 0 12px 30px rgba(15, 39, 66, 0.08);
  --sdia-overlay: rgba(15, 39, 66, 0.48);
  --sdia-transition: 200ms ease;

  /* Radius */
  --sdia-radius-sm: 12px;
  --sdia-radius-md: 16px;
  --sdia-radius-lg: 20px;
  --sdia-radius-xl: 24px;
}
```

---

## 13. Tailwind Reference Mapping

If the frontend uses Tailwind CSS, map SDIA tokens into the project configuration.

Suggested semantic mapping:

```js
const sdiaTheme = {
  colors: {
    sdia: {
      primary: "#0F2742",
      secondary: "#0F766E",
      secondaryHover: "#115E59",
      secondaryActive: "#0D4F4A",
      accent: "#2DD4BF",
      background: "#F8FAFC",
      surface: "#FFFFFF",
      surfaceWarm: "#F5EFE6",
      surfaceWarmBorder: "#E8D5C4",
      muted: "#E2E8F0",
      border: "#CBD5E1",
      textPrimary: "#111827",
      textSecondary: "#475569",
      textInverse: "#FFFFFF",
      focus: "#0F766E",
      success: "#16A34A",
      successLight: "#DCFCE7",
      info: "#2563EB",
      infoLight: "#DBEAFE",
      warning: "#F59E0B",
      warningLight: "#FEF3C7",
      danger: "#DC2626",
      dangerLight: "#FEE2E2"
    }
  },
  borderRadius: {
    sdiaSm: "12px",
    sdiaMd: "16px",
    sdiaLg: "20px",
    sdiaXl: "24px"
  },
  boxShadow: {
    sdiaSoft: "0 12px 30px rgba(15, 39, 66, 0.08)",
    sdiaFocus: "0 0 0 3px rgba(15, 118, 110, 0.35)"
  },
  transitionTimingFunction: {
    sdia: "ease"
  },
  transitionDuration: {
    sdia: "200ms"
  }
};

export default sdiaTheme;
```

---

## 14. Report Design Guidance

Generated reports should use the same theme principles.

Recommended report usage:

- Cover title: Trust Navy
- Section headings: Trust Navy
- Key actions: Guardian Teal
- Educational callouts: Family Sand background with Warm Sand Border
- Positive findings: Safe Green with `✓` icon and text label
- Medium-risk findings: Care Amber with `!` icon and text label
- High-risk findings: Coral Red with `✕` icon and text label
- Explanatory notes: Info Blue with `i` icon and text label
- Banners: light semantic background with solid semantic accent border

Reports should avoid fear-based design. A high-risk section should be direct but supportive.

Example high-risk wording:

> This information may make it easier for someone to guess personal details about you. Review it with your family and consider removing or limiting visibility.

Generated reports must remain understandable in grayscale. Do not rely on color-only risk communication.

---

## 15. GitHub Pages / Landing Page Direction

The public landing page should communicate trust and educational purpose immediately.

Recommended hero structure:

- Headline: clear, calm, and protective
- Subheadline: explain self-audit and family accompaniment
- Primary CTA: Guardian Teal
- Secondary CTA: outline button using Trust Navy
- Background: Soft Cloud
- Educational panel: Family Sand
- Focus-visible styles for all keyboard navigation

Example visual hierarchy:

1. Trust Navy headline
2. Slate Gray explanatory paragraph
3. Guardian Teal CTA
4. White cards with soft shadows
5. Mint accents for learning highlights
6. Semantic state cards with icon + text + color

---

## 16. Dark Mode Strategy

Dark mode is **planned for v1.1** and is not part of the v1.0.1 baseline implementation.

However, the theme should be structured so dark mode can be added without rewriting components.

Tokens that will require dark-mode variants:

- `--sdia-background`
- `--sdia-surface`
- `--sdia-surface-warm`
- `--sdia-surface-warm-border`
- `--sdia-text-primary`
- `--sdia-text-secondary`
- `--sdia-border`
- `--sdia-muted`
- `--sdia-overlay`
- Semantic light tokens:
  - `--sdia-success-light`
  - `--sdia-info-light`
  - `--sdia-warning-light`
  - `--sdia-danger-light`

Implementation flag:

```text
Dark mode: planned for v1.1 — do not hardcode light-only colors in components.
```

Recommended implementation approach for future dark mode:

```css
:root {
  color-scheme: light;
}

[data-theme="dark"] {
  color-scheme: dark;
  /* Dark-mode token overrides will be defined in v1.1 */
}
```

---

## 17. Design Do and Do Not

### Do

- Use calm colors and clear hierarchy.
- Design for minors and adults at the same time.
- Explain risk in plain language.
- Use warm surfaces for family guidance.
- Pair risk colors with icons and labels.
- Keep the interface spacious and readable.
- Use visible focus rings for all interactive elements.
- Use light semantic tokens for banners and full-width alerts.
- Test critical color combinations before release.

### Do Not

- Use dark hacker aesthetics as the main identity.
- Use red as a brand color.
- Shame the user for findings.
- Make the experience feel like parental spying.
- Use overly childish illustrations.
- Depend on color alone to explain risk.
- Use Learning Mint as body text on light backgrounds.
- Remove outlines without providing an accessible replacement.
- Hardcode light-only colors in components if dark mode is planned.

---

## 18. Initial Implementation Checklist

Before applying the theme to production UI, validate:

- [ ] CSS variables are defined globally.
- [ ] Tailwind or design token mapping is configured if applicable.
- [ ] Primary and secondary buttons are visually distinct.
- [ ] Button states include default, hover, active, focus-visible, disabled, and loading.
- [ ] Risk colors include icons/shapes and text labels.
- [ ] Forms include accessible labels and helper text.
- [ ] Focus states are visible for all interactive elements.
- [ ] Report templates use the same color system.
- [ ] High-risk messaging is supportive and actionable.
- [ ] The interface does not resemble surveillance software.
- [ ] The design remains readable on mobile devices.
- [ ] Learning Mint is not used as body text on light backgrounds.
- [ ] Semantic banners use light semantic backgrounds.
- [ ] Warm family cards use `--sdia-surface-warm-border`.
- [ ] Components do not hardcode colors that would block future dark mode.

---

## 19. Verified Contrast Guidance

The following combinations are recommended as baseline-safe usage patterns. Final UI implementation should still be validated in context, especially when opacity, gradients, shadows, or overlays are introduced.

| Foreground | Background | Intended Use | Guidance |
|---|---|---|---|
| `--sdia-text-primary` | `--sdia-background` | Body text | Recommended |
| `--sdia-text-primary` | `--sdia-surface` | Body text | Recommended |
| `--sdia-text-primary` | `--sdia-surface-warm` | Body text | Recommended |
| `--sdia-text-inverse` | `--sdia-primary` | Header/nav text | Recommended |
| `--sdia-text-inverse` | `--sdia-secondary` | Primary button text | Recommended |
| `--sdia-accent` | `--sdia-surface` | Body text | Not recommended |
| `--sdia-accent` | `--sdia-background` | Body text | Not recommended |
| `--sdia-warning` | `--sdia-surface` | Body text | Not recommended for normal text; use icon/border/accent instead |
| `--sdia-danger` | `--sdia-danger-light` | Alert emphasis | Recommended with text label and icon |
| `--sdia-success` | `--sdia-success-light` | Success emphasis | Recommended with text label and icon |
| `--sdia-info` | `--sdia-info-light` | Info emphasis | Recommended with text label and icon |

---

## 20. Responsive Typography and Breakpoint Notes

Responsive typography tokens are not required for the baseline, but the following conventions are recommended:

```text
Mobile first: design from small screens upward.
Small screens: prioritize short labels and step-by-step flows.
Tablet/Desktop: use cards and side panels for educational explanations.
Reports: preserve readability in both digital and printed formats.
```

Future token candidates:

```css
--sdia-text-xs: 0.75rem;
--sdia-text-sm: 0.875rem;
--sdia-text-base: 1rem;
--sdia-text-lg: 1.125rem;
--sdia-text-xl: 1.25rem;
--sdia-text-2xl: 1.5rem;
--sdia-text-3xl: 1.875rem;
```

---

## 21. Versioning

This document should be versioned as part of the repository documentation.

Suggested versioning policy:

- Patch version: minor wording, accessibility refinements, or token documentation updates.
- Minor version: new tokens, new report styles, new UI components, dark mode token additions.
- Major version: brand direction change or replacement of the core palette.

Current version:

```text
1.0.1 — Guardian Teal & Trust Navy baseline theme with accessibility refinements
```
Rationale:

- The theme is a cross-cutting design reference, not only a frontend implementation file.
- It applies to the frontend, generated reports, documentation, and future product assets.
- Keeping it under `docs/design/` separates visual identity from functional specifications.

---

## 23. Ownership

Recommended owner:

```text
Project Maintainer / Product Design Owner
```

Recommended reviewers:

- Frontend owner
- Report generation owner
- Security/privacy reviewer
- Documentation owner
- Accessibility reviewer

---

## 24. Summary

**Guardian Teal & Trust Navy** gives SDIA a visual identity that is trustworthy, protective, educational, humane, and accessible.

It supports the project’s ethical positioning by avoiding fear-based cybersecurity aesthetics and reinforcing a calm self-audit experience for minors and families.

The v1.0.1 update strengthens the theme by adding accessibility-critical interaction tokens, semantic light backgrounds, non-color risk differentiation, and implementation guidance for future dark mode support.
