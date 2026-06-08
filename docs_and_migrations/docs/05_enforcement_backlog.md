# Skyward Enforcement Backlog

Last verified on 2026-06-08.

## Baseline

- `flutter analyze`: passing
- `flutter test`: passing

## Current strengths

- Feature-first structure is stable.
- App state is Cubit-owned.
- Backend world-clock reconciliation is centralized in `SimulationCubit`.
- Cross-feature sync reactivity uses `SimulationReactiveMixin`.
- Shared design-system primitives are materially stronger than before.
- Supabase owns production game time; Flutter observes it.

## Active enforcement items

### P0

- Keep [03_supabase_contract_map.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/03_supabase_contract_map.md) current when RPCs or mutable table flows change.
- Keep docs aligned with code after UI/runtime behavior changes.
- Continue fixing live UI/runtime issues as they are found during play.
- Keep Phase 9 deterministic daily simulation isolated from unrelated work.
- Validate Phase 14 world-tick compaction dry runs against live Supabase before
  allowing any non-dry-run execution.
- Validate Phase 15 ledger compaction dry runs against live Supabase before
  allowing any non-dry-run execution.

### P1

- Define Phase 16 foundation cleanly before wiring any inactive-player
  automation into world ticking.
- Keep owner/operator SQL surfaces documented as they evolve; they now have
  more operational complexity than a one-off helper RPC.
- Audit remaining feature-local styling overrides that bypass shared tokens without a good reason.
- Continue centralizing user-facing operational copy where it improves consistency.
- Review dense operational screens for any remaining avoidable interaction friction.
- Audit repeated Supabase parsing for safe extraction opportunities.
- Keep runtime perf instrumentation and lazy workspace loading documented when
  their behavior changes.
- Keep simulation wear/repair math consistent between Flutter previews and SQL truth.
- Add stronger regression coverage around compaction and owner-operator tooling.

### P2

- Keep backend flow documentation current for:
  - auth
  - simulation sync
  - leaderboard refresh
  - finance ledger refresh
  - settings/reset flows

## Current documentation set

- [../README.md](/home/sachiel/Projects/skyward/docs_and_migrations/README.md)
- [01_ai_handover.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/01_ai_handover.md)
- [02_architecture_baseline.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/02_architecture_baseline.md)
- [03_supabase_contract_map.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/03_supabase_contract_map.md)
- [04_database_design.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/04_database_design.md)
- [05_enforcement_backlog.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/05_enforcement_backlog.md)
- [06_simulation_troubleshooting.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/06_simulation_troubleshooting.md)
- [07_live_backend_audit_queries.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/07_live_backend_audit_queries.md)
- [08_owner_operator_tools.md](/home/sachiel/Projects/skyward/docs_and_migrations/docs/08_owner_operator_tools.md)

Historical planning docs that no longer matched the app were intentionally removed.
