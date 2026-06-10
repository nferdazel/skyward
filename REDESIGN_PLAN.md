# SKYWARD Big-Bang UI/UX Redesign — Implementation Plan

**Date:** 2026-06-09
**Status:** COMPLETED (v4 "Skyward Ops")
**Approach:** Single-pass (big bang), UI implementation first
**Scope:** Complete visual redesign per Master UI/UX Redesign Prompt v4

---

## Executive Summary

This plan covered a complete visual transformation of the Skyward Flutter application. The redesign preserves the existing architecture (Cubit-only state, Supabase backend, feature-first modules) while elevating the visual system to match the authoritative design tokens specified in the Master Redesign Prompt v4.

**Key decisions:**
- Dark-only mode (keep static getters, no Theme.of(context) refactor)
- Global spacing token rename across 1242+ usage sites
- World map integration for Routes view (flutter_map)
- Extract _OverviewSnapshot to separate file
- 4px border-radius on all containers (3px for badges)
- Inter for body/UI text, IBM Plex Mono for all data/labels
- 44px icon-only sidebar, 40px status bar with pill indicators
- Pulse animation on live status dots (radar ping every 2s)

---

## Phase 1: Design System Foundation — COMPLETED

### 1.1 `lib/core/theme/skyward_colors.dart`

v4 palette:
- `background` = `#0A0C0F` (near-black base)
- `surface` = `#111318` (card backgrounds)
- `surfaceRaised` = `#181C22` (raised elements)
- `success` = `#00E676` (operational green)
- `warning` = `#FFB300` (caution amber)
- `error` = `#FF3D00` (critical red)
- `info` = `#448AFF` (information blue)
- `textMuted` = `#6B7280` (muted text)
- `border` = `#3A3F4A` (borders)
- `textPrimary` = `#E6EDF3` (primary text)
- `textSecondary` = `#8B949E` (secondary text)

### 1.2 `lib/core/theme/app_theme_colors.dart`

ThemeExtension rewritten to match v4 palette.

### 1.3 `lib/core/theme/app_theme.dart`

Updated with:
- New color tokens matching v4 palette
- Inter textTheme for body text
- IBM Plex Mono for labels, headings, data
- Updated button/input themes

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

Rewritten with:
- Inter for body text (bodyLarge, bodyMedium, captionRegular, captionLight)
- IBM Plex Mono for data/labels (microLabel, badgeText, hudValue, dataEmphasis, largeKpi, telemetry, monoValue, monoLabel)

---

## Phase 2: Shared Component Primitives — COMPLETED

### 2.1 Widgets Updated (10)

All widgets now use `BorderRadius.circular(4)`:
- `AppCard` — v4 spec: #111318 bg, 0.5px border, 4px radius, header/body split
- `AppBadge` — v4 spec: 3px radius, rgba bg at 0.12 alpha, dot indicator
- `SegmentedProgressBar` — v4 spec: 3px height, 20 segments, 1px gaps
- `PulseDot` — radar ping animation (2s cycle)

### 2.2 Widgets Unchanged (12)

No container changes needed: `AppControlLabel`, `AppEmptyState`, `AppLabeledValue`, `AppSectionHeader`, `AppStatText`, `AppTableHeaderCell`, `AppTableBodyCell`, `AppTableShell`, `ResponsiveLayout`, `TerminalLoader`

---

## Phase 3: Desktop Shell Layout — COMPLETED

### 3.1 Ticker Tape
- Height: 24px (bottom position)
- Scrolling animation with `AnimationController`
- UPPERCASE text, 10px, IBM Plex Mono, letter-spacing +0.1em
- Background: `surface`, text: `textMuted`
- Top border: 0.5px

### 3.2 Dashboard Sidebar
- Width: 44px icon-only (no labels)
- Logo mark at top (28px square)
- Icons only, 32px tap targets
- Active state: `accentSubtle` background, `accent` border (0.5px)
- Logout icon at bottom (error color)

### 3.3 Status Bar (TopHud)
- Height: 40px
- Pill indicators with labels
- Monospace font for values
- Pulse dot for live status
- Pipe separators between items

### 3.4 Dashboard Screen
- Desktop layout: sidebar (44px) + status bar (40px) + content + ticker (24px)
- Ticker at bottom position

---

## Phase 4: Screen Redesigns — COMPLETED

### 4.1 Auth Screen
- Centered 420px column, "SKYWARD" wordmark
- Tab switcher: LOGIN / REGISTER
- Full-width primary button

### 4.2 Overview Tab
- Extracted `_OverviewSnapshot` to `lib/features/dashboard/domain/overview_snapshot.dart`
- 3-region layout: identity+cash, health KPIs, risk signals/quick actions
- Monospace font for metric values
- AppBadge with dot indicator for status

### 4.3 Fleet View
- Table headers updated with `surfaceRaised` background
- Tab bar: 1.5px indicator weight
- Condition cell uses `LinearProgressIndicator` (was manual Container)

### 4.4 Routes View
- Table headers updated with `surfaceRaised` background
- Map removed from flight connections tab (available in `route_network_map.dart` if needed)
- IATA boxes: 3px radius, monoLabel font
- Borders: 0.5px throughout

### 4.5 Finance View
- Ledger table header updated with `surfaceRaised` background
- Summary cards: 1.5px top border accent
- Icons: 8px padding, 4px radius

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
*Source: Master UI/UX Redesign Prompt v4*
