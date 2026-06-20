# Schema Reference — KZ Serviços Database

Complete column-level reference for all 23 tables.

## users

Tabela principal de usuários, vinculada ao `auth.users` do Supabase Auth.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, FK → auth.users(id) ON DELETE CASCADE |
| `role` | user_role | NOT NULL, DEFAULT 'client' |
| `full_name` | VARCHAR(255) | NOT NULL |
| `email` | VARCHAR(255) | UNIQUE, NOT NULL |
| `phone` | VARCHAR(20) | |
| `cpf` | VARCHAR(14) | UNIQUE |
| `avatar_url` | TEXT | |
| `date_of_birth` | DATE | |
| `is_active` | BOOLEAN | DEFAULT true |
| `auth_provider` | VARCHAR(20) | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |
| `deleted_at` | TIMESTAMPTZ | |

**Indexes**: `idx_users_email`, `idx_users_cpf`, `idx_users_role`

---

## service_categories

Categorias de serviço (Motorista, Diarista, Eletricista, etc.).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `name` | VARCHAR(100) | UNIQUE, NOT NULL |
| `slug` | VARCHAR(100) | UNIQUE, NOT NULL |
| `description` | TEXT | |
| `service_type` | service_type_enum | NOT NULL |
| `is_active` | BOOLEAN | DEFAULT true |
| `icon_url` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Seed data**: Motorista (trip), Diarista (other_service), Eletricista (other_service)

---

## provider_profiles

Perfil do prestador de serviço com documentos, dados bancários e avaliações.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `user_id` | UUID | FK → users, UNIQUE, NOT NULL, ON DELETE CASCADE |
| `service_category_id` | UUID | FK → service_categories, NOT NULL, ON DELETE RESTRICT |
| `status` | provider_status | DEFAULT 'pending' |
| `rg_document_url` | TEXT | |
| `cnh_document_url` | TEXT | |
| `proof_of_address_url` | TEXT | |
| `has_card_machine` | BOOLEAN | DEFAULT false |
| `has_tap_payment` | BOOLEAN | DEFAULT false |
| `issues_invoice` | BOOLEAN | DEFAULT false |
| `issues_receipt` | BOOLEAN | DEFAULT false |
| `bank_name` | VARCHAR(100) | |
| `bank_agency` | VARCHAR(20) | |
| `bank_account` | VARCHAR(30) | |
| `bank_account_type` | bank_account_type | |
| `bank_pix_key` | VARCHAR(255) | |
| `average_rating` | DECIMAL(3,2) | DEFAULT 0 |
| `total_ratings` | INTEGER | DEFAULT 0 |
| `bio` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_provider_profiles_user_id`, `idx_provider_profiles_service_category_id`, `idx_provider_profiles_status`

---

## driver_profiles

Extensão do perfil de prestador para motoristas (dados CNH).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `provider_profile_id` | UUID | FK → provider_profiles, UNIQUE, NOT NULL, ON DELETE CASCADE |
| `cnh_category` | VARCHAR(5) | |
| `cnh_expiration_date` | DATE | |
| `cnh_number` | VARCHAR(20) | UNIQUE |
| `is_available` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

---

## vehicles

Veículos cadastrados pelos motoristas.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `driver_profile_id` | UUID | FK → driver_profiles, NOT NULL, ON DELETE CASCADE |
| `brand` | VARCHAR(100) | NOT NULL |
| `model` | VARCHAR(100) | NOT NULL |
| `year` | INTEGER | NOT NULL |
| `color` | VARCHAR(50) | NOT NULL |
| `license_plate` | VARCHAR(10) | UNIQUE, NOT NULL |
| `vehicle_document_url` | TEXT | NOT NULL |
| `passenger_capacity` | INTEGER | DEFAULT 4 |
| `is_active` | BOOLEAN | DEFAULT true |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

---

## vehicle_photos

Fotos dos veículos por tipo (frente, traseira, interior, laterais).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `vehicle_id` | UUID | FK → vehicles, NOT NULL, ON DELETE CASCADE |
| `photo_url` | TEXT | NOT NULL |
| `photo_type` | photo_type | NOT NULL |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

---

## addresses

Endereços com dados do Google Places e coordenadas PostGIS.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `google_place_id` | VARCHAR(255) | |
| `formatted_address` | TEXT | NOT NULL |
| `street` | VARCHAR(255) | |
| `number` | VARCHAR(20) | |
| `complement` | VARCHAR(255) | |
| `neighborhood` | VARCHAR(255) | |
| `city` | VARCHAR(255) | NOT NULL |
| `state` | VARCHAR(2) | NOT NULL |
| `zip_code` | VARCHAR(10) | |
| `latitude` | DECIMAL(10,7) | NOT NULL |
| `longitude` | DECIMAL(10,7) | NOT NULL |
| `location` | GEOGRAPHY(Point, 4326) | Auto-populated via trigger |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_addresses_location` (GiST)
**Trigger**: `trg_set_address_location` — auto-sets `location` from lat/lng on INSERT/UPDATE

---

## trips

Tabela principal de viagens (transporte de passageiros).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `client_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `driver_profile_id` | UUID | FK → driver_profiles, ON DELETE SET NULL |
| `vehicle_id` | UUID | FK → vehicles, ON DELETE SET NULL |
| `service_category_id` | UUID | FK → service_categories, NOT NULL, ON DELETE RESTRICT |
| `pickup_address_id` | UUID | FK → addresses, NOT NULL, ON DELETE RESTRICT |
| `dropoff_address_id` | UUID | FK → addresses, NOT NULL, ON DELETE RESTRICT |
| `scheduled_datetime` | TIMESTAMPTZ | NOT NULL |
| `is_round_trip` | BOOLEAN | DEFAULT false |
| `return_datetime` | TIMESTAMPTZ | |
| `passenger_count` | INTEGER | NOT NULL |
| `children_count` | INTEGER | DEFAULT 0 |
| `observations` | TEXT | |
| `driver_observations` | TEXT | |
| `luggage_count` | INTEGER | DEFAULT 0 |
| `status` | trip_status | DEFAULT 'open' |
| `estimated_price` | DECIMAL(10,2) | |
| `final_price` | DECIMAL(10,2) | |
| `is_paid` | BOOLEAN | DEFAULT false |
| `is_driver_paied` | BOOLEAN | DEFAULT false |
| `payment_method` | payment_method | |
| `payment_date` | TIMESTAMPTZ | |
| `started_at` | TIMESTAMPTZ | |
| `finished_at` | TIMESTAMPTZ | |
| `cancelled_at` | TIMESTAMPTZ | |
| `cancellation_reason` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_trips_client_id`, `idx_trips_driver_profile_id`, `idx_trips_status`, `idx_trips_scheduled_datetime`

---

## trip_children

Crianças em viagens (idade e necessidade de cadeirinha).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, NOT NULL, ON DELETE CASCADE |
| `age` | INTEGER | NOT NULL |
| `needs_car_seat` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

---

## trip_luggage

Bagagens de viagens com tamanho e quantidade.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, NOT NULL, ON DELETE CASCADE |
| `size` | luggage_size | NOT NULL |
| `quantity` | INTEGER | DEFAULT 1 |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

---

## trip_status_history

Histórico de mudanças de status de viagens (auto-registrado via trigger).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, NOT NULL, ON DELETE CASCADE |
| `from_status` | VARCHAR(50) | |
| `to_status` | VARCHAR(50) | NOT NULL |
| `changed_by` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `observations` | TEXT | |
| `metadata` | JSONB | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_trip_status_history_trip_id`, `idx_trip_status_history_created_at`

---

## trip_driver_candidates

Candidatos a motorista para viagens no status `searching_drivers`. Permite indicar múltiplos motoristas antes da confirmação final.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, NOT NULL, ON DELETE CASCADE |
| `driver_profile_id` | UUID | FK → driver_profiles, NOT NULL, ON DELETE CASCADE |
| `status` | trip_status_candidate | NOT NULL, DEFAULT 'pending' — valores: pending, accepted, rejected |
| `invited_at` | TIMESTAMPTZ | DEFAULT now() |
| `responded_at` | TIMESTAMPTZ | |
| `observations` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Constraints**: `UNIQUE(trip_id, driver_profile_id)`
**Indexes**: `idx_trip_driver_candidates_trip_id`, `idx_trip_driver_candidates_driver_profile_id`

---

## service_requests

Solicitações de serviços genéricos (diarista, eletricista, etc.).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `client_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `provider_profile_id` | UUID | FK → provider_profiles, ON DELETE SET NULL |
| `service_category_id` | UUID | FK → service_categories, NOT NULL, ON DELETE RESTRICT |
| `service_date` | TIMESTAMPTZ | NOT NULL |
| `description` | TEXT | NOT NULL |
| `status` | service_request_status | DEFAULT 'open' |
| `address_id` | UUID | FK → addresses, ON DELETE SET NULL |
| `estimated_price` | DECIMAL(10,2) | |
| `final_price` | DECIMAL(10,2) | |
| `is_paid` | BOOLEAN | DEFAULT false |
| `payment_method` | payment_method | |
| `observations` | TEXT | |
| `provider_observations` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_service_requests_client_id`, `idx_service_requests_provider_profile_id`, `idx_service_requests_status`, `idx_service_requests_service_date`

---

## service_request_status_history

Histórico de mudanças de status de solicitações (auto-registrado via trigger).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `service_request_id` | UUID | FK → service_requests, NOT NULL, ON DELETE CASCADE |
| `from_status` | VARCHAR(50) | |
| `to_status` | VARCHAR(50) | NOT NULL |
| `changed_by` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `observations` | TEXT | |
| `metadata` | JSONB | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_sr_status_history_service_request_id`, `idx_sr_status_history_created_at`

---

## chat_rooms

Salas de chat entre cliente e prestador (vinculada a trip OU service_request).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, ON DELETE SET NULL |
| `service_request_id` | UUID | FK → service_requests, ON DELETE SET NULL |
| `client_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `provider_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `is_active` | BOOLEAN | DEFAULT true |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Constraint**: `chk_chat_room_reference` — exatamente um de `trip_id` / `service_request_id` deve ser NOT NULL

---

## chat_messages

Mensagens de chat (texto, imagem, áudio, arquivo, localização). **Realtime enabled.**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `chat_room_id` | UUID | FK → chat_rooms, NOT NULL, ON DELETE CASCADE |
| `sender_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `message` | TEXT | NOT NULL |
| `message_type` | message_type | DEFAULT 'text' |
| `attachment_url` | TEXT | |
| `is_read` | BOOLEAN | DEFAULT false |
| `read_at` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_chat_messages_chat_room_id`, `idx_chat_messages_sender_id`, `idx_chat_messages_created_at`

---

## notifications

Notificações do sistema (referência polimórfica). **Realtime enabled.**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `user_id` | UUID | FK → users, NOT NULL, ON DELETE CASCADE |
| `title` | VARCHAR(255) | NOT NULL |
| `body` | TEXT | NOT NULL |
| `type` | VARCHAR(50) | NOT NULL |
| `reference_type` | VARCHAR(50) | |
| `reference_id` | UUID | |
| `link` | TEXT | |
| `is_read` | BOOLEAN | DEFAULT false |
| `read_at` | TIMESTAMPTZ | |
| `is_pushed` | BOOLEAN | DEFAULT false |
| `pushed_at` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_notifications_user_id`, `idx_notifications_is_read`, `idx_notifications_created_at`

---

## user_devices

Dispositivos para push notifications.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `user_id` | UUID | FK → users, NOT NULL, ON DELETE CASCADE |
| `device_token` | TEXT | NOT NULL |
| `platform` | platform_type | NOT NULL |
| `is_active` | BOOLEAN | DEFAULT true |
| `last_used_at` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Constraint**: `uq_user_device_token` UNIQUE (user_id, device_token)

---

## driver_locations

Localização em tempo real dos motoristas (PostGIS). **Realtime enabled.**

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `driver_profile_id` | UUID | FK → driver_profiles, UNIQUE, NOT NULL, ON DELETE CASCADE |
| `trip_id` | UUID | FK → trips, ON DELETE SET NULL |
| `latitude` | DECIMAL(10,7) | NOT NULL |
| `longitude` | DECIMAL(10,7) | NOT NULL |
| `location` | GEOGRAPHY(Point, 4326) | Auto-populated via trigger |
| `heading` | DECIMAL(5,2) | |
| `speed` | DECIMAL(6,2) | |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_driver_locations_location` (GiST)
**Trigger**: `trg_set_driver_location` — auto-sets `location` from lat/lng

---

## private_comments

Comentários privados de prestadores, visíveis ao autor e admins.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `author_id` | UUID | FK → users, NOT NULL, ON DELETE CASCADE |
| `reference_type` | VARCHAR(50) | NOT NULL |
| `reference_id` | UUID | |
| `comment` | TEXT | NOT NULL |
| `admin_response` | TEXT | |
| `responded_by` | UUID | FK → users, ON DELETE SET NULL |
| `responded_at` | TIMESTAMPTZ | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Indexes**: `idx_private_comments_author_id`, `idx_private_comments_reference_type`, `idx_private_comments_reference_id`

---

## ratings

Avaliações de viagens e serviços (1-5 estrelas).

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `trip_id` | UUID | FK → trips, ON DELETE SET NULL |
| `service_request_id` | UUID | FK → service_requests, ON DELETE SET NULL |
| `rater_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `rated_id` | UUID | FK → users, NOT NULL, ON DELETE RESTRICT |
| `rating` | DECIMAL(2,1) | NOT NULL, CHECK (rating >= 1 AND rating <= 5) |
| `comment` | TEXT | |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Constraint**: `chk_rating_reference` — exatamente um de `trip_id` / `service_request_id` deve ser NOT NULL
**Trigger**: `trg_recalculate_provider_rating` — recalcula `provider_profiles.average_rating` e `total_ratings`

---

## provider_category_services

Relação N:N entre prestadores e categorias de serviço.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `provider_profile_id` | UUID | FK → provider_profiles, NOT NULL, ON DELETE CASCADE |
| `service_category_id` | UUID | FK → service_categories, NOT NULL, ON DELETE RESTRICT |
| `is_primary` | BOOLEAN | DEFAULT false |
| `created_at` | TIMESTAMPTZ | DEFAULT now() |

**Constraint**: `uq_provider_category` UNIQUE (provider_profile_id, service_category_id)

---

## system_settings

Configurações do sistema em formato chave-valor (JSONB). Somente admin.

| Column | Type | Constraints |
|--------|------|-------------|
| `id` | UUID | PK, DEFAULT gen_random_uuid() |
| `key` | VARCHAR(100) | UNIQUE, NOT NULL |
| `value` | JSONB | NOT NULL |
| `description` | TEXT | |
| `updated_by` | UUID | FK → users, ON DELETE SET NULL |
| `updated_at` | TIMESTAMPTZ | DEFAULT now() |
