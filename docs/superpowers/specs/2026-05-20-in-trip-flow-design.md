# In-Trip Flow — Design Spec
**Data:** 2026-05-20  
**Projetos afetados:** kz-servicos-web-app · kz-servicos-app-cliente · kz-servicos-app-prestador  
**Status:** Aprovado

---

## Visão Geral

Quando o admin seta uma corrida para `started` no webapp, os dois apps entram automaticamente em modo de corrida ativa via Supabase Realtime. O motorista recebe navegação GPS 3D até o cliente, depois até o destino. O cliente acompanha o motorista em tempo real no mapa, com transições automáticas de fase. Paralelamente, o fluxo de definição de valor da corrida passa a ser responsabilidade do motorista (não do admin), e a forma de pagamento é responsabilidade do cliente (apenas na criação).

---

## 1. Banco de Dados

### 1.1 Migrations necessárias (3)

#### Migration 1 — `offered_price` em `trip_driver_candidates`
```sql
ALTER TABLE trip_driver_candidates
  ADD COLUMN offered_price DECIMAL(10,2);
```
Motorista seta o valor ao aceitar. Sem NOT NULL — candidatos sem valor ficam visíveis no admin como "Aguardando valor".

#### Migration 2 — `driver_arrived_at` em `trips`
```sql
ALTER TABLE trips
  ADD COLUMN driver_arrived_at TIMESTAMPTZ;
```
Setado pelo app prestador quando motorista clica "Cheguei ao local". Sinaliza para o app cliente que o motorista está no ponto de embarque.

#### Migration 3 — Realtime em `trips`
```sql
ALTER PUBLICATION supabase_realtime ADD TABLE trips;
```
Necessário para que os apps Flutter recebam mudanças de `status`, `driver_arrived_at` e `started_at` em tempo real sem polling.

### 1.2 Mudança de semântica em `trips.started_at`
- **Antes:** setado pelo admin ao clicar "Em Andamento"
- **Depois:** setado pelo motorista ao clicar "Iniciar corrida" no app prestador
- O admin muda apenas `trips.status` para `started` — não seta `started_at`
- `started_at` representa "cliente embarcou, corrida em movimento"

### 1.3 Campos financeiros — responsabilidades
| Campo | Quem seta | Onde |
|-------|-----------|------|
| `payment_method` | Cliente (ou admin na criação) | Form de nova corrida apenas |
| `offered_price` (candidates) | Motorista | App prestador, ao aceitar |
| `final_price` | Sistema | Copiado de `offered_price` quando admin seleciona motorista |
| `is_paid` | Admin | Webapp (campo informacional, permanece) |

---

## 2. Webapp (`kz-servicos-web-app`)

### 2.1 Remoções no `TripDetailModal.tsx`
- Remover campo editável "Valor Final" (`final_price`) de **todos** os status
- Remover campo editável "Forma de Pagamento" (`payment_method`) de **todos** os status
- Manter `is_paid` como campo informacional (sem edição inline de valor)
- `final_price` continua visível como texto readonly quando preenchido (exibição apenas)

### 2.2 Seção "Motoristas Candidatos" — status `searching_drivers`
**Antes:** nome + status badge + botão remover  
**Depois:** nome + `R$ offered_price` (ou "Aguardando valor" em muted) + botão "Selecionar" + botão remover

Regra do botão "Selecionar":
- Habilitado apenas se `offered_price IS NOT NULL`
- Ao clicar executa atomicamente:
  1. `trips.driver_profile_id = candidate.driver_profile_id`
  2. `trips.final_price = candidate.offered_price`
  3. `trips.status = 'scheduled'`
  4. `trip_driver_candidates.status = 'accepted'` para o selecionado
  5. `trip_driver_candidates.status = 'rejected'` para todos os outros

### 2.3 `NovaViagemForm.tsx` — sem mudança
Campo "Forma de pagamento" permanece. É o único lugar onde admin (criando como cliente) pode setar `payment_method`.

### 2.4 Ação "Em Andamento" (status `scheduled → started`)
- Webapp muda apenas `trips.status = 'started'`
- **Não** seta `started_at` — isso passa a ser responsabilidade do motorista
- Remover qualquer atribuição de `started_at` nessa ação

---

## 3. App Prestador (`kz-servicos-app-prestador`)

### 3.1 Remoção de dados mock
- Remover uso de `MockTripRequest` do fluxo ativo
- Dados vêm do Supabase via query na trip assignada ao motorista logado

### 3.2 Popup de aceitação de corrida (existente — modificar)
Adicionar abaixo dos detalhes da corrida:

```
Seu valor para esta corrida:
┌──────────────────────────┐
│ R$  [campo numérico]     │
└──────────────────────────┘
```

**Validação no botão "Aceitar":**
- Campo vazio → não submete
- Efeito de erro: bounce animation + borda vermelha + texto "Informe um valor antes de aceitar"
- Com valor → salva `offered_price` em `trip_driver_candidates`, status `accepted`

### 3.3 Subscription Realtime — trip ativa
O app prestador mantém subscription em `trips` onde `driver_profile_id = motorista_logado`.  
- Quando `status` muda para `scheduled`: motor recebe confirmação de seleção (notificação já existente)
- Quando `status` muda para `started`: entra em `TripPhase.navigatingToClient`
- Subscription também monitora `driver_arrived_at` e `started_at` para transições de fase

### 3.4 Publicação de localização
Durante qualquer fase ativa (`navigatingToClient` ou `tripInProgress`):
- Geolocator stream → upsert em `driver_locations` a cada **5 segundos**
- Campos: `latitude`, `longitude`, `heading`, `speed`, `trip_id`

### 3.5 Fase `navigatingToClient`
- **Câmera:** 3D — `tilt: 45.0`, bearing = heading GPS atual, zoom ~17
- **Rota:** amarela, pickup do cliente como destino, atualizada a cada nova posição
- **Ícone do motorista:** triângulo azul (`▲`) rotacionado conforme `heading`
- **Botão:** "Cheguei ao local" → `UPDATE trips SET driver_arrived_at = now()`

### 3.6 Fase `arrivedAtClient` (popup modal)
Disparado quando motorista clica "Cheguei ao local":
```
✓ Você chegou ao local de embarque

Cliente: [nome]
Destino: [endereço destino]
Passageiros: [n]
Valor combinado: R$ [offered_price]

        [Iniciar corrida]
```
Ao clicar "Iniciar corrida":
- `UPDATE trips SET started_at = now()`
- Fase → `tripInProgress`

### 3.7 Fase `tripInProgress`
- **Câmera:** 3D igual, bearing seguindo heading, rota amarela até o **destino**
- **Ícone:** mesmo triângulo azul
- **GPS:** continua publicando a cada 5s
- **Botão:** "Finalizar corrida" (fluxo existente de `tripCompleted`)

---

## 4. App Cliente (`kz-servicos-app-cliente`)

### 4.1 Subscription Realtime — trip ativa
O app cliente assina mudanças na trip ativa do usuário logado.  
Quando `trips.status = 'started'` → sai do fluxo normal e entra no `TripFlowStep.tripStarted` (sub-fases abaixo).

Também assina `driver_locations` para o `driver_profile_id` da trip ativa → recebe posição do motorista em tempo real.

### 4.2 Sub-fase A — Motorista a caminho
**Condição:** `status = 'started' AND driver_arrived_at IS NULL`

- Mapa normal (sem 3D)
- Rota do **motorista → pickup do cliente** traçada em `AppColors.secondary` (azul)
- Ícone do motorista: ponto animado (`AppColors.secondary`) que se move conforme `driver_locations` updates
- Avatar do motorista: `users.avatar_url` via join `driver_profiles → provider_profiles → users`
- Painel inferior fixo:
  ```
  [avatar] (Nome) está indo até você
           ETA: ~X min
  ```
- ETA calculado via Directions API entre posição atual do motorista e pickup

### 4.3 Sub-fase B — Motorista chegou
**Condição:** `status = 'started' AND driver_arrived_at IS NOT NULL AND started_at IS NULL`

- Bottom sheet sobe com:
  ```
  ✓ (Nome) já está no local de embarque
  ```
- Mapa mostra motorista parado no ponto de pickup

### 4.4 Sub-fase C — Corrida em andamento
**Condição:** `status = 'started' AND started_at IS NOT NULL`

- Rota amarela **completa** (pickup → destino)
- Animação pulsante branca existente sobre a rota amarela
- Camera zoom-out automático para encaixar a rota completa (`LatLngBounds` do pickup + destino)
- Ponto azul = posição atual do veículo (via `driver_locations` Realtime)
- Painel inferior mínimo: nome do motorista + destino (sem controles)
- Sem 3D

### 4.5 Forma de pagamento — `passenger_details_panel.dart`
- Substituir `paymentMethod: 'pix'` hardcoded por um seletor real
- Opções: PIX, Débito, Crédito, Dinheiro, Faturamento (enum `payment_method`)
- Valor selecionado enviado no `TripRequest.paymentMethod`

---

## 5. Fluxo Completo Integrado

```
Cliente cria corrida (payment_method selecionado)
  │
  ▼
Admin: open → under_review → searching_drivers
  │  Motoristas recebem popup com campo de valor
  │  Motoristas setam offered_price e aceitam
  ▼
Admin: seleciona motorista → final_price = offered_price → scheduled
  │
  ▼
Admin: scheduled → started (só muda status, não started_at)
  │
  ├─► App Prestador:
  │     navigatingToClient (3D, triângulo azul, GPS publishing)
  │       │ "Cheguei ao local" → driver_arrived_at = now()
  │     arrivedAtClient (popup com detalhes)
  │       │ "Iniciar corrida" → started_at = now()
  │     tripInProgress (3D, rota até destino)
  │       │ "Finalizar corrida" → status = finished
  │
  └─► App Cliente:
        Sub-fase A: motorista a caminho (ponto movendo, ETA)
          │ driver_arrived_at set →
        Sub-fase B: motorista chegou (bottom sheet)
          │ started_at set →
        Sub-fase C: in-trip map (rota amarela pulsante, ponto azul)
          │ status = finished →
        TripSummary → Rating (fluxo existente)
```

---

## 6. Arquivos a Criar/Modificar

### Banco (supabase/migrations — no web-app repo)
- `20260520120000_add_offered_price_to_candidates.sql`
- `20260520120001_add_driver_arrived_at_to_trips.sql`
- `20260520120002_enable_realtime_trips.sql`

### Webapp (`kz-servicos-web-app`)
- `src/components/TripDetailModal.tsx` — remover campos financeiros editáveis
- `src/components/TripDriverCandidates.tsx` (ou inline no modal) — mostrar offered_price + botão Selecionar
- `src/lib/api.ts` — função `selectTripDriver(tripId, candidateId)` que executa as 5 operações atômicas
- `src/types/database.ts` — adicionar `offered_price` em `TripDriverCandidate`

### App Prestador (`kz-servicos-app-prestador`)
- `lib/features/trip/data/models/trip_driver_candidate_model.dart` — adicionar `offered_price`
- `lib/features/trip/presentation/widgets/trip_offer_popup.dart` — campo de valor + validação
- `lib/features/trip/presentation/pages/active_trip_page.dart` — Realtime subscription + GPS publishing
- `lib/features/trip/presentation/widgets/active_trip_panels.dart` — popup arrivedAtClient
- `lib/features/trip/domain/trip_phase.dart` — sem mudança de enum, mas lógica de `isGpsMode`

### App Cliente (`kz-servicos-app-cliente`)
- `lib/features/trip/presentation/pages/trip_home_page.dart` — Realtime subscription + sub-fases
- `lib/features/trip/presentation/widgets/driver_en_route_panel.dart` — sub-fase A (motorista a caminho)
- `lib/features/trip/presentation/widgets/driver_arrived_sheet.dart` — **novo** — sub-fase B
- `lib/features/trip/presentation/widgets/in_trip_map_view.dart` — **novo** — sub-fase C (rota amarela)
- `lib/features/trip/presentation/widgets/passenger_details_panel.dart` — seletor de pagamento real
- `lib/features/trip/data/models/scheduled_trip_model.dart` — já corrigido (timezone)

---

## 7. Sem Mudanças
- Fluxo de avaliação pós-corrida (existente, funciona)
- Chat entre cliente e motorista
- Notificações push
- Histórico de corridas
- Outros serviços (diarista, etc.)
