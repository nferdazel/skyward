# Skyward Docs And Migrations

Last verified on 2026-06-09.

This folder is the maintenance record for Skyward's Supabase-backed runtime.
Use it as an operator guide, not as a chronological diary.

## Start Here

If you only open four files, open these:

1. [01_ai_handover.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/01_ai_handover.md)
2. [03_supabase_contract_map.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/03_supabase_contract_map.md)
3. [04_database_design.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/04_database_design.md)
4. [07_live_backend_audit_queries.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/07_live_backend_audit_queries.md)

## Current Runtime State

Backend/runtime milestones already in place:
- shared season-clock world time
- deterministic daily simulation segmentation
- realtime UI reflection for `users`, `user_fleet`, `user_routes`, and `financial_ledger`
- finance snapshot RPC and retention/compaction audit surfaces
- owner/operator optimizer tooling
- Supabase Auth username-only flow via synthetic emails
- auth-bound gameplay RPC wrappers
- RLS on the app-facing read surface
- removal of the legacy custom-session auth system

Current major next step:
- Phase 16 foundation: player activity tracking and inactive-player policy

## How To Use This Folder

Use docs by question:
- "What is the app/backend shape right now?"
  Open [01_ai_handover.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/01_ai_handover.md)
- "What RPCs or direct table reads does Flutter rely on?"
  Open [03_supabase_contract_map.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/03_supabase_contract_map.md)
- "What is the current database/security model?"
  Open [04_database_design.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/04_database_design.md)
- "How do I troubleshoot suspicious simulation behavior?"
  Open [06_simulation_troubleshooting.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/06_simulation_troubleshooting.md)
- "What SQL should I run against live Supabase?"
  Open [07_live_backend_audit_queries.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/07_live_backend_audit_queries.md)
- "How does the private owner/operator optimizer work?"
  Open [08_owner_operator_tools.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/08_owner_operator_tools.md)

## Documentation Set

Core maintenance docs:
- `docs/01_ai_handover.md`
- `docs/02_architecture_baseline.md`
- `docs/03_supabase_contract_map.md`
- `docs/04_database_design.md`

Operational/reference docs:
- `docs/06_simulation_troubleshooting.md`
- `docs/07_live_backend_audit_queries.md`
- `docs/08_owner_operator_tools.md`

## Migration Bands

Apply migrations in numeric order.

High-level grouping:
- `01`-`18`
  Foundation schema, legacy auth, economy, reset, bots, maintenance
- `19`-`24`
  Regression audits and bot hardening
- `25`-`37`
  Realtime, balancing, replenishment, leaderboard fixes, offline-anchor fix,
  RPC write-boundary work
- `38`-`45`
  Season clock, scheduler, actor tick, world guardrails, deterministic daily simulation
- `46`-`61`
  Capacity/retention audits, compaction foundations, finance snapshot,
  route/cabin hardening, fleet disposal, owner/operator optimizer
- `62`-`68`
  Security hardening: Supabase Auth identity, auth bootstrap, RPC auth binding,
  RLS, and legacy custom-session removal

## Current Time Authority

Supabase owns production game time.

- `season_clock.current_game_time` is the shared season time
- `users.game_current_time` and `ai_competitors.game_current_time` are actor progress cursors
- `process_world_tick()` advances the season and actors
- Flutter observes backend time through realtime and `process_simulation_delta()`
- production Flutter does not locally advance game time

## Standard Verification

```bash
flutter analyze
flutter test
```

## Standard Live Checks

```sql
select *
from get_world_tick_guardrail_report();
```

```sql
select *
from get_database_size_report();
```

```sql
select *
from get_table_size_report()
limit 20;
```

```sql
select *
from get_world_tick_log_compaction_report();
```

```sql
select *
from get_financial_ledger_compaction_report();
```
