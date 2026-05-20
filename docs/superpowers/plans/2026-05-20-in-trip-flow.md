# In-Trip Flow — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the complete uber-like in-trip flow across webapp (financial field rework + candidate pricing), app-prestador (3D GPS navigation + Supabase integration), and app-cliente (real-time driver tracking + sub-phase map).

**Architecture:** Supabase Realtime drives all state transitions. DB migrations are blocking; webapp, app-prestador, and app-cliente tasks run in parallel after migrations complete. The driver app publishes GPS to `driver_locations` every 5s; the client app subscribes to `trips` and `driver_locations` via Realtime channels to drive sub-phase transitions (`driver_arrived_at IS NULL` → A, `IS NOT NULL` → B, `started_at IS NOT NULL` → C).

**Tech Stack:** Supabase PostgreSQL + Realtime, Flutter (`supabase_flutter`, `google_maps_flutter`, `geolocator`), Next.js 14 (TypeScript, Tailwind CSS)

**Spec:** `docs/superpowers/specs/2026-05-20-in-trip-flow-design.md`

---

## Execution Order

```
Task 1  ─── DB Migrations (BLOCKING — all other tasks depend on this)
             │
             ├── Tasks 2-3   Webapp (parallel)
             ├── Tasks 4-7   App Prestador (parallel)
             └── Tasks 8-12  App Cliente (parallel)
```

---

## File Map

### `kz-servicos-web-app`
| Action | File |
|--------|------|
| Create | `supabase/migrations/20260520120000_add_offered_price_to_candidates.sql` |
| Create | `supabase/migrations/20260520120001_add_driver_arrived_at_to_trips.sql` |
| Create | `supabase/migrations/20260520120002_enable_realtime_trips.sql` |
| Modify | `src/types/database.ts` — add `offered_price`, `driver_arrived_at` |
| Modify | `src/lib/api.ts` — add `selectTripDriver()` |
| Modify | `src/components/TripDetailModal.tsx` — remove financial inputs, update candidates |

### `kz-servicos-app-prestador`
| Action | File |
|--------|------|
| Modify | `lib/core/models/trip_data.dart` — add `tripId`, `candidateId` |
| Modify | `lib/features/home/presentation/widgets/trip_request_card.dart` — add price input |
| Create | `lib/features/trip/data/models/active_trip_data.dart` — real trip model |
| Modify | `lib/features/trip/domain/trip_phase.dart` — replace `MockTripRequest` with `ActiveTripData` |
| Modify | `lib/features/trip/presentation/pages/active_trip_page.dart` — Supabase, GPS publish, Realtime |
| Modify | `lib/features/trip/presentation/widgets/active_trip_panels.dart` — add `ArrivedAtClientPanel` |
| Modify | `lib/core/utils/custom_map_markers.dart` — add `createBlueTriangleIcon()` |

### `kz-servicos-app-cliente`
| Action | File |
|--------|------|
| Modify | `lib/features/trip/presentation/widgets/passenger_details_panel.dart` — payment selector |
| Modify | `lib/features/trip/presentation/pages/trip_home_page.dart` — Realtime, sub-phases |
| Modify | `lib/features/trip/presentation/widgets/driver_en_route_panel.dart` — sub-phase A params |
| Create | `lib/features/trip/presentation/widgets/driver_arrived_sheet.dart` — sub-phase B |

---

## Task 1: DB Migrations

**Files:**
- Create: `kz-servicos-web-app/supabase/migrations/20260520120000_add_offered_price_to_candidates.sql`
- Create: `kz-servicos-web-app/supabase/migrations/20260520120001_add_driver_arrived_at_to_trips.sql`
- Create: `kz-servicos-web-app/supabase/migrations/20260520120002_enable_realtime_trips.sql`

- [ ] **Step 1: Create migration — offered_price**

`supabase/migrations/20260520120000_add_offered_price_to_candidates.sql`:
```sql
-- +goose Up
ALTER TABLE trip_driver_candidates
  ADD COLUMN IF NOT EXISTS offered_price DECIMAL(10,2);

-- +goose Down
ALTER TABLE trip_driver_candidates
  DROP COLUMN IF EXISTS offered_price;
```

- [ ] **Step 2: Create migration — driver_arrived_at**

`supabase/migrations/20260520120001_add_driver_arrived_at_to_trips.sql`:
```sql
-- +goose Up
ALTER TABLE trips
  ADD COLUMN IF NOT EXISTS driver_arrived_at TIMESTAMPTZ;

-- +goose Down
ALTER TABLE trips
  DROP COLUMN IF EXISTS driver_arrived_at;
```

- [ ] **Step 3: Create migration — Realtime on trips**

`supabase/migrations/20260520120002_enable_realtime_trips.sql`:
```sql
-- +goose Up
ALTER PUBLICATION supabase_realtime ADD TABLE trips;

-- +goose Down
ALTER PUBLICATION supabase_realtime DROP TABLE trips;
```

- [ ] **Step 4: Apply migrations via Supabase MCP or CLI**

Using MCP tools (`mcp__supabase__apply_migration`) or locally:
```bash
supabase db push
```
Expected: 3 migrations applied with no errors.

- [ ] **Step 5: Verify columns exist**

Run in Supabase SQL editor:
```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'trip_driver_candidates' AND column_name = 'offered_price';

SELECT column_name FROM information_schema.columns
WHERE table_name = 'trips' AND column_name = 'driver_arrived_at';
```
Expected: 1 row returned for each query.

- [ ] **Step 6: Commit**

```bash
cd kz-servicos-web-app
git add supabase/migrations/
git commit -m "feat: add offered_price, driver_arrived_at, enable realtime on trips"
```

---

## Task 2: Webapp — TypeScript Types + selectTripDriver API

**Files:**
- Modify: `kz-servicos-web-app/src/types/database.ts`
- Modify: `kz-servicos-web-app/src/lib/api.ts`

- [ ] **Step 1: Add `offered_price` to TripDriverCandidate**

In `src/types/database.ts`, find the `TripDriverCandidate` interface and add the new field:
```typescript
interface TripDriverCandidate {
  id: string;
  trip_id: string;
  driver_profile_id: string;
  status: TripDriverCandidateStatus;
  offered_price: number | null;          // ADD THIS
  invited_at: string;
  responded_at: string | null;
  observations: string | null;
  created_at: string;
  driver_profiles?: DriverProfile & {
    provider_profiles?: ProviderProfile & {
      users?: User;
    };
  };
}
```

- [ ] **Step 2: Add `driver_arrived_at` to Trip**

In `src/types/database.ts`, find the `Trip` interface and add:
```typescript
  driver_arrived_at: string | null;      // ADD after started_at
```

Full context (around the area):
```typescript
  started_at: string | null;
  driver_arrived_at: string | null;      // ← ADD HERE
  finished_at: string | null;
```

- [ ] **Step 3: Add `selectTripDriver` function to api.ts**

In `src/lib/api.ts`, add after the existing `updateTripDriverCandidateStatus` function:

```typescript
export async function selectTripDriver(
  tripId: string,
  candidateId: string,
  driverProfileId: string,
  offeredPrice: number
): Promise<void> {
  const supabase = createClient();

  // 1. Assign driver and copy offered price to final_price
  const { error: tripError } = await supabase
    .from('trips')
    .update({
      driver_profile_id: driverProfileId,
      final_price: offeredPrice,
      status: 'scheduled',
    })
    .eq('id', tripId);
  if (tripError) throw new Error(tripError.message);

  // 2. Accept the selected candidate
  const { error: acceptError } = await supabase
    .from('trip_driver_candidates')
    .update({ status: 'accepted', responded_at: new Date().toISOString() })
    .eq('id', candidateId);
  if (acceptError) throw new Error(acceptError.message);

  // 3. Reject all other candidates for this trip
  const { error: rejectError } = await supabase
    .from('trip_driver_candidates')
    .update({ status: 'rejected', responded_at: new Date().toISOString() })
    .eq('trip_id', tripId)
    .neq('id', candidateId);
  if (rejectError) throw new Error(rejectError.message);
}
```

- [ ] **Step 4: Verify TypeScript compiles**

```bash
cd kz-servicos-web-app
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add src/types/database.ts src/lib/api.ts
git commit -m "feat(webapp): add offered_price type, driver_arrived_at, selectTripDriver api"
```

---

## Task 3: Webapp — TripDetailModal Refactor

**Files:**
- Modify: `kz-servicos-web-app/src/components/TripDetailModal.tsx`

- [ ] **Step 1: Remove financial editable state variables**

Find and **delete** these state declarations (near the top of the component):
```typescript
const [finalPriceInput, setFinalPriceInput] = useState(...)
const [paymentMethodInput, setPaymentMethodInput] = useState(...)
```
Also delete the `handleSaveFinancial` function entirely.

- [ ] **Step 2: Remove financial editable JSX section**

Find the JSX section that contains `finalPriceInput`, `paymentMethodInput`, and "Salvar valores" button (around lines 715-752 in the original). Replace the entire editable financial block with a read-only display:

```tsx
{/* Financeiro — read-only */}
<div className="space-y-2">
  {trip.estimated_price != null && (
    <InfoRow
      icon={<DollarSign className="w-4 h-4" />}
      label="Preço estimado"
      value={`R$ ${trip.estimated_price.toFixed(2)}`}
    />
  )}
  {trip.final_price != null && (
    <InfoRow
      icon={<DollarSign className="w-4 h-4" />}
      label="Valor final"
      value={`R$ ${trip.final_price.toFixed(2)}`}
    />
  )}
  {trip.payment_method && (
    <InfoRow
      icon={<CreditCard className="w-4 h-4" />}
      label="Pagamento"
      value={paymentMethodLabel(trip.payment_method)}
    />
  )}
  <div className="flex gap-3 mt-2">
    <button
      onClick={() => handleTogglePaid('client')}
      className={`flex-1 py-2 rounded-lg text-sm font-medium border transition-colors ${
        trip.is_paid
          ? 'bg-green-50 border-green-300 text-green-700'
          : 'bg-gray-50 border-gray-200 text-gray-500'
      }`}
    >
      {trip.is_paid ? '✓ Cliente pagou' : 'Cliente não pagou'}
    </button>
    <button
      onClick={() => handleTogglePaid('driver')}
      className={`flex-1 py-2 rounded-lg text-sm font-medium border transition-colors ${
        trip.is_driver_paied
          ? 'bg-blue-50 border-blue-300 text-blue-700'
          : 'bg-gray-50 border-gray-200 text-gray-500'
      }`}
    >
      {trip.is_driver_paied ? '✓ Motorista pago' : 'Motorista não pago'}
    </button>
  </div>
</div>
```

Add the helper at the top of the component (outside JSX):
```typescript
const paymentMethodLabel = (m: string) => ({
  pix: 'PIX', debit: 'Débito', credit: 'Crédito',
  cash: 'Dinheiro', billing: 'Faturamento',
}[m] ?? m);
```

Keep the `handleTogglePaid` function — it only toggles `is_paid` / `is_driver_paied`.

- [ ] **Step 3: Update candidates section — add offered_price display**

Find the candidate loop (around `candidates.map(...)`) and update the name + status row to include the offered price:

```tsx
{candidates.map((candidate) => {
  const driverName =
    candidate.driver_profiles?.provider_profiles?.users?.full_name ?? 'Motorista';
  const offeredPrice = candidate.offered_price;

  return (
    <div key={candidate.id} className="flex items-center gap-2 p-2 rounded-lg bg-gray-50">
      <span className="flex-1 text-sm font-medium text-gray-800">{driverName}</span>
      {offeredPrice != null ? (
        <span className="text-sm font-semibold text-green-700">
          R$ {offeredPrice.toFixed(2)}
        </span>
      ) : (
        <span className="text-xs text-gray-400 italic">Aguardando valor</span>
      )}
      {/* Selecionar button — only in searching_drivers status */}
      {trip.status === 'searching_drivers' && candidate.status === 'pending' && (
        <button
          onClick={() => handleSelectDriver(candidate)}
          disabled={offeredPrice == null}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-colors ${
            offeredPrice != null
              ? 'bg-blue-600 text-white hover:bg-blue-700'
              : 'bg-gray-200 text-gray-400 cursor-not-allowed'
          }`}
        >
          Selecionar
        </button>
      )}
      {/* Keep existing accept/reject/remove buttons for other statuses */}
      {trip.status !== 'searching_drivers' && (
        <>
          {/* existing status buttons here — no change */}
        </>
      )}
      <button
        onClick={() => handleRemoveCandidate(candidate.driver_profile_id)}
        className="p-1 text-gray-400 hover:text-red-500"
      >
        <Trash2 className="w-4 h-4" />
      </button>
    </div>
  );
})}
```

- [ ] **Step 4: Add `handleSelectDriver` function**

Add this function inside the component (after the existing candidate handlers):
```typescript
const handleSelectDriver = async (candidate: TripDriverCandidate) => {
  if (candidate.offered_price == null) return;
  try {
    await selectTripDriver(
      trip.id,
      candidate.id,
      candidate.driver_profile_id,
      candidate.offered_price
    );
    // Refresh candidates and trip data
    const [updatedCandidates, updatedTrip] = await Promise.all([
      fetchTripDriverCandidates(trip.id),
      fetchTripById(trip.id),
    ]);
    setCandidates(updatedCandidates);
    setLiveTrip(updatedTrip);
    toast.success(`Motorista selecionado — R$ ${candidate.offered_price.toFixed(2)}`);
  } catch {
    toast.error('Erro ao selecionar motorista');
  }
};
```

Import `selectTripDriver` at the top of the file:
```typescript
import { ..., selectTripDriver } from '@/lib/api';
```

- [ ] **Step 5: Verify TypeScript compiles**

```bash
cd kz-servicos-web-app
npx tsc --noEmit
```
Expected: no errors.

- [ ] **Step 6: Commit**

```bash
git add src/components/TripDetailModal.tsx
git commit -m "feat(webapp): remove editable financials, add selectTripDriver to candidates"
```

---

## Task 4: App Prestador — TripData + TripRequestCard Price Input

**Files:**
- Modify: `kz-servicos-app-prestador/lib/core/models/trip_data.dart`
- Modify: `kz-servicos-app-prestador/lib/features/home/presentation/widgets/trip_request_card.dart`
- Create: `kz-servicos-app-prestador/test/features/home/widgets/trip_request_card_test.dart`

- [ ] **Step 1: Write failing widget test**

Create `test/features/home/widgets/trip_request_card_test.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kz_servicos_prestador/core/models/trip_data.dart';
import 'package:kz_servicos_prestador/features/home/presentation/widgets/trip_request_card.dart';

final _mockTrip = TripData(
  tripId: 'trip-1',
  candidateId: 'cand-1',
  clientName: 'Ana',
  price: 85.0,
  origin: 'Rua A',
  destination: 'Rua B',
  hasChildren: false,
  childrenCount: 0,
  hasLuggage: false,
);

void main() {
  testWidgets('accept button blocked without price', (tester) async {
    double? acceptedPrice;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TripRequestCard(
          request: _mockTrip,
          onAccept: (price) => acceptedPrice = price,
          onReject: () {},
        ),
      ),
    ));
    await tester.tap(find.text('Aceitar solicitação'));
    await tester.pump();
    expect(acceptedPrice, isNull);
    expect(find.text('Informe um valor antes de aceitar'), findsOneWidget);
  });

  testWidgets('accept button works when price is filled', (tester) async {
    double? acceptedPrice;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TripRequestCard(
          request: _mockTrip,
          onAccept: (price) => acceptedPrice = price,
          onReject: () {},
        ),
      ),
    ));
    await tester.enterText(find.byKey(const Key('price_input')), '85.00');
    await tester.tap(find.text('Aceitar solicitação'));
    await tester.pump();
    expect(acceptedPrice, equals(85.0));
    expect(find.text('Informe um valor antes de aceitar'), findsNothing);
  });
}
```

- [ ] **Step 2: Run tests — verify FAIL**

```bash
cd kz-servicos-app-prestador
flutter test test/features/home/widgets/trip_request_card_test.dart
```
Expected: compilation error (TripData missing tripId/candidateId, onAccept has wrong signature).

- [ ] **Step 3: Update TripData model**

In `lib/core/models/trip_data.dart`, add `tripId` and `candidateId`:
```dart
class TripData {
  final String tripId;        // ADD
  final String candidateId;   // ADD
  final String clientName;
  final double price;
  final String origin;
  final String destination;
  final bool hasChildren;
  final int childrenCount;
  final bool hasLuggage;

  const TripData({
    required this.tripId,
    required this.candidateId,
    required this.clientName,
    required this.price,
    required this.origin,
    required this.destination,
    required this.hasChildren,
    required this.childrenCount,
    required this.hasLuggage,
  });
}
```

- [ ] **Step 4: Rewrite TripRequestCard as StatefulWidget with price input**

Replace the entire content of `trip_request_card.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kz_servicos_prestador/core/constants/app_colors.dart';
import 'package:kz_servicos_prestador/core/models/trip_data.dart';

class TripRequestCard extends StatefulWidget {
  final TripData request;
  final void Function(double price) onAccept;
  final VoidCallback onReject;

  const TripRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  State<TripRequestCard> createState() => _TripRequestCardState();
}

class _TripRequestCardState extends State<TripRequestCard>
    with SingleTickerProviderStateMixin {
  final _priceController = TextEditingController();
  bool _showError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleAccept() {
    final text = _priceController.text.trim().replaceAll(',', '.');
    final price = double.tryParse(text);
    if (price == null || price <= 0) {
      setState(() => _showError = true);
      _shakeController.forward(from: 0);
      return;
    }
    setState(() => _showError = false);
    widget.onAccept(price);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: client name
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.highlight.withValues(alpha: 0.15),
                child: Text(
                  widget.request.clientName[0],
                  style: const TextStyle(
                    fontFamily: 'OutfitBlack',
                    fontSize: 18,
                    color: AppColors.highlight,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.request.clientName,
                  style: const TextStyle(
                    fontFamily: 'OutfitBlack',
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Route
          _RoutePoint(color: AppColors.highlight, label: widget.request.origin),
          Padding(
            padding: const EdgeInsets.only(left: 7),
            child: Container(width: 2, height: 20, color: Colors.grey.shade300),
          ),
          _RoutePoint(
            color: AppColors.highlight,
            label: widget.request.destination,
            isCircle: true,
          ),

          // Extra info chips
          if (widget.request.hasChildren || widget.request.hasLuggage) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                if (widget.request.hasChildren)
                  _InfoChip(
                    icon: Icons.child_care,
                    label: '${widget.request.childrenCount} criança(s)',
                  ),
                if (widget.request.hasLuggage)
                  _InfoChip(icon: Icons.luggage, label: 'Com mala'),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // Price input
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (_, child) {
              final offset = _shakeController.isAnimating
                  ? math.sin(_shakeAnimation.value * math.pi * 6) * 6
                  : 0.0;
              return Transform.translate(
                offset: Offset(offset, 0),
                child: child,
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seu valor para esta corrida:',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const Key('price_input'),
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  onChanged: (_) {
                    if (_showError) setState(() => _showError = false);
                  },
                  decoration: InputDecoration(
                    prefixText: 'R\$  ',
                    hintText: '0,00',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _showError
                            ? Colors.red.shade400
                            : Colors.grey.shade200,
                        width: _showError ? 1.5 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _showError
                            ? Colors.red.shade400
                            : AppColors.highlight,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_showError) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Informe um valor antes de aceitar',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    side: BorderSide(color: Colors.red.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Recusar solicitação',
                    style: TextStyle(fontFamily: 'OutfitBlack', fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _handleAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2ECC71),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Aceitar solicitação',
                    style: TextStyle(fontFamily: 'OutfitBlack', fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add dart:math import at the top of file for sin() in shake animation
// import 'dart:math' as math;
```

Add `import 'dart:math' as math;` at the top of the file.

Keep `_RoutePoint` and `_InfoChip` private classes unchanged at the bottom of the file.

- [ ] **Step 5: Run tests — verify PASS**

```bash
flutter test test/features/home/widgets/trip_request_card_test.dart
```
Expected: 2 tests pass.

- [ ] **Step 6: Find all usages of `TripRequestCard` and update `onAccept` signatures**

```bash
grep -rn "onAccept:" lib/ --include="*.dart"
```
Update each call site so `onAccept` receives a `double price` parameter.

- [ ] **Step 7: Commit**

```bash
git add lib/core/models/trip_data.dart \
        lib/features/home/presentation/widgets/trip_request_card.dart \
        test/features/home/widgets/trip_request_card_test.dart
git commit -m "feat(prestador): add price input to trip request card with validation"
```

---

## Task 5: App Prestador — ActiveTripData Model + TripPhase Update

**Files:**
- Create: `kz-servicos-app-prestador/lib/features/trip/data/models/active_trip_data.dart`
- Modify: `kz-servicos-app-prestador/lib/features/trip/domain/trip_phase.dart`

- [ ] **Step 1: Create ActiveTripData model**

Create `lib/features/trip/data/models/active_trip_data.dart`:
```dart
class ActiveTripData {
  final String id;
  final String candidateId;
  final String clientName;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final int passengerCount;
  final double offeredPrice;

  const ActiveTripData({
    required this.id,
    required this.candidateId,
    required this.clientName,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.passengerCount,
    required this.offeredPrice,
  });

  factory ActiveTripData.fromSupabase(Map<String, dynamic> trip, String candidateId, double offeredPrice) {
    final pickup = trip['pickup_address'] as Map<String, dynamic>;
    final dropoff = trip['dropoff_address'] as Map<String, dynamic>;
    final clientUser = trip['users'] as Map<String, dynamic>?;

    String shortAddress(Map<String, dynamic> addr) {
      final street = addr['street'] as String? ?? '';
      final number = addr['number'] as String? ?? '';
      final neighborhood = addr['neighborhood'] as String? ?? '';
      return '$street, $number - $neighborhood';
    }

    return ActiveTripData(
      id: trip['id'] as String,
      candidateId: candidateId,
      clientName: clientUser?['full_name'] as String? ?? 'Cliente',
      pickupAddress: shortAddress(pickup),
      destinationAddress: shortAddress(dropoff),
      pickupLat: double.parse('${pickup['latitude']}'),
      pickupLng: double.parse('${pickup['longitude']}'),
      destinationLat: double.parse('${dropoff['latitude']}'),
      destinationLng: double.parse('${dropoff['longitude']}'),
      passengerCount: trip['passenger_count'] as int? ?? 1,
      offeredPrice: offeredPrice,
    );
  }
}
```

- [ ] **Step 2: Update TripPhase to use ActiveTripData**

Replace the entire content of `lib/features/trip/domain/trip_phase.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_prestador/core/constants/app_colors.dart';
import 'package:kz_servicos_prestador/features/trip/data/models/active_trip_data.dart';

enum TripPhase {
  navigatingToClient,
  arrivedAtClient,
  tripInProgress,
  tripCompleted,
}

extension TripPhaseProperties on TripPhase {
  String get title => switch (this) {
        TripPhase.navigatingToClient => 'Indo buscar passageiro',
        TripPhase.arrivedAtClient => 'Chegou ao local',
        TripPhase.tripInProgress => 'Viagem em andamento',
        TripPhase.tripCompleted => 'Viagem finalizada',
      };

  String subtitle(ActiveTripData trip) => switch (this) {
        TripPhase.navigatingToClient => trip.pickupAddress,
        TripPhase.arrivedAtClient => 'Aguardando ${trip.clientName}',
        TripPhase.tripInProgress => trip.destinationAddress,
        TripPhase.tripCompleted => 'R\$ ${trip.offeredPrice.toStringAsFixed(2)}',
      };

  Color get color => switch (this) {
        TripPhase.navigatingToClient => AppColors.secondary,
        TripPhase.arrivedAtClient => AppColors.highlight,
        TripPhase.tripInProgress => const Color(0xFF2ECC71),
        TripPhase.tripCompleted => const Color(0xFF2ECC71),
      };

  IconData get icon => switch (this) {
        TripPhase.navigatingToClient => Icons.navigation_rounded,
        TripPhase.arrivedAtClient => Icons.location_on_rounded,
        TripPhase.tripInProgress => Icons.directions_car_rounded,
        TripPhase.tripCompleted => Icons.check_circle_rounded,
      };

  String get buttonLabel => switch (this) {
        TripPhase.navigatingToClient => 'Cheguei ao local',
        TripPhase.arrivedAtClient => 'Iniciar viagem',
        TripPhase.tripInProgress => 'Finalizar viagem',
        TripPhase.tripCompleted => '',
      };

  bool get isGpsMode =>
      this == TripPhase.navigatingToClient || this == TripPhase.tripInProgress;

  bool get isActive => this != TripPhase.tripCompleted;
}
```

- [ ] **Step 3: Verify compile**

```bash
cd kz-servicos-app-prestador
flutter analyze lib/features/trip/domain/trip_phase.dart \
                lib/features/trip/data/models/active_trip_data.dart
```
Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/trip/data/models/active_trip_data.dart \
        lib/features/trip/domain/trip_phase.dart
git commit -m "feat(prestador): add ActiveTripData model, update TripPhase to remove mock dependency"
```

---

## Task 6: App Prestador — ActiveTripPage Full Refactor

**Files:**
- Modify: `kz-servicos-app-prestador/lib/features/trip/presentation/pages/active_trip_page.dart`

Replace the entire `active_trip_page.dart` with the real Supabase integration:

- [ ] **Step 1: Replace file content**

```dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kz_servicos_prestador/core/constants/app_colors.dart';
import 'package:kz_servicos_prestador/core/constants/map_styles.dart';
import 'package:kz_servicos_prestador/core/utils/custom_map_markers.dart';
import 'package:kz_servicos_prestador/core/utils/route_pulse_animator.dart';
import 'package:kz_servicos_prestador/core/widgets/circle_button.dart';
import 'package:kz_servicos_prestador/features/trip/data/models/active_trip_data.dart';
import 'package:kz_servicos_prestador/features/trip/data/services/directions_service.dart';
import 'package:kz_servicos_prestador/features/trip/domain/trip_phase.dart';
import 'package:kz_servicos_prestador/features/trip/presentation/helpers/external_nav_helper.dart';
import 'package:kz_servicos_prestador/features/trip/presentation/widgets/active_trip_panels.dart';
import 'package:kz_servicos_prestador/features/trip/presentation/widgets/phase_badge.dart';

class ActiveTripPage extends StatefulWidget {
  final ActiveTripData trip;
  const ActiveTripPage({super.key, required this.trip});

  @override
  State<ActiveTripPage> createState() => _ActiveTripPageState();
}

class _ActiveTripPageState extends State<ActiveTripPage>
    with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  TripPhase _phase = TripPhase.navigatingToClient;
  GoogleMapController? _mapController;
  int _clientRating = 0;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  final _directionsService = DirectionsService();

  LatLng _currentLocation = const LatLng(-23.5505, -46.6333);
  double _currentHeading = 0;
  StreamSubscription<Position>? _positionStream;
  Timer? _gpsPublishTimer;
  RoutePulseAnimator? _pulseAnimator;

  BitmapDescriptor? _yellowPinIcon;
  BitmapDescriptor? _yellowCircleIcon;
  BitmapDescriptor? _blueTriangleIcon;

  bool _showArrivedPopup = false;

  LatLng get _pickup =>
      LatLng(widget.trip.pickupLat, widget.trip.pickupLng);
  LatLng get _destination =>
      LatLng(widget.trip.destinationLat, widget.trip.destinationLng);

  @override
  void initState() {
    super.initState();
    _pulseAnimator = RoutePulseAnimator(vsync: this, onTick: _onPulseTick);
    _initIcons();
    _initLocationTracking();
    _startGpsPublishing();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _gpsPublishTimer?.cancel();
    _pulseAnimator?.dispose();
    super.dispose();
  }

  Future<void> _initIcons() async {
    final results = await Future.wait([
      CustomMapMarkers.createYellowPinIcon(),
      CustomMapMarkers.createYellowCircleIcon(),
      CustomMapMarkers.createBlueTriangleIcon(),
    ]);
    _yellowPinIcon = results[0];
    _yellowCircleIcon = results[1];
    _blueTriangleIcon = results[2];
    _rebuildMarkers();
    _fetchRouteForPhase();
  }

  Future<void> _initLocationTracking() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      _currentLocation = LatLng(pos.latitude, pos.longitude);
      _currentHeading = pos.heading;
      _rebuildMarkers();
      _updateCamera();
    } catch (_) {}

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate);
  }

  void _startGpsPublishing() {
    _gpsPublishTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _publishLocation();
    });
  }

  Future<void> _publishLocation() async {
    try {
      await _supabase.from('driver_locations').upsert({
        'driver_profile_id': _supabase.auth.currentUser!.id,
        'latitude': _currentLocation.latitude,
        'longitude': _currentLocation.longitude,
        'heading': _currentHeading,
        'speed': 0.0,
        'trip_id': widget.trip.id,
      }, onConflict: 'driver_profile_id');
    } catch (_) {}
  }

  void _onPositionUpdate(Position position) {
    if (!mounted) return;
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _currentHeading = position.heading;
    });
    _rebuildMarkers();
    _updateCamera();
  }

  void _updateCamera() {
    if (_mapController == null || !_phase.isGpsMode) return;
    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(
        target: _currentLocation,
        zoom: 17,
        tilt: 60,
        bearing: _currentHeading,
      )),
    );
  }

  void _rebuildMarkers() {
    final markers = <Marker>{};
    if (_blueTriangleIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('driver'),
        position: _currentLocation,
        icon: _blueTriangleIcon!,
        rotation: _currentHeading,
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 10,
      ));
    }
    if (_yellowPinIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: _pickup,
        icon: _yellowPinIcon!,
      ));
    }
    if (_yellowCircleIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('destination'),
        position: _destination,
        icon: _yellowCircleIcon!,
      ));
    }
    setState(() => _markers = markers);
  }

  Future<void> _fetchRouteForPhase() async {
    _pulseAnimator?.stop();
    LatLng target;
    Color routeColor;
    switch (_phase) {
      case TripPhase.navigatingToClient:
        target = _pickup;
        routeColor = AppColors.highlight;
      case TripPhase.tripInProgress:
        target = _destination;
        routeColor = AppColors.highlight;
      default:
        setState(() => _polylines = {});
        return;
    }
    final points = await _directionsService.fetchRoute(
      origin: _currentLocation,
      destination: target,
    );
    if (points.isEmpty || !mounted) return;
    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_glow'),
          points: points,
          color: routeColor.withValues(alpha: 0.18),
          width: 10,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: routeColor,
          width: 5,
        ),
      };
    });
    _pulseAnimator?.start(points);
  }

  void _onPulseTick() {
    if (!mounted) return;
    final pulse = _pulseAnimator!.buildPulsePolylines();
    setState(() {
      _polylines = {
        ..._polylines.where((p) =>
            p.polylineId.value != 'pulse_glow' &&
            p.polylineId.value != 'pulse_core'),
        ...pulse,
      };
    });
  }

  Future<void> _advancePhase() async {
    final nextPhase = switch (_phase) {
      TripPhase.navigatingToClient => TripPhase.arrivedAtClient,
      TripPhase.arrivedAtClient => TripPhase.tripInProgress,
      TripPhase.tripInProgress => TripPhase.tripCompleted,
      TripPhase.tripCompleted => TripPhase.tripCompleted,
    };

    // Write to Supabase on phase transitions
    if (_phase == TripPhase.navigatingToClient) {
      await _supabase
          .from('trips')
          .update({'driver_arrived_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', widget.trip.id);
      setState(() => _showArrivedPopup = true);
    } else if (_phase == TripPhase.arrivedAtClient) {
      await _supabase
          .from('trips')
          .update({'started_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', widget.trip.id);
      setState(() => _showArrivedPopup = false);
    }

    setState(() => _phase = nextPhase);

    switch (nextPhase) {
      case TripPhase.arrivedAtClient:
        _pulseAnimator?.stop();
        setState(() => _polylines = {});
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _pickup, zoom: 15),
          ),
        );
      case TripPhase.tripInProgress:
        _fetchRouteForPhase();
      case TripPhase.tripCompleted:
        _pulseAnimator?.stop();
        _positionStream?.cancel();
        _gpsPublishTimer?.cancel();
        setState(() => _polylines = {});
      default:
        break;
    }
  }

  LatLng get _navTarget =>
      (_phase == TripPhase.navigatingToClient ||
              _phase == TripPhase.arrivedAtClient)
          ? _pickup
          : _destination;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickup,
              zoom: 17,
              tilt: 60,
            ),
            style: MapStyles.standard,
            onMapCreated: (c) {
              _mapController = c;
              _updateCamera();
            },
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            top: topPadding + 8,
            left: 16,
            child: CircleButton(
              icon: Icons.arrow_back,
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            top: topPadding + 8,
            left: 64,
            right: 64,
            child: PhaseBadge(phase: _phase),
          ),
          if (_phase.isActive)
            Positioned(
              right: 16,
              bottom: 220,
              child: CircleButton(
                icon: Icons.open_in_new_rounded,
                onTap: () => showExternalNavSheet(context, _navTarget),
              ),
            ),
          // Arrived-at-client popup overlay
          if (_showArrivedPopup)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ArrivedAtClientPanel(
                trip: widget.trip,
                onStart: _advancePhase,
              ),
            )
          else
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _phase == TripPhase.tripCompleted
                  ? TripCompletedPanel(
                      price: widget.trip.offeredPrice,
                      rating: _clientRating,
                      onRatingChanged: (r) =>
                          setState(() => _clientRating = r),
                      onFinish: () => context.go('/home'),
                    )
                  : _phase != TripPhase.arrivedAtClient
                      ? ActiveTripPanel(
                          clientName: widget.trip.clientName,
                          subtitle: _phase.subtitle(widget.trip),
                          phaseColor: _phase.color,
                          buttonLabel: _phase.buttonLabel,
                          onAdvance: _advancePhase,
                          onChat: () => context.push('/chat/0'),
                          onCall: () {},
                        )
                      : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Fix any import/compile errors**

```bash
flutter analyze lib/features/trip/presentation/pages/active_trip_page.dart
```

- [ ] **Step 3: Update all usages of ActiveTripPage to pass `ActiveTripData`**

```bash
grep -rn "ActiveTripPage(" lib/ --include="*.dart"
```
Replace each `ActiveTripPage(request: mockRequest)` with `ActiveTripPage(trip: activeTripData)` where `activeTripData` is fetched from Supabase at the accept point.

In the home page where `onAccept` is called, fetch the trip and build `ActiveTripData`:
```dart
onAccept: (price) async {
  // Persist accepted offer to Supabase
  await supabase.from('trip_driver_candidates').update({
    'offered_price': price,
    'status': 'accepted',
    'responded_at': DateTime.now().toUtc().toIso8601String(),
  }).eq('id', request.candidateId);

  // Fetch trip details
  final tripData = await supabase.from('trips').select('''
    *,
    pickup_address:addresses!pickup_address_id(*),
    dropoff_address:addresses!dropoff_address_id(*),
    users!client_id(full_name)
  ''').eq('id', request.tripId).single();

  final activeTripData = ActiveTripData.fromSupabase(
    tripData,
    request.candidateId,
    price,
  );

  if (context.mounted) {
    context.push('/trip/active', extra: activeTripData);
  }
},
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/trip/presentation/pages/active_trip_page.dart
git commit -m "feat(prestador): refactor active trip page with real supabase, gps publish, phase transitions"
```

---

## Task 7: App Prestador — Blue Triangle Marker + ArrivedAtClientPanel

**Files:**
- Modify: `kz-servicos-app-prestador/lib/core/utils/custom_map_markers.dart`
- Modify: `kz-servicos-app-prestador/lib/features/trip/presentation/widgets/active_trip_panels.dart`

- [ ] **Step 1: Add `createBlueTriangleIcon` to CustomMapMarkers**

In `lib/core/utils/custom_map_markers.dart`, add after the existing methods:
```dart
static Future<BitmapDescriptor> createBlueTriangleIcon() async {
  const size = 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Blue filled triangle pointing north (up)
  final fillPaint = Paint()
    ..color = const Color(0xFF2261FE)
    ..style = PaintingStyle.fill;
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  final path = Path()
    ..moveTo(size / 2, 2)          // apex (north)
    ..lineTo(size - 4, size - 4)   // bottom right
    ..lineTo(4, size - 4)          // bottom left
    ..close();

  canvas.drawPath(path, fillPaint);
  canvas.drawPath(path, borderPaint);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
}
```

Add `import 'dart:ui' as ui;` at the top if not already present.

- [ ] **Step 2: Add ArrivedAtClientPanel to active_trip_panels.dart**

In `lib/features/trip/presentation/widgets/active_trip_panels.dart`, add after `TripCompletedPanel`:
```dart
class ArrivedAtClientPanel extends StatelessWidget {
  final ActiveTripData trip;
  final VoidCallback onStart;

  const ArrivedAtClientPanel({
    super.key,
    required this.trip,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 24, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: AppColors.highlight,
            size: 40,
          ),
          const SizedBox(height: 8),
          const Text(
            'Você chegou ao local de embarque',
            style: TextStyle(
              fontFamily: 'OutfitBlack',
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          _DetailRow(icon: Icons.person_outline, label: trip.clientName),
          const SizedBox(height: 6),
          _DetailRow(icon: Icons.flag_outlined, label: trip.destinationAddress),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.people_outline,
            label: '${trip.passengerCount} passageiro(s)',
          ),
          const SizedBox(height: 6),
          _DetailRow(
            icon: Icons.attach_money,
            label: 'R\$ ${trip.offeredPrice.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Iniciar corrida',
                style: TextStyle(fontFamily: 'OutfitBlack', fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
```

Add `import 'package:kz_servicos_prestador/features/trip/data/models/active_trip_data.dart';` at top of file.

- [ ] **Step 3: Verify compile**

```bash
flutter analyze lib/features/trip/presentation/widgets/active_trip_panels.dart \
                lib/core/utils/custom_map_markers.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/core/utils/custom_map_markers.dart \
        lib/features/trip/presentation/widgets/active_trip_panels.dart
git commit -m "feat(prestador): blue triangle map marker, arrived-at-client popup panel"
```

---

## Task 8: App Cliente — Payment Method Selector

**Files:**
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/widgets/passenger_details_panel.dart`

- [ ] **Step 1: Add payment method state variable**

Find the `_PassengerDetailsPanelState` class. Add the state variable near the top:
```dart
String _paymentMethod = 'pix'; // default
```

- [ ] **Step 2: Replace hardcoded `_buildPaymentMethod` widget**

Find the `_buildPaymentMethod()` method and replace it entirely:
```dart
Widget _buildPaymentMethod() {
  const methods = [
    ('pix', 'PIX'),
    ('debit', 'Débito'),
    ('credit', 'Crédito'),
    ('cash', 'Dinheiro'),
    ('billing', 'Faturamento'),
  ];

  return SizedBox(
    height: 40,
    child: ListView(
      scrollDirection: Axis.horizontal,
      children: methods.map((entry) {
        final (value, label) = entry;
        final selected = _paymentMethod == value;
        return GestureDetector(
          onTap: () => setState(() => _paymentMethod = value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.highlight
                  : AppColors.highlight.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected
                    ? AppColors.highlight
                    : AppColors.highlight.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'QuasimodoSemiBold',
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
```

- [ ] **Step 3: Pass selected payment method on submit**

Find the method that builds the `PassengerFormData` / `TripRequest` and submits it. Replace the hardcoded `'pix'` with `_paymentMethod`:
```dart
// Before:
paymentMethod: 'pix',
// After:
paymentMethod: _paymentMethod,
```

- [ ] **Step 4: Verify compile**

```bash
cd kz-servicos-app-cliente
flutter analyze lib/features/trip/presentation/widgets/passenger_details_panel.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/presentation/widgets/passenger_details_panel.dart
git commit -m "feat(cliente): replace hardcoded PIX with payment method selector"
```

---

## Task 9: App Cliente — Realtime Subscription + TripFlowStep.driverArrived

**Files:**
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Add `driverArrived` to TripFlowStep enum**

Find the `TripFlowStep` enum (lines 45-57) and add `driverArrived`:
```dart
enum TripFlowStep {
  idle,
  pickOnMap,
  confirmPickup,
  passengerDetails,
  searchingDriver,
  driverSelection,
  driverConfirming,
  driverEnRoute,
  driverArrived,    // ← ADD: driver is at pickup, client not yet boarded
  tripStarted,
  tripSummary,
  tripRating,
}
```

- [ ] **Step 2: Add Realtime state variables**

In `_TripHomePageState`, add these fields after the existing state variables:
```dart
// Realtime in-trip tracking
String? _activeTripId;
String? _activeDriverProfileId;
RealtimeChannel? _tripChannel;
RealtimeChannel? _driverLocationChannel;
LatLng? _liveDriverLocation;
double _liveDriverHeading = 0;
String? _activeDriverName;
```

Add import at the top if not present:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

- [ ] **Step 3: Add Realtime subscription methods**

Add these methods to `_TripHomePageState`:

```dart
void _startTripTracking(String tripId, String driverProfileId, String driverName) {
  _activeTripId = tripId;
  _activeDriverProfileId = driverProfileId;
  _activeDriverName = driverName;

  final supabase = Supabase.instance.client;

  // Subscribe to trip updates (driver_arrived_at, started_at)
  _tripChannel = supabase
      .channel('trip-$tripId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'trips',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: tripId,
        ),
        callback: _onTripUpdate,
      )
      .subscribe();

  // Subscribe to driver location updates
  _driverLocationChannel = supabase
      .channel('driver-loc-$driverProfileId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'driver_locations',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'driver_profile_id',
          value: driverProfileId,
        ),
        callback: _onDriverLocationUpdate,
      )
      .subscribe();
}

void _stopTripTracking() {
  _tripChannel?.unsubscribe();
  _driverLocationChannel?.unsubscribe();
  _tripChannel = null;
  _driverLocationChannel = null;
}

void _onTripUpdate(PostgresChangePayload payload) {
  if (!mounted) return;
  final record = payload.newRecord;
  final driverArrivedAt = record['driver_arrived_at'];
  final startedAt = record['started_at'];

  if (startedAt != null && _step != TripFlowStep.tripStarted) {
    setState(() => _step = TripFlowStep.tripStarted);
    _enterInTripMapView();
  } else if (driverArrivedAt != null && _step == TripFlowStep.driverEnRoute) {
    setState(() => _step = TripFlowStep.driverArrived);
  }
}

void _onDriverLocationUpdate(PostgresChangePayload payload) {
  if (!mounted) return;
  final record = payload.newRecord;
  final lat = (record['latitude'] as num?)?.toDouble();
  final lng = (record['longitude'] as num?)?.toDouble();
  final heading = (record['heading'] as num?)?.toDouble() ?? 0.0;
  if (lat == null || lng == null) return;
  setState(() {
    _liveDriverLocation = LatLng(lat, lng);
    _liveDriverHeading = heading;
  });
  _updateDriverMarker();
}

void _updateDriverMarker() {
  if (_liveDriverLocation == null) return;
  final driverMarker = Marker(
    markerId: const MarkerId('live_driver'),
    position: _liveDriverLocation!,
    icon: _cachedBlueDotIcon ?? BitmapDescriptor.defaultMarker,
    anchor: const Offset(0.5, 0.5),
    zIndexInt: 10,
  );
  setState(() {
    _markers = {
      ..._markers.where((m) => m.markerId.value != 'live_driver'),
      driverMarker,
    };
  });
}

Future<void> _enterInTripMapView() async {
  if (_pickupLatLng == null || _destinationLatLng == null) return;

  // Zoom out to show full route
  final bounds = LatLngBounds(
    southwest: LatLng(
      math.min(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
      math.min(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
    ),
    northeast: LatLng(
      math.max(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
      math.max(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
    ),
  );
  _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));

  // Draw yellow pulsing route pickup → destination (already exists from driverEnRoute)
  _startPulseAnimation();
}
```

- [ ] **Step 4: Call `_startTripTracking` when trip creation succeeds**

Find the `TripCreationSuccess` BlocListener handler and store the trip ID + start tracking:
```dart
// In BlocListener for TripCreationState:
if (state is TripCreationSuccess) {
  setState(() {
    _activeTripId = state.tripId;
    _isCreatingTrip = false;
  });
  // Tracking will start when trip gets to 'started' status
  // Subscribe to trip to detect when admin starts it
  _subscribeToTripStart(state.tripId);
}
```

Add `_subscribeToTripStart`:
```dart
void _subscribeToTripStart(String tripId) {
  final supabase = Supabase.instance.client;
  _tripChannel = supabase
      .channel('trip-start-$tripId')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'trips',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: tripId,
        ),
        callback: (payload) {
          final status = payload.newRecord['status'] as String?;
          final driverProfileId = payload.newRecord['driver_profile_id'] as String?;
          if (status == 'started' && driverProfileId != null) {
            _tripChannel?.unsubscribe();
            // Fetch driver name
            _fetchDriverNameAndStartTracking(tripId, driverProfileId);
          }
        },
      )
      .subscribe();
}

Future<void> _fetchDriverNameAndStartTracking(
    String tripId, String driverProfileId) async {
  try {
    final data = await Supabase.instance.client
        .from('driver_profiles')
        .select('provider_profiles(users(full_name))')
        .eq('id', driverProfileId)
        .single();
    final fullName = (data['provider_profiles']?['users']?['full_name'] as String?) ?? 'Motorista';
    if (!mounted) return;
    setState(() => _step = TripFlowStep.driverEnRoute);
    _startTripTracking(tripId, driverProfileId, fullName);
  } catch (_) {}
}
```

- [ ] **Step 5: Add dispose cleanup**

In `dispose()`, add:
```dart
_stopTripTracking();
```

- [ ] **Step 6: Verify compile**

```bash
flutter analyze lib/features/trip/presentation/pages/trip_home_page.dart
```

- [ ] **Step 7: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat(cliente): add realtime trip tracking, driverArrived step, sub-phase state"
```

---

## Task 10: App Cliente — Sub-phase A: Live Driver on Map

**Files:**
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/pages/trip_home_page.dart`
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/widgets/driver_en_route_panel.dart`

- [ ] **Step 1: Update DriverEnRoutePanel to accept driverName and eta**

In `lib/features/trip/presentation/widgets/driver_en_route_panel.dart`, find where `"está a caminho"` text is rendered. The panel already accepts `etaMinutes`. Add `driverName` parameter if not already present and use `_activeDriverName` from the page state. Verify the panel shows:
- `"(driverName) está indo até você"` when `tripStarted == false`
- Keep existing ETA display

The `DriverEnRoutePanel` widget already receives `etaMinutes` and driver info. Make sure it renders correctly for the new sub-phase A state where we pass `_activeDriverName`.

- [ ] **Step 2: Show live driver position on map during driverEnRoute**

In `_buildMap()` in `trip_home_page.dart`, the markers set already includes logic based on `_step`. Ensure `_liveDriverLocation` is added as a marker when `_step == TripFlowStep.driverEnRoute` or `_step == TripFlowStep.driverArrived`.

The `_updateDriverMarker()` method added in Task 9 already handles this via the `live_driver` marker ID.

- [ ] **Step 3: Draw driver → pickup route during sub-phase A**

Find or add the polyline rendering logic for `driverEnRoute`. Currently the code has `_driverToPickupRoute`. Replace the fake driver route with a real one drawn from `_liveDriverLocation` to `_pickupLatLng` when driver location updates:

```dart
// In _onDriverLocationUpdate, after updating marker:
if (_step == TripFlowStep.driverEnRoute && _pickupLatLng != null) {
  _fetchDriverToPickupRoute();
}
```

```dart
Future<void> _fetchDriverToPickupRoute() async {
  if (_liveDriverLocation == null || _pickupLatLng == null) return;
  final points = await _directionsService.fetchRoute(
    origin: _liveDriverLocation!,
    destination: _pickupLatLng!,
  );
  if (!mounted || points.isEmpty) return;
  setState(() {
    _polylines = {
      ..._polylines.where((p) =>
          p.polylineId.value != 'driver_route_glow' &&
          p.polylineId.value != 'driver_route'),
      Polyline(
        polylineId: const PolylineId('driver_route_glow'),
        points: points,
        color: AppColors.secondary.withValues(alpha: 0.15),
        width: 10,
      ),
      Polyline(
        polylineId: const PolylineId('driver_route'),
        points: points,
        color: AppColors.secondary,
        width: 4,
      ),
    };
  });
}
```

- [ ] **Step 4: Show DriverEnRoutePanel for driverEnRoute step**

Find the panel-building section in `build()`. Ensure `DriverEnRoutePanel` is shown when `_step == TripFlowStep.driverEnRoute`, passing `_activeDriverName` and a computed ETA (or `_driverEtaMinutes`).

- [ ] **Step 5: Commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart \
        lib/features/trip/presentation/widgets/driver_en_route_panel.dart
git commit -m "feat(cliente): sub-phase A - live driver position on map with route to pickup"
```

---

## Task 11: App Cliente — Sub-phase B: DriverArrivedSheet

**Files:**
- Create: `kz-servicos-app-cliente/lib/features/trip/presentation/widgets/driver_arrived_sheet.dart`
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Create DriverArrivedSheet widget**

Create `lib/features/trip/presentation/widgets/driver_arrived_sheet.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:kz_servicos_app/core/constants/app_colors.dart';

class DriverArrivedSheet extends StatelessWidget {
  final String driverName;

  const DriverArrivedSheet({super.key, required this.driverName});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2ECC71),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$driverName já está no local de embarque',
                  style: const TextStyle(
                    fontFamily: 'QuasimodoSemiBold',
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dirija-se ao ponto de embarque',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Show DriverArrivedSheet in trip_home_page during driverArrived step**

In the panel-building section of `build()`, add the case for `driverArrived`:
```dart
if (_step == TripFlowStep.driverArrived)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: PointerInterceptor(
      child: DriverArrivedSheet(
        driverName: _activeDriverName ?? 'Motorista',
      ),
    ),
  ),
```

Add import at the top of `trip_home_page.dart`:
```dart
import 'package:kz_servicos_app/features/trip/presentation/widgets/driver_arrived_sheet.dart';
```

- [ ] **Step 3: Verify compile**

```bash
flutter analyze lib/features/trip/presentation/widgets/driver_arrived_sheet.dart \
                lib/features/trip/presentation/pages/trip_home_page.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/trip/presentation/widgets/driver_arrived_sheet.dart \
        lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat(cliente): sub-phase B - driver arrived sheet notification"
```

---

## Task 12: App Cliente — Sub-phase C: In-Trip Map

**Files:**
- Modify: `kz-servicos-app-cliente/lib/features/trip/presentation/pages/trip_home_page.dart`

- [ ] **Step 1: Implement `_enterInTripMapView` fully**

The method was started in Task 9. Complete it:
```dart
Future<void> _enterInTripMapView() async {
  if (_pickupLatLng == null || _destinationLatLng == null) return;

  // Clear driver-to-pickup route
  setState(() {
    _polylines = _polylines.where((p) =>
        p.polylineId.value != 'driver_route' &&
        p.polylineId.value != 'driver_route_glow').toSet();
  });

  // Fetch pickup → destination route
  final points = await _directionsService.fetchRoute(
    origin: _pickupLatLng!,
    destination: _destinationLatLng!,
  );
  if (!mounted || points.isEmpty) return;

  setState(() {
    _routePoints = points;
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route_glow'),
        points: points,
        color: AppColors.highlight.withValues(alpha: 0.18),
        width: 12,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: AppColors.highlight,
        width: 5,
      ),
    };
  });

  // Start pulsing animation on the yellow route
  _startPulseAnimation();

  // Zoom camera to show full route
  final bounds = LatLngBounds(
    southwest: LatLng(
      math.min(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
      math.min(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
    ),
    northeast: LatLng(
      math.max(_pickupLatLng!.latitude, _destinationLatLng!.latitude),
      math.max(_pickupLatLng!.longitude, _destinationLatLng!.longitude),
    ),
  );
  _controller?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
}
```

- [ ] **Step 2: Update blue dot to track driver position during tripStarted**

During `tripStarted`, the blue dot (marker ID `live_driver`) already moves via `_updateDriverMarker()` called from `_onDriverLocationUpdate`. Ensure the `_cachedBlueDotIcon` (existing blue dot icon) is used here and that `_updateDriverMarker()` runs when `_step == TripFlowStep.tripStarted`.

The `_updateDriverMarker()` method from Task 9 already handles this unconditionally (it updates whenever a driver location event arrives), so no additional change needed.

- [ ] **Step 3: Show minimal panel during tripStarted sub-phase C**

Find the `tripStarted` panel rendering. Replace any existing fake-driver panel with a clean info strip:
```dart
if (_step == TripFlowStep.tripStarted)
  Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: PointerInterceptor(
      child: _buildInTripInfoStrip(),
    ),
  ),
```

```dart
Widget _buildInTripInfoStrip() {
  final bottomPadding = MediaQuery.of(context).padding.bottom;
  return Container(
    padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding + 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.highlight,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Em direção a ${_destinationAddress ?? 'destino'}',
            style: const TextStyle(
              fontFamily: 'QuasimodoSemiBold',
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 4: Handle trip `finished` status to transition out of tripStarted**

In `_onTripUpdate`, add:
```dart
final status = record['status'] as String?;
if (status == 'finished' && _step == TripFlowStep.tripStarted) {
  _stopTripTracking();
  setState(() => _step = TripFlowStep.tripSummary);
}
```

- [ ] **Step 5: Full compile check**

```bash
cd kz-servicos-app-cliente
flutter analyze lib/
```
Expected: no errors (warnings for unused variables are OK).

- [ ] **Step 6: Final commit**

```bash
git add lib/features/trip/presentation/pages/trip_home_page.dart
git commit -m "feat(cliente): sub-phase C - in-trip yellow pulsing route, blue dot, zoom-out"
```

---

## Self-Review Checklist

| Spec Requirement | Task |
|---|---|
| DB: `offered_price` in candidates | Task 1 + 2 |
| DB: `driver_arrived_at` in trips | Task 1 |
| DB: Realtime on trips | Task 1 |
| Webapp: remove `final_price` editable | Task 3 |
| Webapp: remove `payment_method` editable | Task 3 |
| Webapp: candidates show `offered_price` + Selecionar | Task 3 |
| Webapp: `selectTripDriver` atomic op | Task 2 + 3 |
| Prestador: price input in popup | Task 4 |
| Prestador: error validation bounce | Task 4 |
| Prestador: real data (no mock) | Task 5 + 6 |
| Prestador: 3D camera tilt 60 | Task 6 (already existed, preserved) |
| Prestador: blue triangle marker | Task 7 |
| Prestador: GPS publish every 5s | Task 6 |
| Prestador: `driver_arrived_at` on arrive | Task 6 |
| Prestador: `started_at` on start | Task 6 |
| Prestador: arrivedAtClient popup | Task 7 |
| Cliente: payment method selector | Task 8 |
| Cliente: Realtime subscription | Task 9 |
| Cliente: sub-phase A (driver moving) | Task 10 |
| Cliente: sub-phase B (arrived sheet) | Task 11 |
| Cliente: sub-phase C (yellow route, blue dot, zoom) | Task 12 |
| Cliente: `driverArrived` TripFlowStep | Task 9 |
