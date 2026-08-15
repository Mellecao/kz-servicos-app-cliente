# Endereços de ida e volta para agendamentos Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When a client picks "Ida e volta" for a scheduled ride (either the "escolher motorista" or the automatic-match "agendamento" flow), let them enter 4 distinct addresses (partida/destino de ida, partida/destino de volta, each defaulting to the opposite leg's address but editable), persist those return addresses end-to-end (RPC, `trips` table), and surface the round-trip flag, both address pairs, and both date/times everywhere a driver or client currently sees trip details — including the driver app's request card and schedule detail page, which today show no round-trip information at all.

**Architecture:** Backend gets 2 new nullable `addresses` FK columns on `trips` (`return_pickup_address_id`, `return_dropoff_address_id`) and the `client_send_scheduled_direct_request` RPC gains 4 new optional trailing params (it currently has zero round-trip awareness — not even the flag). On the client, a new `RoundTripAddressForm` widget (4 stacked address-search rows, Google-Places-backed, reusing the existing `TripAddressSearchBar`) replaces the map-pin picker only when `_isRoundTripRequest` is true; the outbound pair flows through the existing `_onPickupSelected`/`_onDestinationSelected`/`_onConfirmAddresses` pipeline unchanged, and the return pair is stored as two new lightweight state fields (place IDs) resolved to `TripAddress` at submit time, mirroring how the existing pickup/dropoff already work. `TripRequest`/`TripModel`/`TripRepositoryImpl` (scheduled_quote path) and `ScheduledDirectRequestRepository`/`DriverSelectionCubit` (scheduled_choose_driver path) are extended to carry the 2 new addresses plus the already-partially-wired `isRoundTrip`/`returnDatetime` through to persistence. `PriceOfferDetails`/`AwaitingDriverContent`/`PriceOfferContent` gain optional round-trip fields/UI so the client sees the full itinerary while waiting. On the driver app, `TripData`, `ScheduledDirectRequestCard`, `schedules_page.dart`'s query, and `schedule_detail_page.dart` are extended to parse and display the round-trip flag, both address pairs, and both date/times — including fixing a pre-existing bug where the fromHome route timeline renders a placeholder-only return row instead of the real return address.

**Tech Stack:** Next.js/Supabase Postgres backend (migrations + pgTAP), Flutter/Dart client and driver apps (Cubit/BLoC state management, mocktail for tests, `flutter_test`).

---

## Phase A — Backend (kz-servicos-web-app-fork)

### Task A1: Add return address columns to `trips`

**Files:**
- Create: `supabase/migrations/20260814150000_trips_return_addresses.sql`
- Test: `supabase/tests/round_trip/01_trips_return_addresses_test.sql`

- [ ] **Step 1: Write the failing pgTAP test**

```sql
-- supabase/tests/round_trip/01_trips_return_addresses_test.sql
BEGIN;
SELECT plan(3);

SELECT has_column('public', 'trips', 'return_pickup_address_id', 'trips has return_pickup_address_id column');
SELECT has_column('public', 'trips', 'return_dropoff_address_id', 'trips has return_dropoff_address_id column');
SELECT col_is_fk('public', 'trips', 'return_pickup_address_id', 'return_pickup_address_id references addresses');

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db --file supabase/tests/round_trip/01_trips_return_addresses_test.sql`
Expected: FAIL — columns `return_pickup_address_id`/`return_dropoff_address_id` do not exist on `trips`.

- [ ] **Step 3: Write the migration**

```sql
-- supabase/migrations/20260814150000_trips_return_addresses.sql
-- +goose Up
ALTER TABLE public.trips
  ADD COLUMN return_pickup_address_id UUID REFERENCES public.addresses(id) ON DELETE RESTRICT,
  ADD COLUMN return_dropoff_address_id UUID REFERENCES public.addresses(id) ON DELETE RESTRICT;

COMMENT ON COLUMN public.trips.return_pickup_address_id IS 'Endereço de embarque da volta (round trip). NULL quando is_round_trip=false.';
COMMENT ON COLUMN public.trips.return_dropoff_address_id IS 'Endereço de desembarque da volta (round trip). NULL quando is_round_trip=false.';
```

- [ ] **Step 4: Apply migration locally and run test to verify it passes**

Run: `supabase db reset` then `supabase test db --file supabase/tests/round_trip/01_trips_return_addresses_test.sql`
Expected: PASS (3/3 tests ok)

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260814150000_trips_return_addresses.sql supabase/tests/round_trip/01_trips_return_addresses_test.sql
git commit -m "feat(db): adiciona colunas de endereco de retorno em trips"
```

---

### Task A2: Extend `client_send_scheduled_direct_request` RPC with round-trip params

**Context:** The current RPC (see `supabase/migrations/20260730140000_fix_client_send_scheduled_direct_request_scheduled_datetime.sql`) has exactly 7 params and zero round-trip awareness — not even a flag. This task adds 4 new optional trailing params so `scheduled_choose_driver` requests can carry round-trip data all the way to the `trips` row.

**Files:**
- Read first: `supabase/migrations/20260730140000_fix_client_send_scheduled_direct_request_scheduled_datetime.sql` (current full function body — copy it verbatim before editing, do not guess at unrelated lines)
- Create: `supabase/migrations/20260814160000_client_send_scheduled_direct_request_round_trip.sql`
- Test: `supabase/tests/round_trip/02_client_send_scheduled_direct_request_round_trip_test.sql`

- [ ] **Step 1: Write the failing pgTAP test**

```sql
-- supabase/tests/round_trip/02_client_send_scheduled_direct_request_round_trip_test.sql
BEGIN;
SELECT plan(1);

SELECT has_function_privilege(
  'authenticated',
  'public.client_send_scheduled_direct_request(uuid, uuid, uuid, uuid, int, text, timestamptz, boolean, timestamptz, uuid, uuid)',
  'EXECUTE'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run test to verify it fails**

Run: `supabase test db --file supabase/tests/round_trip/02_client_send_scheduled_direct_request_round_trip_test.sql`
Expected: FAIL — function with this 11-arg signature does not exist yet.

- [ ] **Step 3: Read the current function body**

Open `supabase/migrations/20260730140000_fix_client_send_scheduled_direct_request_scheduled_datetime.sql` and copy the full `CREATE OR REPLACE FUNCTION ... $$ ... $$ LANGUAGE plpgsql;` body verbatim. Do not paraphrase it — the migration below must be that exact body, with only the signature and the `INSERT INTO trips` statement modified as shown.

- [ ] **Step 4: Write the migration**

```sql
-- supabase/migrations/20260814160000_client_send_scheduled_direct_request_round_trip.sql
-- +goose Up
DROP FUNCTION IF EXISTS public.client_send_scheduled_direct_request(uuid, uuid, uuid, uuid, int, text, timestamptz);

CREATE OR REPLACE FUNCTION public.client_send_scheduled_direct_request(
  driver_profile_id_input uuid,
  pickup_address_id_input uuid,
  dropoff_address_id_input uuid,
  service_category_id_input uuid,
  passenger_count_input int,
  observations_input text,
  scheduled_datetime_input timestamptz,
  is_round_trip_input boolean DEFAULT false,
  return_datetime_input timestamptz DEFAULT NULL,
  return_pickup_address_id_input uuid DEFAULT NULL,
  return_dropoff_address_id_input uuid DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid;
  v_trip_id uuid;
BEGIN
  PERFORM pg_advisory_xact_lock(hashtext('client_send_scheduled_direct_request'));

  v_client_id := auth.uid();

  INSERT INTO public.trips (
    client_id,
    pickup_address_id,
    dropoff_address_id,
    service_category_id,
    passenger_count,
    observations,
    scheduled_datetime,
    status,
    trip_type,
    is_round_trip,
    return_datetime,
    return_pickup_address_id,
    return_dropoff_address_id
  ) VALUES (
    v_client_id,
    pickup_address_id_input,
    dropoff_address_id_input,
    service_category_id_input,
    passenger_count_input,
    observations_input,
    scheduled_datetime_input,
    'awaiting_driver_confirmation',
    'scheduled_choose_driver',
    is_round_trip_input,
    return_datetime_input,
    return_pickup_address_id_input,
    return_dropoff_address_id_input
  )
  RETURNING id INTO v_trip_id;

  INSERT INTO public.trip_driver_candidates (trip_id, driver_profile_id, status)
  VALUES (v_trip_id, driver_profile_id_input, 'pending');

  RETURN v_trip_id;
END;
$$;

REVOKE ALL ON FUNCTION public.client_send_scheduled_direct_request(uuid, uuid, uuid, uuid, int, text, timestamptz, boolean, timestamptz, uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.client_send_scheduled_direct_request(uuid, uuid, uuid, uuid, int, text, timestamptz, boolean, timestamptz, uuid, uuid) TO authenticated;
```

**IMPORTANT:** Before finalizing this file, replace the `DECLARE`/`BEGIN`/insert-into-`trip_driver_candidates`/etc. body above with whatever the actual current body from the Step 3 read contains (this plan drafts the body from the known column set — if the real function has additional logic such as notification inserts, validation, or different column names, preserve that logic exactly and only add the 4 new params + 4 new `INSERT` columns/values as shown).

- [ ] **Step 5: Apply migration locally and run test to verify it passes**

Run: `supabase db reset` then `supabase test db --file supabase/tests/round_trip/02_client_send_scheduled_direct_request_round_trip_test.sql`
Expected: PASS (1/1 tests ok)

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/20260814160000_client_send_scheduled_direct_request_round_trip.sql supabase/tests/round_trip/02_client_send_scheduled_direct_request_round_trip_test.sql
git commit -m "feat(db): adiciona parametros de ida e volta em client_send_scheduled_direct_request"
```

---

### Task A3: Update `kz-database` skill docs

**Files:**
- Modify: `.github/skills/kz-database/references/schema.md` (trips table section, right after the `return_datetime` row)

- [ ] **Step 1: Add the new columns to the trips table doc**

Find the `return_datetime` row in the `trips` table documentation and add these two rows immediately after it:

```markdown
| `return_pickup_address_id` | UUID | FK → addresses.id, nullable | Endereço de embarque da volta (round trip) |
| `return_dropoff_address_id` | UUID | FK → addresses.id, nullable | Endereço de desembarque da volta (round trip) |
```

- [ ] **Step 2: Update `client_send_scheduled_direct_request` RPC doc**

If `.github/skills/kz-database/references/api-endpoints.md` or another reference file documents this RPC's parameter list, add the 4 new optional params (`is_round_trip_input`, `return_datetime_input`, `return_pickup_address_id_input`, `return_dropoff_address_id_input`) to that entry. If no such entry exists, skip this step.

- [ ] **Step 3: Commit inside the skill submodule**

The `kz-database` skill is a git submodule with its own repo. Commit and push there first, then commit the submodule pointer bump in the parent repo:

```bash
cd .github/skills/kz-database
git add references/schema.md references/api-endpoints.md
git commit -m "docs: documenta colunas de retorno em trips e parametros de round trip na RPC"
git push
cd ../../..
git add .github/skills/kz-database
git commit -m "chore: atualiza submodulo kz-database"
```

---

## Phase B — Client app (kz-servicos-app-cliente)

### Task B1: `TripAddressSearchBar` — add `hintText` and `initialText`

**Files:**
- Modify: `lib/features/trip/presentation/widgets/trip_address_search_bar.dart`
- Test: `test/features/trip/presentation/widgets/trip_address_search_bar_test.dart` (new file)

- [ ] **Step 1: Write the failing test**

```dart
// test/features/trip/presentation/widgets/trip_address_search_bar_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_address_search_bar.dart';

void main() {
  testWidgets('mostra hintText quando fornecido e sem initialText', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripAddressSearchBar(
            label: 'Partida (ida)',
            hintText: 'Buscar endereço de partida',
            onPlaceSelected: (_) {},
          ),
        ),
      ),
    );

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration?.hintText, 'Buscar endereço de partida');
  });

  testWidgets('pré-preenche o texto com initialText', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripAddressSearchBar(
            label: 'Destino (volta)',
            initialText: 'Rua das Flores, 120',
            onPlaceSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Rua das Flores, 120'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/presentation/widgets/trip_address_search_bar_test.dart`
Expected: FAIL — `TripAddressSearchBar` has no `hintText`/`initialText` named params (compile error).

- [ ] **Step 3: Read the current widget before editing**

Read `lib/features/trip/presentation/widgets/trip_address_search_bar.dart` in full first — it is 296 lines. Locate the constructor and the internal `TextEditingController` initialization. Add the two new optional params to the constructor, and seed the controller's initial text from `initialText` when provided. Add `hintText` to whatever `InputDecoration` the internal `TextField`/`TextFormField` already uses (do not create a second decoration, extend the existing one — if it currently hardcodes a hint string, make that string the fallback: `hintText: widget.hintText ?? 'Buscar endereço'` or equivalent, matching whatever the existing default hint text is).

- [ ] **Step 4: Implement**

Add to the widget's constructor parameter list:

```dart
final String? hintText;
final String? initialText;
```

with both defaulting to `null`, and thread `hintText` into the existing `InputDecoration(hintText: widget.hintText ?? <existing default>, ...)`. In `initState()` (or wherever the controller is created), initialize it as:

```dart
_controller = TextEditingController(text: widget.initialText ?? '');
```

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/trip/presentation/widgets/trip_address_search_bar_test.dart`
Expected: PASS (2/2)

- [ ] **Step 6: Commit**

```bash
git add lib/features/trip/presentation/widgets/trip_address_search_bar.dart test/features/trip/presentation/widgets/trip_address_search_bar_test.dart
git commit -m "feat(trip): adiciona hintText e initialText ao TripAddressSearchBar"
```

---

### Task B2: `RoundTripAddressSelection` entity

**Files:**
- Create: `lib/features/trip/domain/entities/round_trip_address_selection.dart`
- Test: `test/features/trip/domain/entities/round_trip_address_selection_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/trip/domain/entities/round_trip_address_selection_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/round_trip_address_selection.dart';

void main() {
  test('agrupa os 4 endereços da ida e volta', () {
    const pickupOut = PlacePrediction(
      placeId: 'p1',
      description: 'Rua A, 100',
    );
    const dropoffOut = PlacePrediction(
      placeId: 'p2',
      description: 'Rua B, 200',
    );
    const pickupReturn = PlacePrediction(
      placeId: 'p2',
      description: 'Rua B, 200',
    );
    const dropoffReturn = PlacePrediction(
      placeId: 'p1',
      description: 'Rua A, 100',
    );

    const selection = RoundTripAddressSelection(
      pickupOut: pickupOut,
      dropoffOut: dropoffOut,
      pickupReturn: pickupReturn,
      dropoffReturn: dropoffReturn,
    );

    expect(selection.pickupOut, pickupOut);
    expect(selection.dropoffOut, dropoffOut);
    expect(selection.pickupReturn, pickupReturn);
    expect(selection.dropoffReturn, dropoffReturn);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/domain/entities/round_trip_address_selection_test.dart`
Expected: FAIL — file `round_trip_address_selection.dart` does not exist.

**Before implementing:** read `lib/features/trip/domain/entities/place_prediction.dart` to confirm its exact constructor shape (field names `placeId`/`description` are assumed above from existing usage in `trip_home_page.dart`'s `_onPickupSelected(PlacePrediction ...)` calls — confirm before writing the test literals, adjust field names if they differ).

- [ ] **Step 3: Implement**

```dart
// lib/features/trip/domain/entities/round_trip_address_selection.dart
import 'package:equatable/equatable.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/place_prediction.dart';

class RoundTripAddressSelection extends Equatable {
  const RoundTripAddressSelection({
    required this.pickupOut,
    required this.dropoffOut,
    required this.pickupReturn,
    required this.dropoffReturn,
  });

  final PlacePrediction pickupOut;
  final PlacePrediction dropoffOut;
  final PlacePrediction pickupReturn;
  final PlacePrediction dropoffReturn;

  @override
  List<Object?> get props => [pickupOut, dropoffOut, pickupReturn, dropoffReturn];
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trip/domain/entities/round_trip_address_selection_test.dart`
Expected: PASS (1/1)

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/domain/entities/round_trip_address_selection.dart test/features/trip/domain/entities/round_trip_address_selection_test.dart
git commit -m "feat(trip): adiciona entidade RoundTripAddressSelection"
```

---

### Task B3: `RoundTripAddressForm` widget

**Context:** Replaces the map-pin picker only for round-trip bookings. 4 stacked `TripAddressSearchBar` rows: Partida (ida), Destino (ida), Partida (volta), Destino (volta). The return pair defaults to the reverse of the outbound pair (destino-ida → partida-volta, partida-ida → destino-volta) but is independently editable. Confirm button only enables once all 4 fields have a selection.

**Files:**
- Create: `lib/features/trip/presentation/widgets/round_trip_address_form.dart`
- Test: `test/features/trip/presentation/widgets/round_trip_address_form_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/features/trip/presentation/widgets/round_trip_address_form_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/round_trip_address_selection.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/round_trip_address_form.dart';

const pickupOut = PlacePrediction(placeId: 'p1', description: 'Rua A, 100');
const dropoffOut = PlacePrediction(placeId: 'p2', description: 'Rua B, 200');

void main() {
  testWidgets('botão de confirmar fica desabilitado até 4 endereços selecionados', (
    tester,
  ) async {
    RoundTripAddressSelection? confirmed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundTripAddressForm(
            onConfirmed: (s) => confirmed = s,
            onDismissed: () {},
          ),
        ),
      ),
    );

    final confirmButton = find.byKey(const Key('round-trip-confirm-button'));
    expect(tester.widget<ElevatedButton>(confirmButton).onPressed, isNull);
    expect(confirmed, isNull);
  });

  testWidgets('preenche destino-ida e partida-volta é pré-preenchida automaticamente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RoundTripAddressForm(onConfirmed: (_) {}, onDismissed: () {}),
        ),
      ),
    );

    final dropoffOutField = find.byKey(const Key('round-trip-dropoff-out'));
    final dropoffOutState = tester.state(dropoffOutField) as dynamic;
    dropoffOutState.widget.onPlaceSelected(dropoffOut);
    await tester.pump();

    expect(find.text('Rua B, 200'), findsWidgets);
  });
}
```

**Note:** the direct `state.widget.onPlaceSelected(...)` call above is a placeholder testing strategy. Before finalizing this test, read `lib/features/trip/presentation/widgets/trip_address_search_bar.dart` fully (already read in Task B1) and use whatever interaction pattern its own existing tests (from Task B1) use to trigger `onPlaceSelected` from a widget test. If `TripAddressSearchBar` only exposes selection via a real Places API call not mockable in a widget test, driving it through `tester.widget<TripAddressSearchBar>(find.byKey(key)).onPlaceSelected!(prediction)` directly is acceptable — but confirm this is genuinely necessary rather than assumed.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/presentation/widgets/round_trip_address_form_test.dart`
Expected: FAIL — file `round_trip_address_form.dart` does not exist.

- [ ] **Step 3: Implement**

```dart
// lib/features/trip/presentation/widgets/round_trip_address_form.dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/place_prediction.dart';
import 'package:kz_servicos_app/features/trip/domain/entities/round_trip_address_selection.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/trip_address_search_bar.dart';

class RoundTripAddressForm extends StatefulWidget {
  const RoundTripAddressForm({
    super.key,
    required this.onConfirmed,
    required this.onDismissed,
  });

  final ValueChanged<RoundTripAddressSelection> onConfirmed;
  final VoidCallback onDismissed;

  @override
  State<RoundTripAddressForm> createState() => _RoundTripAddressFormState();
}

class _RoundTripAddressFormState extends State<RoundTripAddressForm> {
  PlacePrediction? _pickupOut;
  PlacePrediction? _dropoffOut;
  PlacePrediction? _pickupReturn;
  PlacePrediction? _dropoffReturn;

  bool _returnPickupTouched = false;
  bool _returnDropoffTouched = false;

  bool get _canConfirm =>
      _pickupOut != null &&
      _dropoffOut != null &&
      _pickupReturn != null &&
      _dropoffReturn != null;

  void _onPickupOutSelected(PlacePrediction prediction) {
    setState(() {
      _pickupOut = prediction;
      if (!_returnDropoffTouched) {
        _dropoffReturn = prediction;
      }
    });
  }

  void _onDropoffOutSelected(PlacePrediction prediction) {
    setState(() {
      _dropoffOut = prediction;
      if (!_returnPickupTouched) {
        _pickupReturn = prediction;
      }
    });
  }

  void _onPickupReturnSelected(PlacePrediction prediction) {
    setState(() {
      _pickupReturn = prediction;
      _returnPickupTouched = true;
    });
  }

  void _onDropoffReturnSelected(PlacePrediction prediction) {
    setState(() {
      _dropoffReturn = prediction;
      _returnDropoffTouched = true;
    });
  }

  void _confirm() {
    if (!_canConfirm) return;
    widget.onConfirmed(
      RoundTripAddressSelection(
        pickupOut: _pickupOut!,
        dropoffOut: _dropoffOut!,
        pickupReturn: _pickupReturn!,
        dropoffReturn: _dropoffReturn!,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ida e volta',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onDismissed,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Ida', style: TextStyle(fontWeight: FontWeight.w600)),
        TripAddressSearchBar(
          key: const Key('round-trip-pickup-out'),
          label: 'Partida (ida)',
          hintText: 'Buscar endereço de partida',
          onPlaceSelected: _onPickupOutSelected,
        ),
        TripAddressSearchBar(
          key: const Key('round-trip-dropoff-out'),
          label: 'Destino (ida)',
          hintText: 'Buscar endereço de destino',
          onPlaceSelected: _onDropoffOutSelected,
        ),
        const SizedBox(height: 16),
        const Text('Volta', style: TextStyle(fontWeight: FontWeight.w600)),
        TripAddressSearchBar(
          key: ValueKey('round-trip-pickup-return-${_pickupReturn?.placeId}'),
          label: 'Partida (volta)',
          hintText: 'Buscar endereço de partida',
          initialText: _pickupReturn?.description,
          onPlaceSelected: _onPickupReturnSelected,
        ),
        TripAddressSearchBar(
          key: ValueKey(
            'round-trip-dropoff-return-${_dropoffReturn?.placeId}',
          ),
          label: 'Destino (volta)',
          hintText: 'Buscar endereço de destino',
          initialText: _dropoffReturn?.description,
          onPlaceSelected: _onDropoffReturnSelected,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const Key('round-trip-confirm-button'),
          onPressed: _canConfirm ? _confirm : null,
          child: const Text('Confirmar endereços'),
        ),
      ],
    );
  }
}
```

**Note on the `ValueKey` trick:** giving the return-leg `TripAddressSearchBar` widgets a key derived from the currently selected `placeId` forces Flutter to tear down and rebuild the widget (and its internal `TextEditingController`) whenever the default changes — this is required because `initialText` is only read in `initState()`, so without a key change, editing `_dropoffOut` after the return-pickup default was already set would not visually update the return-pickup field's text.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trip/presentation/widgets/round_trip_address_form_test.dart`
Expected: PASS (2/2)

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/presentation/widgets/round_trip_address_form.dart test/features/trip/presentation/widgets/round_trip_address_form_test.dart
git commit -m "feat(trip): adiciona formulario de enderecos de ida e volta"
```

---

### Task B4: `TripRequest` — add return address fields

**Context:** `TripRequest` already has `isRoundTrip`/`returnDatetime` (see full file, 63 lines). This adds the 2 missing address fields.

**Files:**
- Modify: `lib/features/trip/domain/entities/trip_request.dart`
- Test: `test/features/trip/domain/entities/trip_request_test.dart` (create if it does not already exist; if it exists, add to it)

- [ ] **Step 1: Write the failing test**

```dart
test('carrega enderecos de retorno quando informados', () {
  const returnPickup = TripAddress(
    formattedAddress: 'Rua B, 200',
    latitude: -23.5,
    longitude: -46.6,
  );
  const returnDropoff = TripAddress(
    formattedAddress: 'Rua A, 100',
    latitude: -23.6,
    longitude: -46.7,
  );

  final request = TripRequest(
    pickupAddress: returnDropoff,
    dropoffAddress: returnPickup,
    scheduledDatetime: DateTime(2026, 8, 20, 9),
    passengerCount: 1,
    isRoundTrip: true,
    returnDatetime: DateTime(2026, 8, 20, 18),
    returnPickupAddress: returnPickup,
    returnDropoffAddress: returnDropoff,
  );

  expect(request.returnPickupAddress, returnPickup);
  expect(request.returnDropoffAddress, returnDropoff);
});
```

Adapt required constructor args (`pickupAddress`/`dropoffAddress`/`scheduledDatetime`/`passengerCount`/etc.) to match whatever the actual `TripRequest` constructor already requires — read the full 63-line file first if not already in context before writing this test's literal call.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/domain/entities/trip_request_test.dart`
Expected: FAIL — no `returnPickupAddress`/`returnDropoffAddress` named params (compile error).

- [ ] **Step 3: Implement**

In `lib/features/trip/domain/entities/trip_request.dart`, add to the constructor and fields:

```dart
final TripAddress? returnPickupAddress;
final TripAddress? returnDropoffAddress;
```

both optional, defaulting to `null`, added to the constructor's named params and to the `props` list (Equatable) alongside the existing `isRoundTrip`/`returnDatetime` entries.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trip/domain/entities/trip_request_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/domain/entities/trip_request.dart test/features/trip/domain/entities/trip_request_test.dart
git commit -m "feat(trip): adiciona enderecos de retorno em TripRequest"
```

---

### Task B5: `TripModel.buildInsertJson` — return address IDs

**Files:**
- Modify: `lib/features/trip/data/models/trip_model.dart`
- Test: `test/features/trip/data/models/trip_models_test.dart` (existing file, 198 lines — add new cases, do not remove existing ones)

- [ ] **Step 1: Write the failing tests**

Add to `test/features/trip/data/models/trip_models_test.dart`, following the existing test structure/imports already in that file:

```dart
test('buildInsertJson inclui return_pickup_address_id e return_dropoff_address_id quando informados', () {
  final json = TripModel.buildInsertJson(
    clientId: 'client-1',
    pickupAddressId: 'addr-pickup',
    dropoffAddressId: 'addr-dropoff',
    scheduledDatetime: DateTime(2026, 8, 20, 9),
    passengerCount: 1,
    isRoundTrip: true,
    returnDatetime: DateTime(2026, 8, 20, 18),
    returnPickupAddressId: 'addr-return-pickup',
    returnDropoffAddressId: 'addr-return-dropoff',
  );

  expect(json['return_pickup_address_id'], 'addr-return-pickup');
  expect(json['return_dropoff_address_id'], 'addr-return-dropoff');
});

test('buildInsertJson omite return_pickup_address_id e return_dropoff_address_id quando nao informados', () {
  final json = TripModel.buildInsertJson(
    clientId: 'client-1',
    pickupAddressId: 'addr-pickup',
    dropoffAddressId: 'addr-dropoff',
    scheduledDatetime: DateTime(2026, 8, 20, 9),
    passengerCount: 1,
  );

  expect(json.containsKey('return_pickup_address_id'), isFalse);
  expect(json.containsKey('return_dropoff_address_id'), isFalse);
});
```

Adjust the required params in these calls (`clientId`/`pickupAddressId`/etc.) to match `buildInsertJson`'s actual required signature — read the existing tests in the same file for the exact required-args pattern already used for `isRoundTrip`/`returnDatetime` cases, and mirror it.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/data/models/trip_models_test.dart`
Expected: FAIL — no `returnPickupAddressId`/`returnDropoffAddressId` params (compile error).

- [ ] **Step 3: Implement**

In `lib/features/trip/data/models/trip_model.dart`'s `buildInsertJson`, add 2 new optional params:

```dart
String? returnPickupAddressId,
String? returnDropoffAddressId,
```

and, following the exact same conditional-add pattern already used for `isRoundTrip`/`returnDatetime` in this method (read the method body first to match the pattern precisely — likely an `if (returnDatetime != null) json['return_datetime'] = ...` style block), add:

```dart
if (returnPickupAddressId != null) {
  json['return_pickup_address_id'] = returnPickupAddressId;
}
if (returnDropoffAddressId != null) {
  json['return_dropoff_address_id'] = returnDropoffAddressId;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trip/data/models/trip_models_test.dart`
Expected: PASS — all existing + 2 new cases pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/data/models/trip_model.dart test/features/trip/data/models/trip_models_test.dart
git commit -m "feat(trip): adiciona ids de enderecos de retorno em TripModel.buildInsertJson"
```

---

### Task B6: `TripRepositoryImpl` — persist return addresses + new `persistAddress` wrapper

**Context:** `createTrip` (scheduled_quote path) currently inserts only pickup/dropoff addresses. `persistAddressesForDirectRequest` already persists the outbound pair for scheduled_choose_driver. This task adds conditional return-address insertion to `createTrip`, and a new public `persistAddress` wrapper reusing the existing private `_insertAddress` so `trip_home_page.dart` (Task B9) can persist the 2 return addresses before building the scheduled_choose_driver `extra` map.

**Files:**
- Modify: `lib/features/trip/data/repositories/trip_repository_impl.dart`
- Test: `test/features/trip/data/repositories/trip_repository_impl_test.dart` (existing file — read it first to confirm exact mocktail/Supabase-mock setup pattern already used for `createTrip`, then mirror it)

- [ ] **Step 1: Write the failing tests**

Add 2 new tests to the existing test file, following its established mock setup for `createTrip`:

```dart
test('createTrip insere enderecos de retorno quando fornecidos', () async {
  final request = TripRequest(
    pickupAddress: pickupAddress,
    dropoffAddress: dropoffAddress,
    scheduledDatetime: DateTime(2026, 8, 20, 9),
    passengerCount: 1,
    isRoundTrip: true,
    returnDatetime: DateTime(2026, 8, 20, 18),
    returnPickupAddress: dropoffAddress,
    returnDropoffAddress: pickupAddress,
  );

  await repository.createTrip(request);

  verify(
    () => mockSupabaseClient.from('addresses').insert(any()),
  ).called(greaterThanOrEqualTo(4));
});

test('persistAddress insere um endereço avulso e retorna o id', () async {
  final id = await repository.persistAddress(pickupAddress);
  expect(id, isNotEmpty);
});
```

Replace `pickupAddress`/`dropoffAddress`/`mockSupabaseClient`/`repository` with whatever fixtures and mock variable names the existing test file already declares — read the file first (it exists per prior research) rather than inventing new fixture names.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/trip/data/repositories/trip_repository_impl_test.dart`
Expected: FAIL — `persistAddress` does not exist; return-address insert count assertion fails (only 2 inserts happen today).

- [ ] **Step 3: Implement**

In `lib/features/trip/data/repositories/trip_repository_impl.dart`:

1. Add a new public method reusing the existing private insert helper:

```dart
Future<String> persistAddress(TripAddress address) =>
    _insertAddress(AddressModel.fromEntity(address));
```

(Confirm the exact private method name and its return type by reading the file — `_insertAddress` is inferred from the `persistAddressesForDirectRequest` pattern; if the actual private helper has a different name or signature, use that exact name/signature instead.)

2. In `createTrip`, after the existing pickup/dropoff address insertion and before/alongside building the insert JSON, conditionally insert the return addresses when present:

```dart
String? returnPickupAddressId;
String? returnDropoffAddressId;
if (request.isRoundTrip &&
    request.returnPickupAddress != null &&
    request.returnDropoffAddress != null) {
  returnPickupAddressId = await persistAddress(request.returnPickupAddress!);
  returnDropoffAddressId = await persistAddress(
    request.returnDropoffAddress!,
  );
}
```

and pass `returnPickupAddressId: returnPickupAddressId, returnDropoffAddressId: returnDropoffAddressId` into the existing `TripModel.buildInsertJson(...)` call.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/trip/data/repositories/trip_repository_impl_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/data/repositories/trip_repository_impl.dart test/features/trip/data/repositories/trip_repository_impl_test.dart
git commit -m "feat(trip): persiste enderecos de retorno em createTrip e expoe persistAddress"
```

---

### Task B7: `trip_home_page.dart` — new state fields + reset blocks

**Context:** `trip_home_page.dart` already has `bool _isRoundTripRequest = false;` at line 157. This task adds 2 new state fields to hold the return leg's selected place IDs, and resets them alongside the existing `_pickupPlaceId`/`_destinationPlaceId` resets at all 4 known reset sites (~2296-2297, 2348-2349, 2734-2735, 2785-2786).

**Files:**
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Add the new state fields**

Near line 157 (immediately after `bool _isRoundTripRequest = false;`), add:

```dart
String? _returnPickupPlaceId;
String? _returnDropoffPlaceId;
```

- [ ] **Step 2: Reset the new fields at every existing pickup/destination reset site**

Read the 4 reset blocks first (around lines 2296-2297, 2348-2349, 2734-2735, 2785-2786) to confirm each one's exact current content:

```dart
_pickupPlaceId = null;
_destinationPlaceId = null;
```

At each of the 4 sites, add the 2 new lines immediately after:

```dart
_pickupPlaceId = null;
_destinationPlaceId = null;
_returnPickupPlaceId = null;
_returnDropoffPlaceId = null;
```

Do this at all 4 sites — do not consolidate them into a shared helper, since this plan intentionally mirrors the existing repetition pattern already used for `_pickupPlaceId`/`_destinationPlaceId` at these 4 independent call sites (YAGNI — introducing a new reset helper is out of scope for this bug fix).

- [ ] **Step 3: Verify no test regressions**

Run: `flutter analyze lib/features/trip/presentation/pages/trip_home_page.dart`
Expected: no new errors (this step only adds field declarations and reset statements, no test exists for this file directly — behavior is covered by Tasks B8/B9's tests).

- [ ] **Step 4: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat(trip): adiciona estado para place ids de retorno em trip_home_page"
```

---

### Task B8: `trip_home_page.dart` — wire `RoundTripAddressForm` into the search overlay

**Context:** `_buildSearchOverlay()` (lines ~3557-3596) currently renders, inside an `AnimatedSwitcher`, a ternary: `_isSearchActive ? AddressSearchSheet(...) : SizedBox.shrink()`. This task changes it so that when `_isRoundTripRequest` is true, `RoundTripAddressForm` renders instead of `AddressSearchSheet`.

**Files:**
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Read the exact current `_buildSearchOverlay()` body**

Read lines 3557-3596 in full before editing — the exact ternary structure and `AnimatedSwitcher` child must be preserved except for the one conditional swap described below.

- [ ] **Step 2: Add the new handler method**

Add this new private method near the other `_on*` handlers in the same class (e.g., next to `_onConfirmAddresses`):

```dart
Future<void> _onRoundTripAddressesConfirmed(
  RoundTripAddressSelection selection,
) async {
  await _onPickupSelected(selection.pickupOut);
  await _onDestinationSelected(selection.dropoffOut);
  if (!mounted) return;
  setState(() {
    _returnPickupPlaceId = selection.pickupReturn.placeId;
    _returnDropoffPlaceId = selection.dropoffReturn.placeId;
  });
  await _onConfirmAddresses();
}
```

This reuses the existing outbound-pair pipeline (`_onPickupSelected`/`_onDestinationSelected`/`_onConfirmAddresses`) unchanged — only the 2 new state fields are new writes.

- [ ] **Step 3: Add the import**

At the top of `trip_home_page.dart`, add:

```dart
import 'package:kz_servicos_app/features/trip/domain/entities/round_trip_address_selection.dart';
import 'package:kz_servicos_app/features/trip/presentation/widgets/round_trip_address_form.dart';
```

- [ ] **Step 4: Replace the ternary inside `_buildSearchOverlay()`**

Change:

```dart
child: _isSearchActive
    ? AddressSearchSheet(/* existing params, unchanged */)
    : const SizedBox.shrink(),
```

to:

```dart
child: !_isSearchActive
    ? const SizedBox.shrink()
    : _isRoundTripRequest
    ? RoundTripAddressForm(
        onConfirmed: _onRoundTripAddressesConfirmed,
        onDismissed: () => setState(() => _isSearchActive = false),
      )
    : AddressSearchSheet(/* existing params, unchanged */),
```

Preserve every existing `AddressSearchSheet(...)` constructor argument exactly as they are today — only the surrounding ternary structure changes. If `_isSearchActive` is not the actual guarding boolean field name, use whichever field name the real code at lines 3557-3596 uses (confirm via the Step 1 read).

- [ ] **Step 5: Manual verification**

Run the app (`flutter run`), navigate to "Agendar viagem" → select "Ida e volta", and confirm the new 4-field `RoundTripAddressForm` renders instead of the map-pin `AddressSearchSheet`. Select all 4 addresses, confirm, and verify the flow proceeds to the passenger-details panel as before (this replaces an automated test, since this is a page-level integration wiring change already covered by Task B3's widget test for `RoundTripAddressForm` itself).

- [ ] **Step 6: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat(trip): exibe RoundTripAddressForm para agendamentos de ida e volta"
```

---

### Task B9: `trip_home_page.dart` — resolve return addresses and fix both downstream call sites

**Context:** `_onPassengerDetailsConfirmed` (lines ~1407-1570+) resolves `pickupAddress`/`dropoffAddress` from place IDs before branching by trip type. Two bugs to fix here:
1. The **scheduled_choose_driver** branch (~1509-1538) builds an `extra` map for `context.push('/scheduled-choose-driver/select', extra: {...})` that has NO `isRoundTrip`/`returnDatetime`/return-address keys at all — this is the user-reported bug where round-trip info is silently dropped for this flow.
2. The **scheduled_quote** branch (~1541-1557) already passes `isRoundTrip`/`returnDatetime` to `TripRequest(...)` but lacks `returnPickupAddress`/`returnDropoffAddress`.

**Files:**
- Modify: `lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Read the exact current `_onPassengerDetailsConfirmed` body**

Read lines 1407-1570 in full before editing (already read once during research this session — re-read to get exact current line numbers and variable names, since B7/B8 edits above may have shifted line numbers slightly).

- [ ] **Step 2: Resolve the return addresses alongside the existing pickup/dropoff resolution**

Find wherever `pickupAddress`/`dropoffAddress` are resolved (via place ID → `TripAddress`, likely through a geocoding/places lookup call already used for the outbound pair). Add, guarded by `_isRoundTripRequest`:

```dart
TripAddress? returnPickupAddress;
TripAddress? returnDropoffAddress;
if (_isRoundTripRequest &&
    _returnPickupPlaceId != null &&
    _returnDropoffPlaceId != null) {
  returnPickupAddress = await /* same resolution call used for pickupAddress, applied to _returnPickupPlaceId */;
  returnDropoffAddress = await /* same resolution call used for dropoffAddress, applied to _returnDropoffPlaceId */;
}
```

Use whatever the actual existing resolution mechanism is (e.g., a method like `_resolveAddress(placeId)` — confirm its exact name from the Step 1 read) rather than guessing a new one.

- [ ] **Step 3: Fix the scheduled_choose_driver branch's `extra` map**

Find the `context.push('/scheduled-choose-driver/select', extra: {...})` call (~line 1509-1538). Add the 4 missing keys to the existing map literal, alongside the existing `pickupAddressId`/`dropoffAddressId`/`scheduledDatetime` keys:

```dart
'isRoundTrip': _isRoundTripRequest,
'returnDatetime': returnDatetime,
'returnPickupAddressId': _returnPickupPlaceId,
'returnDropoffAddressId': _returnDropoffPlaceId,
```

(`returnDatetime` here refers to whatever the existing local variable holding the volta panel's collected date/time is called — confirm its exact name from the Step 1 read; it is already computed somewhere in this method per the pre-existing two-pass `PassengerDetailsPanel` flow, since the design doc for this feature already states "the fix here is purely about not losing this data downstream.")

- [ ] **Step 4: Fix the scheduled_quote branch's `TripRequest(...)` call**

Find the `TripRequest(...)` construction (~line 1541-1557) that already passes `isRoundTrip: _isRoundTripRequest, returnDatetime: returnDatetime`. Add:

```dart
returnPickupAddress: returnPickupAddress,
returnDropoffAddress: returnDropoffAddress,
```

using the variables resolved in Step 2.

- [ ] **Step 5: Manual verification**

Run the app, complete a full round-trip "escolher motorista" booking end-to-end, and confirm (via a temporary debug print or by checking the Supabase `trips` row after submission) that `is_round_trip`, `return_datetime`, `return_pickup_address_id`, and `return_dropoff_address_id` are all populated. Repeat for the "agendamento automático" (scheduled_quote) path. Remove any temporary debug prints before committing.

- [ ] **Step 6: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "fix(trip): propaga dados de ida e volta para os dois fluxos de agendamento"
```

---

### Task B10: `ScheduledDirectRequestRepository` — forward round-trip params to the RPC

**Context:** `sendRequest` currently has 7 params matching the OLD RPC exactly. After Task A2, the RPC accepts 4 new optional trailing params. `fetchActiveRequest`'s select string also needs extending so the client can see round-trip data while awaiting the driver's response (Task B14 depends on this).

**Files:**
- Modify: `lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart`
- Test: `test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart` (existing file — read it first to confirm the exact mocktail RPC-call verification pattern already used for the 7 existing params)

- [ ] **Step 1: Write the failing test**

Add to the existing test file, mirroring its established pattern for verifying `rpc('client_send_scheduled_direct_request', params: {...})` calls:

```dart
test('sendRequest envia parametros de ida e volta quando isRoundTrip=true', () async {
  await repository.sendRequest(
    driverProfileId: 'driver-1',
    pickupAddressId: 'addr-pickup',
    dropoffAddressId: 'addr-dropoff',
    serviceCategoryId: 'cat-1',
    passengerCount: 1,
    observations: null,
    scheduledDatetime: DateTime(2026, 8, 20, 9),
    isRoundTrip: true,
    returnDatetime: DateTime(2026, 8, 20, 18),
    returnPickupAddressId: 'addr-return-pickup',
    returnDropoffAddressId: 'addr-return-dropoff',
  );

  final captured = verify(
    () => mockSupabaseClient.rpc(
      'client_send_scheduled_direct_request',
      params: captureAny(named: 'params'),
    ),
  ).captured.single as Map;

  expect(captured['is_round_trip_input'], true);
  expect(captured['return_datetime_input'], isNotNull);
  expect(captured['return_pickup_address_id_input'], 'addr-return-pickup');
  expect(captured['return_dropoff_address_id_input'], 'addr-return-dropoff');
});
```

Replace `mockSupabaseClient`/`repository` with whatever fixture names the existing test file already declares — read it first rather than inventing new names, and confirm the exact existing 7-param call signature for `sendRequest` to keep this test's other required args accurate.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart`
Expected: FAIL — no `isRoundTrip`/`returnDatetime`/`returnPickupAddressId`/`returnDropoffAddressId` params on `sendRequest` (compile error).

- [ ] **Step 3: Implement — extend `sendRequest`**

Add 4 new optional params to `sendRequest`, defaulting to safe values matching the RPC's own defaults:

```dart
bool isRoundTrip = false,
DateTime? returnDatetime,
String? returnPickupAddressId,
String? returnDropoffAddressId,
```

and add the corresponding 4 keys to the existing `params: {...}` map passed to `.rpc('client_send_scheduled_direct_request', params: {...})`:

```dart
'is_round_trip_input': isRoundTrip,
'return_datetime_input': returnDatetime?.toIso8601String(),
'return_pickup_address_id_input': returnPickupAddressId,
'return_dropoff_address_id_input': returnDropoffAddressId,
```

Match the exact date-serialization style already used for `scheduledDatetime` in this same map (e.g., if it uses `.toIso8601String()` or a shared formatter, use the same one for `returnDatetime`).

- [ ] **Step 4: Implement — extend `fetchActiveRequest`'s select string**

Find the existing `select(...)` string in `fetchActiveRequest` and add:

```dart
, is_round_trip, return_datetime, return_pickup_address:addresses!return_pickup_address_id(formatted_address), return_dropoff_address:addresses!return_dropoff_address_id(formatted_address)
```

appended to whatever the current select string already contains (preserve every existing selected column/relation exactly).

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart test/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository_test.dart
git commit -m "feat(scheduled-choose-driver): envia e busca dados de ida e volta no repositorio de pedido direto"
```

---

### Task B11: `DriverSelectionCubit` — accept and forward round-trip params

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart`
- Test: `test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart` (new file — mirror the mocktail pattern already confirmed in `test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart`)

- [ ] **Step 1: Write the failing test**

```dart
// test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart';
import 'package:kz_servicos_app/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart';

class MockScheduledDirectRequestRepository extends Mock
    implements ScheduledDirectRequestRepository {}

void main() {
  late MockScheduledDirectRequestRepository repository;
  late DriverSelectionCubit cubit;

  setUp(() {
    repository = MockScheduledDirectRequestRepository();
    registerFallbackValue(DateTime(2026));
    cubit = DriverSelectionCubit(
      repository: repository,
      driverProfileId: 'driver-1',
      pickupAddressId: 'addr-pickup',
      dropoffAddressId: 'addr-dropoff',
      serviceCategoryId: 'cat-1',
      passengerCount: 1,
      scheduledDatetime: DateTime(2026, 8, 20, 9),
      isRoundTrip: true,
      returnDatetime: DateTime(2026, 8, 20, 18),
      returnPickupAddressId: 'addr-return-pickup',
      returnDropoffAddressId: 'addr-return-dropoff',
    );
  });

  test('request() encaminha parametros de ida e volta para sendRequest', () async {
    when(
      () => repository.sendRequest(
        driverProfileId: any(named: 'driverProfileId'),
        pickupAddressId: any(named: 'pickupAddressId'),
        dropoffAddressId: any(named: 'dropoffAddressId'),
        serviceCategoryId: any(named: 'serviceCategoryId'),
        passengerCount: any(named: 'passengerCount'),
        observations: any(named: 'observations'),
        scheduledDatetime: any(named: 'scheduledDatetime'),
        isRoundTrip: any(named: 'isRoundTrip'),
        returnDatetime: any(named: 'returnDatetime'),
        returnPickupAddressId: any(named: 'returnPickupAddressId'),
        returnDropoffAddressId: any(named: 'returnDropoffAddressId'),
      ),
    ).thenAnswer((_) async {});

    await cubit.request();

    verify(
      () => repository.sendRequest(
        driverProfileId: 'driver-1',
        pickupAddressId: 'addr-pickup',
        dropoffAddressId: 'addr-dropoff',
        serviceCategoryId: 'cat-1',
        passengerCount: 1,
        observations: any(named: 'observations'),
        scheduledDatetime: DateTime(2026, 8, 20, 9),
        isRoundTrip: true,
        returnDatetime: DateTime(2026, 8, 20, 18),
        returnPickupAddressId: 'addr-return-pickup',
        returnDropoffAddressId: 'addr-return-dropoff',
      ),
    ).called(1);
  });
}
```

Adjust the constructor's required params (`observations` may or may not be required — confirm against the actual current constructor, re-verified this session as matching prior research exactly) and the exact `request()` method name/behavior to match the real file precisely.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart`
Expected: FAIL — no `isRoundTrip`/`returnDatetime`/`returnPickupAddressId`/`returnDropoffAddressId` constructor params (compile error).

- [ ] **Step 3: Implement**

In `lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart`, add 4 new fields + constructor params:

```dart
final bool isRoundTrip;
final DateTime? returnDatetime;
final String? returnPickupAddressId;
final String? returnDropoffAddressId;
```

with `isRoundTrip` defaulting to `false` and the other 3 to `null` in the constructor, and forward all 4 into the existing `repository.sendRequest(...)` call inside `request()`, alongside the existing 7 args.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart test/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit_test.dart
git commit -m "feat(scheduled-choose-driver): encaminha dados de ida e volta no DriverSelectionCubit"
```

---

### Task B12: `app_router.dart` — wire the extra map into `DriverSelectionCubit`

**Files:**
- Modify: `lib/routes/app_router.dart` (route `/scheduled-choose-driver/select`, ~lines 171-189)

- [ ] **Step 1: Read the exact current route builder**

Read lines 171-189 in full before editing — confirmed this session to construct `DriverSelectionCubit(...)` from an `extra` map with keys `pickupAddressId`/`dropoffAddressId`/`scheduledDatetime`/etc.

- [ ] **Step 2: Add the 4 new extra-map reads**

Add to the `DriverSelectionCubit(...)` constructor call:

```dart
isRoundTrip: extra['isRoundTrip'] as bool? ?? false,
returnDatetime: extra['returnDatetime'] as DateTime?,
returnPickupAddressId: extra['returnPickupAddressId'] as String?,
returnDropoffAddressId: extra['returnDropoffAddressId'] as String?,
```

matching the exact `extra` map variable name already used at this route (confirmed this session, likely `extra` — verify from the Step 1 read) and the exact key names produced by Task B9's Step 3 fix to the `context.push` call in `trip_home_page.dart`.

- [ ] **Step 3: Manual verification**

Run the app, complete the "escolher motorista" round-trip flow end-to-end from address entry through driver selection, and confirm (via the same Supabase row check as Task B9 Step 5) that the round-trip data survives the full navigation + RPC round trip.

- [ ] **Step 4: Commit**

```bash
git add lib/routes/app_router.dart
git commit -m "fix(routes): propaga dados de ida e volta para DriverSelectionCubit"
```

---

### Task B13: `PriceOfferDetails` — new round-trip fields

**Context:** All 14 existing fields are `required`. New fields must be optional-with-defaults to preserve `const` constructor compatibility (confirmed via `awaiting_driver_content_test.dart`'s `const PriceOfferDetails(...)` fixture).

**Files:**
- Modify: `lib/features/scheduled_choose_driver/domain/entities/price_offer_details.dart`
- Test: `test/features/scheduled_choose_driver/domain/entities/price_offer_details_test.dart` (create if it does not exist; if it exists, add to it)

- [ ] **Step 1: Write the failing test**

```dart
test('fromMap parseia campos de ida e volta quando presentes', () {
  final map = {
    // ... existing required keys already covered by other tests in this file,
    // read the file first if it exists to reuse its base map fixture ...
    'is_round_trip': true,
    'return_datetime': '2026-08-20T18:00:00.000',
    'return_pickup_address': {'formatted_address': 'Rua B, 200'},
    'return_dropoff_address': {'formatted_address': 'Rua A, 100'},
  };

  final details = PriceOfferDetails.fromMap(map);

  expect(details.isRoundTrip, isTrue);
  expect(details.returnDatetime, DateTime.parse('2026-08-20T18:00:00.000'));
  expect(details.returnPickupAddress, 'Rua B, 200');
  expect(details.returnDropoffAddress, 'Rua A, 100');
});

test('fromMap trata campos de ida e volta ausentes como nao round trip', () {
  final map = {
    // ... same base fixture, without the 4 round-trip keys ...
  };

  final details = PriceOfferDetails.fromMap(map);

  expect(details.isRoundTrip, isFalse);
  expect(details.returnDatetime, isNull);
  expect(details.returnPickupAddress, isNull);
  expect(details.returnDropoffAddress, isNull);
});
```

Fill in the base map fixture using the same required-field shape already established in `awaiting_driver_content_test.dart`'s `const PriceOfferDetails(...)` (driverName, rating, vehicle, pickupAddress, etc.) translated into the raw-map form `fromMap` expects — read `price_offer_details.dart`'s existing `fromMap` implementation first if not already in context to match its exact key names for the other 14 fields.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/scheduled_choose_driver/domain/entities/price_offer_details_test.dart`
Expected: FAIL — no `isRoundTrip`/`returnDatetime`/`returnPickupAddress`/`returnDropoffAddress` fields (compile error).

- [ ] **Step 3: Implement**

In `lib/features/scheduled_choose_driver/domain/entities/price_offer_details.dart`, add 4 new fields to the class and its `const` constructor, all optional:

```dart
final bool isRoundTrip;
final DateTime? returnDatetime;
final String? returnPickupAddress;
final String? returnDropoffAddress;
```

with `isRoundTrip` defaulting to `false` in the constructor (`this.isRoundTrip = false`) and the other 3 defaulting to `null`. Add all 4 to the `props` list (Equatable) if the class uses one — confirm from the existing file.

In `fromMap`, add parsing using a new nullable helper (distinct from the existing `_address` helper, which has a non-null fallback string):

```dart
static String? _addressOrNull(Map<String, dynamic>? map) {
  final formatted = map?['formatted_address'] as String?;
  return formatted;
}
```

and in the body of `fromMap`:

```dart
isRoundTrip: map['is_round_trip'] as bool? ?? false,
returnDatetime: map['return_datetime'] != null
    ? DateTime.parse(map['return_datetime'] as String)
    : null,
returnPickupAddress: _addressOrNull(
  map['return_pickup_address'] as Map<String, dynamic>?,
),
returnDropoffAddress: _addressOrNull(
  map['return_dropoff_address'] as Map<String, dynamic>?,
),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/scheduled_choose_driver/domain/entities/price_offer_details_test.dart`
Expected: PASS

- [ ] **Step 5: Run the existing widget test fixtures to confirm no regression**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart test/features/scheduled_choose_driver/presentation/widgets/price_offer_content_test.dart`
Expected: PASS — the existing `const PriceOfferDetails(...)` fixtures (all 14 original fields, no round-trip fields) must still compile and pass, confirming the new fields are truly optional.

- [ ] **Step 6: Commit**

```bash
git add lib/features/scheduled_choose_driver/domain/entities/price_offer_details.dart test/features/scheduled_choose_driver/domain/entities/price_offer_details_test.dart
git commit -m "feat(scheduled-choose-driver): adiciona campos de ida e volta em PriceOfferDetails"
```

---

### Task B14: `AwaitingDriverContent` — show round-trip itinerary while waiting

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart` (`_TripSummary`, lines ~553-612)
- Test: `test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart` (existing file — add a new test, keep the existing one unmodified)

- [ ] **Step 1: Write the failing test**

Add to the existing test file:

```dart
testWidgets('mostra secao de volta quando isRoundTrip=true', (tester) async {
  const roundTripDetails = PriceOfferDetails(
    driverName: 'Motorista Teste',
    driverAvatarUrl: null,
    rating: 4.9,
    totalRatings: 128,
    completedTrips: 342,
    driverPhotoUrls: [],
    vehicle: PriceOfferVehicle(
      brand: 'Toyota',
      model: 'Corolla',
      year: 2024,
      color: 'Prata',
      licensePlate: 'ABC1D23',
      passengerCapacity: 4,
      photoUrls: [],
    ),
    pickupAddress: 'Rua das Flores, 120',
    stopAddresses: ['Av. Brasil, 450'],
    dropoffAddress: 'Aeroporto Internacional',
    scheduledDatetime: null,
    passengerCount: 2,
    childrenCount: 0,
    luggageCount: 1,
    observations: null,
    isRoundTrip: true,
    returnDatetime: null,
    returnPickupAddress: 'Aeroporto Internacional',
    returnDropoffAddress: 'Rua das Flores, 120',
  );

  await tester.pumpWidget(
    const MaterialApp(
      home: AwaitingDriverContent(
        details: roundTripDetails,
        cancelling: false,
        error: null,
        onContinue: null,
        onCancel: null,
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.textContaining('Volta'), findsWidgets);
  expect(find.text('Aeroporto Internacional'), findsWidgets);
});
```

Adjust `onContinue`/`onCancel` to match the existing test's callback style (the existing test passes `() {}`, not `null` — use `() {}` for both to match `_TripSummary`'s existing usage pattern exactly, since the class fields are likely non-nullable callbacks).

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`
Expected: FAIL — no "Volta" text rendered yet.

- [ ] **Step 3: Implement**

In `_TripSummary` (lines ~553-612), after the existing pickup/dropoff address rows, add a conditional round-trip section:

```dart
if (details.isRoundTrip) ...[
  const SizedBox(height: 12),
  const Text(
    'Volta',
    style: TextStyle(fontWeight: FontWeight.w600),
  ),
  const SizedBox(height: 4),
  if (details.returnPickupAddress != null)
    Text('De: ${details.returnPickupAddress}'),
  if (details.returnDropoffAddress != null)
    Text('Para: ${details.returnDropoffAddress}'),
],
```

Insert this into the existing `Column`'s `children` list within `_TripSummary`, matching the styling conventions (font sizes, spacing widgets) already used by the surrounding pickup/dropoff rows in this same widget — read the current 553-612 block first and mirror its exact `Text`/`SizedBox` patterns rather than inventing new styling.

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart`
Expected: PASS (both the existing one-way test and the new round-trip test).

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart test/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content_test.dart
git commit -m "feat(scheduled-choose-driver): exibe itinerario de volta em AwaitingDriverContent"
```

---

### Task B15: `PriceOfferContent` — show round-trip itinerary in the price offer

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/widgets/price_offer_content.dart` (`_TripCard`, lines ~592-677)
- Test: `test/features/scheduled_choose_driver/presentation/widgets/price_offer_content_test.dart` (existing file — add a new test, keep the existing one unmodified)

- [ ] **Step 1: Write the failing test**

Mirror Task B14's test structure exactly, but targeting `PriceOfferContent` instead of `AwaitingDriverContent` — read the existing `price_offer_content_test.dart` first (confirmed non-const `PriceOfferDetails` fixture variant this session) to match its exact widget-under-test constructor shape (it likely also takes `details`, plus offer-specific callbacks like `onAccept`/`onReject` not present on `AwaitingDriverContent`):

```dart
testWidgets('mostra secao de volta na proposta quando isRoundTrip=true', (
  tester,
) async {
  final roundTripDetails = PriceOfferDetails(
    // ... same base fixture as the existing test in this file, plus: ...
    isRoundTrip: true,
    returnDatetime: null,
    returnPickupAddress: 'Aeroporto Internacional',
    returnDropoffAddress: 'Rua das Flores, 120',
  );

  await tester.pumpWidget(
    MaterialApp(
      home: PriceOfferContent(
        details: roundTripDetails,
        // ... same other required params as the existing test in this file ...
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 500));

  expect(find.textContaining('Volta'), findsWidgets);
  expect(find.text('Aeroporto Internacional'), findsWidgets);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/price_offer_content_test.dart`
Expected: FAIL — no "Volta" text rendered yet.

- [ ] **Step 3: Implement**

In `_TripCard` (lines ~592-677), add the same conditional round-trip section pattern as Task B14's Step 3, matching `_TripCard`'s own existing styling conventions (read the current 592-677 block first — `PriceOfferContent`'s card styling may differ visually from `AwaitingDriverContent`'s, e.g. using `Card`/`Container` decoration not present in `_TripSummary`, so mirror whatever container/row pattern this specific widget already uses for its pickup/dropoff rows):

```dart
if (details.isRoundTrip) ...[
  const SizedBox(height: 12),
  const Text('Volta', style: TextStyle(fontWeight: FontWeight.w600)),
  const SizedBox(height: 4),
  if (details.returnPickupAddress != null)
    Text('De: ${details.returnPickupAddress}'),
  if (details.returnDropoffAddress != null)
    Text('Para: ${details.returnDropoffAddress}'),
],
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/features/scheduled_choose_driver/presentation/widgets/price_offer_content_test.dart`
Expected: PASS (both the existing one-way test and the new round-trip test).

- [ ] **Step 5: Commit**

```bash
git add lib/features/scheduled_choose_driver/presentation/widgets/price_offer_content.dart test/features/scheduled_choose_driver/presentation/widgets/price_offer_content_test.dart
git commit -m "feat(scheduled-choose-driver): exibe itinerario de volta em PriceOfferContent"
```

---

## Phase C — Driver app (kz-servicos-app-prestador)

**Context for the whole phase:** The user's explicit instruction for this plan was: *"no app prestador deve aparecer que é ida e volta, endereços de ida e endereços de volta, data e hora de ida e de volta"* — i.e. the driver must see, at minimum: the round-trip flag, both address pairs, and both date/times. `TripData` already has `isRoundTrip`/`returnAt`; it's missing the return address pair. The request card and schedule detail page currently show none of this.

### Task C1: `TripData` — parse return addresses

**Files:**
- Modify: `lib/core/models/trip_data.dart`
- Test: `test/core/models/trip_data_test.dart` (existing file, 198 lines confirmed this session — add to it, do not remove existing tests)

- [ ] **Step 1: Write the failing test**

Add to `test/core/models/trip_data_test.dart`, inside the existing `group('TripData.fromMap()', ...)` block, reusing the existing `map` fixture declared at the top of that group:

```dart
test('parseia return_pickup_address e return_dropoff_address quando presentes', () {
  final roundTripMap = Map<String, dynamic>.from(map)
    ..['is_round_trip'] = true
    ..['return_datetime'] = '2026-05-25T20:00:00.000'
    ..['return_pickup_address'] = {
      'formatted_address': 'Aeroporto Congonhas',
    }
    ..['return_dropoff_address'] = {
      'formatted_address': 'Av. Paulista, 1000',
    };

  final trip = TripData.fromMap(roundTripMap);

  expect(trip.isRoundTrip, isTrue);
  expect(trip.returnPickupAddress, 'Aeroporto Congonhas');
  expect(trip.returnDropoffAddress, 'Av. Paulista, 1000');
});

test('returnPickupAddress e returnDropoffAddress sao null quando ausentes', () {
  final trip = TripData.fromMap(map);

  expect(trip.returnPickupAddress, isNull);
  expect(trip.returnDropoffAddress, isNull);
});
```

Before writing this test, read `lib/core/models/trip_data.dart` in full to confirm the exact existing field name for the round-trip flag (`isRoundTrip` is assumed per prior research — confirm it is not named differently, e.g. `roundTrip`) and how `origin`/`destination` are currently resolved from joined address maps (`pickup_address`/`dropoff_address` with a `formatted_address` key, per the `map` fixture already in the test file) — mirror that exact resolution pattern for the 2 new fields.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/models/trip_data_test.dart`
Expected: FAIL — no `returnPickupAddress`/`returnDropoffAddress` fields (compile error).

- [ ] **Step 3: Implement**

In `lib/core/models/trip_data.dart`, add 2 new fields:

```dart
final String? returnPickupAddress;
final String? returnDropoffAddress;
```

both optional, added to the constructor (defaulting to `null`) and to `copyWith` (following whatever pattern `copyWith` already uses for nullable fields like `clientId`/`candidateStatus`, confirmed in the existing test's `copyWith` group).

In `fromMap`, add parsing mirroring how `origin`/`destination` are resolved from `pickup_address`/`dropoff_address`:

```dart
returnPickupAddress:
    (map['return_pickup_address'] as Map<String, dynamic>?)?['formatted_address']
        as String?,
returnDropoffAddress:
    (map['return_dropoff_address'] as Map<String, dynamic>?)?['formatted_address']
        as String?,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/core/models/trip_data_test.dart`
Expected: PASS — all existing tests plus the 2 new ones.

- [ ] **Step 5: Commit**

```bash
git add lib/core/models/trip_data.dart test/core/models/trip_data_test.dart
git commit -m "feat(trip-data): adiciona enderecos de retorno em TripData"
```

---

### Task C2: `ScheduledDirectRequestCard` — show scheduled date/time and round-trip summary

**Context:** This card currently doesn't show the scheduled date/time at all, let alone round-trip info — the very first notification the driver sees is missing this. This task adds both: scheduled date/time always, and when `isRoundTrip`, a compact "Ida ... • Volta ..." summary.

**Files:**
- Modify: `lib/features/schedules/presentation/widgets/scheduled_direct_request_card.dart` (currently 73 lines, full content confirmed this session)
- Test: `test/features/schedules/presentation/widgets/scheduled_direct_request_card_test.dart` (new file)

- [ ] **Step 1: Read the current widget in full**

Read `lib/features/schedules/presentation/widgets/scheduled_direct_request_card.dart` (73 lines) before writing the test, to confirm its exact current constructor's required params (pickup/dropoff address strings, driver-facing labels, callbacks, etc.) — this plan's test below assumes a `pickupAddress`/`dropoffAddress` param pair exists already; adjust names to match.

- [ ] **Step 2: Write the failing tests**

```dart
// test/features/schedules/presentation/widgets/scheduled_direct_request_card_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_prestador/features/schedules/presentation/widgets/scheduled_direct_request_card.dart';

void main() {
  testWidgets('mostra data e hora agendada', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduledDirectRequestCard(
            pickupAddress: 'Rua das Flores, 120',
            dropoffAddress: 'Aeroporto Internacional',
            scheduledDatetime: DateTime(2026, 5, 25, 14, 30),
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('25/05/2026'), findsOneWidget);
    expect(find.textContaining('14:30'), findsOneWidget);
  });

  testWidgets('mostra resumo ida e volta quando isRoundTrip=true', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduledDirectRequestCard(
            pickupAddress: 'Rua das Flores, 120',
            dropoffAddress: 'Aeroporto Internacional',
            scheduledDatetime: DateTime(2026, 5, 25, 14, 30),
            isRoundTrip: true,
            returnDatetime: DateTime(2026, 5, 25, 20),
            returnPickupAddress: 'Aeroporto Internacional',
            returnDropoffAddress: 'Rua das Flores, 120',
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Ida'), findsWidgets);
    expect(find.textContaining('Volta'), findsWidgets);
    expect(find.textContaining('20:00'), findsOneWidget);
  });

  testWidgets('nao mostra resumo de volta quando isRoundTrip=false', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduledDirectRequestCard(
            pickupAddress: 'Rua das Flores, 120',
            dropoffAddress: 'Aeroporto Internacional',
            scheduledDatetime: DateTime(2026, 5, 25, 14, 30),
            onAccept: () {},
            onReject: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Volta'), findsNothing);
  });
}
```

Adjust every constructor param name to whatever Step 1's read confirms as accurate (e.g. `onAccept`/`onReject` are assumed from the "direct request card" naming convention — verify against the real file).

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/schedules/presentation/widgets/scheduled_direct_request_card_test.dart`
Expected: FAIL — `scheduledDatetime` param does not exist yet (compile error), or the date/time text is not rendered.

- [ ] **Step 4: Implement**

Add to the widget's constructor:

```dart
required this.scheduledDatetime,
this.isRoundTrip = false,
this.returnDatetime,
this.returnPickupAddress,
this.returnDropoffAddress,
```

with corresponding fields:

```dart
final DateTime scheduledDatetime;
final bool isRoundTrip;
final DateTime? returnDatetime;
final String? returnPickupAddress;
final String? returnDropoffAddress;
```

Add a private formatting helper (this card has no access to a shared formatter per prior research — `lib/core/utils/brazil_time.dart` only has `fromBackend`/`maybeFromBackend`, no display formatter):

```dart
String _formatDateTime(DateTime dt) {
  final day = dt.day.toString().padLeft(2, '0');
  final month = dt.month.toString().padLeft(2, '0');
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$day/$month/${dt.year} às $hour:$minute';
}
```

In the widget's `build()`, add a row showing `_formatDateTime(scheduledDatetime)` (near the existing pickup/dropoff address rows — match the existing `Text`/`Row` styling in this file), and a conditional round-trip section:

```dart
if (isRoundTrip) ...[
  const SizedBox(height: 8),
  Text(
    'Ida: $pickupAddress • ${_formatDateTime(scheduledDatetime)}',
    style: const TextStyle(fontSize: 12),
  ),
  if (returnPickupAddress != null && returnDropoffAddress != null)
    Text(
      'Volta: $returnPickupAddress → $returnDropoffAddress'
      '${returnDatetime != null ? ' • ${_formatDateTime(returnDatetime!)}' : ''}',
      style: const TextStyle(fontSize: 12),
    ),
],
```

Adjust field references (`pickupAddress`/`dropoffAddress`) to whatever the real existing field names are per Step 1.

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/features/schedules/presentation/widgets/scheduled_direct_request_card_test.dart`
Expected: PASS (3/3)

- [ ] **Step 6: Commit**

```bash
git add lib/features/schedules/presentation/widgets/scheduled_direct_request_card.dart test/features/schedules/presentation/widgets/scheduled_direct_request_card_test.dart
git commit -m "feat(schedules): exibe data/hora agendada e resumo de ida e volta no card de pedido direto"
```

---

### Task C3: `schedules_page.dart` — extend query for round-trip return addresses

**Files:**
- Modify: `lib/features/schedules/presentation/pages/schedules_page.dart` (`_fetchDirectRequests` select string and the `ScheduledDirectRequestCard(...)` call site)

- [ ] **Step 1: Read the current `_fetchDirectRequests` method and its call site**

Read the full method in `lib/features/schedules/presentation/pages/schedules_page.dart` before editing, to confirm the exact current select string and how the fetched rows are mapped into `ScheduledDirectRequestCard(...)` widgets.

- [ ] **Step 2: Extend the select string**

Add to the existing `select(...)` string:

```
, scheduled_datetime, is_round_trip, return_datetime, return_pickup_address:return_pickup_address_id(street,number,neighborhood), return_dropoff_address:return_dropoff_address_id(street,number,neighborhood)
```

appended to whatever columns/relations are already selected — preserve them exactly. (Column names `street`/`number`/`neighborhood` mirror whatever the existing `pickup_address`/`dropoff_address` join already selects in this same method — confirm and match exactly rather than assuming `formatted_address`, since this file's existing join shape may differ from `TripData`'s `formatted_address`-based shape used in Task C1.)

- [ ] **Step 3: Pass the new fields into the card**

At the `ScheduledDirectRequestCard(...)` construction site, add:

```dart
scheduledDatetime: BrazilTime.fromBackend(row['scheduled_datetime'] as String),
isRoundTrip: row['is_round_trip'] as bool? ?? false,
returnDatetime: row['return_datetime'] != null
    ? BrazilTime.fromBackend(row['return_datetime'] as String)
    : null,
returnPickupAddress: /* format row['return_pickup_address'] the same way the existing pickup address is formatted for display in this file */,
returnDropoffAddress: /* format row['return_dropoff_address'] the same way the existing dropoff address is formatted for display in this file */,
```

Use whatever the existing pickup/dropoff formatting helper already is in this file (confirm its name/shape from the Step 1 read) rather than introducing new formatting logic.

- [ ] **Step 4: Add the import**

If not already imported, add:

```dart
import 'package:kz_servicos_prestador/core/utils/brazil_time.dart';
```

- [ ] **Step 5: Manual verification**

Run the driver app, and as a client, send a round-trip "escolher motorista" direct request to a test driver account. Confirm the request card on the driver's schedules page shows the scheduled date/time and the "Ida ... • Volta ..." summary from Task C2.

- [ ] **Step 6: Commit**

```bash
git add lib/features/schedules/presentation/pages/schedules_page.dart
git commit -m "feat(schedules): busca dados de ida e volta para o card de pedido direto"
```

---

### Task C4: `schedule_detail_page.dart` — non-fromHome "Rota" section shows real return addresses

**Context:** The "Rota" section card (agendamentos / non-fromHome view, ~line 820) currently has a placeholder return row: `'Retorno previsto em X'` with no real address. This replaces it with the actual return pickup/dropoff addresses plus the return time, using the existing `_SectionCard`/`_InfoRow` widgets and `_formatShortDateTime` helper already confirmed present in this file.

**Files:**
- Modify: `lib/features/schedules/presentation/pages/schedule_detail_page.dart` (non-fromHome "Rota" section, ~line 820)

- [ ] **Step 1: Read the current "Rota" section in full**

Read the section around line 820 before editing, to confirm the exact current placeholder text and the exact `_SectionCard`/`_InfoRow` constructor shapes.

- [ ] **Step 2: Replace the placeholder return row**

Replace the `'Retorno previsto em X'` placeholder row with, guarded by the trip's `isRoundTrip` flag (confirm the exact field/variable holding this in the page's state — likely `trip.isRoundTrip` if `trip` is a `TripData`):

```dart
if (trip.isRoundTrip) ...[
  _InfoRow(
    label: 'Partida (volta)',
    value: trip.returnPickupAddress ?? '—',
  ),
  _InfoRow(
    label: 'Destino (volta)',
    value: trip.returnDropoffAddress ?? '—',
  ),
  if (trip.returnAt != null)
    _InfoRow(
      label: 'Data e hora (volta)',
      value: _formatShortDateTime(trip.returnAt!),
    ),
],
```

Adjust `trip.returnAt` to whatever the actual existing field name is for the return date/time on this page's trip model (confirmed this session as already present, but re-verify the exact name — `returnAt` vs `returnDatetime`) and adjust `_InfoRow`'s param names (`label`/`value`) to match the real widget's constructor.

- [ ] **Step 3: Manual verification**

Run the driver app, open a round-trip trip's schedule detail page (non-fromHome / "agendamentos" view), and confirm the "Rota" card shows the real return addresses and time instead of the old placeholder text.

- [ ] **Step 4: Commit**

```bash
git add lib/features/schedules/presentation/pages/schedule_detail_page.dart
git commit -m "fix(schedules): exibe enderecos reais de retorno na secao Rota do detalhe do agendamento"
```

---

### Task C5: `schedule_detail_page.dart` — fromHome route timeline: fix ordering bug and show real addresses

**Context:** Confirmed pre-existing bug in `_buildRouteTimeline()` (fromHome / incoming request view, ~line 1260): the round-trip placeholder row renders BEFORE the final 'Destino' row in the timeline, which is visually wrong (return leg should appear after the outbound destination), and it shows no real address, just placeholder text.

**Files:**
- Modify: `lib/features/schedules/presentation/pages/schedule_detail_page.dart` (`_buildRouteTimeline()`, fromHome view, ~line 1260)

- [ ] **Step 1: Read the current `_buildRouteTimeline()` in full**

Read the method around line 1260 before editing, to confirm the exact current ordering of timeline entries (pickup → dropoff → [misplaced return placeholder]) and the timeline entry widget's constructor shape.

- [ ] **Step 2: Reorder and fix the return entry**

Move the round-trip timeline entry to after the final 'Destino' (dropoff) entry in the list/column of timeline widgets, and replace its placeholder text with the real addresses, guarded by `trip.isRoundTrip`:

```dart
// existing pickup entry
// existing dropoff ('Destino') entry
if (trip.isRoundTrip) ...[
  /* return-pickup timeline entry, using trip.returnPickupAddress ?? '—' */,
  /* return-dropoff timeline entry, using trip.returnDropoffAddress ?? '—' */,
],
```

Use whatever the existing timeline-entry widget/constructor is (confirm its exact name and required params from the Step 1 read — this file's fromHome timeline is a distinct widget from the non-fromHome `_SectionCard`/`_InfoRow` pattern used in Task C4) rather than inventing a new one. Include the return date/time (`trip.returnAt` or equivalent, matching whatever name Task C4 confirmed) in the entry's subtitle/label if the existing timeline entry widget supports a subtitle field, mirroring how the outbound entries already show their own timing if they do.

- [ ] **Step 3: Manual verification**

Run the driver app, trigger an incoming round-trip direct request notification (fromHome view), open its schedule detail page, and confirm the route timeline now shows: pickup → destino → return-pickup → return-dropoff, in that order, with real addresses instead of placeholder text.

- [ ] **Step 4: Commit**

```bash
git add lib/features/schedules/presentation/pages/schedule_detail_page.dart
git commit -m "fix(schedules): corrige ordem e exibe enderecos reais de volta na timeline de rota"
```

---

