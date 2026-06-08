# Skyward Supabase Contract Map

Last verified against code on 2026-06-07.

This is the live Flutter-to-Supabase contract surface.

## Runtime rules

- Supabase remains the authoritative source of game state.
- Flutter does not calculate authoritative simulation or economy outcomes.
- `DevModeManager.isDevMode` bypasses these contracts with local mock data.
- Realtime subscriptions are a reflection layer for UI freshness, not a replacement for SQL/RPC authority.

## RPC surface

### Auth

`validate_session`
- caller: `AuthCubit.autoLogin()`
- params:
  - `p_token`
- expected:
  - first row contains `success`
  - on success also returns the user payload consumed by `User.fromMap`
- current behavior:
  - validates the session token without mutating simulation time state
  - leaves world-clock reconciliation to backend tick/sync RPCs

`register_company`
- caller: `AuthCubit.register()`
- params:
  - `p_username`
  - `p_password`
  - `p_company_name`
  - `p_ceo_name`
- expected:
  - first row contains `success`
  - `message` on failure

`login_company`
- caller: `AuthCubit.login()`
- params:
  - `p_username`
  - `p_password`
- expected:
  - first row contains `success`
  - `message` on failure
  - on success returns `session_token` plus the user payload for `User.fromMap`
- current behavior:
  - creates a session token without mutating simulation time state
  - leaves world-clock reconciliation to backend tick/sync RPCs

### Simulation

`process_simulation_delta`
- caller: `SimulationCubit.syncWithDatabase()`
- params:
  - `p_user_id`
- expected:
  - first row may include:
    - `elapsed_game_days`
    - `flights_run`
- current behavior:
  - compatibility sync surface for Flutter
  - ensures the active season clock is current
  - processes the player from `users.game_current_time` to
    `season_clock.current_game_time`
  - no longer drives bot simulation from the player sync path

`process_world_tick`
- caller: scheduler / manual backend audit
- params:
  - `p_season_id`
  - `p_max_ticks`
- current behavior:
  - advances `season_clock.current_game_time` under advisory and row locks
  - records each attempt in `world_tick_log`
  - synchronizes player and bot actor state to the new season game time
  - after Phase 5.1, uses qualified season references and assumes the active
    season has been bootstrapped to the existing actor frontier

`process_player_simulation_to_time`
- caller: `process_world_tick`, `process_simulation_delta`
- params:
  - `p_user_id`
  - `p_target_game_time`
- current behavior:
  - processes one player from `users.game_current_time` to the target season
    game time through deterministic game-day boundaries

`process_all_bots_simulation_to_time`
- caller: `process_world_tick`
- params:
  - `p_target_game_time`
  - `p_season_id`
- current behavior:
  - processes active bots from `ai_competitors.game_current_time` to the target
    season game time through deterministic game-day boundaries

`ensure_world_current`
- caller: command RPCs and snapshot reads
- params:
  - `p_season_id`
- current behavior:
  - wrapper around `process_world_tick`
  - brings the season clock current up to the configured tick cap

`get_world_tick_scheduler_health`
- caller: backend audit / operations checks
- params: none
- current behavior:
  - reports active season clock state
  - reports latest `world_tick_log` row
  - reports whether the `skyward_world_tick` pg_cron job exists and is active
  - runs as a narrow security-definer audit surface so client roles do not need
    direct `cron.job` access

`get_world_tick_guardrail_report`
- caller: backend audit / operations checks
- params: none
- current behavior:
  - reports active season presence
  - reports player/bot lag or ahead counts against `season_clock`
  - reports backwards successful world-tick logs
  - reports recent successful world-tick activity

`get_database_size_report`
- caller: backend audit / operations checks
- params: none
- current behavior:
  - reports current database size
  - reports configured Supabase Free quota reference
  - returns `ok`, `warn`, or `critical`

`get_table_size_report`
- caller: backend audit / operations checks
- params: none
- current behavior:
  - reports approximate row counts
  - reports table, index, and total relation sizes for public user tables
  - runs as a narrow security-definer audit surface so client roles do not need
    extension schema access

`get_finance_snapshot`
- caller: `FinanceCubit.loadLedger()`
- params:
  - `p_id`
  - `p_is_bot`
- current behavior:
  - returns current balance-sheet values (`cash`, `net_worth`)
  - returns owned-aircraft asset value and leased monthly exposure
  - returns fleet count and deployed-route footprint
  - returns rolling 30-day revenue, expense, and net values
  - supports both human players and AI competitors through one shared contract

`data_retention_policy`
- caller: backend audit / future compaction RPCs
- current behavior:
  - stores retention thresholds and capacity warning thresholds
  - does not trigger deletion by itself

`get_world_tick_log_compaction_report`
- caller: backend audit / storage-maintenance dry runs
- params: none
- current behavior:
  - reads `data_retention_policy.world_tick_log_raw_real_days`
  - groups eligible raw `world_tick_log` rows by UTC day and status
  - reports the exact buckets that `compact_world_tick_log(FALSE)` would write
    into `world_tick_daily_summary`

`compact_world_tick_log`
- caller: manual backend maintenance only
- params:
  - `p_dry_run`
- current behavior:
  - defaults to dry-run mode
  - returns the same candidate buckets as `get_world_tick_log_compaction_report`
  - when called with `FALSE`, upserts `world_tick_daily_summary` and deletes
    raw `world_tick_log` rows older than the configured retention cutoff
  - after migration `49`, uses the summary-table primary-key constraint name
    explicitly to avoid PL/pgSQL output-column ambiguity in `ON CONFLICT`
  - is intentionally not granted to anon clients

`get_financial_ledger_compaction_report`
- caller: backend audit / storage-maintenance dry runs
- params: none
- current behavior:
  - reads `data_retention_policy.player_ledger_raw_game_days`
  - reads `data_retention_policy.bot_ledger_raw_game_days`
  - groups eligible raw `financial_ledger` rows by actor, UTC game date, month,
    transaction type, and category
  - uses actor-relative `game_current_time` cutoffs rather than wall-clock time

`compact_financial_ledger`
- caller: manual backend maintenance only
- params:
  - `p_dry_run`
- current behavior:
  - defaults to dry-run mode
  - returns the same candidate buckets as
    `get_financial_ledger_compaction_report()`
  - when called with `FALSE`, upserts `financial_ledger_summary` and deletes
    raw ledger rows older than each actor's configured game-day cutoff
  - is intentionally not granted to anon clients

`assign_active_season_id`
- caller: database insert triggers on `users` and `ai_competitors`
- current behavior:
  - assigns the active season when `season_id` is missing
  - starts newly inserted actors at the active season game time

### Fleet

`purchase_aircraft`
- caller: `FleetCubit.purchaseAircraft()`
- params:
  - `p_user_id`
  - `p_model_id`
  - `p_nickname`
  - `p_economy_seats`
  - `p_business_seats`
  - `p_first_class_seats`
- current behavior:
  - catches up simulation before purchase
  - validates seat-slot capacity inside the purchase transaction

`lease_aircraft`
- caller: `FleetCubit.leaseAircraft()`
- params:
  - `p_user_id`
  - `p_model_id`
  - `p_nickname`
  - `p_economy_seats`
  - `p_business_seats`
  - `p_first_class_seats`
- current behavior:
  - catches up simulation before lease
  - validates seat-slot capacity inside the lease transaction

`repair_aircraft`
- caller: `FleetCubit.repairAircraft()`
- params:
  - `p_user_id`
  - `p_fleet_id`
- current behavior:
  - restores the airframe to 100%
  - repair pricing now matches the client display model
  - leased and owned aircraft use different cost bases

`sell_aircraft`
- caller: `FleetCubit.sellAircraft()`
- params:
  - `p_user_id`
  - `p_fleet_id`
- current behavior:
  - catches up simulation before sale
  - requires an owned aircraft
  - blocks disposal while the aircraft is still assigned
  - credits condition-adjusted residual value
  - writes `financial_ledger.category = 'aircraft_sale'`
  - removes the fleet row

`terminate_aircraft_lease`
- caller: `FleetCubit.terminateLease()`
- params:
  - `p_user_id`
  - `p_fleet_id`
- current behavior:
  - catches up simulation before termination
  - requires a leased aircraft
  - blocks disposal while the aircraft is still assigned
  - charges a lease exit fee
  - writes `financial_ledger.category = 'aircraft_lease_exit'`
  - removes the fleet row

`configure_aircraft_seats`
- caller: `FleetCubit.configureSeats()`
- params:
  - `p_user_id`
  - `p_fleet_id`
  - `p_economy_seats`
  - `p_business_seats`
  - `p_first_class_seats`
- current behavior:
  - catches up simulation before seat changes
  - validates seat-slot capacity server-side

### Routes

`create_route`
- caller: `RoutesCubit.createRoute()`
- params:
  - `p_user_id`
  - `p_origin_iata`
  - `p_destination_iata`
  - `p_distance_km`
  - `p_ticket_price`
  - `p_flights_per_week`
- current behavior:
  - catches up simulation before creating the route
  - stores blueprint economics before any aircraft is assigned

`assign_aircraft_to_route`
- caller: `RoutesCubit.assignAircraft()`
- params:
  - `p_user_id`
  - `p_route_id`
  - `p_aircraft_id`
- current behavior:
  - catches up simulation before changing assignment
  - validates ownership, safety threshold, route range fit, weekly schedule fit,
    and single-route assignment server-side

`update_route_frequency_and_price`
- caller: `RoutesCubit.updateRouteFrequencyAndPrice()`
- params:
  - `p_user_id`
  - `p_route_id`
  - `p_ticket_price`
  - `p_flights_per_week`
- current behavior:
  - catches up simulation before changing fare or schedule
  - enforces assigned-aircraft weekly schedule limits server-side

### Owner-only tools

`get_owner_route_optimizer`
- caller: operator only, not Flutter
- params:
  - `p_user_id`
  - `p_origin_iata`
  - `p_destination_iata`
  - `p_limit`
  - `p_include_assigned`
  - `p_exclude_existing_routes`
- current behavior:
  - scans reachable destinations for one player fleet
  - scores fare and seat-layout candidates
  - returns top route opportunities by estimated weekly contribution
  - is intentionally granted only to `service_role`

`delete_route`
- caller: `RoutesCubit.deleteRoute()`
- params:
  - `p_user_id`
  - `p_route_id`
- current behavior:
  - catches up simulation before closing the route
  - grounds the assigned aircraft before deleting the route

### Leaderboard

`get_global_leaderboard`
- caller: `LeaderboardCubit.loadRankings()`
- params: none
- current client behavior:
  - rankings are always presented by net worth
  - client-side sort controls were removed
  - overview consumes this feed for competitor-gap and leading-bot signals
  - `monthly_revenue` now means realized revenue over the last 30 in-game days for both players and bots
  - `status` comes from `users.operational_status` for human players and `ai_competitors.status` for bots

`get_competitor_insights`
- caller: `LeaderboardCubit.getInsights()`
- params:
  - `p_id`
  - `p_is_bot`
- current client behavior:
  - bot intelligence is loaded from the live RPC, not synthetic client fallback
  - competitor dialogs reflect the live backend status surface (`Active`, `Distress`, `Maintenance`, `Recovery`, `Bankrupt`)

### Settings

`reset_user_airline`
- caller: `SettingsCubit.resetAirline()`
- params:
  - `p_user_id`

`save_airline_settings`
- caller: `SettingsCubit.saveSettings()`
- params:
  - `p_user_id`
  - `p_company_name`
  - `p_auto_grounding_threshold`
  - `p_hq_airport_iata`
- current behavior:
  - catches up simulation before saving settings
  - validates safety threshold and HQ airport server-side

### Direct table writes

The Flutter client should not directly write simulation-sensitive tables. Player
commands that mutate fleet, routes, settings, cash, ledger, or simulation state
must go through RPCs.

## Direct table reads

The client also reads some tables directly through Supabase queries:
- `user_fleet`
- `aircraft_models`
- `user_routes`
- `financial_ledger`
- `users`
- `airports`
- `global_game_settings`

These are still part of the effective contract because UI parsing depends on their returned fields.

## Realtime subscription surface

The Flutter client now subscribes to Postgres Changes on:
- `users`
- `user_fleet`
- `user_routes`
- `financial_ledger`
- `ai_competitors`

Operational rule:
- the pg_cron world tick is the authoritative catch-up trigger
- periodic/app-resume `process_simulation_delta` calls remain compatibility
  reconciliation for the current player
- Realtime is used to reflect committed row changes into Cubit state sooner between syncs
- production Flutter does not locally advance game time; mock/dev mode may still
  use a local display ticker

## Backend-only behavior surfaces

The app also depends indirectly on backend jobs that are not called as standalone RPCs from Flutter:
- `season_clock`
  - shared-world clock foundation, with scheduler-driven world ticks
  - links users and bots into an active season through `season_id`
  - not yet runtime authority while actor clocks remain active
- `skyward_world_tick`
  - Phase 4 pg_cron job
  - calls `ensure_world_current(NULL)` once per minute
  - advances `season_clock` only until actor simulation migrates into world ticks
- `execute_bot_decisions()`
  - archetype-specific fleet growth
  - archetype-specific route doctrine retuning on existing active routes
  - idle-aircraft route deployment
  - distance-stage and demand-aware route selection by archetype
  - contribution-based distress route cutbacks
  - paid bot repair recovery for grounded airframes
  - reserve-aware expansion gates tied to active lease burden
