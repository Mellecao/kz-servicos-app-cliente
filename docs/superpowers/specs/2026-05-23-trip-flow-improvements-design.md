# Spec: Trip Flow Improvements — KZ Serviços App Cliente

**Data:** 2026-05-23  
**Branch:** develop  
**Status:** Aprovado

---

## Contexto

O fluxo de viagem do app cliente possui vários pontos incompletos ou incorretos:

1. Após confirmar um motorista, o app trava numa tela `driverSelected` sem saída.
2. Não há botão para recusar um motorista na tela de perfil.
3. A rejeição não é propagada para o backend nem para o app web.
4. A tela "motorista a caminho" não mostra ETA real nem botões de contato.
5. A tela "motorista chegou" exibe título errado ("Viagem em andamento") antes da corrida iniciar.
6. Quando o motorista chega, o mapa não mostra o trajeto do usuário até o embarque.
7. O chat usa dados mock; não está conectado ao Supabase real.
8. O ícone de Agendamentos no nav não mostra badge quando há viagens agendadas.

---

## Escopo das mudanças

### 1. Recusar motorista

**Trigger:** cliente visualiza perfil do motorista no `_DriverProfileSheet`.

**Mudanças em `driver_selection_panel.dart`:**
- Adicionar `onReject: VoidCallback` ao `_DriverProfileSheet`.
- Adicionar botão outlined "Recusar motorista" abaixo de "Selecionar motorista".
- Ao tocar: chamar `PATCH trip_driver_candidates SET status = 'rejected' WHERE id = candidateId` no Supabase, depois fechar o sheet via `Navigator.pop`.
- Ao fechar o sheet, o cliente permanece no `DriverSelectionPanel` com os demais candidatos.
- `_showDriverProfile()` em `DriverSelectionPanel` passa o callback de rejeição com o candidateId correto.
- O app web lê `trip_driver_candidates.status` diretamente do DB — a mudança para `rejected` se reflete automaticamente no card do motorista no painel web.

**Supabase query (no `_onDriverRejected` no `trip_home_page.dart`):**
```dart
await Supabase.instance.client
    .from('trip_driver_candidates')
    .update({'status': 'rejected'})
    .eq('id', candidateId);
```

---

### 2. Pós-confirmação → reset para idle

**Trigger:** `_onDriverAccepted()` recebe sucesso da API.

**Mudanças em `trip_home_page.dart`:**
- Após `acceptCandidate()` retornar sem erro, chamar `_finishScheduledTripFlow()` em vez de permanecer em `driverSelected`.
- `_finishScheduledTripFlow()`:
  - Cancela `_searchingTimer`, `_confirmingTimer`, `_driverMoveTimer`.
  - Desinscreve `_tripChannel` e `_candidatesChannel`.
  - `setState` → `TripFlowStep.idle` com reset de todas as variáveis de rota/motorista.
  - NÃO seta `_isSearchActive = true` (diferente de `_onDetailsBack`).
  - Não chama `_loadScheduledTrips()` novamente — já é chamado dentro de `_onDriverAccepted`.

**Resultado:** a home fica visível com o mapa, a barra de busca e o `ScheduledTripCard` (que já é renderizado em `_buildScheduledTripsList()` quando `state is ScheduledTripsLoaded && trips.isNotEmpty`).

---

### 3. Badge no ícone de Agendamentos

**Mudanças em `trip_bottom_nav.dart`:**
- Adicionar parâmetro `scheduledCount: int` (default 0).
- No item de índice 3 (Agendamentos), envolver o ícone em `Stack` com um `Badge` circular vermelho no canto superior direito exibindo `+N` quando `scheduledCount > 0`.
- Badge oculto quando `scheduledCount == 0`.

**Mudanças em `trip_home_page.dart` (`_buildBottomNav`):**
- Envolver `TripBottomNav` em `BlocBuilder<ScheduledTripsCubit, ScheduledTripsState>`.
- Passar `scheduledCount: state is ScheduledTripsLoaded ? state.trips.length : 0`.

---

### 4. ETA real via Directions API

**Mudanças em `directions_service_mobile.dart`:**
- Criar classe `DirectionsResult { final List<LatLng> points; final int durationSeconds; }`.
- Novo método `fetchRouteWithDuration` retorna `DirectionsResult` extraindo `routes[0].legs[0].duration.value` da resposta JSON.
- Manter `fetchRoute` como wrapper que retorna só os pontos (compatibilidade retroativa).

**Mudanças em `trip_home_page.dart`:**
- `_fetchDriverToPickupRoute` passa a chamar `fetchRouteWithDuration`.
- Atualiza `_driverEtaMinutes = (result.durationSeconds / 60).ceil()` após cada resposta.
- Isso já acontece a cada 15 s via `_onDriverLocationUpdate`.

---

### 5. Ícone do motorista com heading (rotação)

**Mudanças em `trip_home_page.dart`:**
- Novo método `_createCarIcon(double heading)`: desenha ícone de carro no Canvas com `canvas.rotate(heading em radianos)`, retorna `BitmapDescriptor`.
- Cache em `Map<int, BitmapDescriptor> _carIconCache` com chave = `heading.round() ~/ 5 * 5` (arredondado a 5°).
- `_updateDriverMarker` usa `_carIconCache[roundedHeading]` em vez de `_cachedBlueDotIcon`.

---

### 6. Ligar para o motorista

**Mudanças em `trip_home_page.dart`:**
- `_fetchDriverNameAndStartTracking` adiciona `phone` à query:
  ```dart
  .select('provider_profiles(user_id, users(full_name, phone))')
  ```
- Novo campo `String? _activeDriverPhone`.
- Passar `driverPhone: _activeDriverPhone` para `DriverEnRoutePanel`.

**Mudanças em `driver_en_route_panel.dart`:**
- Adicionar `driverPhone: String?` ao widget.
- No conteúdo expandido, adicionar linha de botões de ação abaixo das informações do motorista:
  - Botão "Ligar" (ícone telefone): `launchUrl(Uri.parse('tel:$driverPhone'))` — oculto se `driverPhone == null`.
  - Botão "Chat" (ícone chat): chama callback `onOpenChat`.
- Adicionar `onOpenChat: VoidCallback` ao widget.

---

### 7. Chat real no Supabase

**Fluxo de abertura do chat (em `trip_home_page.dart`):**
- `_openDriverChat()`: como `chat_rooms` não tem `UNIQUE(trip_id)`, o fluxo é:
  1. `SELECT id FROM chat_rooms WHERE trip_id = X LIMIT 1`
  2. Se encontrado: usa o `id` retornado.
  3. Se não encontrado: `INSERT INTO chat_rooms {trip_id, client_id: auth.uid(), provider_id: _activeDriverUserId}` e usa o `id` inserido.
- Botão de chat só aparece quando `_activeDriverUserId != null`.
- Após obter `chatRoomId`: `context.go('/chat/$chatRoomId')`.

**Refatoração de `chat_page.dart`:**
- Remover `MockConversation` e `MockChatMessage`.
- `initState`: busca histórico `SELECT * FROM chat_messages WHERE chat_room_id = conversationId ORDER BY created_at ASC`.
- Assina canal Realtime `chat-$conversationId` em `chat_messages` para inserções novas → adiciona mensagem à lista local.
- `_sendMessage(text)`: `INSERT INTO chat_messages {chat_room_id, sender_id: auth.uid(), message: text, message_type: 'text'}`.
- Distingue mensagens próprias vs. do motorista via `sender_id == auth.uid()`.
- Mantém preset messages como botões de atalho que disparam `_sendMessage(text)`.
- Cancela subscription Realtime no `dispose`.

**Schema relevante:**
```
chat_rooms(id, trip_id, client_id, provider_id, is_active)
chat_messages(id, chat_room_id, sender_id, message, message_type, created_at)
```

---

### 8. Tela "Motorista chegou" — redesign

#### 8a. Panel inferior (`driver_arrived_sheet.dart`)

**Mudanças:**
- Remover título "Viagem em andamento".
- Novo título: `"${driverName} chegou ao local de embarque"` (estilo `QuasimodoSemiBold`, 16px).
- Novo subtexto: `"Dirija-se até ${pickupAddress}"` (13px, cinza).
- Manter seção de detalhes colapsável (origem, destino, passageiros, valor).

#### 8b. Mapa durante `driverArrived` (em `trip_home_page.dart`)

**Novo método `_enterDriverArrivedMapView()`** chamado em `_onTripUpdate` ao detectar `driverArrivedAt != null` (e também em `_onDriverArrived` para o fluxo simulado):

1. Limpa polylines do motorista (`driver_route`, `driver_route_glow`).
2. Guard: se `_pickupLatLng == null`, encerra sem fazer nada. Se `_currentLocation == null`, exibe apenas o pin de embarque sem rota.
3. Busca rota `_currentLocation → _pickupLatLng` via `fetchRouteWithDuration`.
3. **Se pontos retornados (rota de carro/moto):**
   - Exibe `Polyline` amarela sólida (`AppColors.highlight`, largura 4) sobre a rota.
   - Exibe glow amarelo (`alpha: 0.18`, largura 10).
4. **Se lista vazia (sem estradas entre os pontos):**
   - Exibe `Polyline` amarela com `patterns: [PatternItem.dash(20), PatternItem.gap(10)]` em linha reta de `_currentLocation` a `_pickupLatLng` (caminho a pé).
5. Marcadores: ponto azul do usuário + pin amarelo no embarque.
6. `fitBounds` entre `_currentLocation` e `_pickupLatLng` com padding 80.

**Transição para `tripStarted`** (comportamento atual preservado):
- `_onTripUpdate` detecta `started_at != null` → `_step = tripStarted` → `_enterInTripMapView()` (limpa rota atual, busca rota pickup→destino, zoom-out).

---

## Ordem de implementação

1. `directions_service_mobile.dart` — `DirectionsResult` + `fetchRouteWithDuration`
2. `driver_selection_panel.dart` — botão recusar + `onReject` callback
3. `trip_bottom_nav.dart` — badge `scheduledCount`
4. `driver_arrived_sheet.dart` — título e subtexto corretos
5. `chat_page.dart` — refatorar para Supabase real
6. `driver_en_route_panel.dart` — botões ligar/chat, param `driverPhone`/`onOpenChat`
7. `trip_home_page.dart` — todas as integrações:
   - `_onDriverRejected` (backend reject)
   - `_finishScheduledTripFlow` (reset idle)
   - Badge via BlocBuilder
   - `_fetchDriverNameAndStartTracking` com phone
   - `_fetchDriverToPickupRoute` com ETA real
   - `_createCarIcon` com heading
   - `_openDriverChat` (upsert chat_room + navigate)
   - `_enterDriverArrivedMapView`
   - badge no `_buildBottomNav`

---

## Invariantes e restrições

- `_finishScheduledTripFlow` NÃO seta `_isSearchActive = true` — preserva a home limpa.
- `fetchRoute` (assinatura original) permanece inalterado — apenas `fetchRouteWithDuration` é novo.
- Chat somente é aberto quando `_activeDriverUserId != null` (motorista real em rota).
- Dashed line só é usado como fallback — a chamada à Directions API é sempre tentada primeiro.
- O badge some quando `trips.isEmpty` (count volta a 0 se a viagem for cancelada).
- A rejeição de candidato (`status = 'rejected'`) só ocorre se a API call tiver sucesso — em caso de erro, o sheet permanece aberto e exibe SnackBar de erro.
