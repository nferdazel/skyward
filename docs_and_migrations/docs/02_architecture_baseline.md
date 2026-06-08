# Skyward Architecture Baseline

Last verified against code on 2026-06-07.

## Application model

Skyward is a single-user airline-tycoon simulation with a Flutter frontend and a Supabase/Postgres backend.

The Flutter app is responsible for:
- authentication flow and local session token storage
- dashboard shell and navigation
- rendering fleet, routes, finance, leaderboard, and settings surfaces
- dispatching user actions to Cubits

The backend is responsible for:
- authoritative economy and simulation outcomes
- transactional validation
- leaderboard payloads
- competitor insights
- player operational-status transitions for failure and recovery pressure

The Phase 2 world-clock foundation is present through `season_clock`, Phase 3
adds scheduler-safe world-tick RPCs plus `world_tick_log`, Phase 4 wires a
pg_cron job to advance the season clock every minute, and Phase 5 synchronizes
player/bot actor rows to the shared season time. Actor fields
(`users.game_current_time` and `ai_competitors.game_current_time`) are retained
as progress cursors, but the shared season clock is now the source of elapsed
game time. New actors join at the active season time.

## State management

App state is Cubit-owned.

Current runtime cubits:
- `AuthCubit`
- `NavigationCubit`
- `SimulationCubit`
- `FleetCubit`
- `RoutesCubit`
- `FinanceCubit`
- `LeaderboardCubit`
- `SettingsCubit`

Allowed local widget state is limited to widget lifecycle concerns such as:
- `TextEditingController`
- `FocusNode`
- dialog-local control composition

## Reactive flow

`SimulationCubit` calls the compatibility sync RPC and reads actor state. It is
not a time authority. Production game time is not locally advanced; it is
reflected from Supabase realtime updates and periodic backend reconciliation.

Feature cubits react to simulation sync completion through `SimulationReactiveMixin`.
They do not reference one another directly.

The UI now also uses a hybrid Supabase Realtime reflection layer:
- `SimulationCubit` listens to `users`
- `FleetCubit` listens to `user_fleet`
- `RoutesCubit` listens to `user_routes` and `user_fleet`
- `FinanceCubit` listens to `financial_ledger`
- `LeaderboardCubit` listens to `ai_competitors`

Realtime is used to reflect database writes into Cubit state faster.
It does not replace authoritative SQL simulation or periodic reconciliation.

## UI system

The shared UI system is anchored by:
- `AppTheme`
- `AppTypography`
- `AppSpacing`
- `AppStrings`

Shared widget primitives now cover:
- cards
- buttons
- badges
- dialogs
- empty states
- table shells and cells
- compact table actions
- control labels and dropdowns
- stat text / info strips / labeled values

## Feature notes

### Fleet
- active fleet management
- acquisition market
- repairs
- seat configuration

### Routes
- route creation
- fare and schedule updates
- aircraft assignment
- route retirement
- maintenance-slot previewing for schedule pressure before commit
- interactive world-map network preview with live route and planned-route overlays

### Finance
- ledger reads
- category analytics
- executive summaries
- runway / burn-mix / coverage signals
- daily operating snapshots and pressure-oriented cash diagnostics

### Leaderboard
- net-worth-based global ranking
- competitor intelligence panels
- live backend status and doctrine summaries for bot competitors
- no client-side sorting controls

### Overview
- multi-cubit operational dashboard
- action queue for grounded fleet / route pressure / runway risk
- competitor watch and finance watch rollups
- player operational-status, distress streak, and recovery streak guidance

### AI competitors
- backend-controlled simulation and decision loop
- archetype-shaped fleet seeding and route deployment
- doctrine-driven route retuning, contribution-based distress cutbacks, and paid grounded-aircraft recovery

### Settings
- airline profile / HQ / safety threshold
- UI scale
- airline reset flow
