---
name: kz-database
description: "Complete KZ Serviços database and API reference. Use when: querying Supabase, writing API calls, creating migrations, building forms that map to tables, debugging RLS errors, understanding relationships between tables, or implementing features that read/write data. Covers all 22 tables, enums, RLS policies, triggers, Realtime, and REST API endpoints."
---

# KZ Serviços — Database & API Reference

Complete reference for the KZ Serviços Supabase database. Use this skill whenever you need to interact with the database, write queries, create new migrations, or implement features that read/write data.

## When to Use

- Writing Supabase queries (select, insert, update, delete)
- Creating or modifying API routes
- Building forms that map to database tables
- Debugging RLS (Row Level Security) errors
- Understanding table relationships and foreign keys
- Creating new database migrations
- Implementing features that require specific data shapes

## Supabase Connection

- **URL**: `https://wmlsiwjrgjygqdjtsayt.supabase.co`
- **Auth**: Supabase Auth (JWT-based)
- **Client keys**: `NEXT_PUBLIC_SUPABASE_ANON_KEY` (browser), `SUPABASE_SERVICE_ROLE_KEY` (server-only, bypasses RLS)
- **REST API**: `{SUPABASE_URL}/rest/v1/{table}` with `apikey` and `Authorization: Bearer {token}` headers
- **API Docs page**: `/documentacao-da-api` in the web app
- **Postman collection**: `docs/KZ_Servicos_Supabase_API.postman_collection.json`

## Database Overview

**23 tables** across these domains:

| Domain | Tables |
|--------|--------|
| Users & Auth | `users` |
| Service Catalog | `service_categories` |
| Providers | `provider_profiles`, `provider_category_services` |
| Drivers | `driver_profiles`, `vehicles`, `vehicle_photos`, `driver_locations` |
| Addresses | `addresses` |
| Trips | `trips`, `trip_children`, `trip_luggage`, `trip_status_history`, `trip_driver_candidates` |
| Service Requests | `service_requests`, `service_request_status_history` |
| Chat | `chat_rooms`, `chat_messages` |
| Notifications | `notifications`, `user_devices` |
| Ratings | `ratings` |
| Admin | `private_comments`, `system_settings` |

## Enums

| Enum | Values |
|------|--------|
| `user_role` | `client`, `provider`, `admin` |
| `provider_status` | `pending`, `approved`, `rejected`, `suspended` |
| `bank_account_type` | `checking`, `savings` |
| `trip_status` | `open`, `under_review`, `review_rejected`, `searching_drivers`, `awaiting_client_confirmation`, `awaiting_driver_confirmation`, `scheduled`, `started`, `finished`, `cancelled` |
| `service_request_status` | `open`, `under_review`, `review_rejected`, `searching_provider`, `assigned`, `in_progress`, `finished`, `cancelled` |
| `service_type_enum` | `trip`, `other_service` |
| `payment_method` | `pix`, `debit`, `credit`, `cash`, `billing` |
| `luggage_size` | `small`, `medium`, `large`, `extra_large` |
| `platform_type` | `android`, `ios`, `web` |
| `message_type` | `text`, `image`, `audio`, `file`, `location` |
| `photo_type` | `front`, `back`, `interior`, `side_left`, `side_right` |
| `trip_status_candidate` | `pending`, `accepted`, `rejected` |

## Key Relationships (ER Summary)

```
auth.users ──1:1──► users (id = auth.uid())
users ──1:1──► provider_profiles (user_id)
provider_profiles ──1:1──► driver_profiles (provider_profile_id)
provider_profiles ──N:N──► service_categories (via provider_category_services)
driver_profiles ──1:N──► vehicles (driver_profile_id)
vehicles ──1:N──► vehicle_photos (vehicle_id)
driver_profiles ──1:1──► driver_locations (driver_profile_id)

users ──1:N──► trips (client_id)
driver_profiles ──1:N──► trips (driver_profile_id)
trips ──1:N──► trip_children, trip_luggage, trip_status_history, trip_driver_candidates
driver_profiles ──1:N──► trip_driver_candidates (driver_profile_id)
trips ──1:1──► addresses (pickup_address_id, dropoff_address_id)

users ──1:N──► service_requests (client_id)
provider_profiles ──1:N──► service_requests (provider_profile_id)
service_requests ──1:N──► service_request_status_history

chat_rooms ──► trip_id XOR service_request_id (polymorphic, exactly one)
ratings ──► trip_id XOR service_request_id (polymorphic, exactly one)

users ──1:N──► notifications, user_devices, private_comments
```

## Detailed References

For full column definitions, constraints, indexes, and SQL:
- [Schema Reference (all tables)](./references/schema.md)
- [RLS Policies](./references/rls-policies.md)
- [Triggers & Functions](./references/triggers.md)
- [API Endpoints](./references/api-endpoints.md)

## Important Patterns

### Creating Users (bypasses RLS)
`users.id` is a FK to `auth.users(id)`. You MUST create the auth user first via `supabaseAdmin.auth.admin.createUser()`, then insert into `public.users` with the same ID. Use the server-side API route `/api/users` (POST) which handles this with the `service_role` key.

### Querying with Relations
Supabase supports `select("*, relation(*)")` syntax:
```typescript
// Trip with all relations
supabase.from("trips").select("*, pickup_address:addresses!pickup_address_id(*), dropoff_address:addresses!dropoff_address_id(*), service_categories(*), users!client_id(*)")

// Service request with relations
supabase.from("service_requests").select("*, service_categories(*), addresses(*), users!client_id(*)")

// Provider with user and category
supabase.from("provider_profiles").select("*, users(*), service_categories(*)")

// Driver with nested provider → user
supabase.from("driver_profiles").select("*, provider_profiles(*, users(*))")
```

### RLS Context
All RLS policies use `auth.uid()` and `public.get_user_role()`. The `get_user_role()` function is `SECURITY DEFINER` and reads from `public.users WHERE id = auth.uid()`.

- **Anon key**: Subject to RLS policies (use for client-side)
- **Service role key**: Bypasses ALL RLS (use only server-side, never expose to browser)

### Realtime Tables
These tables publish changes via Supabase Realtime (WebSocket):
- `driver_locations` — real-time driver tracking
- `chat_messages` — real-time chat
- `notifications` — real-time notification delivery

### PostGIS / Geography
- `addresses.location`: Auto-populated via trigger from `latitude`/`longitude`
- `driver_locations.location`: Auto-populated via trigger from `latitude`/`longitude`
- Use `ST_DWithin(location, ST_MakePoint(lng,lat)::geography, radius_meters)` for proximity queries

### Auto-updated Timestamps
Tables with `updated_at` auto-update via trigger: `users`, `provider_profiles`, `driver_profiles`, `vehicles`, `trips`, `service_requests`, `driver_locations`.

### Status History (auto-logged via trigger)
- `trips.status` changes → auto-inserted into `trip_status_history`
- `service_requests.status` changes → auto-inserted into `service_request_status_history`

### Rating Recalculation
When a `rating` is inserted, a trigger recalculates `provider_profiles.average_rating` and `total_ratings` automatically.

## PostgreSQL Extensions

- **PostGIS**: Geographic queries (`GEOGRAPHY(Point, 4326)`, `ST_DWithin`, `ST_MakePoint`)
- **pg_trgm**: Fuzzy text search (`%` similarity operator, `similarity()`)
- **unaccent**: Accent-insensitive search (`unaccent('São Paulo')` → `'Sao Paulo'`)

## Migration Conventions

Migrations are in `supabase/migrations/` using the naming pattern:
```
YYYYMMDDHHMMSS_description.sql
```
Current range: `20260410120000` to `20260428120000` (34 migrations + `seed_service_categories.sql`).

When creating new migrations:
1. Use the next sequential timestamp
2. Include `-- +goose Up` and `-- +goose Down` markers
3. Always enable RLS: `ALTER TABLE {name} ENABLE ROW LEVEL SECURITY;`
4. Create appropriate RLS policies
5. Add indexes for frequently queried columns
6. **Update this skill** with the new table/column information

## Keeping This Skill Updated

**IMPORTANT**: Whenever a new migration is created or the database schema changes, this skill and its reference files MUST be updated to reflect the changes. The skill must always represent the current state of the database.
