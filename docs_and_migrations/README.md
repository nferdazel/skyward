# Skyward Docs And Migrations

Last verified on 2026-06-09.

This folder is the maintenance record for Skyward's Supabase-backed runtime.

## How To Use This Folder

1. Apply SQL migrations in numeric order from `migrations/`.
2. Use `docs/01_ai_handover.md` for current project state before making changes.
3. Use `docs/03_supabase_contract_map.md` before changing Flutter-to-Supabase flows.
4. Use `docs/07_live_backend_audit_queries.md` for live Supabase checks.

## Current Runtime Status

Completed world-time phases:
- Phase 1: RPC write boundary
- Phase 2: season clock foundation
- Phase 3: world tick RPC foundation
- Phase 4: scheduler wiring
- Phase 4.1: scheduler health permission fix
- Phase 5: world actor tick foundation
- Phase 5.1: actor tick bootstrap fix
- Phase 6: Flutter observes backend world time
- Phase 7: live soak audit
- Phase 8: legacy time cleanup
- Phase 9: deterministic daily simulation engine
- Phase 10-lite: realtime refresh hardening
- Phase 11-lite: world-time guardrail report
- Phase 12: database size audit RPCs
- Phase 13: retention policy config foundation
- Phase 14: world-tick log compaction dry-run foundation
- Phase 15: financial ledger compaction dry-run foundation
- Phase 15.1: route contract and cabin-capacity hardening
- Phase 15.2: fleet disposal and owner operator tools
- Phase 15.2.1: owner optimizer hardening and refinement

Phase 9 implementation note:
- existing economy formulas are preserved as segment processors
- player and bot catch-up now runs through deterministic game-day boundaries
- multi-day catch-up can flush ledger/streak effects per crossed game day

Current next major backend step:
- Phase 16 foundation: player activity tracking and inactive-player policy
- Security Phase 1 foundation: Supabase Auth identity linkage ahead of the
  username-only auth cutover and RLS hardening
- Security Phase 2 bootstrap: auth.users to public.users trigger plus
  server-side username registration using synthetic auth emails

## Documentation Index

- `docs/01_ai_handover.md`: current handoff and maintenance priorities
- `docs/02_architecture_baseline.md`: Flutter/backend architecture baseline
- `docs/03_supabase_contract_map.md`: active RPC and table-read contracts
- `docs/04_database_design.md`: high-level database design and phase history
- `docs/05_enforcement_backlog.md`: enforcement priorities and docs index
- `docs/06_simulation_troubleshooting.md`: simulation debugging notes
- `docs/07_live_backend_audit_queries.md`: live Supabase audit queries
- `docs/08_owner_operator_tools.md`: private owner/operator SQL surfaces

## Migration Bands

- `01`-`18`: initial schema, auth, economy, reset, bots, maintenance
- `19`-`24`: regression audits and bot hardening
- `25`-`35`: realtime, balancing, replenishment, leaderboard fixes
- `36`-`37`: offline-anchor fix and RPC write boundary
- `38`-`45`: world-clock foundation, scheduler, actor ticks, guardrails,
  deterministic daily segmentation
- `46`: database size reporting and retention policy foundation
- `47`-`61`: table-size permission hardening, world-tick and ledger compaction foundations, finance snapshot RPC, route/cabin contract hardening, fleet disposal/operator tooling, and owner-optimizer hardening/refinement
- `62+`: security hardening, Supabase Auth identity foundation, auth bootstrap trigger/server registration, planned RLS rollout, and gameplay RPC auth binding

## Current Time Authority

Supabase owns production game time.

- `season_clock.current_game_time` is the shared season time.
- `users.game_current_time` and `ai_competitors.game_current_time` are actor
  progress cursors.
- `process_world_tick()` advances the season and actors.
- Flutter observes backend time through realtime and `process_simulation_delta()`
  compatibility reconciliation.
- Production Flutter does not locally advance game time.

## Standard Verification

```bash
flutter analyze
flutter test
```

## Standard Live Checks

World-clock guardrail:

```sql
select *
from get_world_tick_guardrail_report();
```

Database capacity:

```sql
select *
from get_database_size_report();
```

```sql
select *
from get_table_size_report()
limit 20;
```

World-tick log compaction audit:

```sql
select *
from get_world_tick_log_compaction_report();
```

Ledger compaction audit:

```sql
select *
from get_financial_ledger_compaction_report();
```
