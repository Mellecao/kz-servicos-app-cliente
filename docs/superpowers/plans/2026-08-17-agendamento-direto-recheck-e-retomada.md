# Agendamento Direto: Re-check e Retomada Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** No fluxo `scheduled_choose_driver`, tornar o re-check do motorista explícito e visível ao cliente, permitir várias solicitações abertas por cliente, retomar uma solicitação em andamento a partir da tela de agendamentos, e persistir passageiros/bagagens/pagamento separados por perna (ida/volta).

**Architecture:** O estado do fluxo é **derivado** da combinação `trips.status` × `trip_driver_candidates.status` — não há novo enum. As cinco fases são:

| Fase | `trips.status` | `trip_driver_candidates.status` |
|---|---|---|
| `awaitingDriver` | `awaiting_driver_confirmation` | `pending` |
| `priceOffered` | `awaiting_client_confirmation` | `accepted` |
| `awaitingRecheck` | `awaiting_driver_confirmation` | `accepted` |
| `confirmed` | `scheduled` | `accepted` |
| `rejected` | `searching_drivers` | `rejected` |

Toda transição acontece dentro de uma RPC `SECURITY DEFINER` com `pg_advisory_xact_lock` na trip. O app cliente deriva a fase via `scheduledDirectStatusFrom(tripStatus:, candidateStatus:)` e resolve a rota via `ScheduledDirectRoutes.pathFor(...)`. Passageiros e bagagens ganham uma coluna `leg` (`outbound` / `return`) para que o app motorista consiga exibir "passageiros na ida" / "passageiros na volta".

**Tech Stack:** PostgreSQL/Supabase (plpgsql, RLS, pgTAP), Flutter, flutter_bloc (Cubit), go_router, supabase_flutter, equatable, mocktail, bloc_test, flutter_test.

---

## Contexto que o executor precisa saber

**Três repositórios, todos irmãos em `C:\Projetos\`:**

| Repositório | Caminho absoluto | Papel |
|---|---|---|
| Backend (migrations) | `C:\Projetos\kz-servicos-web-app-fork\kz-servicos-web-app-fork\` | Migrations SQL + testes pgTAP. **Note o diretório aninhado duplicado — não é erro de digitação.** |
| App cliente (Flutter) | `C:\Projetos\kz-servicos-app-cliente\` | Onde este plano está salvo |
| App motorista (Flutter) | `C:\Projetos\kz-servicos-app-prestador\` | |

**Estilo de migration deste projeto:** arquivos usam marcadores goose (`-- +goose Up`, `-- +goose Down`) e **não** usam `-- +goose StatementBegin` / `StatementEnd`, mesmo em funções plpgsql. O bloco `Down` é escrito **comentado**. Siga `supabase/migrations/20260816120000_add_round_trip_addresses.sql` como referência de estilo.

**Toda função nova precisa de:** `LANGUAGE plpgsql`, `SECURITY DEFINER`, `SET search_path = public`, e depois `REVOKE EXECUTE ... FROM PUBLIC, anon;` + `GRANT EXECUTE ... TO authenticated;`.

**Fato importante descoberto na investigação:** o trigger `trg_require_driver_recheck_before_scheduled` **foi removido** pela migration `20260609104114_migration.sql`. Portanto hoje `client_accept_scheduled_price` marca a viagem como `scheduled` imediatamente, sem nenhum re-check. A Tarefa 3 introduz o re-check explicitamente dentro da RPC — não existe trigger para conflitar.

**Códigos de erro customizados** (SQLSTATE de 5 caracteres, classe `KZ` é reservada para uso do usuário):

| Código | Significado |
|---|---|
| `KZ001` | Viagem não está na fase esperada para esta operação |
| `KZ002` | Motorista não encontrado ou não aprovado |
| `KZ003` | Não é possível trocar de motorista durante o re-check |
| `KZ004` | Parâmetros de volta incoerentes com `is_round_trip_input` |

---

## File Structure

### Backend — `kz-servicos-web-app-fork/kz-servicos-web-app-fork/`

| Arquivo | Responsabilidade |
|---|---|
| `supabase/migrations/20260817120000_add_leg_to_trip_details.sql` | Coluna `leg` em `trip_passengers` e `trip_luggage`; troca a UNIQUE para incluir `leg` |
| `supabase/migrations/20260817120100_scheduled_direct_persist_details.sql` | Reescreve `client_send_scheduled_direct_request`: persiste passageiros/bagagens/pagamento, remove a trava de "uma pendente por cliente" |
| `supabase/migrations/20260817120200_scheduled_direct_explicit_recheck.sql` | `client_accept_scheduled_price` passa a exigir re-check; `driver_reject_scheduled_direct` passa a aceitar recusa durante o re-check |
| `supabase/migrations/20260817120300_scheduled_direct_retarget_and_quote.sql` | `client_retarget_scheduled_direct_request` e `client_convert_scheduled_direct_to_quote` |
| `supabase/migrations/20260817120400_driver_confirm_scheduled_recheck.sql` | `driver_confirm_scheduled_recheck` — fecha o ciclo marcando `scheduled` e gravando `final_price` |
| `supabase/tests/scheduled_direct/01_leg_columns_test.sql` | pgTAP estrutural das colunas `leg` |
| `supabase/tests/scheduled_direct/02_rpc_signatures_test.sql` | pgTAP das assinaturas das RPCs novas/alteradas |

### App cliente — `kz-servicos-app-cliente/`

| Arquivo | Responsabilidade |
|---|---|
| `lib/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart` | (modificar) adiciona `awaitingRecheck` ao enum e à função derivadora |
| `lib/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart` | (modificar) ganha `pathFor(...)` que mapeia fase → rota |
| `lib/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart` | (criar) traduz SQLSTATE `KZ00x` em erro tipado |
| `lib/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart` | (criar) `sealed class` — sessão nova vs. sessão retomada |
| `lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart` | (modificar) `sendRequest` estendido, `fetchRequestByTripId`, `retarget`, `convertToQuote` |
| `lib/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate.dart` | (deletar) substituído por `ScheduledDirectRoutes.pathFor` |
| `lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart` | (modificar) passa a receber uma sessão em vez de 12 parâmetros soltos |
| `lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart` | (modificar) diálogo de confirmação de troca de motorista |
| `lib/features/scheduled_choose_driver/presentation/widgets/driver_selection_content.dart` | (modificar) `disableRequests` durante o re-check |
| `lib/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart` | (modificar) busca por `tripId` em vez de por cliente |
| `lib/features/trip/domain/entities/scheduled_trip.dart` + `lib/features/trip/data/models/scheduled_trip_model.dart` | (modificar) ganham `tripType` e `candidateStatus` |
| `lib/features/profile/presentation/widgets/scheduled_trip_widget.dart` | (modificar) tags de status novas + toque retoma o fluxo |
| `lib/features/trip/presentation/pages/trip_home_page.dart` | (modificar) remove a trava local; passa passageiros/bagagens/pagamento |
| `lib/routes/app_router.dart` | (modificar) rota `/scheduled-choose-driver/select` aceita sessão retomada |

### App motorista — `kz-servicos-app-prestador/`

| Arquivo | Responsabilidade |
|---|---|
| `lib/core/models/trip_data.dart` | (modificar) `leg` em `TripPassenger`/`TripLuggage` + getters por perna |
| `lib/core/services/trip_service.dart` | (modificar) selects incluem `leg` |
| `lib/features/home/presentation/widgets/trip_request_card.dart` | (modificar) seções "na ida" / "na volta" |
| `lib/features/home/presentation/widgets/pending_trip_requests_carousel.dart` | (modificar) mesmas seções por perna |
| `lib/features/schedules/presentation/pages/schedule_detail_page.dart` | (modificar) seções por perna + confirmar/recusar re-check via RPC |
| `lib/features/schedules/data/repositories/scheduled_direct_repository.dart` | (modificar) ganha `confirmRecheck` e `reject(reason:)` |

---

# Fase 1 — Backend (migrations SQL)

Todas as tarefas desta fase acontecem em `C:\Projetos\kz-servicos-web-app-fork\kz-servicos-web-app-fork\`. Rode os comandos a partir desse diretório.

---

### Task 1: Coluna `leg` em passageiros e bagagens

**Files:**
- Create: `supabase/migrations/20260817120000_add_leg_to_trip_details.sql`
- Test: `supabase/tests/scheduled_direct/01_leg_columns_test.sql`

**Por quê:** hoje `trip_passengers` tem `UNIQUE (trip_id, sort_order)`, o que impede uma viagem de ida-e-volta ter o passageiro `sort_order = 0` nas duas pernas. A coluna `leg` entra na chave.

- [ ] **Step 1: Escrever o teste pgTAP que falha**

Crie o diretório `supabase/tests/scheduled_direct/` e o arquivo `01_leg_columns_test.sql`:

```sql
-- pgTAP test — coluna leg em trip_passengers e trip_luggage
BEGIN;
SELECT plan(6);

SELECT has_column('public', 'trip_passengers', 'leg', 'trip_passengers has leg column');
SELECT has_column('public', 'trip_luggage', 'leg', 'trip_luggage has leg column');

SELECT col_not_null('public', 'trip_passengers', 'leg', 'trip_passengers.leg is NOT NULL');
SELECT col_not_null('public', 'trip_luggage', 'leg', 'trip_luggage.leg is NOT NULL');

SELECT is(
  (SELECT count(*)::int
     FROM pg_constraint
    WHERE conname = 'trip_passengers_trip_id_leg_sort_order_key'),
  1,
  'trip_passengers unique key includes leg'
);

SELECT is(
  (SELECT count(*)::int
     FROM pg_constraint
    WHERE conname = 'trip_passengers_leg_valid'),
  1,
  'trip_passengers has leg CHECK constraint'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `supabase test db`
Expected: FAIL — `column "leg" does not exist` / `has_column` retorna falso.

- [ ] **Step 3: Escrever a migration**

Crie `supabase/migrations/20260817120000_add_leg_to_trip_details.sql`:

```sql
-- ============================================================================
-- Perna (ida/volta) em passageiros e bagagens
-- Permite que uma viagem de ida e volta tenha listas independentes por perna.
-- ============================================================================

-- +goose Up
ALTER TABLE public.trip_passengers
  ADD COLUMN IF NOT EXISTS leg text NOT NULL DEFAULT 'outbound';

ALTER TABLE public.trip_luggage
  ADD COLUMN IF NOT EXISTS leg text NOT NULL DEFAULT 'outbound';

ALTER TABLE public.trip_passengers
  DROP CONSTRAINT IF EXISTS trip_passengers_leg_valid;
ALTER TABLE public.trip_passengers
  ADD CONSTRAINT trip_passengers_leg_valid CHECK (leg IN ('outbound', 'return'));

ALTER TABLE public.trip_luggage
  DROP CONSTRAINT IF EXISTS trip_luggage_leg_valid;
ALTER TABLE public.trip_luggage
  ADD CONSTRAINT trip_luggage_leg_valid CHECK (leg IN ('outbound', 'return'));

ALTER TABLE public.trip_passengers
  DROP CONSTRAINT IF EXISTS trip_passengers_trip_id_sort_order_key;
ALTER TABLE public.trip_passengers
  ADD CONSTRAINT trip_passengers_trip_id_leg_sort_order_key
    UNIQUE (trip_id, leg, sort_order);

CREATE INDEX IF NOT EXISTS idx_trip_passengers_trip_id_leg
  ON public.trip_passengers(trip_id, leg);
CREATE INDEX IF NOT EXISTS idx_trip_luggage_trip_id_leg
  ON public.trip_luggage(trip_id, leg);

-- +goose Down
-- DROP INDEX IF EXISTS public.idx_trip_luggage_trip_id_leg;
-- DROP INDEX IF EXISTS public.idx_trip_passengers_trip_id_leg;
-- ALTER TABLE public.trip_passengers
--   DROP CONSTRAINT IF EXISTS trip_passengers_trip_id_leg_sort_order_key;
-- ALTER TABLE public.trip_passengers
--   ADD CONSTRAINT trip_passengers_trip_id_sort_order_key UNIQUE (trip_id, sort_order);
-- ALTER TABLE public.trip_luggage DROP CONSTRAINT IF EXISTS trip_luggage_leg_valid;
-- ALTER TABLE public.trip_passengers DROP CONSTRAINT IF EXISTS trip_passengers_leg_valid;
-- ALTER TABLE public.trip_luggage DROP COLUMN IF EXISTS leg;
-- ALTER TABLE public.trip_passengers DROP COLUMN IF EXISTS leg;
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `supabase db reset && supabase test db`
Expected: `01_leg_columns_test.sql .. ok` — 6 de 6.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260817120000_add_leg_to_trip_details.sql supabase/tests/scheduled_direct/01_leg_columns_test.sql
git commit -m "feat(db): adiciona coluna leg em trip_passengers e trip_luggage"
```

---

### Task 2: `client_send_scheduled_direct_request` persiste detalhes e permite múltiplas pendentes

**Files:**
- Create: `supabase/migrations/20260817120100_scheduled_direct_persist_details.sql`
- Reference: `supabase/migrations/20260816120000_add_round_trip_addresses.sql` (versão atual da função)

**Duas mudanças de comportamento:**
1. Remove a trava `IF EXISTS (... status IN ('awaiting_driver_confirmation','awaiting_client_confirmation')) THEN RAISE 'Voce ja tem uma solicitacao pendente'` — o cliente pode ter várias solicitações abertas.
2. Grava `payment_method`, contagem de crianças/bagagens e as linhas de `trip_passengers` / `trip_luggage` das duas pernas.

Os sete parâmetros novos têm `DEFAULT`, então apps já instalados que chamam a versão de 11 parâmetros continuam funcionando.

- [ ] **Step 1: Escrever o teste pgTAP que falha**

Crie `supabase/tests/scheduled_direct/02_rpc_signatures_test.sql`:

```sql
-- pgTAP test — assinaturas das RPCs do fluxo agendamento direto
BEGIN;
SELECT plan(4);

SELECT has_function(
  'public',
  'client_send_scheduled_direct_request',
  ARRAY['uuid','uuid','uuid','uuid','integer','text','timestamptz',
        'boolean','timestamptz','uuid','uuid',
        'payment_method','integer','integer',
        'jsonb','jsonb','jsonb','jsonb'],
  'client_send_scheduled_direct_request accepts passenger/luggage payload'
);

SELECT has_function(
  'public',
  'client_retarget_scheduled_direct_request',
  ARRAY['uuid','uuid'],
  'client_retarget_scheduled_direct_request exists'
);

SELECT has_function(
  'public',
  'client_convert_scheduled_direct_to_quote',
  ARRAY['uuid'],
  'client_convert_scheduled_direct_to_quote exists'
);

SELECT has_function(
  'public',
  'driver_confirm_scheduled_recheck',
  ARRAY['uuid','text'],
  'driver_confirm_scheduled_recheck exists'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `supabase test db`
Expected: FAIL — as 4 asserções falham (funções ainda não existem com essas assinaturas).

- [ ] **Step 3: Escrever a migration**

Crie `supabase/migrations/20260817120100_scheduled_direct_persist_details.sql`:

```sql
-- ============================================================================
-- Agendamento direto: persistência de detalhes e múltiplas solicitações
-- Grava passageiros, bagagens e forma de pagamento no momento do envio, e
-- remove a trava de uma solicitacao pendente por cliente.
-- ============================================================================

-- +goose Up
DROP FUNCTION IF EXISTS public.client_send_scheduled_direct_request(
  uuid, uuid, uuid, uuid, integer, text, timestamptz,
  boolean, timestamptz, uuid, uuid
);

CREATE OR REPLACE FUNCTION public.client_send_scheduled_direct_request(
  driver_profile_id_input uuid,
  pickup_address_id_input uuid,
  dropoff_address_id_input uuid,
  service_category_id_input uuid,
  passenger_count_input integer,
  observation_input text,
  scheduled_datetime_input timestamptz,
  is_round_trip_input boolean DEFAULT false,
  return_datetime_input timestamptz DEFAULT NULL,
  return_pickup_address_id_input uuid DEFAULT NULL,
  return_dropoff_address_id_input uuid DEFAULT NULL,
  payment_method_input payment_method DEFAULT NULL,
  children_count_input integer DEFAULT 0,
  luggage_count_input integer DEFAULT 0,
  passengers_input jsonb DEFAULT '[]'::jsonb,
  luggage_input jsonb DEFAULT '[]'::jsonb,
  return_passengers_input jsonb DEFAULT '[]'::jsonb,
  return_luggage_input jsonb DEFAULT '[]'::jsonb
) RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_trip_id uuid;
  v_provider_status text;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  IF scheduled_datetime_input IS NULL THEN
    RAISE EXCEPTION 'scheduled_datetime obrigatorio';
  END IF;

  IF is_round_trip_input AND (
    return_datetime_input IS NULL OR
    return_pickup_address_id_input IS NULL OR
    return_dropoff_address_id_input IS NULL
  ) THEN
    RAISE EXCEPTION 'Dados da volta obrigatorios para ida e volta'
      USING ERRCODE = 'KZ004';
  END IF;

  IF NOT is_round_trip_input AND (
    return_datetime_input IS NOT NULL OR
    return_pickup_address_id_input IS NOT NULL OR
    return_dropoff_address_id_input IS NOT NULL OR
    jsonb_array_length(COALESCE(return_passengers_input, '[]'::jsonb)) > 0 OR
    jsonb_array_length(COALESCE(return_luggage_input, '[]'::jsonb)) > 0
  ) THEN
    RAISE EXCEPTION 'Dados de volta enviados em viagem so de ida'
      USING ERRCODE = 'KZ004';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(v_client_id::text, 0));

  SELECT pp.status::text INTO v_provider_status
    FROM driver_profiles dp
    JOIN provider_profiles pp ON pp.id = dp.provider_profile_id
   WHERE dp.id = driver_profile_id_input;

  IF v_provider_status IS NULL THEN
    RAISE EXCEPTION 'Motorista nao encontrado' USING ERRCODE = 'KZ002';
  END IF;

  IF v_provider_status <> 'approved' THEN
    RAISE EXCEPTION 'Motorista nao aprovado' USING ERRCODE = 'KZ002';
  END IF;

  INSERT INTO trips (
    client_id,
    driver_profile_id,
    trip_type,
    status,
    pickup_address_id,
    dropoff_address_id,
    return_pickup_address_id,
    return_dropoff_address_id,
    service_category_id,
    passenger_count,
    children_count,
    luggage_count,
    payment_method,
    observations,
    scheduled_datetime,
    is_round_trip,
    return_datetime
  ) VALUES (
    v_client_id,
    driver_profile_id_input,
    'scheduled_choose_driver',
    'awaiting_driver_confirmation',
    pickup_address_id_input,
    dropoff_address_id_input,
    return_pickup_address_id_input,
    return_dropoff_address_id_input,
    service_category_id_input,
    passenger_count_input,
    COALESCE(children_count_input, 0),
    COALESCE(luggage_count_input, 0),
    payment_method_input,
    observation_input,
    scheduled_datetime_input,
    is_round_trip_input,
    return_datetime_input
  ) RETURNING id INTO v_trip_id;

  INSERT INTO trip_passengers (trip_id, name, age, sort_order, leg)
  SELECT v_trip_id,
         elem->>'name',
         (elem->>'age')::integer,
         (ord - 1)::integer,
         'outbound'
    FROM jsonb_array_elements(COALESCE(passengers_input, '[]'::jsonb))
         WITH ORDINALITY AS t(elem, ord);

  INSERT INTO trip_luggage (trip_id, type, size, weight_kg, quantity, sort_order, leg)
  SELECT v_trip_id,
         COALESCE(elem->>'type', 'unspecified'),
         (elem->>'size')::luggage_size,
         (elem->>'weight_kg')::numeric,
         COALESCE((elem->>'quantity')::integer, 1),
         (ord - 1)::integer,
         'outbound'
    FROM jsonb_array_elements(COALESCE(luggage_input, '[]'::jsonb))
         WITH ORDINALITY AS t(elem, ord);

  INSERT INTO trip_passengers (trip_id, name, age, sort_order, leg)
  SELECT v_trip_id,
         elem->>'name',
         (elem->>'age')::integer,
         (ord - 1)::integer,
         'return'
    FROM jsonb_array_elements(COALESCE(return_passengers_input, '[]'::jsonb))
         WITH ORDINALITY AS t(elem, ord);

  INSERT INTO trip_luggage (trip_id, type, size, weight_kg, quantity, sort_order, leg)
  SELECT v_trip_id,
         COALESCE(elem->>'type', 'unspecified'),
         (elem->>'size')::luggage_size,
         (elem->>'weight_kg')::numeric,
         COALESCE((elem->>'quantity')::integer, 1),
         (ord - 1)::integer,
         'return'
    FROM jsonb_array_elements(COALESCE(return_luggage_input, '[]'::jsonb))
         WITH ORDINALITY AS t(elem, ord);

  INSERT INTO trip_driver_candidates (
    trip_id,
    driver_profile_id,
    status,
    last_push_at
  ) VALUES (
    v_trip_id,
    driver_profile_id_input,
    'pending',
    now()
  );

  RETURN v_trip_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.client_send_scheduled_direct_request(
  uuid, uuid, uuid, uuid, integer, text, timestamptz,
  boolean, timestamptz, uuid, uuid,
  payment_method, integer, integer, jsonb, jsonb, jsonb, jsonb
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.client_send_scheduled_direct_request(
  uuid, uuid, uuid, uuid, integer, text, timestamptz,
  boolean, timestamptz, uuid, uuid,
  payment_method, integer, integer, jsonb, jsonb, jsonb, jsonb
) TO authenticated;

-- +goose Down
-- DROP FUNCTION IF EXISTS public.client_send_scheduled_direct_request(
--   uuid, uuid, uuid, uuid, integer, text, timestamptz,
--   boolean, timestamptz, uuid, uuid,
--   payment_method, integer, integer, jsonb, jsonb, jsonb, jsonb
-- );
```

- [ ] **Step 4: Confirmar que `trips` tem as colunas usadas**

Run:
```bash
supabase db reset
psql "$DATABASE_URL" -c "\d public.trips" | grep -E "children_count|luggage_count|payment_method"
```
Expected: as três colunas aparecem. Se alguma **não** existir, adicione no topo do bloco `-- +goose Up` desta mesma migration:
```sql
ALTER TABLE public.trips
  ADD COLUMN IF NOT EXISTS children_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS luggage_count integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS payment_method payment_method;
```

- [ ] **Step 5: Rodar o teste**

Run: `supabase db reset && supabase test db`
Expected: a primeira asserção de `02_rpc_signatures_test.sql` passa; as outras três ainda falham (Tasks 5-7).

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260817120100_scheduled_direct_persist_details.sql supabase/tests/scheduled_direct/02_rpc_signatures_test.sql
git commit -m "feat(db): persiste passageiros, bagagens e pagamento no envio de agendamento direto"
```

---

### Task 3: `client_accept_scheduled_price` passa a exigir re-check

**Files:**
- Create: `supabase/migrations/20260817120200_scheduled_direct_explicit_recheck.sql`
- Reference: `supabase/migrations/20260729210453_scheduled_choose_driver_rpcs.sql:188-229` (versão atual)

**Mudança:** hoje a função grava `status = 'scheduled', final_price = v_offered_price`. Passa a gravar `status = 'awaiting_driver_confirmation'` e **não** grava `final_price` — o preço continua vivendo em `trip_driver_candidates.offered_price` até o motorista confirmar o re-check (Task 6). O candidato permanece `accepted`, o que produz a fase `awaitingRecheck`.

**`client_reject_scheduled_price` não muda.** Ela já devolve a viagem para `searching_drivers` com o candidato em `rejected` e nunca escreveu `final_price` — depois desta task, nem o caminho de aceite escreve. Não crie migration para ela.

- [ ] **Step 1: Escrever a migration**

Crie `supabase/migrations/20260817120200_scheduled_direct_explicit_recheck.sql`:

```sql
-- ============================================================================
-- Agendamento direto: re-check explicito do motorista
-- Aceitar o preco devolve a viagem para o motorista confirmar, em vez de
-- agendar direto. O motorista tambem pode recusar durante o re-check.
-- ============================================================================

-- +goose Up
CREATE OR REPLACE FUNCTION public.client_accept_scheduled_price(trip_id_input uuid) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_offered_price numeric;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(trip_id_input::text, 0));

  IF NOT EXISTS (
    SELECT 1 FROM trips
     WHERE id = trip_id_input
       AND client_id = v_client_id
       AND trip_type = 'scheduled_choose_driver'
       AND status = 'awaiting_client_confirmation'
  ) THEN
    RAISE EXCEPTION 'Corrida nao esta aguardando sua confirmacao'
      USING ERRCODE = 'KZ001';
  END IF;

  SELECT offered_price INTO v_offered_price
    FROM trip_driver_candidates
   WHERE trip_id = trip_id_input
     AND status = 'accepted';

  IF v_offered_price IS NULL THEN
    RAISE EXCEPTION 'Sem preco proposto para esta corrida'
      USING ERRCODE = 'KZ001';
  END IF;

  UPDATE trips
     SET status = 'awaiting_driver_confirmation', updated_at = now()
   WHERE id = trip_id_input;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.client_accept_scheduled_price(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.client_accept_scheduled_price(uuid) TO authenticated;

DROP FUNCTION IF EXISTS public.driver_reject_scheduled_direct(uuid);

CREATE OR REPLACE FUNCTION public.driver_reject_scheduled_direct(
  trip_id_input uuid,
  reason_input text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_driver_profile_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(trip_id_input::text, 0));

  SELECT dp.id INTO v_driver_profile_id
    FROM driver_profiles dp
    JOIN provider_profiles pp ON pp.id = dp.provider_profile_id
   WHERE pp.user_id = v_user_id;

  IF v_driver_profile_id IS NULL THEN
    RAISE EXCEPTION 'Usuario nao e motorista' USING ERRCODE = 'KZ002';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM trip_driver_candidates
     WHERE trip_id = trip_id_input
       AND driver_profile_id = v_driver_profile_id
       AND status IN ('pending', 'accepted')
  ) THEN
    RAISE EXCEPTION 'Voce nao tem candidatura ativa nesta corrida'
      USING ERRCODE = 'KZ001';
  END IF;

  UPDATE trip_driver_candidates
     SET status = 'rejected',
         offered_price = NULL
   WHERE trip_id = trip_id_input
     AND driver_profile_id = v_driver_profile_id;

  UPDATE trips
     SET status = 'searching_drivers',
         driver_profile_id = NULL,
         final_price = NULL,
         observations = CASE
           WHEN reason_input IS NULL OR btrim(reason_input) = '' THEN observations
           ELSE COALESCE(observations || E'\n', '') || 'Motorista recusou: ' || reason_input
         END,
         updated_at = now()
   WHERE id = trip_id_input
     AND trip_type = 'scheduled_choose_driver';
END;
$$;

REVOKE EXECUTE ON FUNCTION public.driver_reject_scheduled_direct(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.driver_reject_scheduled_direct(uuid, text) TO authenticated;

-- +goose Down
-- DROP FUNCTION IF EXISTS public.driver_reject_scheduled_direct(uuid, text);
```

- [ ] **Step 2: Aplicar e verificar**

Run: `supabase db reset`
Expected: aplica sem erro.

Run:
```bash
psql "$DATABASE_URL" -c "SELECT prosrc LIKE '%awaiting_driver_confirmation%' AS ok FROM pg_proc WHERE proname = 'client_accept_scheduled_price';"
```
Expected: `ok | t`

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260817120200_scheduled_direct_explicit_recheck.sql
git commit -m "feat(db): torna o re-check do motorista explicito ao aceitar preco"
```

---

### Task 4: Teste pgTAP do re-check

**Files:**
- Create: `supabase/tests/scheduled_direct/03_recheck_transitions_test.sql`

Os testes deste projeto são **estruturais** — inserir uma trip completa exigiria fixtures de `auth.users`, `addresses`, `driver_profiles` e `provider_profiles`. Siga o padrão de `supabase/tests/flash/03_flash_no_scheduling_test.sql` e verifique o corpo das funções.

- [ ] **Step 1: Escrever o teste**

```sql
-- pgTAP test — transicoes do re-check no agendamento direto
BEGIN;
SELECT plan(4);

SELECT is(
  (SELECT prosrc LIKE '%awaiting_driver_confirmation%'
     FROM pg_proc WHERE proname = 'client_accept_scheduled_price'),
  true,
  'client_accept_scheduled_price devolve a viagem para o motorista'
);

SELECT is(
  (SELECT prosrc LIKE '%final_price%'
     FROM pg_proc WHERE proname = 'client_accept_scheduled_price'),
  false,
  'client_accept_scheduled_price nao grava final_price'
);

SELECT is(
  (SELECT prosrc LIKE '%IN (''pending'', ''accepted'')%'
     FROM pg_proc WHERE proname = 'driver_reject_scheduled_direct'),
  true,
  'driver_reject_scheduled_direct aceita recusa durante o re-check'
);

SELECT has_function(
  'public',
  'driver_reject_scheduled_direct',
  ARRAY['uuid','text'],
  'driver_reject_scheduled_direct aceita motivo opcional'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Rodar**

Run: `supabase test db`
Expected: `03_recheck_transitions_test.sql .. ok` — 4 de 4.

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/scheduled_direct/03_recheck_transitions_test.sql
git commit -m "test(db): cobre transicoes do re-check do agendamento direto"
```

---

### Task 5: `client_retarget_scheduled_direct_request` — trocar de motorista

**Files:**
- Create: `supabase/migrations/20260817120300_scheduled_direct_retarget_and_quote.sql`

**Por quê:** quando o cliente retoma uma solicitação (fase `awaitingDriver` ou `rejected`), ele volta para a lista de motoristas. Ao escolher outro motorista, a viagem existente é **reapontada** — não se cria uma nova. `trip_driver_candidates` já tem `UNIQUE(trip_id, driver_profile_id)`, então um motorista já recusado antes pode ser reconvidado via `ON CONFLICT DO UPDATE`.

Trocar de motorista **durante o re-check** é proibido (`KZ003`): o cliente já aceitou um preço e o motorista está decidindo.

- [ ] **Step 1: Escrever a migration**

Crie `supabase/migrations/20260817120300_scheduled_direct_retarget_and_quote.sql`:

```sql
-- ============================================================================
-- Agendamento direto: trocar de motorista e converter em cotacao
-- Permite retomar uma solicitacao em andamento sem criar uma viagem nova.
-- ============================================================================

-- +goose Up
CREATE OR REPLACE FUNCTION public.client_retarget_scheduled_direct_request(
  trip_id_input uuid,
  driver_profile_id_input uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_trip_status text;
  v_candidate_status text;
  v_provider_status text;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(trip_id_input::text, 0));

  SELECT status::text INTO v_trip_status
    FROM trips
   WHERE id = trip_id_input
     AND client_id = v_client_id
     AND trip_type = 'scheduled_choose_driver';

  IF v_trip_status IS NULL THEN
    RAISE EXCEPTION 'Corrida nao encontrada' USING ERRCODE = 'KZ001';
  END IF;

  IF v_trip_status NOT IN ('awaiting_driver_confirmation', 'awaiting_client_confirmation', 'searching_drivers') THEN
    RAISE EXCEPTION 'Corrida nao pode mais trocar de motorista'
      USING ERRCODE = 'KZ001';
  END IF;

  SELECT status::text INTO v_candidate_status
    FROM trip_driver_candidates
   WHERE trip_id = trip_id_input
     AND status = 'accepted'
   LIMIT 1;

  IF v_trip_status = 'awaiting_driver_confirmation' AND v_candidate_status = 'accepted' THEN
    RAISE EXCEPTION 'Nao e possivel trocar de motorista durante o re-check'
      USING ERRCODE = 'KZ003';
  END IF;

  SELECT pp.status::text INTO v_provider_status
    FROM driver_profiles dp
    JOIN provider_profiles pp ON pp.id = dp.provider_profile_id
   WHERE dp.id = driver_profile_id_input;

  IF v_provider_status IS NULL OR v_provider_status <> 'approved' THEN
    RAISE EXCEPTION 'Motorista nao encontrado ou nao aprovado'
      USING ERRCODE = 'KZ002';
  END IF;

  UPDATE trip_driver_candidates
     SET status = 'rejected',
         offered_price = NULL,
         responded_at = now()
   WHERE trip_id = trip_id_input
     AND driver_profile_id <> driver_profile_id_input
     AND status IN ('pending', 'accepted');

  INSERT INTO trip_driver_candidates (trip_id, driver_profile_id, status, last_push_at)
  VALUES (trip_id_input, driver_profile_id_input, 'pending', now())
  ON CONFLICT (trip_id, driver_profile_id) DO UPDATE
     SET status = 'pending',
         offered_price = NULL,
         responded_at = NULL,
         last_push_at = now();

  UPDATE trips
     SET status = 'awaiting_driver_confirmation',
         driver_profile_id = driver_profile_id_input,
         final_price = NULL,
         updated_at = now()
   WHERE id = trip_id_input;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.client_retarget_scheduled_direct_request(uuid, uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.client_retarget_scheduled_direct_request(uuid, uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.client_convert_scheduled_direct_to_quote(trip_id_input uuid) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_trip_status text;
  v_has_accepted boolean;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(trip_id_input::text, 0));

  SELECT status::text INTO v_trip_status
    FROM trips
   WHERE id = trip_id_input
     AND client_id = v_client_id
     AND trip_type = 'scheduled_choose_driver';

  IF v_trip_status IS NULL THEN
    RAISE EXCEPTION 'Corrida nao encontrada' USING ERRCODE = 'KZ001';
  END IF;

  IF v_trip_status NOT IN ('awaiting_driver_confirmation', 'awaiting_client_confirmation', 'searching_drivers') THEN
    RAISE EXCEPTION 'Corrida nao pode mais virar cotacao' USING ERRCODE = 'KZ001';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM trip_driver_candidates
     WHERE trip_id = trip_id_input AND status = 'accepted'
  ) INTO v_has_accepted;

  IF v_trip_status = 'awaiting_driver_confirmation' AND v_has_accepted THEN
    RAISE EXCEPTION 'Nao e possivel virar cotacao durante o re-check'
      USING ERRCODE = 'KZ003';
  END IF;

  UPDATE trip_driver_candidates
     SET status = 'rejected',
         offered_price = NULL,
         responded_at = now()
   WHERE trip_id = trip_id_input
     AND status IN ('pending', 'accepted');

  UPDATE trips
     SET trip_type = 'scheduled_quote',
         status = 'searching_drivers',
         driver_profile_id = NULL,
         final_price = NULL,
         updated_at = now()
   WHERE id = trip_id_input;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.client_convert_scheduled_direct_to_quote(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.client_convert_scheduled_direct_to_quote(uuid) TO authenticated;

-- +goose Down
-- DROP FUNCTION IF EXISTS public.client_convert_scheduled_direct_to_quote(uuid);
-- DROP FUNCTION IF EXISTS public.client_retarget_scheduled_direct_request(uuid, uuid);
```

- [ ] **Step 2: Aplicar e rodar os testes**

Run: `supabase db reset && supabase test db`
Expected: em `02_rpc_signatures_test.sql` as asserções de `client_retarget_scheduled_direct_request` e `client_convert_scheduled_direct_to_quote` passam. A de `driver_confirm_scheduled_recheck` ainda falha (Task 6).

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260817120300_scheduled_direct_retarget_and_quote.sql
git commit -m "feat(db): permite trocar de motorista e converter agendamento direto em cotacao"
```

---

### Task 6: `driver_confirm_scheduled_recheck` — fecha o ciclo

**Files:**
- Create: `supabase/migrations/20260817120400_driver_confirm_scheduled_recheck.sql`

Esta é a função que fecha o requisito 2: motorista confirma o re-check → viagem vira `scheduled` e `final_price` recebe o `offered_price` do candidato.

- [ ] **Step 1: Escrever a migration**

```sql
-- ============================================================================
-- Agendamento direto: motorista confirma o re-check
-- Ultima etapa do fluxo — a viagem passa a scheduled e o preco vira final.
-- ============================================================================

-- +goose Up
CREATE OR REPLACE FUNCTION public.driver_confirm_scheduled_recheck(
  trip_id_input uuid,
  driver_observation_input text DEFAULT NULL
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_driver_profile_id uuid;
  v_offered_price numeric;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nao autenticado';
  END IF;

  PERFORM pg_advisory_xact_lock(hashtextextended(trip_id_input::text, 0));

  SELECT dp.id INTO v_driver_profile_id
    FROM driver_profiles dp
    JOIN provider_profiles pp ON pp.id = dp.provider_profile_id
   WHERE pp.user_id = v_user_id;

  IF v_driver_profile_id IS NULL THEN
    RAISE EXCEPTION 'Usuario nao e motorista' USING ERRCODE = 'KZ002';
  END IF;

  SELECT offered_price INTO v_offered_price
    FROM trip_driver_candidates
   WHERE trip_id = trip_id_input
     AND driver_profile_id = v_driver_profile_id
     AND status = 'accepted';

  IF v_offered_price IS NULL THEN
    RAISE EXCEPTION 'Voce nao tem preco aceito nesta corrida'
      USING ERRCODE = 'KZ001';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM trips
     WHERE id = trip_id_input
       AND trip_type = 'scheduled_choose_driver'
       AND status = 'awaiting_driver_confirmation'
  ) THEN
    RAISE EXCEPTION 'Corrida nao esta aguardando seu re-check'
      USING ERRCODE = 'KZ001';
  END IF;

  UPDATE trip_driver_candidates
     SET responded_at = now(),
         observations = COALESCE(driver_observation_input, observations)
   WHERE trip_id = trip_id_input
     AND driver_profile_id = v_driver_profile_id;

  UPDATE trips
     SET status = 'scheduled',
         driver_profile_id = v_driver_profile_id,
         final_price = v_offered_price,
         updated_at = now()
   WHERE id = trip_id_input;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.driver_confirm_scheduled_recheck(uuid, text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.driver_confirm_scheduled_recheck(uuid, text) TO authenticated;

-- +goose Down
-- DROP FUNCTION IF EXISTS public.driver_confirm_scheduled_recheck(uuid, text);
```

- [ ] **Step 2: Aplicar e rodar os testes**

Run: `supabase db reset && supabase test db`
Expected: **todos** os testes de `supabase/tests/scheduled_direct/` passam — `02_rpc_signatures_test.sql` 4 de 4.

- [ ] **Step 3: Commit**

```bash
git add supabase/migrations/20260817120400_driver_confirm_scheduled_recheck.sql
git commit -m "feat(db): adiciona driver_confirm_scheduled_recheck para fechar o agendamento"
```

---

### Task 7: Verificação final da Fase 1

- [ ] **Step 1: Reset limpo + suíte completa**

Run: `supabase db reset && supabase test db`
Expected: nenhuma migration falha; todos os arquivos em `supabase/tests/` reportam `ok`.

- [ ] **Step 2: Conferir que nenhuma RPC ficou sem GRANT**

Run:
```bash
psql "$DATABASE_URL" -c "SELECT proname, has_function_privilege('anon', p.oid, 'EXECUTE') AS anon_pode FROM pg_proc p WHERE proname IN ('client_send_scheduled_direct_request','client_accept_scheduled_price','client_retarget_scheduled_direct_request','client_convert_scheduled_direct_to_quote','driver_confirm_scheduled_recheck','driver_reject_scheduled_direct');"
```
Expected: `anon_pode` = `f` em todas as linhas.

- [ ] **Step 3: Commit (se algo foi ajustado)**

```bash
git add supabase/
git commit -m "chore(db): verificacao final das migrations do agendamento direto"
```

---

# Fase 2 — App cliente (Flutter)

Todas as tarefas desta fase acontecem em `C:\Projetos\kz-servicos-app-cliente\`. Rode os comandos a partir desse diretório.

**Mapa de rotas por fase** (usado nas Tasks 9, 15 e 17):

| Fase derivada | Rota |
|---|---|
| `awaitingDriver` | `/scheduled-choose-driver/select?tripId={id}` |
| `rejected` | `/scheduled-choose-driver/select?tripId={id}` |
| `priceOffered` | `/scheduled-choose-driver/price-review/{id}` |
| `awaitingRecheck` | `/scheduled-choose-driver/awaiting/{id}` |
| `confirmed` | `/trip?activeTripId={id}` |
| `cancelled` | `null` (não navega) |

O cliente volta para a **lista de motoristas** nas fases `awaitingDriver` e `rejected` porque nelas ele ainda pode trocar de motorista ou pedir cotação. Durante o `awaitingRecheck` ele já aceitou o preço e só resta esperar — por isso a tela de espera.

---

### Task 8: Fase `awaitingRecheck` no enum derivado

**Files:**
- Modify: `lib/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart`
- Test: `test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart`

**O bug:** hoje `awaiting_driver_confirmation` + `accepted` cai no `return ScheduledDirectStatus.awaitingDriver` final e o cliente não distingue "esperando o motorista responder" de "esperando o motorista confirmar o re-check".

- [ ] **Step 1: Escrever o teste que falha**

Adicione ao final do `main()` em `test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart`:

```dart
  test('re-check é distinguido da espera inicial pelo motorista', () {
    expect(
      scheduledDirectStatusFrom(
        tripStatus: 'awaiting_driver_confirmation',
        candidateStatus: 'accepted',
      ),
      ScheduledDirectStatus.awaitingRecheck,
    );
  });

  test('espera inicial continua sendo awaitingDriver', () {
    expect(
      scheduledDirectStatusFrom(
        tripStatus: 'awaiting_driver_confirmation',
        candidateStatus: 'pending',
      ),
      ScheduledDirectStatus.awaitingDriver,
    );
  });
```

Garanta que o arquivo importa:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart`
Expected: FAIL — `awaitingRecheck` não é membro de `ScheduledDirectStatus` (erro de compilação).

- [ ] **Step 3: Implementar**

Em `lib/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart`, substitua o enum e a função por:

```dart
enum ScheduledDirectStatus {
  awaitingDriver,
  priceOffered,
  awaitingRecheck,
  rejected,
  confirmed,
  cancelled,
}

ScheduledDirectStatus scheduledDirectStatusFrom({
  required String tripStatus,
  required String candidateStatus,
}) {
  if (tripStatus == 'cancelled') return ScheduledDirectStatus.cancelled;
  if (tripStatus == 'scheduled') return ScheduledDirectStatus.confirmed;
  if (tripStatus == 'awaiting_client_confirmation' &&
      candidateStatus == 'accepted') {
    return ScheduledDirectStatus.priceOffered;
  }
  if (tripStatus == 'awaiting_driver_confirmation' &&
      candidateStatus == 'accepted') {
    return ScheduledDirectStatus.awaitingRecheck;
  }
  if (tripStatus == 'searching_drivers' && candidateStatus == 'rejected') {
    return ScheduledDirectStatus.rejected;
  }
  return ScheduledDirectStatus.awaitingDriver;
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart`
Expected: todos os testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart
git commit -m "feat: distingue a fase de re-check no agendamento direto"
```

---

### Task 9: `ScheduledDirectRoutes.pathFor` substitui o gate

**Files:**
- Modify: `lib/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart`
- Test: `test/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes_test.dart`
- Delete: `lib/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate.dart`
- Delete: `test/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate_test.dart`

**Por quê deletar o gate:** `ActiveScheduledDirectGate.resolveTargetPath()` é código morto (nenhum caller em `lib/`) e `resolvePathForTrip` decide a rota olhando só `trips.status` — insuficiente agora que `awaiting_driver_confirmation` significa duas coisas diferentes. Único consumidor: `lib/features/trip/presentation/pages/trip_home_page.dart:4047` (ajustado na Task 17).

- [ ] **Step 1: Escrever os testes que falham**

Substitua todo o conteúdo de `test/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes_test.dart` por:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart';

void main() {
  test('corrida confirmada usa a rota ativa existente no app', () {
    expect(
      ScheduledDirectRoutes.activeTrip('trip-123'),
      '/trip?activeTripId=trip-123',
    );
  });

  group('ScheduledDirectRoutes.pathFor', () {
    test('espera inicial volta para a lista de motoristas', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-1',
          tripStatus: 'awaiting_driver_confirmation',
          candidateStatus: 'pending',
        ),
        '/scheduled-choose-driver/select?tripId=trip-1',
      );
    });

    test('recusa do motorista volta para a lista de motoristas', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-2',
          tripStatus: 'searching_drivers',
          candidateStatus: 'rejected',
        ),
        '/scheduled-choose-driver/select?tripId=trip-2',
      );
    });

    test('preço proposto abre a revisão de preço', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-3',
          tripStatus: 'awaiting_client_confirmation',
          candidateStatus: 'accepted',
        ),
        '/scheduled-choose-driver/price-review/trip-3',
      );
    });

    test('re-check abre a tela de espera', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-4',
          tripStatus: 'awaiting_driver_confirmation',
          candidateStatus: 'accepted',
        ),
        '/scheduled-choose-driver/awaiting/trip-4',
      );
    });

    test('corrida agendada vai para a corrida ativa', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-5',
          tripStatus: 'scheduled',
          candidateStatus: 'accepted',
        ),
        '/trip?activeTripId=trip-5',
      );
    });

    test('corrida cancelada não navega', () {
      expect(
        ScheduledDirectRoutes.pathFor(
          tripId: 'trip-6',
          tripStatus: 'cancelled',
          candidateStatus: 'rejected',
        ),
        isNull,
      );
    });
  });
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes_test.dart`
Expected: FAIL — `pathFor` não existe.

- [ ] **Step 3: Implementar**

Substitua todo o conteúdo de `lib/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart` por:

```dart
import '../entities/scheduled_direct_request.dart';

abstract final class ScheduledDirectRoutes {
  static String activeTrip(String tripId) =>
      Uri(path: '/trip', queryParameters: {'activeTripId': tripId}).toString();

  static String driverSelection(String tripId) => Uri(
    path: '/scheduled-choose-driver/select',
    queryParameters: {'tripId': tripId},
  ).toString();

  static String? pathFor({
    required String tripId,
    required String tripStatus,
    required String candidateStatus,
  }) {
    final phase = scheduledDirectStatusFrom(
      tripStatus: tripStatus,
      candidateStatus: candidateStatus,
    );
    return switch (phase) {
      ScheduledDirectStatus.awaitingDriver => driverSelection(tripId),
      ScheduledDirectStatus.rejected => driverSelection(tripId),
      ScheduledDirectStatus.priceOffered =>
        '/scheduled-choose-driver/price-review/$tripId',
      ScheduledDirectStatus.awaitingRecheck =>
        '/scheduled-choose-driver/awaiting/$tripId',
      ScheduledDirectStatus.confirmed => activeTrip(tripId),
      ScheduledDirectStatus.cancelled => null,
    };
  }
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes_test.dart`
Expected: 7 testes passam.

- [ ] **Step 5: Deletar o gate e o teste dele**

```bash
git rm lib/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate.dart test/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate_test.dart
```

- [ ] **Step 6: Confirmar que só sobrou um caller quebrado**

Run: `flutter analyze`
Expected: erro somente em `lib/features/trip/presentation/pages/trip_home_page.dart` (import + uso de `ActiveScheduledDirectGate`). Isso é esperado e será corrigido na Task 17.

- [ ] **Step 7: Commit**

```bash
git add lib/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart test/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes_test.dart
git commit -m "feat: resolve rota do agendamento direto pela fase derivada"
```

---

### Task 10: Erro tipado para os SQLSTATE `KZ00x`

**Files:**
- Create: `lib/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart`
- Test: `test/features/scheduled_choose_driver/domain/errors/scheduled_direct_error_test.dart`

**Por quê:** a UI precisa reagir diferente a "não dá pra trocar de motorista durante o re-check" (`KZ003`, mostra explicação) e a um erro genérico. Comparar substring da mensagem é frágil.

- [ ] **Step 1: Escrever o teste que falha**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('ScheduledDirectException.from', () {
    test('mapeia KZ003 para lockedByRecheck', () {
      final error = ScheduledDirectException.from(
        const PostgrestException(
          message: 'Nao e possivel trocar de motorista durante o re-check',
          code: 'KZ003',
        ),
      );
      expect(error.code, ScheduledDirectErrorCode.lockedByRecheck);
      expect(error.message, 'Nao e possivel trocar de motorista durante o re-check');
    });

    test('mapeia KZ001 para wrongPhase', () {
      final error = ScheduledDirectException.from(
        const PostgrestException(message: 'fora de fase', code: 'KZ001'),
      );
      expect(error.code, ScheduledDirectErrorCode.wrongPhase);
    });

    test('mapeia KZ002 para driverUnavailable', () {
      final error = ScheduledDirectException.from(
        const PostgrestException(message: 'motorista', code: 'KZ002'),
      );
      expect(error.code, ScheduledDirectErrorCode.driverUnavailable);
    });

    test('mapeia KZ004 para invalidReturnData', () {
      final error = ScheduledDirectException.from(
        const PostgrestException(message: 'volta', code: 'KZ004'),
      );
      expect(error.code, ScheduledDirectErrorCode.invalidReturnData);
    });

    test('código desconhecido vira unknown preservando a mensagem', () {
      final error = ScheduledDirectException.from(
        const PostgrestException(message: 'boom', code: 'P0001'),
      );
      expect(error.code, ScheduledDirectErrorCode.unknown);
      expect(error.message, 'boom');
    });

    test('erro que não é PostgrestException vira unknown', () {
      final error = ScheduledDirectException.from(StateError('offline'));
      expect(error.code, ScheduledDirectErrorCode.unknown);
      expect(error.message, contains('offline'));
    });
  });
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/domain/errors/scheduled_direct_error_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

Crie `lib/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

enum ScheduledDirectErrorCode {
  wrongPhase,
  driverUnavailable,
  lockedByRecheck,
  invalidReturnData,
  unknown,
}

class ScheduledDirectException implements Exception {
  const ScheduledDirectException(this.code, this.message);

  final ScheduledDirectErrorCode code;
  final String message;

  factory ScheduledDirectException.from(Object error) {
    if (error is PostgrestException) {
      return ScheduledDirectException(
        switch (error.code) {
          'KZ001' => ScheduledDirectErrorCode.wrongPhase,
          'KZ002' => ScheduledDirectErrorCode.driverUnavailable,
          'KZ003' => ScheduledDirectErrorCode.lockedByRecheck,
          'KZ004' => ScheduledDirectErrorCode.invalidReturnData,
          _ => ScheduledDirectErrorCode.unknown,
        },
        error.message,
      );
    }
    return ScheduledDirectException(
      ScheduledDirectErrorCode.unknown,
      error.toString(),
    );
  }

  @override
  String toString() => message;
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/domain/errors/scheduled_direct_error_test.dart`
Expected: 6 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart test/features/scheduled_choose_driver/domain/errors/scheduled_direct_error_test.dart
git commit -m "feat: erro tipado para os codigos KZ do agendamento direto"
```

---

### Task 11: Payload RPC de passageiros e bagagens

**Files:**
- Modify: `lib/features/trip/data/models/trip_passenger_model.dart`
- Modify: `lib/features/trip/data/models/trip_luggage_model.dart`
- Test: `test/features/trip/data/models/trip_models_test.dart`

**Por quê:** `toInsertJson` inclui `trip_id` e `sort_order`, que fazem sentido num INSERT direto. A RPC recebe um array JSON sem `trip_id` (ela sabe o id) e deriva `sort_order` da ordem do array (`WITH ORDINALITY`). Precisamos de um serializador separado.

- [ ] **Step 1: Escrever os testes que falham**

Adicione ao final do `main()` em `test/features/trip/data/models/trip_models_test.dart`:

```dart
  group('payload RPC', () {
    test('passageiro serializa sem trip_id nem sort_order', () {
      expect(
        TripPassengerModel.buildRpcJsonList(const [
          TripPassengerData(name: 'Ana', age: 30),
          TripPassengerData(name: 'Bruno', age: 8),
        ]),
        [
          {'name': 'Ana', 'age': 30},
          {'name': 'Bruno', 'age': 8},
        ],
      );
    });

    test('bagagem serializa sem trip_id nem sort_order', () {
      expect(
        TripLuggageModel.buildRpcJsonList(const [
          TripLuggageData(type: 'mala', size: 'large', weightKg: 22.5, quantity: 2),
        ]),
        [
          {'type': 'mala', 'size': 'large', 'weight_kg': 22.5, 'quantity': 2},
        ],
      );
    });

    test('bagagem sem peso omite weight_kg', () {
      expect(
        TripLuggageModel.buildRpcJsonList(const [
          TripLuggageData(type: 'mochila', size: 'small'),
        ]),
        [
          {'type': 'mochila', 'size': 'small', 'quantity': 1},
        ],
      );
    });
  });
```

Confirme que o arquivo já importa `TripPassengerModel`, `TripLuggageModel`, `TripPassengerData` e `TripLuggageData`; adicione os imports que faltarem:

```dart
import 'package:kz_servicos_app/features/trip/data/models/trip_luggage_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_passenger_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/trip/data/models/trip_models_test.dart`
Expected: FAIL — `buildRpcJsonList` não está definido.

- [ ] **Step 3: Implementar em `trip_passenger_model.dart`**

Adicione dentro da classe `TripPassengerModel`, logo depois de `toInsertJson`:

```dart
  Map<String, dynamic> toRpcJson() => {'name': name, 'age': age};

  static List<Map<String, dynamic>> buildRpcJsonList(
    List<TripPassengerData> passengers,
  ) => [
    for (final passenger in passengers)
      TripPassengerModel.fromEntity(passenger).toRpcJson(),
  ];
```

- [ ] **Step 4: Implementar em `trip_luggage_model.dart`**

Adicione dentro da classe `TripLuggageModel`, logo depois de `toInsertJson`:

```dart
  Map<String, dynamic> toRpcJson() => {
    'type': type,
    'size': size,
    if (weightKg != null) 'weight_kg': weightKg,
    'quantity': quantity,
  };

  static List<Map<String, dynamic>> buildRpcJsonList(
    List<TripLuggageData> luggage,
  ) => [
    for (final item in luggage) TripLuggageModel.fromEntity(item).toRpcJson(),
  ];
```

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `flutter test test/features/trip/data/models/trip_models_test.dart`
Expected: todos os testes passam.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trip/data/models/trip_passenger_model.dart lib/features/trip/data/models/trip_luggage_model.dart test/features/trip/data/models/trip_models_test.dart
git commit -m "feat: serializa passageiros e bagagens para o payload da RPC"
```

---

### Task 12: Repositório — `sendRequest` estendido e operações de retomada

**Files:**
- Modify: `lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart`
- Test: `test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart` (criar)

O repositório fala direto com `Supabase.instance.client`, então não dá para testar as chamadas de rede sem refatorar tudo. O que **dá** para testar puramente é a montagem do mapa de parâmetros — extraia-a para um método estático.

- [ ] **Step 1: Escrever o teste que falha**

Crie `test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

void main() {
  group('ScheduledDirectRequestRepository.buildSendParams', () {
    test('viagem só de ida não envia dados de volta', () {
      final params = ScheduledDirectRequestRepository.buildSendParams(
        driverProfileId: 'driver-1',
        pickupAddressId: 'pickup-1',
        dropoffAddressId: 'dropoff-1',
        serviceCategoryId: 'cat-1',
        passengerCount: 2,
        scheduledDatetime: DateTime.utc(2026, 8, 20, 14, 30),
        observation: 'sem observacao',
        paymentMethod: 'pix',
        passengers: const [TripPassengerData(name: 'Ana', age: 30)],
        luggage: const [TripLuggageData(type: 'mala', size: 'large')],
      );

      expect(params['is_round_trip_input'], false);
      expect(params['return_datetime_input'], isNull);
      expect(params['return_passengers_input'], isEmpty);
      expect(params['return_luggage_input'], isEmpty);
      expect(params['payment_method_input'], 'pix');
      expect(params['children_count_input'], 0);
      expect(params['luggage_count_input'], 1);
      expect(params['passengers_input'], [
        {'name': 'Ana', 'age': 30},
      ]);
      expect(
        params['scheduled_datetime_input'],
        DateTime.utc(2026, 8, 20, 14, 30).toIso8601String(),
      );
    });

    test('conta como criança todo passageiro com 10 anos ou menos', () {
      final params = ScheduledDirectRequestRepository.buildSendParams(
        driverProfileId: 'driver-1',
        pickupAddressId: 'pickup-1',
        dropoffAddressId: 'dropoff-1',
        serviceCategoryId: 'cat-1',
        passengerCount: 3,
        scheduledDatetime: DateTime.utc(2026, 8, 20),
        passengers: const [
          TripPassengerData(name: 'Ana', age: 30),
          TripPassengerData(name: 'Bruno', age: 8),
          TripPassengerData(name: 'Caio', age: 4),
        ],
      );

      expect(params['children_count_input'], 2);
    });

    test('ida e volta envia as listas da volta', () {
      final params = ScheduledDirectRequestRepository.buildSendParams(
        driverProfileId: 'driver-1',
        pickupAddressId: 'pickup-1',
        dropoffAddressId: 'dropoff-1',
        serviceCategoryId: 'cat-1',
        passengerCount: 1,
        scheduledDatetime: DateTime.utc(2026, 8, 20),
        isRoundTrip: true,
        returnDatetime: DateTime.utc(2026, 8, 22),
        returnPickupAddressId: 'dropoff-1',
        returnDropoffAddressId: 'pickup-1',
        passengers: const [TripPassengerData(name: 'Ana', age: 30)],
        returnPassengers: const [TripPassengerData(name: 'Ana', age: 30)],
        returnLuggage: const [TripLuggageData(type: 'mala', size: 'small')],
      );

      expect(params['is_round_trip_input'], true);
      expect(params['return_pickup_address_id_input'], 'dropoff-1');
      expect(params['return_passengers_input'], [
        {'name': 'Ana', 'age': 30},
      ]);
      expect(params['return_luggage_input'], [
        {'type': 'mala', 'size': 'small', 'quantity': 1},
      ]);
    });

    test('quantidade de bagagem soma as unidades, não as linhas', () {
      final params = ScheduledDirectRequestRepository.buildSendParams(
        driverProfileId: 'driver-1',
        pickupAddressId: 'pickup-1',
        dropoffAddressId: 'dropoff-1',
        serviceCategoryId: 'cat-1',
        passengerCount: 1,
        scheduledDatetime: DateTime.utc(2026, 8, 20),
        luggage: const [
          TripLuggageData(type: 'mala', size: 'large', quantity: 2),
          TripLuggageData(type: 'mochila', size: 'small', quantity: 3),
        ],
      );

      expect(params['luggage_count_input'], 5);
    });
  });
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart`
Expected: FAIL — `buildSendParams` não existe.

- [ ] **Step 3: Implementar**

Em `lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart`, troque os imports do topo por:

```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/errors/scheduled_direct_error.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_luggage_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_passenger_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
```

Substitua o método `sendRequest` inteiro (linhas 4-34 do arquivo atual) por:

```dart
  static Map<String, dynamic> buildSendParams({
    required String driverProfileId,
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required DateTime scheduledDatetime,
    bool isRoundTrip = false,
    DateTime? returnDatetime,
    String? returnPickupAddressId,
    String? returnDropoffAddressId,
    String? observation,
    String? paymentMethod,
    List<TripPassengerData> passengers = const [],
    List<TripLuggageData> luggage = const [],
    List<TripPassengerData> returnPassengers = const [],
    List<TripLuggageData> returnLuggage = const [],
  }) {
    final childrenCount = passengers.where((p) => p.needsCarSeat).length;
    final luggageCount = luggage.fold<int>(0, (sum, l) => sum + l.quantity);

    return {
      'driver_profile_id_input': driverProfileId,
      'pickup_address_id_input': pickupAddressId,
      'dropoff_address_id_input': dropoffAddressId,
      'service_category_id_input': serviceCategoryId,
      'passenger_count_input': passengerCount,
      'observation_input': observation,
      'scheduled_datetime_input': scheduledDatetime.toUtc().toIso8601String(),
      'is_round_trip_input': isRoundTrip,
      'return_datetime_input': isRoundTrip
          ? returnDatetime?.toUtc().toIso8601String()
          : null,
      'return_pickup_address_id_input': isRoundTrip
          ? returnPickupAddressId
          : null,
      'return_dropoff_address_id_input': isRoundTrip
          ? returnDropoffAddressId
          : null,
      'payment_method_input': paymentMethod,
      'children_count_input': childrenCount,
      'luggage_count_input': luggageCount,
      'passengers_input': TripPassengerModel.buildRpcJsonList(passengers),
      'luggage_input': TripLuggageModel.buildRpcJsonList(luggage),
      'return_passengers_input': isRoundTrip
          ? TripPassengerModel.buildRpcJsonList(returnPassengers)
          : const <Map<String, dynamic>>[],
      'return_luggage_input': isRoundTrip
          ? TripLuggageModel.buildRpcJsonList(returnLuggage)
          : const <Map<String, dynamic>>[],
    };
  }

  Future<String> sendRequest({
    required String driverProfileId,
    required String pickupAddressId,
    required String dropoffAddressId,
    required String serviceCategoryId,
    required int passengerCount,
    required DateTime scheduledDatetime,
    bool isRoundTrip = false,
    DateTime? returnDatetime,
    String? returnPickupAddressId,
    String? returnDropoffAddressId,
    String? observation,
    String? paymentMethod,
    List<TripPassengerData> passengers = const [],
    List<TripLuggageData> luggage = const [],
    List<TripPassengerData> returnPassengers = const [],
    List<TripLuggageData> returnLuggage = const [],
  }) async {
    try {
      final result = await Supabase.instance.client.rpc(
        'client_send_scheduled_direct_request',
        params: buildSendParams(
          driverProfileId: driverProfileId,
          pickupAddressId: pickupAddressId,
          dropoffAddressId: dropoffAddressId,
          serviceCategoryId: serviceCategoryId,
          passengerCount: passengerCount,
          scheduledDatetime: scheduledDatetime,
          isRoundTrip: isRoundTrip,
          returnDatetime: returnDatetime,
          returnPickupAddressId: returnPickupAddressId,
          returnDropoffAddressId: returnDropoffAddressId,
          observation: observation,
          paymentMethod: paymentMethod,
          passengers: passengers,
          luggage: luggage,
          returnPassengers: returnPassengers,
          returnLuggage: returnLuggage,
        ),
      );
      return result as String;
    } catch (error) {
      throw ScheduledDirectException.from(error);
    }
  }

  Future<void> retarget({
    required String tripId,
    required String driverProfileId,
  }) async {
    try {
      await Supabase.instance.client.rpc(
        'client_retarget_scheduled_direct_request',
        params: {
          'trip_id_input': tripId,
          'driver_profile_id_input': driverProfileId,
        },
      );
    } catch (error) {
      throw ScheduledDirectException.from(error);
    }
  }

  Future<void> convertToQuote(String tripId) async {
    try {
      await Supabase.instance.client.rpc(
        'client_convert_scheduled_direct_to_quote',
        params: {'trip_id_input': tripId},
      );
    } catch (error) {
      throw ScheduledDirectException.from(error);
    }
  }
```

Depois adicione, logo antes do `}` final da classe, a busca por `tripId` (a `fetchActiveRequest` existente permanece intacta — ela ainda é usada em outros pontos):

```dart
  Future<Map<String, dynamic>?> fetchRequestByTripId(String tripId) async {
    final response = await Supabase.instance.client
        .from('trips')
        .select('''
          id, driver_profile_id, vehicle_id, status, scheduled_datetime,
          passenger_count, children_count, luggage_count, observations,
          pickup_address:addresses!pickup_address_id ( formatted_address ),
          dropoff_address:addresses!dropoff_address_id ( formatted_address ),
          trip_stops ( stop_order, addresses ( formatted_address ) ),
          driver_profiles (
            provider_profiles (
              average_rating, total_ratings, bio,
              users ( full_name, avatar_url )
            ),
            driver_profile_photos ( photo_url, sort_order ),
            vehicles (
              id, brand, model, year, color, license_plate,
              passenger_capacity, is_active,
              vehicle_photos ( photo_url, photo_type )
            )
          ),
          trip_driver_candidates ( driver_profile_id, offered_price, status )
        ''')
        .eq('id', tripId)
        .maybeSingle();

    if (response == null) return null;
    final driverProfileId = response['driver_profile_id'] as String?;
    var completedTrips = 0;
    if (driverProfileId != null) {
      final count = await Supabase.instance.client
          .from('trips')
          .select('id')
          .eq('driver_profile_id', driverProfileId)
          .eq('status', 'finished')
          .count(CountOption.exact);
      completedTrips = count.count;
    }
    return {...response, 'completed_trips': completedTrips};
  }
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart`
Expected: 4 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart
git commit -m "feat: repositorio envia detalhes completos e suporta retomada"
```

---

### Task 13: Sessão de seleção de motorista (nova vs. retomada)

**Files:**
- Create: `lib/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart`
- Test: `test/features/scheduled_choose_driver/domain/sessions/driver_selection_session_test.dart`

**Por quê:** hoje o `DriverSelectionCubit` recebe 12 parâmetros soltos que só fazem sentido para uma solicitação **nova**. Ao retomar uma solicitação existente, nada disso importa — só o `tripId`. Uma `sealed class` deixa os dois modos explícitos e o `switch` exaustivo.

A sessão é **stateless**: ela não guarda qual motorista está ativo. Isso vive em `DriverSelectionLoaded.activeDriverProfileId` (Task 14), porque muda a cada troca de motorista.

- [ ] **Step 1: Escrever o teste que falha**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart';

void main() {
  test('sessão nova não tem tripId', () {
    final session = NewScheduledDirectSession(
      pickupAddressId: 'pickup-1',
      dropoffAddressId: 'dropoff-1',
      serviceCategoryId: 'cat-1',
      passengerCount: 2,
      scheduledDatetime: DateTime.utc(2026, 8, 20),
    );
    expect(session.tripId, isNull);
  });

  test('sessão retomada carrega o tripId', () {
    const session = ExistingScheduledDirectSession(tripId: 'trip-9');
    expect(session.tripId, 'trip-9');
  });

  test('switch sobre a sessão é exaustivo', () {
    String describe(DriverSelectionSession session) => switch (session) {
      NewScheduledDirectSession() => 'nova',
      ExistingScheduledDirectSession() => 'retomada',
    };

    expect(
      describe(
        NewScheduledDirectSession(
          pickupAddressId: 'p',
          dropoffAddressId: 'd',
          serviceCategoryId: 'c',
          passengerCount: 1,
          scheduledDatetime: DateTime.utc(2026, 8, 20),
        ),
      ),
      'nova',
    );
    expect(
      describe(const ExistingScheduledDirectSession(tripId: 'trip-9')),
      'retomada',
    );
  });
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/domain/sessions/driver_selection_session_test.dart`
Expected: FAIL — arquivo não existe.

- [ ] **Step 3: Implementar**

Crie `lib/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart`:

```dart
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';

sealed class DriverSelectionSession {
  const DriverSelectionSession();

  String? get tripId;
}

class NewScheduledDirectSession extends DriverSelectionSession {
  const NewScheduledDirectSession({
    required this.pickupAddressId,
    required this.dropoffAddressId,
    required this.serviceCategoryId,
    required this.passengerCount,
    required this.scheduledDatetime,
    this.isRoundTrip = false,
    this.returnDatetime,
    this.returnPickupAddressId,
    this.returnDropoffAddressId,
    this.observation,
    this.paymentMethod,
    this.passengers = const [],
    this.luggage = const [],
    this.returnPassengers = const [],
    this.returnLuggage = const [],
  });

  final String pickupAddressId;
  final String dropoffAddressId;
  final String serviceCategoryId;
  final int passengerCount;
  final DateTime scheduledDatetime;
  final bool isRoundTrip;
  final DateTime? returnDatetime;
  final String? returnPickupAddressId;
  final String? returnDropoffAddressId;
  final String? observation;
  final String? paymentMethod;
  final List<TripPassengerData> passengers;
  final List<TripLuggageData> luggage;
  final List<TripPassengerData> returnPassengers;
  final List<TripLuggageData> returnLuggage;

  @override
  String? get tripId => null;
}

class ExistingScheduledDirectSession extends DriverSelectionSession {
  const ExistingScheduledDirectSession({required this.tripId});

  @override
  final String tripId;
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/domain/sessions/driver_selection_session_test.dart`
Expected: 3 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart test/features/scheduled_choose_driver/domain/sessions/driver_selection_session_test.dart
git commit -m "feat: modela sessao de selecao de motorista como nova ou retomada"
```

---

### Task 14: `DriverSelectionCubit` passa a operar sobre uma sessão

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart`
- Test: `test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart` (criar)

**O que muda:**
- Construtor recebe `DriverSelectionSession` em vez de 12 campos soltos.
- `load()` numa sessão retomada busca a trip e descobre o motorista ativo e a fase.
- `request()` numa sessão nova chama `sendRequest`; numa sessão retomada chama `retarget`.
- Novo método `convertToQuote()`.
- `DriverSelectionLoaded` ganha `activeDriverProfileId` e `phase`.

- [ ] **Step 1: Escrever os testes que falham**

Crie `test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart`:

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/available_drivers_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/available_driver.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart';
import 'package:mocktail/mocktail.dart';

class _MockDriversRepo extends Mock implements AvailableDriversRepository {}

class _MockRequestRepo extends Mock implements ScheduledDirectRequestRepository {}

const _driver = AvailableDriver(
  driverProfileId: 'driver-1',
  fullName: 'Ana Motorista',
  avatarUrl: null,
  averageRating: 4.9,
  totalRatings: 12,
  vehicle: null,
);

NewScheduledDirectSession _newSession() => NewScheduledDirectSession(
  pickupAddressId: 'pickup-1',
  dropoffAddressId: 'dropoff-1',
  serviceCategoryId: 'cat-1',
  passengerCount: 2,
  scheduledDatetime: DateTime.utc(2026, 8, 20, 14),
);

void main() {
  late _MockDriversRepo driversRepo;
  late _MockRequestRepo requestRepo;

  setUp(() {
    driversRepo = _MockDriversRepo();
    requestRepo = _MockRequestRepo();
    when(() => driversRepo.fetchApproved()).thenAnswer((_) async => [_driver]);
  });

  group('candidateStatusFor', () {
    test('escolhe o candidato do motorista atual da viagem', () {
      expect(
        DriverSelectionCubit.candidateStatusFor({
          'driver_profile_id': 'driver-2',
          'trip_driver_candidates': [
            {'driver_profile_id': 'driver-1', 'status': 'rejected'},
            {'driver_profile_id': 'driver-2', 'status': 'accepted'},
          ],
        }),
        'accepted',
      );
    });

    test('sem candidato correspondente cai em pending', () {
      expect(
        DriverSelectionCubit.candidateStatusFor({
          'driver_profile_id': null,
          'trip_driver_candidates': <Map<String, dynamic>>[],
        }),
        'pending',
      );
    });
  });

  blocTest<DriverSelectionCubit, DriverSelectionState>(
    'sessão nova carrega motoristas sem motorista ativo',
    build: () => DriverSelectionCubit(
      driversRepo: driversRepo,
      requestRepo: requestRepo,
      session: _newSession(),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DriverSelectionLoading>(),
      isA<DriverSelectionLoaded>()
          .having((s) => s.drivers.length, 'drivers', 1)
          .having((s) => s.activeDriverProfileId, 'activeDriverProfileId', isNull)
          .having((s) => s.phase, 'phase', isNull),
    ],
  );

  blocTest<DriverSelectionCubit, DriverSelectionState>(
    'sessão retomada descobre motorista ativo e fase',
    build: () {
      when(() => requestRepo.fetchRequestByTripId('trip-9')).thenAnswer(
        (_) async => {
          'id': 'trip-9',
          'status': 'awaiting_driver_confirmation',
          'driver_profile_id': 'driver-1',
          'trip_driver_candidates': [
            {'driver_profile_id': 'driver-1', 'status': 'pending'},
          ],
        },
      );
      return DriverSelectionCubit(
        driversRepo: driversRepo,
        requestRepo: requestRepo,
        session: const ExistingScheduledDirectSession(tripId: 'trip-9'),
      );
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<DriverSelectionLoading>(),
      isA<DriverSelectionLoaded>()
          .having((s) => s.activeDriverProfileId, 'activeDriverProfileId', 'driver-1')
          .having((s) => s.phase, 'phase', ScheduledDirectStatus.awaitingDriver),
    ],
  );

  blocTest<DriverSelectionCubit, DriverSelectionState>(
    'sessão nova envia uma solicitação nova',
    build: () {
      when(
        () => requestRepo.sendRequest(
          driverProfileId: any(named: 'driverProfileId'),
          pickupAddressId: any(named: 'pickupAddressId'),
          dropoffAddressId: any(named: 'dropoffAddressId'),
          serviceCategoryId: any(named: 'serviceCategoryId'),
          passengerCount: any(named: 'passengerCount'),
          scheduledDatetime: any(named: 'scheduledDatetime'),
          isRoundTrip: any(named: 'isRoundTrip'),
          returnDatetime: any(named: 'returnDatetime'),
          returnPickupAddressId: any(named: 'returnPickupAddressId'),
          returnDropoffAddressId: any(named: 'returnDropoffAddressId'),
          observation: any(named: 'observation'),
          paymentMethod: any(named: 'paymentMethod'),
          passengers: any(named: 'passengers'),
          luggage: any(named: 'luggage'),
          returnPassengers: any(named: 'returnPassengers'),
          returnLuggage: any(named: 'returnLuggage'),
        ),
      ).thenAnswer((_) async => 'trip-novo');
      return DriverSelectionCubit(
        driversRepo: driversRepo,
        requestRepo: requestRepo,
        session: _newSession(),
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.request('driver-1');
    },
    skip: 2,
    expect: () => [
      isA<DriverSelectionLoaded>()
          .having((s) => s.sendingDriverId, 'sendingDriverId', 'driver-1'),
      isA<DriverSelectionRequestSent>()
          .having((s) => s.tripId, 'tripId', 'trip-novo'),
    ],
    verify: (_) {
      verifyNever(
        () => requestRepo.retarget(
          tripId: any(named: 'tripId'),
          driverProfileId: any(named: 'driverProfileId'),
        ),
      );
    },
  );

  blocTest<DriverSelectionCubit, DriverSelectionState>(
    'sessão retomada troca o motorista em vez de criar viagem nova',
    build: () {
      when(() => requestRepo.fetchRequestByTripId('trip-9')).thenAnswer(
        (_) async => {
          'id': 'trip-9',
          'status': 'searching_drivers',
          'driver_profile_id': null,
          'trip_driver_candidates': [
            {'driver_profile_id': 'driver-9', 'status': 'rejected'},
          ],
        },
      );
      when(
        () => requestRepo.retarget(
          tripId: any(named: 'tripId'),
          driverProfileId: any(named: 'driverProfileId'),
        ),
      ).thenAnswer((_) async {});
      return DriverSelectionCubit(
        driversRepo: driversRepo,
        requestRepo: requestRepo,
        session: const ExistingScheduledDirectSession(tripId: 'trip-9'),
      );
    },
    act: (cubit) async {
      await cubit.load();
      await cubit.request('driver-1');
    },
    skip: 2,
    expect: () => [
      isA<DriverSelectionLoaded>()
          .having((s) => s.sendingDriverId, 'sendingDriverId', 'driver-1'),
      isA<DriverSelectionRequestSent>().having((s) => s.tripId, 'tripId', 'trip-9'),
    ],
    verify: (_) {
      verify(
        () => requestRepo.retarget(
          tripId: 'trip-9',
          driverProfileId: 'driver-1',
        ),
      ).called(1);
    },
  );
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart`
Expected: FAIL — o construtor não aceita `session`.

- [ ] **Step 3: Implementar**

Substitua todo o conteúdo de `lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart` por:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/available_drivers_repository.dart';
import '../../data/repositories/scheduled_direct_request_repository.dart';
import '../../domain/entities/available_driver.dart';
import '../../domain/entities/scheduled_direct_request.dart';
import '../../domain/errors/scheduled_direct_error.dart';
import '../../domain/sessions/driver_selection_session.dart';

sealed class DriverSelectionState {
  const DriverSelectionState();
}

class DriverSelectionInitial extends DriverSelectionState {
  const DriverSelectionInitial();
}

class DriverSelectionLoading extends DriverSelectionState {
  const DriverSelectionLoading();
}

class DriverSelectionLoaded extends DriverSelectionState {
  final List<AvailableDriver> drivers;
  final String? sendingDriverId;
  final String? activeDriverProfileId;
  final ScheduledDirectStatus? phase;

  const DriverSelectionLoaded({
    required this.drivers,
    this.sendingDriverId,
    this.activeDriverProfileId,
    this.phase,
  });

  bool get isLockedByRecheck => phase == ScheduledDirectStatus.awaitingRecheck;

  DriverSelectionLoaded copyWith({
    List<AvailableDriver>? drivers,
    String? sendingDriverId,
    String? activeDriverProfileId,
    ScheduledDirectStatus? phase,
    bool clearSending = false,
  }) {
    return DriverSelectionLoaded(
      drivers: drivers ?? this.drivers,
      sendingDriverId: clearSending
          ? null
          : (sendingDriverId ?? this.sendingDriverId),
      activeDriverProfileId: activeDriverProfileId ?? this.activeDriverProfileId,
      phase: phase ?? this.phase,
    );
  }
}

class DriverSelectionError extends DriverSelectionState {
  final String message;
  const DriverSelectionError(this.message);
}

class DriverSelectionRequestSent extends DriverSelectionState {
  final String tripId;
  const DriverSelectionRequestSent(this.tripId);
}

class DriverSelectionConvertedToQuote extends DriverSelectionState {
  final String tripId;
  const DriverSelectionConvertedToQuote(this.tripId);
}

class DriverSelectionCubit extends Cubit<DriverSelectionState> {
  DriverSelectionCubit({
    required AvailableDriversRepository driversRepo,
    required ScheduledDirectRequestRepository requestRepo,
    required this.session,
  }) : _driversRepo = driversRepo,
       _requestRepo = requestRepo,
       super(const DriverSelectionInitial());

  final AvailableDriversRepository _driversRepo;
  final ScheduledDirectRequestRepository _requestRepo;
  final DriverSelectionSession session;

  static String candidateStatusFor(Map<String, dynamic> tripJson) {
    final rows = (tripJson['trip_driver_candidates'] as List?) ?? const [];
    final candidates = rows.whereType<Map<String, dynamic>>().toList();
    if (candidates.isEmpty) return 'pending';
    final driverProfileId = tripJson['driver_profile_id'] as String?;
    final match = candidates.where(
      (c) => c['driver_profile_id'] == driverProfileId,
    );
    final chosen = match.isNotEmpty ? match.first : candidates.first;
    return chosen['status'] as String? ?? 'pending';
  }

  Future<void> load() async {
    emit(const DriverSelectionLoading());
    try {
      final drivers = await _driversRepo.fetchApproved();
      final tripId = session.tripId;
      if (tripId == null) {
        emit(DriverSelectionLoaded(drivers: drivers));
        return;
      }
      final trip = await _requestRepo.fetchRequestByTripId(tripId);
      if (trip == null) {
        emit(DriverSelectionLoaded(drivers: drivers));
        return;
      }
      emit(
        DriverSelectionLoaded(
          drivers: drivers,
          activeDriverProfileId: trip['driver_profile_id'] as String?,
          phase: scheduledDirectStatusFrom(
            tripStatus: trip['status'] as String? ?? 'awaiting_driver_confirmation',
            candidateStatus: candidateStatusFor(trip),
          ),
        ),
      );
    } catch (e) {
      emit(DriverSelectionError(ScheduledDirectException.from(e).message));
    }
  }

  Future<void> request(String driverProfileId) async {
    final s = state;
    if (s is! DriverSelectionLoaded) return;
    if (s.isLockedByRecheck) {
      emit(
        const DriverSelectionError(
          'Não é possível trocar de motorista durante o re-check.',
        ),
      );
      emit(s);
      return;
    }
    emit(s.copyWith(sendingDriverId: driverProfileId));
    try {
      final existingTripId = session.tripId;
      if (existingTripId != null) {
        await _requestRepo.retarget(
          tripId: existingTripId,
          driverProfileId: driverProfileId,
        );
        emit(DriverSelectionRequestSent(existingTripId));
        return;
      }
      final newSession = session as NewScheduledDirectSession;
      final tripId = await _requestRepo.sendRequest(
        driverProfileId: driverProfileId,
        pickupAddressId: newSession.pickupAddressId,
        dropoffAddressId: newSession.dropoffAddressId,
        serviceCategoryId: newSession.serviceCategoryId,
        passengerCount: newSession.passengerCount,
        scheduledDatetime: newSession.scheduledDatetime,
        isRoundTrip: newSession.isRoundTrip,
        returnDatetime: newSession.returnDatetime,
        returnPickupAddressId: newSession.returnPickupAddressId,
        returnDropoffAddressId: newSession.returnDropoffAddressId,
        observation: newSession.observation,
        paymentMethod: newSession.paymentMethod,
        passengers: newSession.passengers,
        luggage: newSession.luggage,
        returnPassengers: newSession.returnPassengers,
        returnLuggage: newSession.returnLuggage,
      );
      emit(DriverSelectionRequestSent(tripId));
    } catch (e) {
      emit(DriverSelectionError(ScheduledDirectException.from(e).message));
      emit(s.copyWith(clearSending: true));
    }
  }

  Future<void> convertToQuote() async {
    final tripId = session.tripId;
    if (tripId == null) return;
    final s = state;
    try {
      await _requestRepo.convertToQuote(tripId);
      emit(DriverSelectionConvertedToQuote(tripId));
    } catch (e) {
      emit(DriverSelectionError(ScheduledDirectException.from(e).message));
      if (s is DriverSelectionLoaded) emit(s);
    }
  }
}
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart`
Expected: 6 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart
git commit -m "feat: cubit de selecao opera sobre sessao nova ou retomada"
```

---

### Task 15: `DriverSelectionContent` bloqueia troca durante o re-check e destaca o motorista ativo

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/widgets/driver_selection_content.dart`
- Test: `test/features/scheduled_choose_driver/presentation/widgets/driver_selection_content_test.dart`

- [ ] **Step 1: Escrever os testes que falham**

Adicione ao final do `main()` em `test/features/scheduled_choose_driver/presentation/widgets/driver_selection_content_test.dart`:

```dart
  testWidgets('durante o re-check os botões de solicitar ficam desabilitados', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverSelectionContent(
          drivers: const [
            AvailableDriver(
              driverProfileId: 'driver-1',
              fullName: 'Ana Motorista',
              avatarUrl: null,
              averageRating: 4.9,
              totalRatings: 10,
              vehicle: null,
            ),
          ],
          lockedByRecheck: true,
          onBack: () {},
          onDriverTap: (_) {},
          onRequest: (_) {},
          onQuotation: () {},
        ),
      ),
    );
    await tester.pump();

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Solicitar'),
    );
    expect(button.onPressed, isNull);
    expect(find.byKey(const Key('recheck_lock_banner')), findsOneWidget);
  });

  testWidgets('motorista ativo aparece marcado', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DriverSelectionContent(
          drivers: const [
            AvailableDriver(
              driverProfileId: 'driver-1',
              fullName: 'Ana Motorista',
              avatarUrl: null,
              averageRating: 4.9,
              totalRatings: 10,
              vehicle: null,
            ),
          ],
          activeDriverProfileId: 'driver-1',
          onBack: () {},
          onDriverTap: (_) {},
          onRequest: (_) {},
          onQuotation: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('active_driver_marker_driver-1')), findsOneWidget);
  });
```

Confirme que o arquivo importa:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/available_driver.dart';
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/driver_selection_content_test.dart`
Expected: FAIL — `lockedByRecheck` e `activeDriverProfileId` não são parâmetros de `DriverSelectionContent`.

- [ ] **Step 3: Adicionar os parâmetros ao widget**

Em `lib/features/scheduled_choose_driver/presentation/widgets/driver_selection_content.dart`, substitua o construtor e os campos (linhas 7-24) por:

```dart
  const DriverSelectionContent({
    super.key,
    required this.drivers,
    required this.onBack,
    required this.onDriverTap,
    required this.onRequest,
    required this.onQuotation,
    this.sendingDriverId,
    this.activeDriverProfileId,
    this.lockedByRecheck = false,
    this.mapBackground,
  });

  final List<AvailableDriver> drivers;
  final String? sendingDriverId;
  final String? activeDriverProfileId;
  final bool lockedByRecheck;
  final Widget? mapBackground;
  final VoidCallback onBack;
  final ValueChanged<AvailableDriver> onDriverTap;
  final ValueChanged<String> onRequest;
  final VoidCallback onQuotation;
```

- [ ] **Step 4: Passar as flags para a lista**

Em `_driverList()`, substitua a construção de `_DriverSelectionRow` por:

```dart
                    child: _DriverSelectionRow(
                      driver: drivers[index],
                      category: _categoryFor(drivers[index]),
                      isWaiting:
                          widget.sendingDriverId ==
                          drivers[index].driverProfileId,
                      isActive:
                          widget.activeDriverProfileId ==
                          drivers[index].driverProfileId,
                      isLocked: widget.lockedByRecheck,
                      onTap: () => widget.onDriverTap(drivers[index]),
                      onRequest: () =>
                          widget.onRequest(drivers[index].driverProfileId),
                    ),
```

- [ ] **Step 5: Adicionar o banner de bloqueio**

Em `build()`, dentro do `Column` do sheet, insira logo depois de `_header(),`:

```dart
                  if (widget.lockedByRecheck)
                    Padding(
                      key: const Key('recheck_lock_banner'),
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF414141),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Você já aceitou o preço. Aguardando a confirmação final do motorista.',
                          style: TextStyle(
                            color: AppColors.sheetTextSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
```

- [ ] **Step 6: Atualizar `_DriverSelectionRow`**

Substitua o construtor e os campos de `_DriverSelectionRow` por:

```dart
  const _DriverSelectionRow({
    required this.driver,
    required this.category,
    required this.isWaiting,
    required this.isActive,
    required this.isLocked,
    required this.onTap,
    required this.onRequest,
  });

  final AvailableDriver driver;
  final String category;
  final bool isWaiting;
  final bool isActive;
  final bool isLocked;
  final VoidCallback onTap;
  final VoidCallback onRequest;
```

No `build()` de `_DriverSelectionRow`, troque `onPressed: isWaiting ? null : onRequest,` por:

```dart
                onPressed: (isWaiting || isLocked) ? null : onRequest,
```

E, dentro do `Row`, logo depois de `const SizedBox(width: 12),`, insira o marcador do motorista ativo:

```dart
            if (isActive)
              Padding(
                key: Key('active_driver_marker_${driver.driverProfileId}'),
                padding: const EdgeInsets.only(right: 8),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.highlight,
                  size: 16,
                ),
              ),
```

- [ ] **Step 7: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/driver_selection_content_test.dart`
Expected: todos os testes passam (os antigos continuam verdes porque os parâmetros novos têm default).

- [ ] **Step 8: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/widgets/driver_selection_content.dart test/features/scheduled_choose_driver/presentation/widgets/driver_selection_content_test.dart
git commit -m "feat: lista de motoristas reflete re-check e motorista ativo"
```

---

### Task 16: `AwaitingResponseCubit` busca por `tripId`

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart`
- Test: `test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart`

**O bug:** `_refetch()` chama `_repo.fetchActiveRequest(clientId)` com `.limit(1)`. Com várias solicitações abertas por cliente (agora permitido), a tela pode exibir a viagem errada. Passa a usar `fetchRequestByTripId(tripId)` (criado na Task 12).

Também troca `candidates.first` por uma escolha determinística: o candidato do motorista atual da viagem.

- [ ] **Step 1: Escrever o teste que falha**

Adicione ao final do `main()` em `test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart` (reaproveite os mocks já declarados no arquivo; se não houver um mock de `ScheduledDirectRequestRepository`, declare `class _MockRepo extends Mock implements ScheduledDirectRequestRepository {}` no topo):

```dart
  test('escolhe o candidato do motorista atual, não o primeiro da lista', () {
    expect(
      AwaitingResponseCubit.candidateFor({
        'driver_profile_id': 'driver-2',
        'trip_driver_candidates': [
          {
            'driver_profile_id': 'driver-1',
            'status': 'rejected',
            'offered_price': 50,
          },
          {
            'driver_profile_id': 'driver-2',
            'status': 'accepted',
            'offered_price': 120,
          },
        ],
      }),
      {
        'driver_profile_id': 'driver-2',
        'status': 'accepted',
        'offered_price': 120,
      },
    );
  });

  test('sem candidatos retorna null', () {
    expect(
      AwaitingResponseCubit.candidateFor({
        'driver_profile_id': 'driver-1',
        'trip_driver_candidates': <Map<String, dynamic>>[],
      }),
      isNull,
    );
  });
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart`
Expected: FAIL — `candidateFor` não existe.

- [ ] **Step 3: Implementar**

Em `lib/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart`, adicione dentro da classe `AwaitingResponseCubit`, logo depois do campo `RealtimeChannel? _channel;`:

```dart
  static Map<String, dynamic>? candidateFor(Map<String, dynamic> tripJson) {
    final rows = (tripJson['trip_driver_candidates'] as List?) ?? const [];
    final candidates = rows.whereType<Map<String, dynamic>>().toList();
    if (candidates.isEmpty) return null;
    final driverProfileId = tripJson['driver_profile_id'] as String?;
    final match = candidates.where(
      (c) => c['driver_profile_id'] == driverProfileId,
    );
    return match.isNotEmpty ? match.first : candidates.first;
  }
```

Substitua o corpo de `_refetch()` (linhas 90-126 do arquivo atual) por:

```dart
  Future<void> _refetch() async {
    final row = await _repo.fetchRequestByTripId(tripId);
    if (row == null) return;

    final providerRaw = row['driver_profiles'];
    final provider = providerRaw is Map
        ? providerRaw['provider_profiles']
        : null;
    final userRaw = provider is Map ? provider['users'] : null;
    final candidate = candidateFor(row);
    final candidateStatus = candidate?['status'] as String? ?? 'pending';
    final offeredPrice = (candidate?['offered_price'] as num?)?.toDouble();

    emit(
      state.copyWith(
        status: scheduledDirectStatusFrom(
          tripStatus: row['status'] as String,
          candidateStatus: candidateStatus,
        ),
        driverName:
            (userRaw is Map ? userRaw['full_name'] as String? : null) ??
            state.driverName,
        driverAvatarUrl: (userRaw is Map
            ? userRaw['avatar_url'] as String?
            : null),
        offeredPrice: offeredPrice,
        details: PriceOfferDetails.fromMap(row),
        clearError: true,
      ),
    );
  }
```

Remova o import agora não usado, se `Supabase` continuar sendo usado em `start()` e `close()` mantenha-o.

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart`
Expected: todos os testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart
git commit -m "fix: tela de espera busca a viagem certa por tripId"
```

---

### Task 17: Tela de espera cobre também o re-check

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart`
- Test: `test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`

A mesma página serve duas fases: logo após enviar (`awaitingDriver` — "aguardando o motorista aceitar") e após o cliente aceitar o preço (`awaitingRecheck` — "aguardando a confirmação final"). O texto precisa diferenciar as duas, senão o cliente acha que travou.

- [ ] **Step 1: Abrir o widget e localizar o texto de espera**

Run: `grep -n "Aguardando\|status" lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart`
Anote o nome do parâmetro que carrega o `ScheduledDirectStatus` (o widget já recebe o estado do cubit).

- [ ] **Step 2: Escrever o teste que falha**

Adicione ao final do `main()` em `test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`, adaptando os parâmetros obrigatórios ao construtor real observado no Step 1 (copie de um teste já existente no arquivo e troque só o status):

```dart
  testWidgets('re-check mostra texto de confirmação final', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AwaitingDriverContent(
          status: ScheduledDirectStatus.awaitingRecheck,
          driverName: 'Ana Motorista',
          driverAvatarUrl: null,
          offeredPrice: 120,
          cancelling: false,
          onCancel: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aguardando confirmação final do motorista'), findsOneWidget);
  });

  testWidgets('espera inicial mostra texto de aceite', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: AwaitingDriverContent(
          status: ScheduledDirectStatus.awaitingDriver,
          driverName: 'Ana Motorista',
          driverAvatarUrl: null,
          offeredPrice: null,
          cancelling: false,
          onCancel: () {},
          onBack: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Aguardando o motorista aceitar'), findsOneWidget);
  });
```

- [ ] **Step 3: Rodar e confirmar a falha**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`
Expected: FAIL — o texto de re-check não existe.

- [ ] **Step 4: Implementar**

Em `awaiting_driver_content.dart`, substitua o texto fixo de espera por um getter derivado do status:

```dart
  String get _waitingHeadline => switch (status) {
    ScheduledDirectStatus.awaitingRecheck =>
      'Aguardando confirmação final do motorista',
    _ => 'Aguardando o motorista aceitar',
  };
```

E use `Text(_waitingHeadline, ...)` no lugar do texto literal anterior, preservando o `style` que já estava ali.

Garanta o import:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';
```

- [ ] **Step 5: Rodar e confirmar que passa**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`
Expected: todos os testes passam.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart
git commit -m "feat: tela de espera diferencia aceite inicial de re-check"
```

---

### Task 18: `ScheduledTrip` carrega `tripType` e `candidateStatus`

**Files:**
- Modify: `lib/features/trip/domain/entities/scheduled_trip.dart`
- Modify: `lib/features/trip/data/models/scheduled_trip_model.dart`
- Modify: `lib/features/trip/data/repositories/trip_repository_impl.dart:222-227`
- Test: `test/features/trip/data/models/scheduled_trip_model_test.dart`

**Por quê:** a tela de agendamentos precisa da fase derivada para escolher a tag e a rota. `trips.status` sozinho não distingue `awaitingDriver` de `awaitingRecheck`.

- [ ] **Step 1: Escrever os testes que falham**

Adicione ao final do `main()` em `test/features/trip/data/models/scheduled_trip_model_test.dart`:

```dart
  test('lê trip_type e o status do candidato do motorista atual', () {
    final trip = ScheduledTripModel.fromJson({
      'id': 'trip-1',
      'status': 'awaiting_driver_confirmation',
      'trip_type': 'scheduled_choose_driver',
      'driver_profile_id': 'driver-2',
      'scheduled_datetime': '2026-08-20T14:30:00+00:00',
      'passenger_count': 2,
      'pickup_address': {'formatted_address': 'Rua A'},
      'dropoff_address': {'formatted_address': 'Rua B'},
      'trip_driver_candidates': [
        {'driver_profile_id': 'driver-1', 'status': 'rejected'},
        {'driver_profile_id': 'driver-2', 'status': 'accepted'},
      ],
    }).toEntity();

    expect(trip.tripType, 'scheduled_choose_driver');
    expect(trip.candidateStatus, 'accepted');
  });

  test('sem candidatos o status do candidato cai em pending', () {
    final trip = ScheduledTripModel.fromJson({
      'id': 'trip-2',
      'status': 'searching_drivers',
      'scheduled_datetime': '2026-08-20T14:30:00+00:00',
      'passenger_count': 1,
      'pickup_address': {'formatted_address': 'Rua A'},
      'dropoff_address': {'formatted_address': 'Rua B'},
    }).toEntity();

    expect(trip.tripType, isNull);
    expect(trip.candidateStatus, 'pending');
  });
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/trip/data/models/scheduled_trip_model_test.dart`
Expected: FAIL — `tripType` e `candidateStatus` não existem.

- [ ] **Step 3: Estender a entidade**

Em `lib/features/trip/domain/entities/scheduled_trip.dart`, adicione ao construtor (depois de `this.observations,`):

```dart
    this.tripType,
    this.candidateStatus = 'pending',
```

E aos campos (depois de `final String? observations;`):

```dart
  final String? tripType;
  final String candidateStatus;
```

- [ ] **Step 4: Estender o model**

Em `lib/features/trip/data/models/scheduled_trip_model.dart`:

Adicione ao construtor, depois de `this.observations,`:
```dart
    this.tripType,
    this.candidateStatus = 'pending',
```

Adicione aos campos, depois de `final String? observations;`:
```dart
  final String? tripType;
  final String candidateStatus;
```

Adicione o helper estático, logo antes de `static String _buildShortAddress`:
```dart
  static String _candidateStatusFrom(Map<String, dynamic> json) {
    final rows = (json['trip_driver_candidates'] as List?) ?? const [];
    final candidates = rows.whereType<Map<String, dynamic>>().toList();
    if (candidates.isEmpty) return 'pending';
    final driverProfileId = json['driver_profile_id'] as String?;
    final match = candidates.where(
      (c) => c['driver_profile_id'] == driverProfileId,
    );
    final chosen = match.isNotEmpty ? match.first : candidates.first;
    return chosen['status'] as String? ?? 'pending';
  }
```

No `return ScheduledTripModel(` do `fromJson`, adicione depois de `observations: json['observations'] as String?,`:
```dart
      tripType: json['trip_type'] as String?,
      candidateStatus: _candidateStatusFrom(json),
```

No `toEntity()`, adicione depois de `observations: observations,`:
```dart
        tripType: tripType,
        candidateStatus: candidateStatus,
```

- [ ] **Step 5: Trazer os candidatos na query**

Em `lib/features/trip/data/repositories/trip_repository_impl.dart`, no `getScheduledTrips`, substitua o `.select(...)` (linhas 222-227) por:

```dart
        .select(
          '*, '
          'pickup_address:addresses!pickup_address_id(*), '
          'dropoff_address:addresses!dropoff_address_id(*), '
          'driver_profiles(provider_profiles(users(full_name))), '
          'trip_driver_candidates(driver_profile_id, status, offered_price)',
        )
```

- [ ] **Step 6: Rodar e confirmar que passa**

Run: `flutter test test/features/trip/data/models/scheduled_trip_model_test.dart`
Expected: todos os testes passam.

- [ ] **Step 7: Commit**

```bash
git add lib/features/trip/domain/entities/scheduled_trip.dart lib/features/trip/data/models/scheduled_trip_model.dart lib/features/trip/data/repositories/trip_repository_impl.dart test/features/trip/data/models/scheduled_trip_model_test.dart
git commit -m "feat: agendamento carrega tipo da viagem e status do candidato"
```

---

### Task 19: Tags de status por fase na tela de agendamentos

**Files:**
- Modify: `lib/features/profile/presentation/widgets/scheduled_trip_widget.dart`
- Test: `test/features/profile/presentation/widgets/scheduled_trip_widget_test.dart` (criar)

**O problema:** hoje `awaiting_client_confirmation` e `awaiting_driver_confirmation` colapsam na mesma tag "Aguardando confirmação". O cliente não sabe se a bola está com ele ou com o motorista.

Novas tags para `trip_type = 'scheduled_choose_driver'`:

| Fase | Tag |
|---|---|
| `awaitingDriver` | Aguardando motorista |
| `priceOffered` | Preço recebido |
| `awaitingRecheck` | Confirmando com motorista |
| `rejected` | Escolher outro motorista |
| `confirmed` | Agendada |

- [ ] **Step 1: Escrever os testes que falham**

Crie `test/features/profile/presentation/widgets/scheduled_trip_widget_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/profile/presentation/widgets/scheduled_trip_widget.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';

ScheduledTrip _trip({
  required String status,
  required String candidateStatus,
  String? tripType = 'scheduled_choose_driver',
}) => ScheduledTrip(
  id: 'trip-1',
  status: status,
  scheduledDatetime: DateTime.utc(2026, 8, 20, 14, 30),
  origin: 'Rua A',
  destination: 'Rua B',
  originLat: 0,
  originLng: 0,
  destinationLat: 0,
  destinationLng: 0,
  passengerCount: 1,
  tripType: tripType,
  candidateStatus: candidateStatus,
);

Future<void> _pump(WidgetTester tester, ScheduledTrip trip) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: ScheduledTripWidget(trip: trip))),
  );
  await tester.pump();
}

void main() {
  testWidgets('espera pelo motorista', (tester) async {
    await _pump(
      tester,
      _trip(status: 'awaiting_driver_confirmation', candidateStatus: 'pending'),
    );
    expect(find.text('Aguardando motorista'), findsOneWidget);
  });

  testWidgets('preço recebido', (tester) async {
    await _pump(
      tester,
      _trip(status: 'awaiting_client_confirmation', candidateStatus: 'accepted'),
    );
    expect(find.text('Preço recebido'), findsOneWidget);
  });

  testWidgets('re-check em andamento', (tester) async {
    await _pump(
      tester,
      _trip(status: 'awaiting_driver_confirmation', candidateStatus: 'accepted'),
    );
    expect(find.text('Confirmando com motorista'), findsOneWidget);
  });

  testWidgets('motorista recusou', (tester) async {
    await _pump(
      tester,
      _trip(status: 'searching_drivers', candidateStatus: 'rejected'),
    );
    expect(find.text('Escolher outro motorista'), findsOneWidget);
  });

  testWidgets('cotação mantém as tags antigas', (tester) async {
    await _pump(
      tester,
      _trip(
        status: 'searching_drivers',
        candidateStatus: 'pending',
        tripType: 'scheduled_quote',
      ),
    );
    expect(find.text('Buscando motorista'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Rodar e confirmar a falha**

Run: `flutter test test/features/profile/presentation/widgets/scheduled_trip_widget_test.dart`
Expected: FAIL — o widget mostra "Aguardando confirmação" nos três primeiros casos.

- [ ] **Step 3: Implementar**

Em `lib/features/profile/presentation/widgets/scheduled_trip_widget.dart`, troque a chamada da linha 72 por:

```dart
                _StatusBadge(
                  status: trip.status,
                  tripType: trip.tripType,
                  candidateStatus: trip.candidateStatus,
                ),
```

Substitua a classe `_StatusBadge` inteira (linhas 93-146) por:

```dart
class _StatusBadge extends StatelessWidget {
  final String status;
  final String? tripType;
  final String candidateStatus;

  const _StatusBadge({
    required this.status,
    this.tripType,
    this.candidateStatus = 'pending',
  });

  static const _blueBg = Color(0xFFE3F2FD);
  static const _blueFg = Color(0xFF2261FE);
  static const _greenBg = Color(0xFFE8F5E9);
  static const _greenFg = Color(0xFF4CAF50);
  static const _amberBg = Color(0xFFFFF3E0);
  static const _amberFg = Color(0xFFFF9800);

  (Color, Color, String) get _directPalette {
    final phase = scheduledDirectStatusFrom(
      tripStatus: status,
      candidateStatus: candidateStatus,
    );
    return switch (phase) {
      ScheduledDirectStatus.awaitingDriver => (
        _blueBg,
        _blueFg,
        'Aguardando motorista',
      ),
      ScheduledDirectStatus.priceOffered => (
        _amberBg,
        _amberFg,
        'Preço recebido',
      ),
      ScheduledDirectStatus.awaitingRecheck => (
        _blueBg,
        _blueFg,
        'Confirmando com motorista',
      ),
      ScheduledDirectStatus.rejected => (
        _amberBg,
        _amberFg,
        'Escolher outro motorista',
      ),
      ScheduledDirectStatus.confirmed => (_greenBg, _greenFg, 'Agendada'),
      ScheduledDirectStatus.cancelled => (
        const Color(0xFFF5F5F5),
        const Color(0xFF9E9E9E),
        'Cancelada',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, label) =
        tripType == 'scheduled_choose_driver'
        ? _directPalette
        : switch (status) {
            'scheduled' => (_greenBg, _greenFg, 'Agendada'),
            'open' => (_amberBg, _amberFg, 'Pendente'),
            'under_review' => (_amberBg, _amberFg, 'Em análise'),
            'searching_drivers' => (_blueBg, _blueFg, 'Buscando motorista'),
            'awaiting_client_confirmation' ||
            'awaiting_driver_confirmation' => (
              _blueBg,
              _blueFg,
              'Aguardando confirmação',
            ),
            'started' => (_greenBg, _greenFg, 'Em andamento'),
            _ => (const Color(0xFFF5F5F5), const Color(0xFF9E9E9E), status),
          };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'QuasimodoSemiBold',
          fontSize: 12,
          color: textColor,
        ),
      ),
    );
  }
}
```

Adicione o import no topo do arquivo:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart';
```

- [ ] **Step 4: Rodar e confirmar que passa**

Run: `flutter test test/features/profile/presentation/widgets/scheduled_trip_widget_test.dart`
Expected: 5 testes passam.

- [ ] **Step 5: Commit**

```bash
git add lib/features/profile/presentation/widgets/scheduled_trip_widget.dart test/features/profile/presentation/widgets/scheduled_trip_widget_test.dart
git commit -m "feat: tags de status por fase no agendamento direto"
```

---

### Task 20: Rota `/scheduled-choose-driver/select` aceita sessão retomada

**Files:**
- Modify: `lib/routes/app_router.dart:96-127`
- Modify: `lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart`

**O que muda:** a rota passa a aceitar duas formas de entrada:
1. **Sessão nova** — `state.extra` traz o mapa que `trip_home_page` monta (comportamento atual, estendido com passageiros/bagagens/pagamento).
2. **Sessão retomada** — `?tripId=` na query string, sem `extra`. Acontece quando o cliente toca no agendamento.

Na sessão retomada, "Cotação" chama `convertToQuote()` no cubit em vez do callback `onQuotation` — não há fluxo em memória para voltar.

- [ ] **Step 1: Reescrever a rota**

Em `lib/routes/app_router.dart`, substitua o `GoRoute` de `/scheduled-choose-driver/select` (linhas 97-127) por:

```dart
                GoRoute(
                  path: '/scheduled-choose-driver/select',
                  builder: (context, state) {
                    final resumedTripId = state.uri.queryParameters['tripId'];
                    if (resumedTripId != null) {
                      return BlocProvider(
                        create: (_) => DriverSelectionCubit(
                          driversRepo: AvailableDriversRepository(),
                          requestRepo: ScheduledDirectRequestRepository(),
                          session: ExistingScheduledDirectSession(
                            tripId: resumedTripId,
                          ),
                        ),
                        child: const DriverSelectionPage(),
                      );
                    }
                    final extra = state.extra! as Map<String, dynamic>;
                    return BlocProvider(
                      create: (_) => DriverSelectionCubit(
                        driversRepo: AvailableDriversRepository(),
                        requestRepo: ScheduledDirectRequestRepository(),
                        session: NewScheduledDirectSession(
                          pickupAddressId: extra['pickupAddressId'] as String,
                          dropoffAddressId: extra['dropoffAddressId'] as String,
                          serviceCategoryId:
                              extra['serviceCategoryId'] as String,
                          passengerCount: extra['passengerCount'] as int,
                          scheduledDatetime:
                              extra['scheduledDatetime'] as DateTime,
                          isRoundTrip: extra['isRoundTrip'] as bool? ?? false,
                          returnDatetime: extra['returnDatetime'] as DateTime?,
                          returnPickupAddressId:
                              extra['returnPickupAddressId'] as String?,
                          returnDropoffAddressId:
                              extra['returnDropoffAddressId'] as String?,
                          observation: extra['observation'] as String?,
                          paymentMethod: extra['paymentMethod'] as String?,
                          passengers:
                              (extra['passengers']
                                  as List<TripPassengerData>?) ??
                              const [],
                          luggage:
                              (extra['luggage'] as List<TripLuggageData>?) ??
                              const [],
                          returnPassengers:
                              (extra['returnPassengers']
                                  as List<TripPassengerData>?) ??
                              const [],
                          returnLuggage:
                              (extra['returnLuggage']
                                  as List<TripLuggageData>?) ??
                              const [],
                        ),
                      ),
                      child: DriverSelectionPage(
                        pickupLatitude: extra['pickupLatitude'] as double?,
                        pickupLongitude: extra['pickupLongitude'] as double?,
                        dropoffLatitude: extra['dropoffLatitude'] as double?,
                        dropoffLongitude: extra['dropoffLongitude'] as double?,
                        onQuotation: extra['onQuotation'] as VoidCallback?,
                      ),
                    );
                  },
                ),
```

Adicione os imports que faltam no topo de `app_router.dart`:

```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/sessions/driver_selection_session.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_luggage_data.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_passenger_data.dart';
```

- [ ] **Step 2: Tornar `onQuotation` opcional na página**

Em `lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart`, substitua o construtor e os campos (linhas 11-25) por:

```dart
class DriverSelectionPage extends StatelessWidget {
  const DriverSelectionPage({
    super.key,
    this.pickupLatitude,
    this.pickupLongitude,
    this.dropoffLatitude,
    this.dropoffLongitude,
    this.onQuotation,
  });

  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? dropoffLatitude;
  final double? dropoffLongitude;
  final VoidCallback? onQuotation;
```

- [ ] **Step 3: Ligar sessão, diálogo de troca e cotação**

Ainda em `driver_selection_page.dart`, substitua todo o `BlocConsumer<DriverSelectionCubit, DriverSelectionState>` do `build()` (linhas 32-68) por:

```dart
      body: BlocConsumer<DriverSelectionCubit, DriverSelectionState>(
        listener: (context, state) {
          if (state is DriverSelectionRequestSent) {
            context.go('/scheduled-choose-driver/awaiting/${state.tripId}');
          } else if (state is DriverSelectionConvertedToQuote) {
            context.go('/scheduled-trips');
          } else if (state is DriverSelectionError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro: ${state.message}')));
          }
        },
        builder: (context, state) {
          if (state is DriverSelectionInitial) {
            context.read<DriverSelectionCubit>().load();
          }
          final loaded = state is DriverSelectionLoaded ? state : null;
          return DriverSelectionContent(
            drivers: loaded?.drivers ?? const <AvailableDriver>[],
            sendingDriverId: loaded?.sendingDriverId,
            activeDriverProfileId: loaded?.activeDriverProfileId,
            lockedByRecheck: loaded?.isLockedByRecheck ?? false,
            mapBackground: map,
            onBack: () => context.pop(),
            onDriverTap: (driver) =>
                Navigator.of(context, rootNavigator: true).push(
                  MaterialPageRoute<void>(
                    fullscreenDialog: true,
                    builder: (_) => _DriverProfilePage(driver: driver),
                  ),
                ),
            onRequest: (id) => _onRequest(context, loaded, id),
            onQuotation: () {
              final cubit = context.read<DriverSelectionCubit>();
              if (cubit.session.tripId != null) {
                cubit.convertToQuote();
                return;
              }
              onQuotation?.call();
            },
          );
        },
      ),
```

Adicione o método `_onRequest` na classe `DriverSelectionPage`, logo depois de `build()`:

```dart
  Future<void> _onRequest(
    BuildContext context,
    DriverSelectionLoaded? loaded,
    String driverProfileId,
  ) async {
    final cubit = context.read<DriverSelectionCubit>();
    final activeId = loaded?.activeDriverProfileId;
    if (activeId != null && activeId != driverProfileId) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('swap_driver_dialog'),
          title: const Text('Trocar de motorista?'),
          content: const Text(
            'A solicitação enviada ao motorista atual será cancelada e '
            'enviada ao motorista escolhido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Manter'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Trocar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await cubit.request(driverProfileId);
  }
```

- [ ] **Step 4: Verificar compilação**

Run: `flutter analyze lib/routes/app_router.dart lib/features/scheduled_choose_driver/`
Expected: nenhum erro.

- [ ] **Step 5: Commit**

```bash
git add lib/routes/app_router.dart lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart
git commit -m "feat: rota de selecao de motorista aceita retomada por tripId"
```

---

### Task 21: `trip_home_page` — remove a trava e passa os detalhes

**Files:**
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart:594-606` (remover)
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart:1725-1755` (estender o `extra`)
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart:4046-4053` (trocar o gate por `pathFor`)

- [ ] **Step 1: Remover a trava de "só 1 pendente"**

Delete integralmente as linhas 594-606:

```dart
    // Guard "só 1 pendente" para scheduled_choose_driver
    if (secondChoice == 'scheduled_choose_driver') {
      final clientId = Supabase.instance.client.auth.currentUser?.id;
      if (clientId != null) {
        final active = await ScheduledDirectRequestRepository()
            .fetchActiveRequest(clientId);
        if (!mounted) return;
        if (active != null) {
          context.go('/scheduled-choose-driver/awaiting/${active['id']}');
          return;
        }
      }
    }
```

O bloco `if (secondChoice != 'scheduled_quote' && ...) return;` logo acima permanece.

- [ ] **Step 2: Passar passageiros, bagagens e pagamento no `extra`**

No bloco `context.push('/scheduled-choose-driver/select', extra: {...})`, adicione as quatro chaves novas logo depois de `'observation': outboundFormData.observations,`:

```dart
            'paymentMethod': outboundFormData.paymentMethod,
            'passengers': outboundFormData.passengers,
            'luggage': outboundFormData.luggage,
            'returnPassengers': returnFormData?.passengers ?? const [],
            'returnLuggage': returnFormData?.luggage ?? const [],
```

- [ ] **Step 3: Trocar o gate pelo resolvedor de rota**

Substitua o `onTap` do `ScheduledTripCard` (linhas 4046-4053) por:

```dart
                      onTap: () {
                        final pendingPath = trip.tripType ==
                                'scheduled_choose_driver'
                            ? ScheduledDirectRoutes.pathFor(
                                tripId: trip.id,
                                tripStatus: trip.status,
                                candidateStatus: trip.candidateStatus,
                              )
                            : null;
                        if (pendingPath != null &&
                            trip.status != 'scheduled') {
                          context.go(pendingPath);
                          return;
                        }
                        TripDetailsSheet.show(context, trip);
                      },
```

A checagem `trip.status != 'scheduled'` preserva o comportamento antigo: uma viagem já agendada abre o `TripDetailsSheet`, não a tela de corrida ativa.

- [ ] **Step 4: Ajustar imports**

Remova:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/services/active_scheduled_direct_gate.dart';
```

Adicione:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart';
```

Se `ScheduledDirectRequestRepository` não for mais usado no arquivo depois do Step 1, remova também esse import.

- [ ] **Step 5: Verificar**

Run: `flutter analyze`
Expected: nenhum erro no projeto inteiro.

Run: `flutter test`
Expected: toda a suíte passa.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat: permite varias solicitacoes e persiste detalhes no agendamento direto"
```

---

### Task 22: Toque no agendamento retoma o fluxo (tela de agendamentos)

**Files:**
- Modify: `lib/features/profile/presentation/pages/scheduled_trips_page.dart:131-144`

Mesma lógica da Task 21 Step 3, aplicada à listagem completa de agendamentos.

- [ ] **Step 1: Implementar**

Substitua o `ScheduledTripWidget(` do `_buildTripsList` por:

```dart
        return ScheduledTripWidget(
          trip: trip,
          showMapPreview: true,
          onDetailsTap: () {
            final pendingPath = trip.tripType == 'scheduled_choose_driver'
                ? ScheduledDirectRoutes.pathFor(
                    tripId: trip.id,
                    tripStatus: trip.status,
                    candidateStatus: trip.candidateStatus,
                  )
                : null;
            if (pendingPath != null && trip.status != 'scheduled') {
              context.push(pendingPath);
              return;
            }
            TripDetailsSheet.show(
              context,
              trip,
              onCancel: () {
                context.read<ScheduledTripsCubit>().cancel(trip.id);
              },
              onChat: () {
                final authState = context.read<AuthCubit>().state;
                if (authState is! AuthSuccess) return;
                context.push('/chat/${trip.id}');
              },
```

Preserve o restante dos argumentos de `TripDetailsSheet.show` que já existem depois de `onChat` — não os remova.

Adicione o import:
```dart
import 'package:kz_servicos_app/features/scheduled_choose_driver/domain/navigation/scheduled_direct_routes.dart';
```

- [ ] **Step 2: Verificar**

Run: `flutter analyze lib/features/profile/presentation/pages/scheduled_trips_page.dart`
Expected: nenhum erro.

- [ ] **Step 3: Verificação manual no app**

Run: `flutter run -d chrome`

Percorra o caminho: **Corrida agendada → preencher passageiros/bagagens/pagamento → Selecionar motorista → Solicitar → voltar para a home → aba Agendamentos.**

Confirme:
1. A viagem aparece na lista com a tag **"Aguardando motorista"**.
2. Tocar nela abre a **lista de motoristas** com o motorista solicitado marcado e o botão **"Cotação"** visível.
3. Escolher outro motorista abre o diálogo **"Trocar de motorista?"**.

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/pages/scheduled_trips_page.dart
git commit -m "feat: agendamento em andamento retoma a tela correspondente"
```

---

# Fase 3 — App motorista (`kz-servicos-app-prestador`)

> **Mude de repositório.** Todos os caminhos das Tasks 23-25 são relativos a
> `C:\Projetos\kz-servicos-app-prestador\`. Rode os comandos a partir desse diretório.
>
> Requisito 4 do usuário: o motorista precisa ver **"Passageiros na ida" / "Passageiros na volta"**
> e **"Bagagens na ida" / "Bagagens na volta"** separadamente. Isso só é possível porque a
> Task 1 adicionou a coluna `leg` em `trip_passengers` e `trip_luggage`.
>
> Nota sobre crianças: `childLabels` permanece **unificado** (sem separação por perna).
> Ele é derivado de `passengers.where(isChild)` e serve como alerta de cadeirinha — o motorista
> precisa saber que existe criança na viagem, não em qual perna.

---

### Task 23: `leg` chega ao app motorista e particiona passageiros/bagagens

**Files:**
- Modify: `lib/core/services/trip_service.dart:6-27` (três das quatro constantes de select)
- Modify: `lib/core/models/trip_data.dart` (classes `TripPassenger`, `TripLuggage` e getters de `TripData`)
- Test: `test/core/models/trip_data_test.dart`

O modelo hoje tem `List<TripPassenger> passengers` e `List<TripLuggage> luggage` únicos
(`trip_data.dart:35,37`). Mantenha esses campos como "tudo junto" — vários consumidores dependem
deles (`hasChildren`, `regularPassengerCount`, `displayChildrenCount`, `passengerLabels`) — e
adicione `leg` aos itens, derivando as listas por perna via getters.

- [ ] **Step 1: Escrever o teste que falha**

Adicione ao final de `test/core/models/trip_data_test.dart`, dentro de `main()`, depois do
último `group(...)`:

```dart
  group('TripData separação por perna', () {
    Map<String, dynamic> baseMap() => {
      'id': 'trip-1',
      'client_id': 'client-1',
      'status': 'awaiting_driver_confirmation',
      'trip_type': 'scheduled_choose_driver',
      'is_round_trip': true,
      'scheduled_datetime': '2026-08-20T14:30:00Z',
      'passenger_count': 3,
      'children_count': 0,
      'luggage_count': 3,
      'pickup_address': {'formatted_address': 'A'},
      'dropoff_address': {'formatted_address': 'B'},
      'client': {'full_name': 'João'},
      'trip_passengers': [
        {'name': 'Ana', 'age': 30, 'needs_car_seat': false, 'sort_order': 0, 'leg': 'outbound'},
        {'name': 'Bruno', 'age': 40, 'needs_car_seat': false, 'sort_order': 1, 'leg': 'outbound'},
        {'name': 'Carla', 'age': 25, 'needs_car_seat': false, 'sort_order': 0, 'leg': 'return'},
      ],
      'trip_luggage': [
        {'type': 'suitcase', 'size': 'large', 'quantity': 2, 'sort_order': 0, 'leg': 'outbound'},
        {'type': 'backpack', 'size': 'small', 'quantity': 1, 'sort_order': 0, 'leg': 'return'},
      ],
    };

    test('particiona passageiros por leg', () {
      final trip = TripData.fromMap(baseMap());
      expect(trip.outboundPassengers.map((p) => p.name).toList(), ['Ana', 'Bruno']);
      expect(trip.returnPassengers.map((p) => p.name).toList(), ['Carla']);
    });

    test('particiona bagagens por leg', () {
      final trip = TripData.fromMap(baseMap());
      expect(trip.outboundLuggage.map((l) => l.type).toList(), ['suitcase']);
      expect(trip.returnLuggage.map((l) => l.type).toList(), ['backpack']);
    });

    test('labels por perna usam detailLabel', () {
      final trip = TripData.fromMap(baseMap());
      expect(trip.outboundPassengerLabels, ['Ana — 30 anos', 'Bruno — 40 anos']);
      expect(trip.returnPassengerLabels, ['Carla — 25 anos']);
      expect(trip.outboundLuggageLabels, ['2x Mala grande']);
      expect(trip.returnLuggageLabels, ['1x Mochila pequena']);
    });

    test('sem leg no payload tudo cai em outbound', () {
      final map = baseMap();
      map['trip_passengers'] = [
        {'name': 'Ana', 'age': 30, 'needs_car_seat': false, 'sort_order': 0},
      ];
      map['trip_luggage'] = [
        {'type': 'suitcase', 'size': 'large', 'quantity': 1, 'sort_order': 0},
      ];
      final trip = TripData.fromMap(map);
      expect(trip.outboundPassengers.length, 1);
      expect(trip.returnPassengers, isEmpty);
      expect(trip.outboundLuggage.length, 1);
      expect(trip.returnLuggage, isEmpty);
    });

    test('passengerLabels continua devolvendo as duas pernas juntas', () {
      final trip = TripData.fromMap(baseMap());
      expect(trip.passengerLabels.length, 3);
    });
  });
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/core/models/trip_data_test.dart`
Expected: FAIL — `The getter 'outboundPassengers' isn't defined for the type 'TripData'`.

- [ ] **Step 3: Adicionar `leg` a `TripPassenger`**

Em `lib/core/models/trip_data.dart`, classe `TripPassenger` (linha ~383). Substitua os campos e
o construtor por:

```dart
class TripPassenger {
  final String name;
  final int? age;
  final bool needsCarSeat;
  final int sortOrder;
  final String leg;

  const TripPassenger({
    required this.name,
    this.age,
    required this.needsCarSeat,
    required this.sortOrder,
    this.leg = 'outbound',
  });
```

E o factory (linha ~411):

```dart
  factory TripPassenger.fromMap(Map<String, dynamic> map) => TripPassenger(
    name: map['name'] as String? ?? 'Passageiro',
    age: (map['age'] as num?)?.toInt(),
    needsCarSeat: map['needs_car_seat'] as bool? ?? false,
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    leg: map['leg'] as String? ?? 'outbound',
  );
```

- [ ] **Step 4: Adicionar `leg` a `TripLuggage`**

No mesmo arquivo, classe `TripLuggage` (linha ~419). Substitua os campos e o construtor por:

```dart
class TripLuggage {
  final String type;
  final String size;
  final double? weightKg;
  final int quantity;
  final int sortOrder;
  final String leg;

  const TripLuggage({
    this.type = 'luggage',
    required this.size,
    this.weightKg,
    required this.quantity,
    this.sortOrder = 0,
    this.leg = 'outbound',
  });
```

E o factory (linha ~458):

```dart
  factory TripLuggage.fromMap(Map<String, dynamic> map) => TripLuggage(
    type: map['type'] as String? ?? 'luggage',
    size: map['size'] as String? ?? 'small',
    weightKg: (map['weight_kg'] as num?)?.toDouble(),
    quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    sortOrder: (map['sort_order'] as num?)?.toInt() ?? 0,
    leg: map['leg'] as String? ?? 'outbound',
  );
```

- [ ] **Step 5: Adicionar os getters por perna em `TripData`**

No mesmo arquivo, logo depois do getter `luggageLabels` (linhas 129-130) e imediatamente antes de
`bool get isAwaitingKzApproval` (linha 132), insira:

```dart
  List<TripPassenger> get outboundPassengers =>
      passengers.where((passenger) => passenger.leg != 'return').toList();
  List<TripPassenger> get returnPassengers =>
      passengers.where((passenger) => passenger.leg == 'return').toList();
  List<TripLuggage> get outboundLuggage =>
      luggage.where((item) => item.leg != 'return').toList();
  List<TripLuggage> get returnLuggage =>
      luggage.where((item) => item.leg == 'return').toList();

  List<String> get outboundPassengerLabels => outboundPassengers
      .where((passenger) => !passenger.isChild)
      .map((passenger) => passenger.detailLabel)
      .toList();
  List<String> get returnPassengerLabels => returnPassengers
      .where((passenger) => !passenger.isChild)
      .map((passenger) => passenger.detailLabel)
      .toList();
  List<String> get outboundLuggageLabels =>
      outboundLuggage.map((item) => item.detailLabel).toList();
  List<String> get returnLuggageLabels =>
      returnLuggage.map((item) => item.detailLabel).toList();
```

`TripData.fromMap` não muda: ele já ordena as listas por `sortOrder` (linhas 260 e 273) e o
`leg` chega dentro de cada item.

- [ ] **Step 6: Rodar o teste e confirmar que passa**

Run: `flutter test test/core/models/trip_data_test.dart`
Expected: PASS — inclusive os grupos antigos de `statusLabel`.

- [ ] **Step 7: Pedir `leg` nas queries**

Em `lib/core/services/trip_service.dart`, substitua **todas** as ocorrências de
`trip_passengers(name,age,needs_car_seat,sort_order)` por
`trip_passengers(name,age,needs_car_seat,sort_order,leg)` e **todas** as ocorrências de
`trip_luggage(type,size,weight_kg,quantity,sort_order)` por
`trip_luggage(type,size,weight_kg,quantity,sort_order,leg)`.

O resultado das três constantes afetadas (linhas 6-27):

```dart
const _tripSelect =
    '*, pickup_address:addresses!pickup_address_id(formatted_address,latitude,longitude), '
    'dropoff_address:addresses!dropoff_address_id(formatted_address,latitude,longitude), '
    'client:users!client_id(full_name,phone,avatar_url), '
    'trip_passengers(name,age,needs_car_seat,sort_order,leg), '
    'trip_luggage(type,size,weight_kg,quantity,sort_order,leg), '
    'trip_stops(*, addresses(*))';

const _tripDetailSelect =
    '*, pickup_address:addresses!pickup_address_id(formatted_address,latitude,longitude), '
    'dropoff_address:addresses!dropoff_address_id(formatted_address,latitude,longitude), '
    'client:users!client_id(full_name,phone,avatar_url), '
    'trip_passengers(name,age,needs_car_seat,sort_order,leg), trip_children(*), '
    'trip_luggage(type,size,weight_kg,quantity,sort_order,leg), trip_stops(*, addresses(*))';

const _tripHistorySelect =
    '*, pickup_address:addresses!pickup_address_id(formatted_address,latitude,longitude), '
    'dropoff_address:addresses!dropoff_address_id(formatted_address,latitude,longitude), '
    'client:users!client_id(full_name,avatar_url), '
    'trip_passengers(name,age,needs_car_seat,sort_order,leg), '
    'trip_luggage(type,size,weight_kg,quantity,sort_order,leg), '
    'ratings(score)';
```

`_activeTripSelect` (linhas 29-34) **não pede** `trip_passengers`/`trip_luggage` — não mexa nela.

- [ ] **Step 8: Rodar analyze e a suíte inteira**

Run: `flutter analyze lib/core/models/trip_data.dart lib/core/services/trip_service.dart`
Expected: nenhum erro.

Run: `flutter test`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/core/models/trip_data.dart lib/core/services/trip_service.dart test/core/models/trip_data_test.dart
git commit -m "feat: modelo do motorista separa passageiros e bagagens por perna"
```

---

### Task 24: UI do motorista mostra ida e volta separadas

**Files:**
- Modify: `lib/features/home/presentation/widgets/trip_request_card.dart:249-273`
- Modify: `lib/features/home/presentation/widgets/pending_trip_requests_carousel.dart:242-256`
- Modify: `lib/features/schedules/presentation/pages/schedule_detail_page.dart:1325-1341` e `:867`
- Test: `test/features/home/trip_request_card_leg_test.dart` (criar)

Regra de renderização, idêntica nos três lugares:
- `!trip.isRoundTrip` → títulos continuam **"Passageiros"** e **"Bagagem"** (nada muda para
  viagens só de ida).
- `trip.isRoundTrip` → dois blocos por categoria: **"Passageiros na ida"** / **"Passageiros na volta"**
  e **"Bagagens na ida"** / **"Bagagens na volta"**. Blocos com lista vazia não são renderizados.

- [ ] **Step 1: Escrever o teste que falha**

Crie `test/features/home/trip_request_card_leg_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_prestador/core/models/trip_data.dart';
import 'package:kz_servicos_prestador/features/home/presentation/widgets/trip_request_card.dart';

Map<String, dynamic> _base({required bool isRoundTrip}) => {
  'id': 'trip-1',
  'client_id': 'client-1',
  'status': 'awaiting_driver_confirmation',
  'trip_type': 'scheduled_choose_driver',
  'is_round_trip': isRoundTrip,
  'scheduled_datetime': '2026-08-20T14:30:00Z',
  'passenger_count': 2,
  'children_count': 0,
  'luggage_count': 3,
  'pickup_address': {'formatted_address': 'Av. Paulista, 1000'},
  'dropoff_address': {'formatted_address': 'Aeroporto'},
  'client': {'full_name': 'João'},
};

TripData roundTripWithLegs() => TripData.fromMap({
  ..._base(isRoundTrip: true),
  'trip_passengers': [
    {'name': 'Ana', 'age': 30, 'needs_car_seat': false, 'sort_order': 0, 'leg': 'outbound'},
    {'name': 'Carla', 'age': 25, 'needs_car_seat': false, 'sort_order': 0, 'leg': 'return'},
  ],
  'trip_luggage': [
    {'type': 'suitcase', 'size': 'large', 'quantity': 2, 'sort_order': 0, 'leg': 'outbound'},
    {'type': 'backpack', 'size': 'small', 'quantity': 1, 'sort_order': 0, 'leg': 'return'},
  ],
});

TripData oneWay() => TripData.fromMap({
  ..._base(isRoundTrip: false),
  'trip_passengers': [
    {'name': 'Ana', 'age': 30, 'needs_car_seat': false, 'sort_order': 0, 'leg': 'outbound'},
  ],
  'trip_luggage': [
    {'type': 'suitcase', 'size': 'large', 'quantity': 1, 'sort_order': 0, 'leg': 'outbound'},
  ],
});

Future<void> pump(WidgetTester tester, TripData trip) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(child: TripRequestCard(request: trip)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('ida e volta mostra seções separadas por perna', (tester) async {
    await pump(tester, roundTripWithLegs());

    expect(find.text('Passageiros na ida'), findsOneWidget);
    expect(find.text('Passageiros na volta'), findsOneWidget);
    expect(find.text('Bagagens na ida'), findsOneWidget);
    expect(find.text('Bagagens na volta'), findsOneWidget);
    expect(find.text('Passageiros'), findsNothing);
    expect(find.text('Bagagem'), findsNothing);
  });

  testWidgets('somente ida mantém os títulos simples', (tester) async {
    await pump(tester, oneWay());

    expect(find.text('Passageiros'), findsOneWidget);
    expect(find.text('Bagagem'), findsOneWidget);
    expect(find.text('Passageiros na volta'), findsNothing);
    expect(find.text('Bagagens na volta'), findsNothing);
  });
}
```

> **Antes de rodar:** abra `trip_request_card.dart` e confira a assinatura do construtor de
> `TripRequestCard`. Se houver parâmetros obrigatórios além de `request`, acrescente-os na chamada
> dentro de `pump` — o teste só depende de `request`.

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/home/trip_request_card_leg_test.dart`
Expected: FAIL — `Expected: exactly one matching candidate / Actual: _TextFinder:<zero widgets with text "Passageiros na ida">`.

- [ ] **Step 3: Renderizar por perna no `TripRequestCard`**

Em `lib/features/home/presentation/widgets/trip_request_card.dart`, substitua o bloco das
linhas 249-273 (os três `_DetailList`: Passageiros / Crianças / Bagagem) por:

```dart
          if (!widget.request.isRoundTrip) ...[
            if (widget.request.passengerLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.people_outline_rounded,
                title: 'Passageiros',
                entries: widget.request.passengerLabels,
              ),
            ],
          ] else ...[
            if (widget.request.outboundPassengerLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.people_outline_rounded,
                title: 'Passageiros na ida',
                entries: widget.request.outboundPassengerLabels,
              ),
            ],
            if (widget.request.returnPassengerLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.people_outline_rounded,
                title: 'Passageiros na volta',
                entries: widget.request.returnPassengerLabels,
              ),
            ],
          ],
          if (widget.request.childLabels.isNotEmpty) ...[
            SizedBox(height: isCompact ? 8 : 10),
            _DetailList(
              icon: Icons.warning_amber_rounded,
              title: 'Crianças',
              entries: widget.request.childLabels,
              warning: true,
            ),
          ],
          if (!widget.request.isRoundTrip) ...[
            if (widget.request.luggageLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.luggage_outlined,
                title: 'Bagagem',
                entries: widget.request.luggageLabels,
              ),
            ],
          ] else ...[
            if (widget.request.outboundLuggageLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.luggage_outlined,
                title: 'Bagagens na ida',
                entries: widget.request.outboundLuggageLabels,
              ),
            ],
            if (widget.request.returnLuggageLabels.isNotEmpty) ...[
              SizedBox(height: isCompact ? 8 : 10),
              _DetailList(
                icon: Icons.luggage_outlined,
                title: 'Bagagens na volta',
                entries: widget.request.returnLuggageLabels,
              ),
            ],
          ],
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/home/trip_request_card_leg_test.dart`
Expected: PASS (2 testes).

- [ ] **Step 5: Aplicar a mesma regra no carrossel**

Em `lib/features/home/presentation/widgets/pending_trip_requests_carousel.dart` o bloco das
linhas 242-256 renderiza `passengerLabels` e `childLabels`. Substitua-o por:

```dart
          if (!trip.isRoundTrip) ...[
            if (trip.passengerLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailList(
                title: 'Passageiros',
                entries: trip.passengerLabels,
              ),
            ],
          ] else ...[
            if (trip.outboundPassengerLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailList(
                title: 'Passageiros na ida',
                entries: trip.outboundPassengerLabels,
              ),
            ],
            if (trip.returnPassengerLabels.isNotEmpty) ...[
              const SizedBox(height: 8),
              _DetailList(
                title: 'Passageiros na volta',
                entries: trip.returnPassengerLabels,
              ),
            ],
          ],
          if (trip.childLabels.isNotEmpty) ...[
            const SizedBox(height: 8),
            _DetailList(
              title: 'Crianças',
              entries: trip.childLabels,
            ),
          ],
```

> **Antes de colar:** o `_DetailList` deste arquivo é uma classe privada **diferente** da do
> `TripRequestCard`. Copie a lista exata de argumentos que já estava nas linhas 242-256 (pode ter
> `icon`, `warning`, altura diferente do `SizedBox`) e mude apenas `title` e `entries`.

Ainda nesse arquivo, a linha 79 filtra as viagens que têm detalhes a exibir:

```dart
      (trip) => trip.passengerLabels.isNotEmpty || trip.childLabels.isNotEmpty,
```

Não mude essa linha — `passengerLabels` continua sendo a união das duas pernas, então o filtro
segue correto.

- [ ] **Step 6: Aplicar a mesma regra na tela de detalhe**

Em `lib/features/schedules/presentation/pages/schedule_detail_page.dart`, substitua o bloco das
linhas 1325-1341 por:

```dart
        if (!_trip.isRoundTrip) ...[
          if (_trip.passengerLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Passageiros',
              value: _trip.passengerLabels.join(', '),
            ),
          ],
        ] else ...[
          if (_trip.outboundPassengerLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Passageiros na ida',
              value: _trip.outboundPassengerLabels.join(', '),
            ),
          ],
          if (_trip.returnPassengerLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Passageiros na volta',
              value: _trip.returnPassengerLabels.join(', '),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
        if (_trip.childLabels.isNotEmpty) ...[
          const SizedBox(height: 10),
          _InfoRow(label: 'Crianças', value: _trip.childLabels.join(', ')),
        ],
        if (!_trip.isRoundTrip) ...[
          if (_trip.luggage.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(label: 'Bagagem', value: _trip.luggageLabels.join(', ')),
          ],
        ] else ...[
          if (_trip.outboundLuggageLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Bagagens na ida',
              value: _trip.outboundLuggageLabels.join(', '),
            ),
          ],
          if (_trip.returnLuggageLabels.isNotEmpty) ...[
            const SizedBox(height: 6),
            _InfoRow(
              label: 'Bagagens na volta',
              value: _trip.returnLuggageLabels.join(', '),
            ),
          ],
        ],
```

- [ ] **Step 7: Ajustar o segundo bloco de bagagem da mesma tela**

Ainda em `schedule_detail_page.dart`, existe um segundo lugar (linhas ~845-868) que lista
`childLabels` e `luggageLabels`. Ali, troque **somente** a linha ~867
(`value: _trip.luggageLabels.join(', '),`) por:

```dart
                            value: _trip.isRoundTrip
                                ? [
                                    if (_trip.outboundLuggageLabels.isNotEmpty)
                                      'Ida: ${_trip.outboundLuggageLabels.join(', ')}',
                                    if (_trip.returnLuggageLabels.isNotEmpty)
                                      'Volta: ${_trip.returnLuggageLabels.join(', ')}',
                                  ].join(' · ')
                                : _trip.luggageLabels.join(', '),
```

Mantenha a indentação existente do arquivo.

- [ ] **Step 8: Rodar analyze e a suíte**

Run: `flutter analyze lib/features/home lib/features/schedules`
Expected: nenhum erro.

Run: `flutter test`
Expected: PASS.

- [ ] **Step 9: Commit**

```bash
git add lib/features/home/presentation/widgets/trip_request_card.dart lib/features/home/presentation/widgets/pending_trip_requests_carousel.dart lib/features/schedules/presentation/pages/schedule_detail_page.dart test/features/home/trip_request_card_leg_test.dart
git commit -m "feat: motorista ve passageiros e bagagens separados por ida e volta"
```

---

### Task 25: Motorista responde ao re-check via RPC

**Files:**
- Modify: `lib/features/schedules/data/repositories/scheduled_direct_repository.dart`
- Modify: `lib/features/schedules/presentation/pages/schedule_detail_page.dart:299-307` e `:353-372`
- Test: `test/features/schedules/scheduled_direct_repository_test.dart` (criar)

**Por quê:** hoje `confirmScheduledTrip` (`trip_service.dart:378-396`) faz um `UPDATE` direto em
`trips` setando `status = 'scheduled'`. Isso **não copia** `offered_price` para `final_price` e
**não valida** que o candidato está em `accepted`. Para `scheduled_choose_driver` precisamos das
RPCs criadas nas Tasks 3 e 6. `TripService` fica **intocado** (serve os outros fluxos); a mudança
mora no `ScheduledDirectRepository` e no ponto de decisão da página.

- [ ] **Step 1: Escrever o teste que falha**

Crie `test/features/schedules/scheduled_direct_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_prestador/features/schedules/data/repositories/scheduled_direct_repository.dart';

void main() {
  group('ScheduledDirectRepository.buildRejectParams', () {
    test('sem motivo envia reason_input nulo', () {
      expect(
        ScheduledDirectRepository.buildRejectParams(tripId: 'trip-1', reason: null),
        {'trip_id_input': 'trip-1', 'reason_input': null},
      );
    });

    test('motivo em branco vira null', () {
      expect(
        ScheduledDirectRepository.buildRejectParams(
          tripId: 'trip-1',
          reason: '   ',
        )['reason_input'],
        isNull,
      );
    });

    test('motivo preenchido vai sem espacos nas pontas', () {
      expect(
        ScheduledDirectRepository.buildRejectParams(
          tripId: 'trip-1',
          reason: '  agenda cheia  ',
        )['reason_input'],
        'agenda cheia',
      );
    });
  });

  group('ScheduledDirectRepository.buildConfirmParams', () {
    test('observacao vazia vira null', () {
      expect(
        ScheduledDirectRepository.buildConfirmParams(tripId: 'trip-1', observation: ''),
        {'trip_id_input': 'trip-1', 'driver_observation_input': null},
      );
    });

    test('observacao preenchida e repassada', () {
      expect(
        ScheduledDirectRepository.buildConfirmParams(
          tripId: 'trip-1',
          observation: 'chego 10 min antes',
        )['driver_observation_input'],
        'chego 10 min antes',
      );
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar que falha**

Run: `flutter test test/features/schedules/scheduled_direct_repository_test.dart`
Expected: FAIL — `The method 'buildRejectParams' isn't defined for the type 'ScheduledDirectRepository'`.

- [ ] **Step 3: Reescrever o repositório**

Substitua todo o conteúdo de
`lib/features/schedules/data/repositories/scheduled_direct_repository.dart` por:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ScheduledDirectRepository {
  static Map<String, dynamic> buildRejectParams({
    required String tripId,
    required String? reason,
  }) {
    final trimmed = reason?.trim();
    return {
      'trip_id_input': tripId,
      'reason_input': (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    };
  }

  static Map<String, dynamic> buildConfirmParams({
    required String tripId,
    required String? observation,
  }) {
    final trimmed = observation?.trim();
    return {
      'trip_id_input': tripId,
      'driver_observation_input':
          (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    };
  }

  Future<void> acceptWithPrice(String tripId, double price) async {
    await Supabase.instance.client.rpc(
      'driver_accept_scheduled_direct',
      params: {'trip_id_input': tripId, 'offered_price_input': price},
    );
  }

  Future<void> reject(String tripId, {String? reason}) async {
    await Supabase.instance.client.rpc(
      'driver_reject_scheduled_direct',
      params: buildRejectParams(tripId: tripId, reason: reason),
    );
  }

  Future<void> confirmRecheck(String tripId, {String? observation}) async {
    await Supabase.instance.client.rpc(
      'driver_confirm_scheduled_recheck',
      params: buildConfirmParams(tripId: tripId, observation: observation),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar que passa**

Run: `flutter test test/features/schedules/scheduled_direct_repository_test.dart`
Expected: PASS (5 testes).

- [ ] **Step 5: Ligar a confirmação do re-check na página**

Em `lib/features/schedules/presentation/pages/schedule_detail_page.dart`, o `else` das linhas
299-307 chama `_tripService.confirmScheduledTrip`. Substitua esse `else` por:

```dart
    } else {
      setState(() => _isLoading = true);
      final observation = _observationController.text.trim().isEmpty
          ? null
          : _observationController.text.trim();
      if (_trip.tripType == 'scheduled_choose_driver') {
        try {
          await _scheduledDirectRepository.confirmRecheck(
            _trip.tripId,
            observation: observation,
          );
          ok = true;
        } catch (_) {
          ok = false;
        }
      } else {
        ok = await _tripService.confirmScheduledTrip(_trip.tripId, observation);
      }
    }
```

- [ ] **Step 6: Ligar a recusa do re-check na página**

No mesmo arquivo, método `_reject()`. O `if (_isScheduledDirectRequest)` da linha 353 já usa o
repositório — passe o motivo:

```dart
    if (_isScheduledDirectRequest) {
      try {
        await _scheduledDirectRepository.reject(
          _trip.tripId,
          reason: _observationController.text.trim(),
        );
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
```

E o `else` final (linhas 366-372), que hoje chama `_tripService.rejectTrip`, vira:

```dart
    } else if (_trip.tripType == 'scheduled_choose_driver') {
      try {
        await _scheduledDirectRepository.reject(
          _trip.tripId,
          reason: _observationController.text.trim(),
        );
        ok = true;
      } catch (_) {
        ok = false;
      }
    } else {
      ok = await _tripService.rejectTrip(
        _trip.tripId,
        _observationController.text.trim(),
        driverProfileId: driverProfileId,
      );
    }
```

Esse novo ramo é o que cobre a **recusa do re-check**: nesse momento a viagem está em
`awaiting_driver_confirmation` com o candidato em `accepted`, então `_isScheduledDirectRequest`
é `false` (ele exige `candidateStatus != 'accepted'`, ver `trip_data.dart:82-85`) e antes a
execução caía no `UPDATE` direto do `TripService`.

- [ ] **Step 7: Rodar analyze e a suíte inteira**

Run: `flutter analyze`
Expected: nenhum erro.

Run: `flutter test`
Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/schedules/data/repositories/scheduled_direct_repository.dart lib/features/schedules/presentation/pages/schedule_detail_page.dart test/features/schedules/scheduled_direct_repository_test.dart
git commit -m "feat: motorista confirma e recusa re-check via RPC dedicada"
```

---

# Verificação final do fluxo completo (manual, 3 apps)

Só execute depois que as Tasks 1-25 estiverem commitadas e as migrations aplicadas no ambiente de
teste (`supabase db push` a partir de `C:\Projetos\kz-servicos-web-app-fork\kz-servicos-web-app-fork\`).

- [ ] **Step 1: Cliente envia a solicitação**

App cliente: Corrida agendada **ida e volta** → passageiros e bagagens **diferentes em cada perna**
→ pagamento → Selecionar motorista → **Solicitar**.

Confirme: a tela vai para `/scheduled-choose-driver/awaiting/{tripId}`.

- [ ] **Step 2: Cliente sai e retoma**

Volte para a home e abra **Agendamentos**. A viagem aparece com a tag **"Aguardando motorista"**.
Toque nela: abre a lista de motoristas, com o motorista solicitado marcado e o botão
**"Cotação"** visível.

- [ ] **Step 3: Motorista vê os detalhes por perna e aceita com preço**

App motorista: o card mostra **"Passageiros na ida"**, **"Passageiros na volta"**,
**"Bagagens na ida"** e **"Bagagens na volta"** com os dados corretos de cada perna.
Aceite informando um preço.

- [ ] **Step 4: Cliente vê o preço sem aprovação do admin**

App cliente: sem nenhuma ação do admin, a tag vira **"Preço recebido"** e tocar nela abre
`/scheduled-choose-driver/price-review/{tripId}` com o valor ofertado.

- [ ] **Step 5: Cliente aceita → re-check**

Aceite o preço. A tag vira **"Confirmando com motorista"**. Verifique no banco:
`trips.status = 'awaiting_driver_confirmation'`, `trip_driver_candidates.status = 'accepted'`,
`trips.final_price IS NULL`.

Tente trocar de motorista pela lista: o botão **Solicitar** deve estar bloqueado com o aviso de
re-check em andamento (erro `KZ003`).

- [ ] **Step 6: Motorista confirma → agendada**

App motorista: confirme o re-check. Verifique no banco que `trips.status = 'scheduled'` e que
`trips.final_price` recebeu o valor de `trip_driver_candidates.offered_price`.

App cliente: a tag vira **"Agendada"**.

- [ ] **Step 7: Caminho de recusa**

Repita os passos 1-5 com outra viagem e faça o motorista **recusar** o re-check.
Confirme: `trips.status = 'searching_drivers'`, `trip_driver_candidates.status = 'rejected'`,
`offered_price` e `final_price` limpos. No app cliente a tag vira **"Escolher outro motorista"**
e tocar nela reabre a lista de motoristas desbloqueada.
