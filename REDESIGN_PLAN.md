# SKYWARD Big-Bang UI/UX Redesign — Implementation Plan

**Date:** 2026-06-09
**Status:** COMPLETED
**Approach:** Single-pass (big bang), UI implementation first
**Scope:** Complete visual redesign per Master UI/UX Redesign Prompt v2

---

## Executive Summary

This plan covered a complete visual transformation of the Skyward Flutter application. The redesign preserves the existing architecture (Cubit-only state, Supabase backend, feature-first modules) while elevating the visual system to match the authoritative design tokens specified in the Master Redesign Prompt.

**Key decisions:**
- Dark-only mode (keep static getters, no Theme.of(context) refactor)
- Global spacing token rename across 1242+ usage sites
- World map integration for Routes view (flutter_map)
- Extract _OverviewSnapshot to separate file
- 4px border-radius on all containers (max 6px for badges)
- IBM Plex Sans throughout, tactical labeling language

---

## Phase 1: Design System Foundation — COMPLETED

### 1.1 `lib/core/theme/skyward_colors.dart`

Added new tokens:
- `darkAccentSubtle` = `#1F3A5F`
- `darkGreenSubtle` = `#1A3A23`
- `darkRedSubtle` = `#3D1F1F`
- `darkAmberSubtle` = `#3D2F0F`
- `darkNeutral` = `#6E7681`
- Light-mode equivalents for all new tokens

### 1.2 `lib/core/theme/app_theme_colors.dart`

Added new fields: `successSubtle`, `dangerSubtle`, `warningSubtle`, `neutral`, `border`, `borderSubtle`, `surfaceRaised`

Updated `copyWith()`, `lerp()`, and factory constructors.

### 1.3 `lib/core/theme/app_theme.dart`

Added static getters: `accentSubtle`, `border`, `borderSubtle`, `surfaceRaised`, `successSubtle`, `dangerSubtle`, `warningSubtle`, `neutral`

Updated component themes to use `BorderRadius.circular(4)`.

### 1.4 `lib/presentation/theme/app_spacing.dart`

Global rename completed:
- `xxs` → `xs` (4.0)
- `xs` → `sm` (6.0)
- `sm` → `md` (10.0)
- `md` → `lg` (14.0)
- `lg` → `xl` (16.0)
- `xl` → `xxl` (20.0)
- `xxl` → `xxxl` (24.0)

Semantic tokens unchanged: `pagePadding`, `cardPadding`, `sectionGap`, `blockGap`, `compactGap`, `microGap`, `tabContentGap`

### 1.5 `lib/presentation/theme/app_typography.dart`

Added new styles: `microLabel` (11px), `hudValue` (13px w700), `dataEmphasis` (16px w700), `largeKpi` (22px w700)

Fixed `buttonText` to use `AppTheme.primary`.

---

## Phase 2: Shared Component Primitives — COMPLETED

### 2.1 Widgets Updated (10)

All widgets now use `BorderRadius.circular(4)`:
- `AppCard` — added borderRadius, ClipRRect fallback for non-uniform custom borders
- `AppButton` — radius added to decoration + InkWell
- `AppDialogShell` — radius on `RoundedRectangleBorder`
- `AppBadge` — radius added to decoration
- `AppSnackBar` — `BorderRadius.circular(4)` replacing `.zero`
- `AppDropdownField` — radius added to decoration
- `AppMultiSelectField` — radius on trigger decoration
- `AppTableIconAction` — radius on decoration + InkWell
- `AppInfoStrip` — radius added to decoration
- `SearchableAirportDropdown` — radius on popup + IATA badge

### 2.2 Widgets Unchanged (12)

No container changes needed: `AppControlLabel`, `AppEmptyState`, `AppLabeledValue`, `AppSectionHeader`, `AppStatText`, `AppTableHeaderCell`, `AppTableBodyCell`, `AppTableShell`, `PulseDot`, `ResponsiveLayout`, `TerminalLoader`, `TickerTape`

---

## Phase 3: Desktop Shell Layout — COMPLETED

### 3.1 Ticker Tape
- Height: 28px
- Scrolling animation with `AnimationController`
- UPPERCASE text, 11px, medium weight, letter-spacing +0.06em
- Background: `accent`, text: `bg`

### 3.2 Dashboard Sidebar
- Width: 220px fixed (removed uiScale dependency)
- Section grouping: OPERATIONS, ANALYTICS, SYSTEM
- Icon + label nav items
- Active state: `accentSubtle` background, `accent` left border (3px)
- "SKYWARD" text logo at top

### 3.3 Top HUD
- Height: 44px (removed uiScale dependency)
- Pipe separators between items
- UPPERCASE labels

### 3.4 Dashboard Screen
- Desktop layout dimensions updated to match new spec
- Ticker 28px + sidebar 220px + HUD 44px + content

---

## Phase 4: Screen Redesigns — COMPLETED

### 4.1 Auth Screen
- Centered 420px column, "SKYWARD" wordmark
- Tab switcher: LOGIN / REGISTER
- Full-width primary button

### 4.2 Overview Tab
- Extracted `_OverviewSnapshot` to `lib/features/dashboard/domain/overview_snapshot.dart`
- 3-region layout: identity+cash, health KPIs, risk signals/quick actions

### 4.3 Fleet View
- Table headers updated with `surfaceRaised` background
- Condition cell uses `LinearProgressIndicator` (was manual Container)

### 4.4 Routes View
- Table headers updated with `surfaceRaised` background
- Map removed from flight connections tab (available in `route_network_map.dart` if needed)

### 4.5 Finance View
- Ledger table header updated with `surfaceRaised` background

### 4.6 Leaderboard View
- Rankings table header updated with `surfaceRaised` background

### 4.7 Settings View
- Credentials and danger zone cards updated to use `borderSubtle` background

---

## Phase 5: Feature-Specific Widgets — COMPLETED

### 5.1 Route Network Map
- Uses flutter_map with dark basemap tiles (CartoDB dark matter)
- Route arcs in `accent` color
- Airport markers with labels

### 5.2 Leaderboard UI Elements
- `RankCell`, `AIBadge` — updated spacing tokens

---

## Verification

```bash
flutter analyze  # No issues found
flutter test     # 48/48 tests passed
```

Post-implementation:
- Visual review at 950px breakpoint (desktop)
- Visual review at 375px (mobile)
- Runtime error: TickerTape `clipBehavior` fix (Container requires decoration with clipBehavior)
- Runtime error: AppCard non-uniform border fix (ClipRRect fallback)

---

*Plan created: 2026-06-09*
*Completed: 2026-06-09*
*Source: Master UI/UX Redesign Prompt v2*
