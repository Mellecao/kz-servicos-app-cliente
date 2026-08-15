# Round-trip addresses for scheduled bookings — Design

## Problem

When a client books a scheduled ride ("agendar uma viagem") and selects **"Ida e volta"**, two things are broken today:

1. **No distinct return route.** The address picker (map pins) only ever captures one pickup/dropoff pair. "Round trip" today means *the same route, implicitly reversed* — there is no way to specify a different pickup/dropoff for the return leg, and the database has no columns to store one.
2. **Silently dropped for "escolher motorista".** In the "escolher motorista" (choose driver) flow specifically, the round-trip flag and return date/time *are* collected from the client (via a second pass of the passenger-details panel), but they are never passed into `DriverSelectionCubit` / `ScheduledDirectRequestRepository.sendRequest()` — so the trip is created as if it were one-way, and the driver never sees round-trip info at all.

This design fixes both, and extends it so the client can specify a genuinely different route for the return leg.

## Scope

Applies to both scheduling paths that share the round-trip toggle in `trip_home_page.dart`:
- **scheduled_choose_driver** ("escolher motorista")
- **scheduled_quote** (agendamento automático / system finds a driver)

One-way ("somente ida") bookings are unaffected — no changes to that path.

Out of scope:
- Splitting a round trip into two independently accept/reject-able trips. It remains **one trip row, one price, one accept/reject** by the driver, consistent with how `is_round_trip`/`return_datetime` already work today.
- Any change to the one-way address-picking UX (map pins stay as-is).

## Client app (`kz-servicos-app-cliente`)

### Address capture

Today: map-pin picker, single pickup/dropoff pair, used for both one-way and round-trip bookings.

New: when the client picks **"Ida e volta"** (in `_showTripTypePicker` in `trip_home_page.dart`), route to a new screen with 4 address search fields instead of the map-pin picker:
- Partida (ida)
- Destino (ida)
- Partida (volta) — defaults to Destino (ida), editable
- Destino (volta) — defaults to Partida (ida), editable

Each field reuses the existing Google Places-backed address search component (the same one powering `address_search_sheet.dart` / `trip_address_search_bar.dart`), presented as a stacked list of tappable rows rather than a map. One-way bookings keep the current map-pin flow unchanged.

### Ride details (date/time)

No structural change. The existing two-pass `PassengerDetailsPanel` flow (ida panel → volta panel, each collecting its own date + time) already satisfies "insert horário de ida e volta, data e hora de ida e volta." The fix here is purely about not losing this data downstream (see below).

### Wiring fixes and extensions

- `trip_home_page.dart`: when building the `extra` map passed to `/scheduled-choose-driver/select`, include `isRoundTrip`, `returnDatetime`, `returnPickupAddressId`, `returnDropoffAddressId` (currently only `pickupAddressId`/`dropoffAddressId`/`scheduledDatetime` are passed — the round-trip data collected upstream is silently dropped).
- `DriverSelectionCubit` + `ScheduledDirectRequestRepository.sendRequest()`: accept the 4 new fields and forward them to the `client_send_scheduled_direct_request` RPC.
- `TripRequest` entity + `TripRepositoryImpl.createTrip()` (auto-match / scheduled_quote path): add `returnPickupAddress`/`returnDropoffAddress` (`TripAddress?`), insert them alongside pickup/dropoff when present, pass through `TripModel.buildInsertJson`.
- `ScheduledDirectRequest` entity, `PriceOfferDetails` entity, and the `fetchActiveRequest()` / `AwaitingResponseCubit` select queries: extend to fetch and expose `isRoundTrip`, `returnDatetime`, and the return address pair, so `AwaitingDriverContent` and `PriceOfferContent` can display the full round-trip itinerary to the client while waiting for the driver's response and price.

## Backend (Supabase)

- New migration: add `return_pickup_address_id UUID REFERENCES addresses(id)` and `return_dropoff_address_id UUID REFERENCES addresses(id)` (both nullable) to `trips`, following the existing `YYYYMMDDHHMMSS_description.sql` convention.
- Update RPC `client_send_scheduled_direct_request` to accept 2 new optional params (`return_pickup_address_id_input`, `return_dropoff_address_id_input`, defaulting to `NULL`) and persist them — backward compatible with any other caller.
- Update `.agents/skills/kz-database` (and its GitHub-skills mirror) reference docs (`schema.md`, etc.) to document the new columns, per this project's own "keep the skill updated" convention.

## Driver app (`kz-servicos-app-prestador`)

- `TripData` model (`lib/core/models/trip_data.dart`): parse `return_pickup_address_id`/`return_dropoff_address_id` (joined to `addresses.formatted_address`, mirroring how `origin`/`destination` are already resolved) alongside the existing `isRoundTrip`/`returnAt`.
- `ScheduledDirectRequestCard` (`lib/features/schedules/presentation/widgets/scheduled_direct_request_card.dart`): currently doesn't even show the scheduled date/time. Add: scheduled date/time, and when `isRoundTrip`, a compact "Ida ... • Volta ..." summary (addresses + times) so the driver sees round-trip info on the very first notification card.
- `schedule_detail_page.dart`: in both the "Rota" section card (agendamentos / non-fromHome view, ~line 820) and the "Rota da corrida" timeline (fromHome / incoming request view, ~line 1260), replace the current placeholder return row (`'Retorno previsto em X'` with no real address) with the actual return pickup/dropoff addresses plus the return time.

## Testing

- Unit tests for the extended entities/models (`TripRequest`, `TripModel`, `ScheduledDirectRequest`, `PriceOfferDetails`, `TripData`) covering the new round-trip address fields, including the "not a round trip" (fields null) case.
- Widget tests for the new 4-field address screen (default pre-fill + edit) and for the updated driver-side cards showing round-trip info.
