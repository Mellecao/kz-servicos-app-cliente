# Redesign do fluxo "Corrida Agora" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Trocar a camada de apresentação do fluxo "Corrida Agora" (ida e volta e somente ida) para o visual escuro do Figma KZ-SERVICOS, com o painel de solicitação sempre expandido na home, wiring real de paradas (`trip_stops`) e um passo dedicado de forma de pagamento — sem alterar rotas, cubits ou regras de negócio existentes.

**Architecture:** `RideRequestPanel` (novo) substitui `_buildFakeSearchBar` + `_buildSearchOverlay` enquanto `_step == TripFlowStep.idle`, absorvendo os campos de Partida/Destino/Paradas com autocomplete inline (reaproveitando os mesmos callbacks que `AddressSearchSheet`/`RoundTripAddressSheet` já expunham). "Corrida Agora" migra para o caminho genérico `TripRequest` → `TripRepositoryImpl.createTrip` (`tripType: 'standard'`, `scheduledDatetime: DateTime.now()`); "Agendar" continua disparando a cascata existente (`SystemSettingsRepository` → `ScheduledModeChoiceSheet`), sem UI nova. Um novo passo `TripFlowStep.paymentMethod` (via `PaymentMethodPanel`) é inserido só no caminho "Corrida Agora", entre `passengerDetails` e `searchingDriver`; os caminhos agendados (Cotação/Escolha seu Motorista) continuam como estão. `PassengerDetailsPanel` é restilizado para o tema escuro e perde a seção de pagamento (que migrou para o novo passo). Paradas passam a ser resolvidas para `TripAddress` e inseridas em `trip_stops` só no caminho padrão (`_isImmediateRequest`), via `TripStopModel.buildInsertJsonList`, função pura testável.

**Decisões de escopo explícitas** (resolvendo ambiguidades não cobertas literalmente pelo spec):
- Existe **um único** passo de pagamento por solicitação (`TripFlowStep.paymentMethod`), reaproveitado tanto para viagens só de ida quanto ida e volta — não há uma segunda tela de "confirmação final" separada.
- **Paradas (`trip_stops`) só são coletadas/persistidas na perna de ida.** O card de endereço da perna de volta (quando "Ida e volta" está ativo) mostra apenas Partida/Destino, sem paradas — consistente com `TripRequest.stops` sendo uma lista única, não dividida por perna.
- A opção "Máquina de cartão" do `PaymentMethodPanel` grava `payment_method = 'credit'` no banco (o enum não distingue "máquina" de crédito/débito; `debit` fica sem UI própria neste fluxo, mesmo padrão que `billing` já não aparece).
- Fluxos Flash e "Escolha seu Motorista" continuam sem paradas e sem o novo passo de pagamento — não são alcançáveis a partir do `RideRequestPanel` padrão (`_isFlashRequest` deixa de ser setado pela UI, mas o campo e o branch seguem existindo, inertes, no código).

**Tech Stack:** Flutter, Material, flutter_bloc, go_router, supabase_flutter, equatable, flutter_test, mocktail, bloc_test.

---

## Estrutura de arquivos

**Criar:**
- `lib/features/trip/data/models/trip_stop_model.dart` — `TripStopModel.buildInsertJsonList` (função pura).
- `test/features/trip/data/models/trip_stop_model_test.dart`
- `lib/features/trip/presentation/widgets/step_scaffold.dart` — app bar preta + seta voltar + card `sheetSurface`, reaproveitado por `PaymentMethodPanel`.
- `test/features/trip/presentation/widgets/step_scaffold_test.dart`
- `lib/features/trip/presentation/widgets/payment_method_panel.dart`
- `test/features/trip/presentation/widgets/payment_method_panel_test.dart`
- `lib/features/trip/presentation/widgets/ride_request_panel.dart`
- `test/features/trip/presentation/widgets/ride_request_panel_test.dart`
- `test/features/trip/domain/entities/trip_request_test.dart`
- `test/features/trip/domain/entities/passenger_form_data_test.dart`

**Modificar:**
- `lib/core/constants/app_colors.dart` — tokens `sheetBackground`/`sheetSurface`/`sheetTextPrimary`/`sheetTextSecondary`.
- `lib/features/trip/domain/entities/passenger_form_data.dart` — `copyWith`.
- `lib/features/trip/domain/entities/trip_request.dart` — campo `stops`.
- `lib/features/trip/data/models/trip_model.dart` — `buildInsertJson` não muda (paradas são uma tabela separada), mas é referenciado como padrão pelo novo `TripStopModel`.
- `lib/features/trip/data/repositories/trip_repository_impl.dart` — `createTrip` insere paradas.
- `lib/features/trip/presentation/widgets/passenger_details_panel.dart` — restilo escuro + remoção da seção de pagamento.
- `test/features/trip/presentation/widgets/passenger_details_panel_test.dart` — remove a asserção `find.text('Dinheiro')`.
- `lib/features/trip/presentation/pages/trip_home_page.dart` — novo enum value, novos campos de estado, `_openSearch` → `_openScheduledCascade`, `_onStopSelected` com `PlacePrediction`, split de `_onPassengerDetailsConfirmed`, novo `_onPaymentMethodConfirmed`, `_onDetailsBack` com branch de pagamento, resets (`_resetToIdle`/`_finishScheduledTripFlow`/`_goHomeFromScheduledSearch`) limpando `_stopPredictions`, `build()`/`_panelForStep()` atualizados, `_buildFakeSearchBar()`/`_buildSearchOverlay()` removidos, novo `_buildRideRequestPanel()`.

---

## Task 1: Tokens de cor escuros em AppColors

**Files:**
- Modify: `lib/core/constants/app_colors.dart`

Constantes puras — sem comportamento a testar, TDD não se aplica aqui (mesmo padrão do restante do arquivo, que também não tem teste dedicado).

- [ ] **Step 1: Adicionar os 4 tokens escuros**

Em `lib/core/constants/app_colors.dart`, adicionar após `static const Color white = Colors.white;` (linha 9):

```dart
  static const Color white = Colors.white;

  // Tema escuro dos painéis do fluxo "Corrida Agora" (spec 2026-08-16)
  static const Color sheetBackground = Color(0xFF141414);
  static const Color sheetSurface = Color(0xFF262626);
  static const Color sheetTextPrimary = Colors.white;
  static const Color sheetTextSecondary = Color(0xFF8A8A8A);
```

- [ ] **Step 2: Confirmar compilação**

Run:

```powershell
flutter analyze lib/core/constants/app_colors.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Commit**

```powershell
git add lib/core/constants/app_colors.dart
git commit -m "feat(theme): adiciona tokens de cor escuros para o redesign de Corrida Agora"
```

## Task 2: PassengerFormData.copyWith

**Files:**
- Modify: `lib/features/trip/domain/entities/passenger_form_data.dart`
- Create: `test/features/trip/domain/entities/passenger_form_data_test.dart`

`copyWith` é necessário porque o novo passo de pagamento precisa devolver uma cópia de `PassengerFormData` com `paymentMethod` atualizado sem duplicar os outros campos (hoje a seleção de pagamento vive dentro do próprio `PassengerDetailsPanel`; depois desta migração, o valor chega de fora, via `PaymentMethodPanel`).

- [ ] **Step 1: Escrever o teste falho**

Criar `test/features/trip/domain/entities/passenger_form_data_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';

void main() {
  group('PassengerFormData.copyWith', () {
    test('overrides only the given fields', () {
      final original = PassengerFormData(
        adults: 2,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        hasChildren: true,
        childrenDescription: '1 criança',
        hasLuggage: true,
        luggageDescription: '1 mala',
        observations: 'Portão azul',
        paymentMethod: 'pix',
        isRoundTrip: true,
        returnDatetime: DateTime(2026, 8, 16, 18, 0),
      );

      final updated = original.copyWith(paymentMethod: 'credit');

      expect(updated.paymentMethod, 'credit');
      expect(updated.adults, 2);
      expect(updated.scheduledDatetime, DateTime(2026, 8, 16, 10, 0));
      expect(updated.hasChildren, isTrue);
      expect(updated.childrenDescription, '1 criança');
      expect(updated.hasLuggage, isTrue);
      expect(updated.luggageDescription, '1 mala');
      expect(updated.observations, 'Portão azul');
      expect(updated.isRoundTrip, isTrue);
      expect(updated.returnDatetime, DateTime(2026, 8, 16, 18, 0));
    });

    test('keeps original values when no override is given', () {
      final original = PassengerFormData(
        adults: 1,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
      );

      final copy = original.copyWith();

      expect(copy.adults, original.adults);
      expect(copy.scheduledDatetime, original.scheduledDatetime);
      expect(copy.paymentMethod, original.paymentMethod);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/trip/domain/entities/passenger_form_data_test.dart
```

Expected: falha de compilação — `The method 'copyWith' isn't defined for the type 'PassengerFormData'`.

- [ ] **Step 3: Implementar copyWith**

Em `lib/features/trip/domain/entities/passenger_form_data.dart`, adicionar após o construtor (depois da linha `});` e antes dos campos `final`), mantendo os campos existentes intactos:

```dart
  PassengerFormData copyWith({
    int? adults,
    DateTime? scheduledDatetime,
    bool? hasChildren,
    String? childrenDescription,
    bool? hasLuggage,
    String? luggageDescription,
    String? observations,
    String? paymentMethod,
    bool? isRoundTrip,
    DateTime? returnDatetime,
  }) {
    return PassengerFormData(
      adults: adults ?? this.adults,
      scheduledDatetime: scheduledDatetime ?? this.scheduledDatetime,
      hasChildren: hasChildren ?? this.hasChildren,
      childrenDescription: childrenDescription ?? this.childrenDescription,
      hasLuggage: hasLuggage ?? this.hasLuggage,
      luggageDescription: luggageDescription ?? this.luggageDescription,
      observations: observations ?? this.observations,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      isRoundTrip: isRoundTrip ?? this.isRoundTrip,
      returnDatetime: returnDatetime ?? this.returnDatetime,
    );
  }
```

- [ ] **Step 4: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/domain/entities/passenger_form_data_test.dart
```

Expected: `00:0X +2: All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/trip/domain/entities/passenger_form_data.dart test/features/trip/domain/entities/passenger_form_data_test.dart
git commit -m "feat(trip): adiciona PassengerFormData.copyWith para o novo passo de pagamento"
```

## Task 3: TripStopModel.buildInsertJsonList

**Files:**
- Create: `lib/features/trip/data/models/trip_stop_model.dart`
- Create: `test/features/trip/data/models/trip_stop_model_test.dart`

Schema confirmado em `supabase/migrations/20260617120000_media_stops_proposals_notifications.sql`: `trip_stops(id, trip_id, address_id, stop_order, created_at)`, com `UNIQUE (trip_id, stop_order)`. `buildInsertJsonList` recebe os IDs de `addresses` já persistidos (o endereço de cada parada é inserido antes, via `_insertAddress`, igual ao pickup/dropoff) e devolve as linhas prontas para um insert em lote, com `stop_order` 1-indexed pela ordem da lista.

- [ ] **Step 1: Escrever o teste falho**

Criar `test/features/trip/data/models/trip_stop_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_stop_model.dart';

void main() {
  group('TripStopModel.buildInsertJsonList', () {
    test('builds one row per address id with 1-indexed stop_order', () {
      final rows = TripStopModel.buildInsertJsonList(
        tripId: 'trip-uuid',
        addressIds: ['addr-1', 'addr-2', 'addr-3'],
      );

      expect(rows, [
        {'trip_id': 'trip-uuid', 'address_id': 'addr-1', 'stop_order': 1},
        {'trip_id': 'trip-uuid', 'address_id': 'addr-2', 'stop_order': 2},
        {'trip_id': 'trip-uuid', 'address_id': 'addr-3', 'stop_order': 3},
      ]);
    });

    test('returns an empty list when there are no stops', () {
      final rows = TripStopModel.buildInsertJsonList(
        tripId: 'trip-uuid',
        addressIds: const [],
      );

      expect(rows, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/trip/data/models/trip_stop_model_test.dart
```

Expected: falha de compilação — `Target of URI doesn't exist: 'package:kz_servicos_app/features/trip/data/models/trip_stop_model.dart'`.

- [ ] **Step 3: Implementar TripStopModel**

Criar `lib/features/trip/data/models/trip_stop_model.dart`:

```dart
class TripStopModel {
  static List<Map<String, dynamic>> buildInsertJsonList({
    required String tripId,
    required List<String> addressIds,
  }) {
    return [
      for (var i = 0; i < addressIds.length; i++)
        {
          'trip_id': tripId,
          'address_id': addressIds[i],
          'stop_order': i + 1,
        },
    ];
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/data/models/trip_stop_model_test.dart
```

Expected: `00:0X +2: All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/trip/data/models/trip_stop_model.dart test/features/trip/data/models/trip_stop_model_test.dart
git commit -m "feat(trip): adiciona TripStopModel.buildInsertJsonList para persistir paradas"
```

## Task 4: TripRequest.stops

**Files:**
- Modify: `lib/features/trip/domain/entities/trip_request.dart`
- Create: `test/features/trip/domain/entities/trip_request_test.dart`

`TripRequest` precisa carregar a lista de paradas (`TripAddress`, mesma origem que pickup/dropoff) para que `TripRepositoryImpl.createTrip` possa persisti-las em `trip_stops` (Task 5). O campo é uma lista única — a decisão de escopo do cabeçalho do plano já define que só a perna de ida usa isso.

- [ ] **Step 1: Escrever o teste falho**

Criar `test/features/trip/domain/entities/trip_request_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';

void main() {
  group('TripRequest.stops', () {
    const pickup = TripAddress(
      formattedAddress: 'Rua A, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.55,
      longitude: -46.63,
    );
    const dropoff = TripAddress(
      formattedAddress: 'Rua B, São Paulo - SP',
      city: 'São Paulo',
      state: 'SP',
      latitude: -23.56,
      longitude: -46.64,
    );

    test('defaults to an empty list when not provided', () {
      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
      );

      expect(request.stops, isEmpty);
    });

    test('stores the given stops in order', () {
      const stop1 = TripAddress(
        formattedAddress: 'Rua C, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.57,
        longitude: -46.65,
      );
      const stop2 = TripAddress(
        formattedAddress: 'Rua D, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.58,
        longitude: -46.66,
      );

      final request = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
        stops: const [stop1, stop2],
      );

      expect(request.stops, [stop1, stop2]);
    });

    test('two requests with different stops are not equal', () {
      const stop = TripAddress(
        formattedAddress: 'Rua C, São Paulo - SP',
        city: 'São Paulo',
        state: 'SP',
        latitude: -23.57,
        longitude: -46.65,
      );

      final withStop = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
        stops: const [stop],
      );
      final withoutStop = TripRequest(
        clientId: 'user-uuid',
        pickupAddress: pickup,
        dropoffAddress: dropoff,
        scheduledDatetime: DateTime(2026, 8, 16, 10, 0),
        passengerCount: 1,
      );

      expect(withStop, isNot(equals(withoutStop)));
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/trip/domain/entities/trip_request_test.dart
```

Expected: falha de compilação — `No named parameter with the name 'stops'` / `The getter 'stops' isn't defined for the type 'TripRequest'`.

- [ ] **Step 3: Adicionar o campo stops**

Em `lib/features/trip/domain/entities/trip_request.dart`, atualizar o construtor, os campos e `props`:

```dart
  const TripRequest({
    required this.clientId,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.scheduledDatetime,
    required this.passengerCount,
    this.childrenCount = 0,
    this.childrenDescription,
    this.luggageCount = 0,
    this.luggageDescription,
    this.observations,
    this.paymentMethod = 'pix',
    this.isRoundTrip = false,
    this.returnDatetime,
    this.returnPickupAddress,
    this.returnDropoffAddress,
    this.tripType = 'standard',
    this.stops = const [],
  });

  final String clientId;
  final TripAddress pickupAddress;
  final TripAddress dropoffAddress;
  final DateTime scheduledDatetime;
  final int passengerCount;
  final int childrenCount;
  final String? childrenDescription;
  final int luggageCount;
  final String? luggageDescription;
  final String? observations;
  final String paymentMethod;
  final bool isRoundTrip;
  final DateTime? returnDatetime;
  final TripAddress? returnPickupAddress;
  final TripAddress? returnDropoffAddress;
  final String tripType;
  final List<TripAddress> stops;
```

E em `props`:

```dart
  @override
  List<Object?> get props => [
    clientId,
    pickupAddress,
    dropoffAddress,
    scheduledDatetime,
    passengerCount,
    isRoundTrip,
    returnDatetime,
    returnPickupAddress,
    returnDropoffAddress,
    tripType,
    stops,
  ];
```

- [ ] **Step 4: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/domain/entities/trip_request_test.dart
```

Expected: `00:0X +3: All tests passed!`

- [ ] **Step 5: Rodar a suíte completa de trip para checar regressões**

Run:

```powershell
flutter test test/features/trip
```

Expected: todos os testes existentes (incluindo `trip_models_test.dart`, `passenger_details_panel_test.dart`, `round_trip_address_sheet_test.dart`) continuam passando — `stops` é opcional com default `const []`, então nenhum call site existente quebra.

- [ ] **Step 6: Commit**

```powershell
git add lib/features/trip/domain/entities/trip_request.dart test/features/trip/domain/entities/trip_request_test.dart
git commit -m "feat(trip): adiciona campo stops a TripRequest"
```

## Task 5: TripRepositoryImpl.createTrip insere paradas

**Files:**
- Modify: `lib/features/trip/data/repositories/trip_repository_impl.dart`

Sem TDD nesta task: `createTrip` fala diretamente com `SupabaseClient` (sem fake/mock configurado no projeto — confirmado pela ausência de teste dedicado para `TripRepositoryImpl` em `test/features/trip`), o mesmo padrão já usado para pickup/dropoff/return addresses no método. A verificação é manual, feita na Task 11 (QA end-to-end). O `TripStopModel` que resolve a lógica pura testável já foi coberto na Task 3.

- [ ] **Step 1: Inserir os endereços das paradas e gravar trip_stops**

Em `lib/features/trip/data/repositories/trip_repository_impl.dart`, modificar `createTrip` para inserir os endereços de `request.stops` (mesmo padrão de `_insertAddress` já usado para pickup/dropoff) e, depois de criar a trip, inserir as linhas em `trip_stops` via `TripStopModel.buildInsertJsonList`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_app/features/trip/data/models/address_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/driver_candidate_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/scheduled_trip_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_model.dart';
import 'package:kz_servicos_app/features/trip/data/models/trip_stop_model.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/scheduled_trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_address.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_request.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/trip_with_candidates.dart';
import 'package:kz_servicos_app/features/trip/domain/repositories/trip_repository.dart';

class TripRepositoryImpl implements TripRepository {
  TripRepositoryImpl({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Future<Trip> createTrip(TripRequest request) async {
    // 1. Fetch trip service category
    final serviceCategoryId = await _fetchTripCategoryId();

    // 2. Create pickup address
    final pickupId = await _insertAddress(
      AddressModel.fromEntity(request.pickupAddress),
    );

    // 3. Create dropoff address
    final dropoffId = await _insertAddress(
      AddressModel.fromEntity(request.dropoffAddress),
    );

    final returnPickupId = request.returnPickupAddress == null
        ? null
        : await _insertAddress(
            AddressModel.fromEntity(request.returnPickupAddress!),
          );
    final returnDropoffId = request.returnDropoffAddress == null
        ? null
        : await _insertAddress(
            AddressModel.fromEntity(request.returnDropoffAddress!),
          );

    // 4. Create trip
    final tripJson = TripModel.buildInsertJson(
      clientId: request.clientId,
      serviceCategoryId: serviceCategoryId,
      pickupAddressId: pickupId,
      dropoffAddressId: dropoffId,
      scheduledDatetime: request.scheduledDatetime,
      passengerCount: request.passengerCount,
      childrenCount: request.childrenCount,
      luggageCount: request.luggageCount,
      observations: request.combinedObservations,
      paymentMethod: request.paymentMethod,
      isRoundTrip: request.isRoundTrip,
      returnDatetime: request.returnDatetime,
      returnPickupAddressId: returnPickupId,
      returnDropoffAddressId: returnDropoffId,
      tripType: request.tripType,
    );

    final tripResponse = await _client.from('trips').insert(tripJson).select();

    if (tripResponse.isEmpty) {
      throw Exception('Failed to create trip: empty response');
    }

    final trip = TripModel.fromJson(tripResponse.first).toEntity();

    // 5. Create stops (outbound leg only — see plan scope decisions).
    if (request.stops.isNotEmpty) {
      final stopAddressIds = <String>[];
      for (final stop in request.stops) {
        stopAddressIds.add(
          await _insertAddress(AddressModel.fromEntity(stop)),
        );
      }
      final stopRows = TripStopModel.buildInsertJsonList(
        tripId: trip.id,
        addressIds: stopAddressIds,
      );
      await _client.from('trip_stops').insert(stopRows);
    }

    return trip;
  }
```

- [ ] **Step 2: Confirmar compilação**

Run:

```powershell
flutter analyze lib/features/trip/data/repositories/trip_repository_impl.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Rodar a suíte completa de trip para checar regressões**

Run:

```powershell
flutter test test/features/trip
```

Expected: todos os testes continuam passando (nenhum teste existente cobre `TripRepositoryImpl` diretamente — a suíte confirma apenas que nada mais quebrou).

- [ ] **Step 4: Commit**

```powershell
git add lib/features/trip/data/repositories/trip_repository_impl.dart
git commit -m "feat(trip): TripRepositoryImpl.createTrip persiste paradas em trip_stops"
```

## Task 6: StepScaffold

**Files:**
- Create: `lib/features/trip/presentation/widgets/step_scaffold.dart`
- Create: `test/features/trip/presentation/widgets/step_scaffold_test.dart`

Casca reutilizável para os novos passos em tela cheia do tema escuro (usada primeiro pelo `PaymentMethodPanel` na Task 7): fundo `sheetBackground`, barra superior preta com seta de voltar + título centralizado, um card `sheetSurface` com o conteúdo do passo, e um botão de confirmação em largura total usando `AppColors.highlight`.

- [ ] **Step 1: Escrever o teste falho**

Criar `test/features/trip/presentation/widgets/step_scaffold_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

void main() {
  group('StepScaffold', () {
    testWidgets('renders title and child content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: () {},
            child: const Text('Conteúdo do passo'),
          ),
        ),
      );

      expect(find.text('Forma de pagamento'), findsOneWidget);
      expect(find.text('Conteúdo do passo'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
    });

    testWidgets('tapping the back arrow calls onBack', (tester) async {
      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () => backTapped = true,
            confirmLabel: 'Continuar',
            onConfirm: () {},
            child: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('tapping the confirm button calls onConfirm', (tester) async {
      var confirmTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: () => confirmTapped = true,
            child: const SizedBox(),
          ),
        ),
      );

      await tester.tap(find.text('Continuar'));
      await tester.pump();

      expect(confirmTapped, isTrue);
    });

    testWidgets('confirm button is disabled when onConfirm is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StepScaffold(
            title: 'Forma de pagamento',
            onBack: () {},
            confirmLabel: 'Continuar',
            onConfirm: null,
            child: const SizedBox(),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/step_scaffold_test.dart
```

Expected: falha de compilação — `Target of URI doesn't exist: 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart'`.

- [ ] **Step 3: Implementar StepScaffold**

Criar `lib/features/trip/presentation/widgets/step_scaffold.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class StepScaffold extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;
  final String confirmLabel;
  final VoidCallback? onConfirm;

  const StepScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.sheetBackground,
      child: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.sheetSurface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: child,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: _buildConfirmButton(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: AppColors.sheetTextPrimary,
            ),
            onPressed: onBack,
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.sheetTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          disabledBackgroundColor: Colors.grey.shade700,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Text(
          confirmLabel,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/step_scaffold_test.dart
```

Expected: `00:0X +4: All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/trip/presentation/widgets/step_scaffold.dart test/features/trip/presentation/widgets/step_scaffold_test.dart
git commit -m "feat(trip): adiciona StepScaffold para os passos em tela cheia do tema escuro"
```

## Task 7: PaymentMethodPanel

**Files:**
- Create: `lib/features/trip/presentation/widgets/payment_method_panel.dart`
- Create: `test/features/trip/presentation/widgets/payment_method_panel_test.dart`

Passo novo `TripFlowStep.paymentMethod` (wiring completo na Task 10). Três opções apenas — PIX, Dinheiro, Máquina de cartão — por decisão de escopo do cabeçalho do plano ("Máquina de cartão" grava `credit`; `debit`/`billing` não têm UI aqui). Usa `StepScaffold` (Task 6) como casca.

- [ ] **Step 1: Escrever o teste falho**

Criar `test/features/trip/presentation/widgets/payment_method_panel_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/payment_method_panel.dart';

void main() {
  group('PaymentMethodPanel', () {
    testWidgets('renders the three payment options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentMethodPanel(onConfirm: (_) {}, onBack: () {}),
        ),
      );

      expect(find.text('PIX'), findsOneWidget);
      expect(find.text('Dinheiro'), findsOneWidget);
      expect(find.text('Máquina de cartão'), findsOneWidget);
    });

    testWidgets('confirms with pix by default', (tester) async {
      String? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentMethodPanel(
            onConfirm: (method) => confirmed = method,
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.text('Confirmar'));
      await tester.pump();

      expect(confirmed, 'pix');
    });

    testWidgets('confirms with cash after selecting Dinheiro', (
      tester,
    ) async {
      String? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentMethodPanel(
            onConfirm: (method) => confirmed = method,
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.text('Dinheiro'));
      await tester.pump();
      await tester.tap(find.text('Confirmar'));
      await tester.pump();

      expect(confirmed, 'cash');
    });

    testWidgets('confirms with credit after selecting Máquina de cartão', (
      tester,
    ) async {
      String? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentMethodPanel(
            onConfirm: (method) => confirmed = method,
            onBack: () {},
          ),
        ),
      );

      await tester.tap(find.text('Máquina de cartão'));
      await tester.pump();
      await tester.tap(find.text('Confirmar'));
      await tester.pump();

      expect(confirmed, 'credit');
    });

    testWidgets('tapping back arrow calls onBack', (tester) async {
      var backTapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PaymentMethodPanel(
            onConfirm: (_) {},
            onBack: () => backTapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      expect(backTapped, isTrue);
    });
  });
}
```

- [ ] **Step 2: Rodar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/payment_method_panel_test.dart
```

Expected: falha de compilação — `Target of URI doesn't exist: 'package:kz_servicos_app/features/trip/presentation/widgets/payment_method_panel.dart'`.

- [ ] **Step 3: Implementar PaymentMethodPanel**

Criar `lib/features/trip/presentation/widgets/payment_method_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/step_scaffold.dart';

class PaymentMethodPanel extends StatefulWidget {
  final ValueChanged<String> onConfirm;
  final VoidCallback onBack;
  final String initialMethod;

  const PaymentMethodPanel({
    super.key,
    required this.onConfirm,
    required this.onBack,
    this.initialMethod = 'pix',
  });

  @override
  State<PaymentMethodPanel> createState() => _PaymentMethodPanelState();
}

class _PaymentMethodPanelState extends State<PaymentMethodPanel> {
  static const _options = [
    ('pix', 'PIX', Icons.pix_rounded),
    ('cash', 'Dinheiro', Icons.payments_rounded),
    ('credit', 'Máquina de cartão', Icons.credit_card_rounded),
  ];

  late String _selected = widget.initialMethod;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      title: 'Forma de pagamento',
      onBack: widget.onBack,
      confirmLabel: 'Confirmar',
      onConfirm: () => widget.onConfirm(_selected),
      child: Column(
        children: [for (final option in _options) _buildOption(option)],
      ),
    );
  }

  Widget _buildOption((String, String, IconData) option) {
    final (value, label, icon) = option;
    final selected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.highlight.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.highlight
                : AppColors.sheetTextSecondary,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.sheetTextPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.sheetTextPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? AppColors.highlight
                  : AppColors.sheetTextSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/payment_method_panel_test.dart
```

Expected: `00:0X +5: All tests passed!`

- [ ] **Step 5: Commit**

```powershell
git add lib/features/trip/presentation/widgets/payment_method_panel.dart test/features/trip/presentation/widgets/payment_method_panel_test.dart
git commit -m "feat(trip): adiciona PaymentMethodPanel como novo passo do fluxo Corrida Agora"
```

## Task 8: PassengerDetailsPanel — restilo escuro e remoção do pagamento

**Files:**
- Modify: `lib/features/trip/presentation/widgets/passenger_details_panel.dart`
- Modify: `test/features/trip/presentation/widgets/passenger_details_panel_test.dart`

Esta task remove um comportamento existente (a seção "Forma de pagamento" dentro do próprio painel, que migrou para o novo passo `PaymentMethodPanel` na Task 7) e restilo o painel para o tema escuro. Como é uma remoção controlada e não uma funcionalidade nova, o ciclo aqui é: primeiro tirar do teste a asserção que depende do comportamento removido (para não travar o pipeline no meio da mudança), confirmar que ele continua verde antes de tocar na implementação, só então aplicar a remoção + restilo, e confirmar verde de novo no final.

- [ ] **Step 1: Remover a asserção obsoleta do teste**

Em `test/features/trip/presentation/widgets/passenger_details_panel_test.dart`, remover a linha `expect(find.text('Dinheiro'), findsOneWidget);` do teste `'renders initial passenger details when provided'` (o restante do teste, incluindo `paymentMethod: 'cash'` no `initialData`, permanece — o campo continua existindo em `PassengerFormData`, só não é mais renderizado por este widget):

```dart
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2 criancas pequenas'), findsOneWidget);
    expect(find.text('3 malas'), findsOneWidget);
    expect(find.text('Portao azul'), findsOneWidget);
  });
```

- [ ] **Step 2: Rodar a suíte e confirmar que continua GREEN**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/passenger_details_panel_test.dart
```

Expected: `00:0X +4: All tests passed!` (o widget ainda não mudou — isso só confirma que o teste não depende mais da asserção removida).

- [ ] **Step 3: Substituir o conteúdo completo do arquivo**

Substituir todo o conteúdo de `lib/features/trip/presentation/widgets/passenger_details_panel.dart` por:

```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/passenger_form_data.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/quantity_selector.dart';

class PassengerDetailsPanel extends StatefulWidget {
  final ValueChanged<PassengerFormData> onConfirm;
  final VoidCallback onBack;
  final bool isMinimized;
  final VoidCallback onRestore;
  final PassengerFormData? initialData;
  final bool isRoundTrip;
  final String? legLabel;
  /// Quando false, remove o chip "Agora" (horário imediato) — reservado
  /// para corridas Flash. Fluxos agendados (Cotação, Escolha seu Motorista)
  /// devem forçar o cliente a escolher um horário futuro explícito.
  final bool allowImmediate;

  const PassengerDetailsPanel({
    super.key,
    required this.onConfirm,
    required this.onBack,
    this.isMinimized = false,
    required this.onRestore,
    this.initialData,
    this.isRoundTrip = false,
    this.legLabel,
    this.allowImmediate = true,
  });

  @override
  State<PassengerDetailsPanel> createState() => PassengerDetailsPanelState();
}

class PassengerDetailsPanelState extends State<PassengerDetailsPanel> {
  int _adults = 1;
  bool _hasChildren = false;
  final TextEditingController _childrenDescriptionController =
      TextEditingController();
  bool _hasLuggage = false;
  final TextEditingController _luggageController = TextEditingController();
  final TextEditingController _observationController = TextEditingController();

  TimeOfDay? _pickupTime;
  DateTime? _pickupDate;
  bool _isNow = true;
  bool _isToday = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.allowImmediate && _isNow) {
      _isNow = false;
    }
  }

  int get adults => _adults;
  bool get hasChildren => _hasChildren;
  String get childrenDescription => _childrenDescriptionController.text;
  bool get hasLuggage => _hasLuggage;
  String get luggageDescription => _luggageController.text;
  String get observation => _observationController.text;
  TimeOfDay? get pickupTime => _isNow ? TimeOfDay.now() : _pickupTime;
  DateTime? get pickupDate => _isToday ? DateTime.now() : _pickupDate;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data == null) return;

    _adults = data.adults;
    _hasChildren = data.hasChildren;
    _childrenDescriptionController.text = data.childrenDescription ?? '';
    _hasLuggage = data.hasLuggage;
    _luggageController.text = data.luggageDescription ?? '';
    _observationController.text = data.observations ?? '';

    final scheduled = data.scheduledDatetime;
    final now = DateTime.now();
    _isToday =
        scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
    _pickupDate = scheduled;
    _isNow = false;
    _pickupTime = TimeOfDay(hour: scheduled.hour, minute: scheduled.minute);
  }

  @override
  void dispose() {
    _luggageController.dispose();
    _childrenDescriptionController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_hasLuggage && _luggageController.text.trim().isEmpty) return false;
    if (!_isNow && _pickupTime == null) return false;
    if (!_isToday && _pickupDate == null) return false;
    if (_hasChildren && _childrenDescriptionController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  String get _summaryDate {
    if (_isToday) return 'Hoje';
    if (_pickupDate != null) {
      return '${_pickupDate!.day.toString().padLeft(2, '0')}/${_pickupDate!.month.toString().padLeft(2, '0')}';
    }
    return 'Hoje';
  }

  String get _summaryTime {
    if (_isNow) return 'Agora';
    if (_pickupTime != null) {
      return '${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}';
    }
    return 'Agora';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.isMinimized ? widget.onRestore : () {},
      onVerticalDragUpdate: widget.isMinimized
          ? (details) {
              if (details.delta.dy < -3) widget.onRestore();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        height: widget.isMinimized ? 130 : screenHeight * 0.55,
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.sheetSurface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.32),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: widget.isMinimized
            ? _buildMinimizedSummary()
            : _buildExpandedContent(),
      ),
    );
  }

  Widget _buildMinimizedSummary() {
    return Column(
      children: [
        _buildGrabber(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: AppColors.sheetTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _summaryDate,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.sheetTextPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.access_time_rounded,
                size: 18,
                color: AppColors.sheetTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                _summaryTime,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.sheetTextPrimary,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.sheetTextSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                '$_adults',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.sheetTextPrimary,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.keyboard_arrow_up_rounded,
                size: 24,
                color: AppColors.sheetTextSecondary,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: _buildConfirmButton(),
        ),
      ],
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        _buildGrabber(),
        _buildTitleRow(),
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                _buildSectionTitle('Data e Horário'),
                const SizedBox(height: 12),
                _buildDateSelector(),
                const SizedBox(height: 12),
                _buildTimeSelector(),
                const SizedBox(height: 20),
                _buildSectionTitle('Passageiros'),
                const SizedBox(height: 12),
                _buildAdultsSelector(),
                const SizedBox(height: 16),
                _buildChildrenToggle(),
                if (_hasChildren) ...[
                  const SizedBox(height: 12),
                  _buildDescriptionField(
                    controller: _childrenDescriptionController,
                    hint: 'Ex: 2 crianças, idades 3 e 7 anos',
                  ),
                ],
                const SizedBox(height: 16),
                _buildLuggageToggle(),
                if (_hasLuggage) ...[
                  const SizedBox(height: 12),
                  _buildDescriptionField(
                    controller: _luggageController,
                    hint: 'Ex: 2 malas grandes e 1 mochila',
                    maxLines: 2,
                  ),
                ],
                const SizedBox(height: 20),
                _buildSectionTitle('Observação'),
                const SizedBox(height: 12),
                _buildDescriptionField(
                  controller: _observationController,
                  hint: 'Ex: Preciso de ajuda com as malas, portão azul...',
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildConfirmButton(),
        ),
      ],
    );
  }

  Widget _buildGrabber() {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.sheetTextSecondary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    final legLabel = widget.legLabel;
    final title = legLabel == null || legLabel.isEmpty
        ? 'Detalhes da viagem'
        : 'Detalhes da $legLabel';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.sheetTextPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.sheetTextPrimary,
      ),
    );
  }

  Widget _buildAdultsSelector() {
    return Row(
      children: [
        const Text(
          'Adultos',
          style: TextStyle(fontSize: 14, color: AppColors.sheetTextPrimary),
        ),
        const Spacer(),
        QuantitySelector(
          value: _adults,
          min: 1,
          max: 10,
          onChanged: (v) => setState(() => _adults = v),
        ),
      ],
    );
  }

  Widget _buildChildrenToggle() {
    return _buildToggleRow(
      label: 'Possui crianças?',
      value: _hasChildren,
      onChanged: (v) {
        setState(() {
          _hasChildren = v;
          if (!v) _childrenDescriptionController.clear();
        });
      },
    );
  }

  Widget _buildLuggageToggle() {
    return _buildToggleRow(
      label: 'Possui malas?',
      value: _hasLuggage,
      onChanged: (v) {
        setState(() {
          _hasLuggage = v;
          if (!v) _luggageController.clear();
        });
      },
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.sheetTextPrimary,
          ),
        ),
        const Spacer(),
        Switch(
          value: value,
          activeThumbColor: AppColors.highlight,
          activeTrackColor: AppColors.highlight.withValues(alpha: 0.4),
          inactiveThumbColor: AppColors.sheetTextSecondary,
          inactiveTrackColor: AppColors.sheetBackground,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDescriptionField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14, color: AppColors.sheetTextPrimary),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.sheetTextSecondary,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sheetTextSecondary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sheetTextSecondary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.highlight),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildTimeSelector() {
    return Row(
      children: [
        const Text(
          'Horário de embarque',
          style: TextStyle(fontSize: 14, color: AppColors.sheetTextPrimary),
        ),
        const Spacer(),
        if (widget.allowImmediate) ...[
          _buildChip(
            label: 'Agora',
            selected: _isNow,
            onTap: () => setState(() => _isNow = true),
          ),
          const SizedBox(width: 8),
        ],
        _buildChip(
          label: _pickupTime != null && !_isNow
              ? '${_pickupTime!.hour.toString().padLeft(2, '0')}:${_pickupTime!.minute.toString().padLeft(2, '0')}'
              : 'Escolher',
          selected: !_isNow,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (time != null) {
              setState(() {
                _pickupTime = time;
                _isNow = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      children: [
        const Text(
          'Data de embarque',
          style: TextStyle(fontSize: 14, color: AppColors.sheetTextPrimary),
        ),
        const Spacer(),
        _buildChip(
          label: 'Hoje',
          selected: _isToday,
          onTap: () => setState(() => _isToday = true),
        ),
        const SizedBox(width: 8),
        _buildChip(
          label: _pickupDate != null && !_isToday
              ? '${_pickupDate!.day.toString().padLeft(2, '0')}/${_pickupDate!.month.toString().padLeft(2, '0')}'
              : 'Escolher',
          selected: !_isToday,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (date != null) {
              setState(() {
                _pickupDate = date;
                _isToday = false;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.highlight : AppColors.sheetBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? Colors.black : AppColors.sheetTextSecondary,
          ),
        ),
      ),
    );
  }

  void _handleConfirm() {
    final date = _isToday ? DateTime.now() : _pickupDate!;
    final time = _isNow ? TimeOfDay.now() : _pickupTime!;
    final scheduledDatetime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    widget.onConfirm(
      PassengerFormData(
        adults: _adults,
        scheduledDatetime: scheduledDatetime,
        hasChildren: _hasChildren,
        childrenDescription: _hasChildren
            ? _childrenDescriptionController.text.trim()
            : null,
        hasLuggage: _hasLuggage,
        luggageDescription: _hasLuggage ? _luggageController.text.trim() : null,
        observations: _observationController.text.trim().isEmpty
            ? null
            : _observationController.text.trim(),
        isRoundTrip: widget.isRoundTrip,
        returnDatetime: null,
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isValid ? _handleConfirm : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.highlight,
          disabledBackgroundColor: AppColors.sheetBackground,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Continuar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
```

Notas sobre a mudança em relação ao arquivo anterior:
- Removidos: campo `String _paymentMethod = 'pix';`, a linha `_paymentMethod = data.paymentMethod;` em `initState`, o bloco `_buildSectionTitle('Forma de pagamento')` + `_buildPaymentMethod()` dentro de `_buildExpandedContent()`, o método `_buildPaymentMethod()` inteiro, e o parâmetro `paymentMethod: _paymentMethod` dentro de `_handleConfirm()` — o `PassengerFormData` resultante agora usa o default `'pix'` do próprio construtor (o valor real será sobrescrito pelo `PaymentMethodPanel` no passo seguinte, via `PassengerFormData.copyWith` — wiring completo na Task 10).
- Todas as cores fixas (`Colors.white`, `Colors.black87`, `Colors.black54`, `Colors.grey.shade*`) foram trocadas pelos tokens escuros da Task 1 (`AppColors.sheetSurface`, `sheetBackground`, `sheetTextPrimary`, `sheetTextSecondary`), e o texto sobre fundo `AppColors.highlight` passou a usar `Colors.black` (chips selecionados e botão de confirmação), consistente com o restante do tema escuro do Figma.

- [ ] **Step 4: Confirmar compilação**

Run:

```powershell
flutter analyze lib/features/trip/presentation/widgets/passenger_details_panel.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Rodar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/trip/presentation/widgets/passenger_details_panel_test.dart
```

Expected: `00:0X +4: All tests passed!`

- [ ] **Step 6: Commit**

```powershell
git add lib/features/trip/presentation/widgets/passenger_details_panel.dart test/features/trip/presentation/widgets/passenger_details_panel_test.dart
git commit -m "refactor(trip): restilo escuro de PassengerDetailsPanel e remoção da seção de pagamento"
```

