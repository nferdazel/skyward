# Skyward

Skyward is a Flutter airline-tycoon simulation with a Supabase/Postgres backend.
The app handles UI, local session flow, and command dispatch. The backend owns
authoritative simulation, economy, world time, and operational validation.

## Current shape

- Flutter frontend with feature-first modules
- Cubit-only app state
- Supabase-backed auth, simulation, finance, routes, fleet, and leaderboard
- backend-owned world clock through `season_clock`
- human and bot actors sharing the same authoritative simulation rules

## Core features

- fleet acquisition, repair, seat configuration, and disposal
- route planning, pricing, assignment, and schedule management
- finance snapshots plus rolling ledger analytics
- AI competitor leaderboard with Intel panel
- backend world-tick simulation and actor reconciliation
- owner/operator SQL tools for private admin use
- dark tactical operations console UI with 4px border-radius design system

## Architecture

- `DashboardScreen` is the runtime composition root
- `SimulationCubit` is the central reconciliation source
- `LazyTabCubit` owns workspace lazy-load state for dashboard, fleet, and routes
- `FleetCubit`, `RoutesCubit`, `FinanceCubit`, and `LeaderboardCubit` react
  through `SimulationReactiveMixin`, but finance and leaderboard are lazy-init
  surfaces
- production Flutter observes backend time; it does not locally advance
  authoritative game time
- debug builds expose lightweight `[PERF]` instrumentation for load/reload audits

Desktop shell layout:
- ticker tape (28px scrolling operational broadcast)
- sidebar (220px fixed width, icon+label nav with section grouping)
- HUD bar (44px with pipe separators)
- main content workspace via `IndexedStack`

For the maintained backend/runtime record, use:
- [docs_and_migrations/README.md](docs_and_migrations/README.md)
- [docs_and_migrations/docs/01_ai_handover.md](docs_and_migrations/docs/01_ai_handover.md)
- [docs_and_migrations/docs/03_supabase_contract_map.md](docs_and_migrations/docs/03_supabase_contract_map.md)

## Local setup

### Prerequisites

- Flutter SDK
- a Supabase project, or placeholder credentials for dev-mode mock data

### Install

```bash
flutter pub get
```

### Configure Supabase

Create local env config:

```bash
cp .env.example .env
dart run build_runner build
```

Required variables:

- `SUPABASE_URL`
- `SUPABASE_KEY`

If placeholder values remain, the app falls back to dev mode with mock data.

### Database setup

Apply SQL migrations in numeric order from:

- `docs_and_migrations/migrations/`

### Run

```bash
flutter run
```

### Verify

```bash
flutter analyze
flutter test
```

## Deployment

Production web deployment is prepared for Vercel.

Required GitHub secrets:

- `VERCEL_TOKEN`
- `VERCEL_ORG_ID`
- `VERCEL_PROJECT_ID`
- `SUPABASE_URL`
- `SUPABASE_KEY`

## Repo guide

- `lib/`: Flutter application code
- `docs_and_migrations/`: maintained SQL and backend/runtime docs
- `data/`: catalog replenishment workflow and curated data artifacts
- `test/`: unit, widget, integration, and database-oriented test layers

## License

[MIT License](LICENSE)
