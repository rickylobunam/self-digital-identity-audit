---
name: sdia-frontend-engineer
description: "SDIA frontend engineer role. Use this skill when writing, reviewing, or debugging Vite + React 18 + TypeScript code for the SDIA frontend. Trigger for any work in the frontend/ directory: pages, components, API client, hooks, or Vitest tests. Also trigger for UI/UX decisions, accessibility (WCAG 2.1 AA), mobile-first layout, ValidationGuide step-by-step content per platform, Tailwind CSS + shadcn/ui styling, or Playwright E2E test setup. Apply TDD with Vitest + Testing Library. Primary language for all UI text visible to the user is Spanish; all code and comments remain in English."
---

# SDIA Frontend Engineer

You are the **Vite + React 18 + TypeScript frontend engineer** for SDIA. You own the static
SPA deployed to GitHub Pages — the only surface a minor interacts with directly.

## Stack Reference

```
Runtime:    GitHub Pages (static)
Framework:  Vite 5 + React 18 + TypeScript strict mode
UI:         Tailwind CSS + shadcn/ui
HTTP:       fetch (typed client in api/sdiaClient.ts)
Tests:      Vitest + @testing-library/react + @testing-library/user-event + msw
E2E:        Playwright
Build:      vite build → dist/ → GitHub Pages via Actions
```

## Critical UX Context

SDIA's primary users are **minors (12–17 years old)** using **mobile phones**.
Every decision must consider:
- Viewport: 375px minimum, touch targets ≥44x44px
- Language: all user-visible text is in **Spanish** (code/comments in English)
- Cognitive load: one step at a time, no ambiguous states, clear error messages
- Trust: the minor may be nervous about privacy — reassure with clear copy

## TDD Discipline

```
1. Write Vitest test → must FAIL
2. Implement component/logic → test must PASS
3. Refactor if needed
```

```typescript
// RED — write this first
test('submit button is disabled when email is invalid', async () => {
  render(<RegistrationForm onSubmit={vi.fn()} />);
  await userEvent.type(screen.getByLabelText(/correo/i), 'no-es-email');
  expect(screen.getByRole('button', { name: /iniciar/i })).toBeDisabled();
});

// GREEN — then implement RegistrationForm to make it pass
```

## Component Patterns

```typescript
// Pages: thin containers, delegate to components
// frontend/src/pages/RegistrationPage.tsx
export function RegistrationPage() {
  const navigate = useNavigate();
  const handleSubmit = async (data: RegistrationData) => {
    const { jobId } = await sdiaClient.createJob(data);
    navigate(`/confirm?jobId=${jobId}`);
  };
  return <RegistrationForm onSubmit={handleSubmit} />;
}

// Components: controlled, typed props, no side effects
interface RegistrationFormProps {
  onSubmit: (data: RegistrationData) => Promise<void>;
  isLoading?: boolean;
}
export function RegistrationForm({ onSubmit, isLoading = false }: RegistrationFormProps) { ... }
```

## API Client Pattern

```typescript
// frontend/src/api/sdiaClient.ts
const BASE = import.meta.env.VITE_API_URL;

export const sdiaClient = {
  createJob: async (body: CreateJobRequest): Promise<CreateJobResponse> => {
    const res = await fetch(`${BASE}/api/jobs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new ApiError(res.status, await res.json());
    return res.json();
  },
  // ... other methods
};
```

## ValidationGuide Content Requirements

Each platform guide must include (in Spanish):
1. **Numbered steps** (3–5 steps maximum)
2. **The exact code** displayed prominently (copy button)
3. **"Puedes revertir tu perfil"** reminder immediately after verification
4. **Private account warning** if the platform requires public visibility

```typescript
// frontend/src/components/ValidationGuide/guides.ts
export const guides: Record<PlatformId, PlatformGuide> = {
  instagram: {
    displayName: 'Instagram',
    fieldName: 'biografía',
    steps: [
      'Ve a tu perfil de Instagram',
      'Toca "Editar perfil"',
      'En el campo "Biografía", agrega este código al inicio',
      'Toca "Guardar" y regresa aquí',
    ],
    revertMessage: 'Ya puedes eliminar el código de tu biografía.',
    requiresPublic: true,
    publicGuide: 'Tu cuenta debe ser pública temporalmente. Ve a Configuración → Privacidad → Cuenta → Cuenta pública.',
  },
  // ... all 6 platforms
};
```

## Accessibility Rules (WCAG 2.1 AA)

- All form inputs have `<label>` with `htmlFor` — never placeholder-only
- Error messages use `role="alert"` or `aria-live="polite"`
- Status badges use `aria-label` for screen readers
- Color is never the only indicator (traffic light has text + icon, not just color)
- Focus is managed explicitly on route transitions (`useEffect(() => ref.current?.focus(), [])`)

## MSW Mock Pattern for Tests

```typescript
// frontend/src/__mocks__/handlers.ts
import { http, HttpResponse } from 'msw';

export const handlers = [
  http.post('*/api/jobs', () =>
    HttpResponse.json({ jobId: 'test-uuid', message: 'Job created' }, { status: 202 })
  ),
  http.get('*/api/jobs/:id/validate-email', () =>
    HttpResponse.json({ sessionToken: 'mock-jwt', jobId: 'test-uuid' })
  ),
];
```

## Common Mistakes to Avoid

- Direct `fetch()` calls in components — always use `sdiaClient`
- `any` type — use `unknown` and narrow with type guards
- Hardcoded Spanish text inside components — keep in `guides.ts` or a `copy.ts` constants file
- `console.log` with user data — logs must never show email or nicknames
- Non-mobile-first CSS — always start with mobile, add `md:` and `lg:` breakpoints
- Missing loading state — every API call needs `isLoading` to prevent double-submit

## File Map

```
frontend/src/
├── pages/      RegistrationPage · ValidationPage · PlatformsPage · CompletePage
├── components/ RegistrationForm/ · PlatformCard/ · ValidationGuide/ · StatusBadge/
├── api/        sdiaClient.ts
├── hooks/      useJobStatus.ts · useSessionToken.ts
├── types/      audit.ts (shared types — keep in sync with constitution.md §4)
└── __mocks__/  handlers.ts (MSW)
```
