# Skyward Maintainer Standard

This document is the repo-local operating contract for anyone changing Skyward.

It supplements:
- `.commandcode/taste/taste.md` *(not in repo)*
- `.commandcode/taste/flutter/dart-code-standards/taste.md` *(not in repo)*

If this document conflicts with implementation convenience, this document wins.

## 1. Core Architecture

- State management is Cubit-only for app state.
- Supabase is the authoritative backend for game state.
- The client never simulates authoritative business outcomes; it only renders server results.
- Feature reactivity after simulation sync must use `SimulationReactiveMixin`.
- Cubit-to-cubit references are forbidden.
- Event-based communication is required across features: callbacks, streams, and `BlocListener`.

## 2. Allowed Local Widget State

`StatefulWidget` is allowed only for widget-local lifecycle concerns such as:
- `TextEditingController`
- `FocusNode`
- animation/controller disposal
- local input composition that does not own app state

It must not be used as a substitute for feature/application state.

Forbidden for app state:
- `setState`
- `ValueNotifier`
- `ChangeNotifier`
- inherited Flutter state-management patterns for business state

## 3. Code Principles

- Enforce DRY strictly. Duplicate logic is a defect.
- Enforce KISS strictly. Prefer the simplest valid design already proven in this repo.
- Decouple widgets. Keep business logic out of views.
- Do not invent new patterns where the repo already has one.
- No static mutable state anywhere.
- All magic numbers belong in `GameConstants` with doc comments.

## 4. Supabase Contract

- RPCs, triggers, and SQL constraints define the source of truth.
- Flutter views/widgets do not call Supabase directly; Cubits and data-layer helpers do.
- Backend-returned fields must be treated as contracts. Do not make silent assumptions about optional or renamed fields.
- Migration history may be broad, but current behavior must be documented from active code paths.

## 5. UI/UX Rules

- **Desktop web only.** Mobile responsive layouts have been removed. Do not add `ResponsiveLayout` or mobile-specific branches.
- Minimum window size: 1024×700.
- Minimize flicker.
- Prefer silent reloads over blocking loaders when data is already on screen.
- Avoid unnecessary page-wide loading states after small actions.
- Preserve loaded state during actions when practical.
- Use dense, operational UI aligned with the existing cockpit/dashboard language.

Use a blocking loading state only when:
- the screen has no usable prior state yet, or
- the action genuinely blocks the whole workflow

## 5a. Design System Rules

All UI code must use the design system tokens defined in the theme files.

### Colors

- Use `AppTheme.*` static const fields for all colors (e.g., `AppTheme.primary`, `AppTheme.success`)
- Use semantic variants for subtle backgrounds: `successSubtle`, `dangerSubtle`, `warningSubtle`
- Use `surfaceRaised` for elevated surfaces (table headers, raised panels)
- Use `borderSubtle` for subtle container backgrounds

### Spacing

- Use `AppSpacing.*` tokens only — never hardcode pixel values for spacing
- Available tokens: `xs` (4), `sm` (8), `md` (12), `lg` (16), `xl` (20), `xxl` (24), `xxxl` (32)
- Use semantic tokens for layout: `pagePadding`, `cardPadding`, `sectionGap`, `blockGap`

### Typography

- Use `AppTypography.*` styles for all text
- UPPERCASE labels must use `microLabel` or explicit `letterSpacing: 0.06`
- Data emphasis values use `hudValue`, `dataEmphasis`, or `largeKpi` as appropriate

### Border Radius

- All containers use `BorderRadius.circular(4)` maximum
- Badges may use `BorderRadius.circular(6)` maximum
- Never use `BorderRadius.circular(8)` or larger

### Component Overrides

- Prefer existing shared widgets (`AppCard`, `AppButton`, `AppBadge`) over custom containers
- If `AppCard` needs a non-uniform border, pass `customBorder` (ClipRRect handles the radius automatically)
- Table headers use `AppTheme.surfaceRaised` background

## 6. Change Workflow

For every non-trivial change:

1. Read the affected feature flow first.
2. Keep the edit scoped to the smallest ownership boundary that solves the problem.
3. Verify architecture compliance:
   - no widget business logic
   - no cubit-to-cubit dependency
   - no duplicated reactivity
   - no client-side authoritative simulation
4. Run:
   - `flutter analyze`
   - `flutter test`
5. Make a micro git commit with a conventional message.

## 7. Commit Rules

- Prefer micro commits.
- Use conventional commit messages such as:
  - `fix: preserve loaded state during fleet actions`
  - `refactor: extract route reload helper`
  - `docs: codify maintainer standard`
  - `test: cover simulation sync callback flow`

## 8. Documentation Rules

- Stale architecture docs are defects.
- If code behavior changes materially, update the relevant docs in the same workstream.
- Do not leave contradictory guidance in-repo when the current code is known.

## 9. Review Checklist

Every change should be reviewable against this checklist:

- Is app state still Cubit-owned?
- Did we avoid cubit-to-cubit references?
- Did we reuse `SimulationReactiveMixin` rather than rewriting reactivity?
- Did we keep Supabase authoritative?
- Did we avoid duplicated logic and unnecessary abstractions?
- Did we preserve or improve silent loading behavior?
- Did `flutter analyze` pass?
- Did `flutter test` pass?

