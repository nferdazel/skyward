# Skyward AI Handover

Last verified against code on 2026-06-09.

## Current shape

Skyward is a Flutter airline-tycoon sim with:
- feature-first structure
- Cubit-owned app state
- Supabase/Postgres as the authoritative backend
- simulation-driven reloads through `SimulationReactiveMixin`
- a shared cockpit-style design system built from `AppTheme`, `AppTypography`, `AppSpacing`, `AppStrings`, and shared presentation widgets

## Composition root

`DashboardScreen` creates the active runtime graph:
- `NavigationCubit`
- `SimulationCubit`
- `FleetCubit`
- `RoutesCubit`
- `FinanceCubit`
- `LeaderboardCubit`
- `LazyTabCubit`
- `BlueprintPlannerFormCubit`
- `SettingsCubit` is provided in `main.dart` at app level

`SimulationCubit` is the central backend-reconciliation source.
Other feature cubits subscribe through `SimulationReactiveMixin`.
`FinanceCubit` and `LeaderboardCubit` are initialized lazily when their
workspaces are first opened.

## Backend truth

Flutter does not calculate authoritative economy outcomes.
The client displays backend results and sends user commands.

Important backend responsibilities:
- auth/session validation
- shared season-clock ticking
- actor simulation reconciliation
- aircraft purchase/lease/repair
- route creation and updates
- leaderboard payloads and competitor insights
- ledger/history reads

See:
- [03_supabase_contract_map.md](03_supabase_contract_map.md)
- [04_database_design.md](04_database_design.md)
- [../README.md](../README.md)

Security migration note:
- Security Phase 1 adds `users.auth_user_id` plus shared username/email helper
  functions as the foundation for the planned Supabase Auth cutover.
- Security Phase 2 adds an `auth.users` bootstrap trigger and a server-side
  username registration surface that creates auto-confirmed synthetic-email
  auth identities.
- Security Phase 3 switches the Flutter auth flow to Supabase Auth sessions,
  while preserving the username-only UX through synthetic emails.
- Security Phase 4 starts moving client-facing gameplay RPCs onto auth-bound
  wrappers that resolve the player row from `auth.uid()` instead of trusting
  `p_user_id` from the client.
- Security Phase 5 enables RLS on the app-facing read surface, converts the
  auth-bound wrappers to security-definer execution, and retires client access
  to the legacy custom-session RPCs.
- Security Phase 6 removes the legacy custom-session database functions and the
  `sessions` table entirely.

## Current time authority

Production game time is backend-owned:
- `season_clock.current_game_time` is the shared season time
- `users.game_current_time` and `ai_competitors.game_current_time` are actor
  progress cursors
- `process_world_tick()` advances the season and actors
- `process_simulation_delta()` is a Flutter compatibility reconciliation RPC
- production Flutter does not locally advance game time

## UI state of the repo

Recent work tightened:
- typography scale
- spacing rhythm
- table/card/dialog consistency
- shared copy centralization
- medium-width responsiveness on dense operational screens
- scheduled maintenance slot previews and backend wear recovery rules
- route blueprinting now uses an interactive tile-backed world map with live network overlays
- route assignment and schedule validation now enforce range and weekly flight
  physics at the backend boundary
- cabin seat configuration now affects effective passenger capacity in both
  player and bot simulation
- players can now dispose of idle aircraft through sale or lease termination
- a private owner/operator optimizer RPC now exists for SQL-side route planning
- dashboard/fleet/routes tab content now lazy-loads through `LazyTabCubit`
- debug builds now emit lightweight `[PERF]` logs for load/reload auditing

Leaderboard sorting was intentionally removed.
Rankings now always default to net worth order.

## Docs and migrations

Project records now live in:
- `docs_and_migrations/docs/`
- `docs_and_migrations/migrations/`
- `docs_and_migrations/README.md`

Apply SQL migrations from `migrations/` in numeric order.
Treat docs in `docs/` as the current maintenance record.

## Quality baseline

Local verification target:
- `flutter analyze`
- `flutter test`

Live backend verification target:
- `get_world_tick_guardrail_report()`
- `get_database_size_report()`
- `get_table_size_report()`

Do not treat handoff docs as the source of current live numbers. Re-run the SQL
audits when you need real operational state.

## Maintenance priorities

1. Fix real UI/runtime issues as they appear during live use.
2. Keep docs aligned with the code, not with old plans.
3. Preserve Cubit-only app state boundaries.
4. Avoid reintroducing blocking loaders where silent refresh is enough.
5. Keep lazy workspace initialization and reload throttling aligned with docs.
6. Keep reset, simulation, and repair behavior aligned across Flutter and SQL.
7. Keep Phase 9 isolated: deterministic daily simulation changes economy
   semantics and should not be bundled with UI or docs work.
8. Keep validating the compaction audit RPCs before any live maintenance runs.
9. Next backend policy step is Phase 16 foundation: player activity tracking,
   simulation status, and inactive-player audit/reporting.
10. Finance now separates current balance-sheet state from rolling 30-day ledger
   analytics. The backend contract for both human players and bots is
   `get_finance_snapshot()`.
11. Security hardening is now an active backend track. Do not add new client
    RPCs that trust caller-supplied `p_user_id`; future work will bind gameplay
    access to `auth.uid()` and RLS.
