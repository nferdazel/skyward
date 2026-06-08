# Skyward Simulation Troubleshooting

Last verified on 2026-06-07.

## Phantom ledger rows after reset

Symptom:
- `ticket_sales`, `operations`, or `aircraft_lease` rows appear after an airline reset
- cash does not move with those rows

Root cause:
- stale buffered simulation values survived reset
- a later `process_simulation_delta()` flush wrote the old buffers into `financial_ledger`

Fix:
- `17_reset_airline_buffer_cleanup.sql`
- reset now clears:
  - `buffered_revenue`
  - `buffered_ops_cost`
  - `buffered_lease_cost`
  - legacy activity anchor fields

Regression audit:
- `19_reset_simulation_regression_audit.sql`

## Scheduled maintenance slots

Authoritative logic lives in:
- `18_scheduled_maintenance_slot_system.sql`

Current behavior:
- unused weekly schedule capacity becomes maintenance hours
- maintenance hours can offset gross wear in the same simulation cycle
- grounded aircraft do not receive free recovery
- manual maintenance cost scales from the remaining condition loss

## Operational checks

When simulation behavior looks suspicious, inspect:
1. `season_clock.current_game_time`
2. `users.game_current_time` or `ai_competitors.game_current_time`
3. actor lag between the season clock and actor cursor
4. `world_tick_log.players_processed` / `world_tick_log.bots_processed`
5. buffered revenue/cost fields and assigned route/aircraft status

Fast guardrail check:

```sql
select *
from get_world_tick_guardrail_report();
```

## Recovery notes

If a reset user is already in a bad ledger state:
- clear the three buffer columns
- align `users.game_current_time` to the active `season_clock` if needed
- delete the phantom ledger rows
- or run `reset_user_airline()` again if no valid post-reset progress must be preserved
