# Triggers & Functions — KZ Serviços Database

## Functions

### `public.get_user_role()`
Returns the `user_role` of the authenticated user. Used by all RLS policies.
```sql
CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

### `public.is_trip_candidate_for_current_user(p_trip_id uuid)`
Returns `true` if `auth.uid()` is a registered candidate for the given trip.
Used by `trips_select` to allow candidates to see the parent trip without
recursing into `trip_driver_candidates_select` (SECURITY DEFINER bypasses RLS).
```sql
CREATE OR REPLACE FUNCTION public.is_trip_candidate_for_current_user(p_trip_id uuid)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.trip_driver_candidates tdc
    JOIN public.driver_profiles dp ON dp.id = tdc.driver_profile_id
    JOIN public.provider_profiles pp ON pp.id = dp.provider_profile_id
    WHERE tdc.trip_id = p_trip_id
      AND pp.user_id = auth.uid()
  );
$$;
```

### `set_address_location()`
Auto-populates `addresses.location` (GEOGRAPHY) from `latitude`/`longitude`.
```sql
NEW.location := ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)::geography;
```
**Trigger**: `trg_set_address_location` — BEFORE INSERT OR UPDATE OF latitude, longitude ON addresses

### `set_driver_location()`
Auto-populates `driver_locations.location` (GEOGRAPHY) from `latitude`/`longitude`.
**Trigger**: `trg_set_driver_location` — BEFORE INSERT OR UPDATE OF latitude, longitude ON driver_locations

### `log_trip_status_change()`
Records trip status changes to `trip_status_history`. Uses `auth.uid()` or `client_id` as `changed_by`.
Reads optional `app.status_observation` session config to attach a justification (e.g. set by `reject_trip` RPC) — keeps the trigger as the single source of inserts into `trip_status_history`.
```sql
DECLARE
  v_observation TEXT;
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    v_observation := NULLIF(current_setting('app.status_observation', true), '');
    INSERT INTO trip_status_history (trip_id, from_status, to_status, changed_by, observations)
    VALUES (NEW.id, OLD.status::VARCHAR, NEW.status::VARCHAR, COALESCE(auth.uid(), NEW.client_id), v_observation);
  END IF;
  RETURN NEW;
END;
```
**Trigger**: `trg_log_trip_status_change` — AFTER UPDATE OF status ON trips

### `reject_trip(p_trip_id UUID, p_reason TEXT DEFAULT NULL)` (RPC)
Recusa uma viagem em `under_review` retornando-a para `open` e registra a justificativa numa única transação. Define `app.status_observation` via `set_config(..., true)` (escopo local) e atualiza `trips.status`, deixando o trigger `log_trip_status_change` inserir uma única linha em `trip_status_history` com `observations` preenchido.
Granted to `authenticated`.

### `log_service_request_status_change()`
Records service request status changes to `service_request_status_history`.
**Trigger**: `trg_log_service_request_status_change` — AFTER UPDATE OF status ON service_requests

### `recalculate_provider_rating()`
Recalculates `provider_profiles.average_rating` and `total_ratings` when a new rating is inserted.
**Trigger**: `trg_recalculate_provider_rating` — AFTER INSERT ON ratings

### `update_updated_at_column()`
Generic function that sets `NEW.updated_at = now()`.
Applied to: `users`, `provider_profiles`, `driver_profiles`, `vehicles`, `trips`, `service_requests`, `driver_locations`

## Trigger Summary

| Trigger | Table | Event | Function |
|---------|-------|-------|----------|
| `trg_set_address_location` | addresses | BEFORE INSERT/UPDATE(lat,lng) | `set_address_location()` |
| `trg_set_driver_location` | driver_locations | BEFORE INSERT/UPDATE(lat,lng) | `set_driver_location()` |
| `trg_log_trip_status_change` | trips | AFTER UPDATE(status) | `log_trip_status_change()` |
| `trg_log_service_request_status_change` | service_requests | AFTER UPDATE(status) | `log_service_request_status_change()` |
| `trg_recalculate_provider_rating` | ratings | AFTER INSERT | `recalculate_provider_rating()` |
| `trg_users_updated_at` | users | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_provider_profiles_updated_at` | provider_profiles | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_driver_profiles_updated_at` | driver_profiles | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_vehicles_updated_at` | vehicles | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_trips_updated_at` | trips | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_service_requests_updated_at` | service_requests | BEFORE UPDATE | `update_updated_at_column()` |
| `trg_driver_locations_updated_at` | driver_locations | BEFORE UPDATE | `update_updated_at_column()` |

## Realtime Publications

```sql
ALTER PUBLICATION supabase_realtime ADD TABLE driver_locations;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
```

## PostgreSQL Extensions

- **PostGIS**: `CREATE EXTENSION IF NOT EXISTS "postgis";`
- **pg_trgm**: `CREATE EXTENSION IF NOT EXISTS "pg_trgm";`
- **unaccent**: `CREATE EXTENSION IF NOT EXISTS "unaccent";`
