# Scheduled Driver Premium Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Corrigir a rota pós-aceite e entregar um fluxo Premium Claro para seleção, espera e proposta de motorista.

**Architecture:** O `GoRouter` receberá um alias `/active-trip` para a tela principal de corrida. A feature `scheduled_choose_driver` ganhará componentes visuais compartilhados e as três páginas serão recompostas sobre esses componentes, preservando Cubits, repositórios e regras de negócio atuais.

**Tech Stack:** Flutter, Material, flutter_bloc, go_router, flutter_test, mocktail.

---

### Task 1: Corrigir a rota da corrida ativa

**Files:**
- Modify: `lib/routes/app_router.dart`
- Modify: `test/routes/app_router_test.dart`

- [ ] **Step 1: Escrever o teste de rota**

Adicionar um teste que constrói o roteador com usuário autenticado, navega para
`/active-trip?tripId=trip-123` e verifica que `TripHomePage` é renderizada:

```dart
router.go('/active-trip?tripId=trip-123');
await tester.pumpAndSettle();
expect(find.byType(TripHomePage), findsOneWidget);
```

- [ ] **Step 2: Executar o teste e confirmar RED**

Run:

```powershell
flutter test test/routes/app_router_test.dart
```

Expected: falha `no routes for location: /active-trip`.

- [ ] **Step 3: Criar o alias autenticado**

Adicionar ao `AppRouter`:

```dart
GoRoute(
  path: '/active-trip',
  builder: (context, state) => const TripHomePage(),
),
```

- [ ] **Step 4: Executar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/routes/app_router_test.dart
```

Expected: todos os testes do arquivo aprovados.

### Task 2: Criar a fundação visual compartilhada

**Files:**
- Create: `lib/features/scheduled_choose_driver/presentation/widgets/scheduled_flow_scaffold.dart`
- Create: `lib/features/scheduled_choose_driver/presentation/widgets/driver_identity.dart`
- Create: `test/features/scheduled_choose_driver/presentation/widgets/scheduled_flow_scaffold_test.dart`

- [ ] **Step 1: Escrever testes dos componentes**

Testar que o scaffold exibe eyebrow, título, descrição, conteúdo e botão de
voltar; testar que `DriverIdentity` exibe avatar/inicial, nome, avaliação e
quantidade de avaliações.

- [ ] **Step 2: Executar os testes e confirmar RED**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/widgets/scheduled_flow_scaffold_test.dart
```

Expected: falha de compilação porque os componentes ainda não existem.

- [ ] **Step 3: Implementar os componentes mínimos**

`ScheduledFlowScaffold` deve usar `Scaffold`, `SafeArea`, fundo
`AppColors.background`, largura máxima adaptativa, rolagem opcional e cabeçalho
editorial. `DriverIdentity` deve usar `CircleAvatar`, textos de alto contraste e
ícone Material `star_rounded`.

- [ ] **Step 4: Executar os testes e confirmar GREEN**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/widgets/scheduled_flow_scaffold_test.dart
```

Expected: todos aprovados.

### Task 3: Redesenhar a seleção de motorista

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart`
- Modify: `lib/features/scheduled_choose_driver/presentation/widgets/driver_card.dart`
- Create: `test/features/scheduled_choose_driver/presentation/widgets/driver_card_test.dart`

- [ ] **Step 1: Escrever o teste do cartão premium**

Renderizar um `AvailableDriver` completo e verificar nome, nota, avaliações,
marca/modelo, cor, placa e CTA `Escolher motorista`. Verificar também spinner e
botão desabilitado quando `isLoading` for verdadeiro.

- [ ] **Step 2: Executar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/widgets/driver_card_test.dart
```

Expected: falha porque o cartão atual não mostra cor nem o novo CTA.

- [ ] **Step 3: Implementar cartão e página**

Transformar o cartão em superfície branca com raio 24, borda sutil, avatar de
64 dp, chips informativos, placa com números tabulares e botão de altura mínima
52 dp. Na página, usar `ScheduledFlowScaffold`, contador de resultados,
esqueletos de carregamento e estado vazio orientativo.

- [ ] **Step 4: Executar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/widgets/driver_card_test.dart
```

Expected: todos aprovados.

### Task 4: Redesenhar a tela de espera

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/pages/awaiting_driver_response_page.dart`
- Modify: `test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart`

- [ ] **Step 1: Escrever o teste visual da espera**

Fornecer um `AwaitingResponseCubit` com nome preenchido e verificar o selo
`SOLICITAÇÃO ENVIADA`, o título `Aguardando confirmação`, nome do motorista,
texto de orientação, `Continuar navegando` e `Cancelar solicitação`.

- [ ] **Step 2: Executar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart
```

Expected: falha nos novos textos e elementos visuais.

- [ ] **Step 3: Implementar o estado editorial**

Usar `ScheduledFlowScaffold`, cartão central branco, avatar com halo amarelo,
barra de progresso indeterminada discreta, caixa de orientação e ações
verticalizadas. Preservar todos os listeners de status e o diálogo de
cancelamento com motivo opcional.

- [ ] **Step 4: Executar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit_test.dart
```

Expected: todos aprovados.

### Task 5: Redesenhar e testar a proposta

**Files:**
- Modify: `lib/features/scheduled_choose_driver/presentation/pages/price_offer_review_page.dart`
- Create: `test/features/scheduled_choose_driver/presentation/pages/price_offer_review_page_test.dart`

- [ ] **Step 1: Escrever o teste visual da proposta**

Renderizar a página com Cubit contendo `driverName` e `offeredPrice=42.50`.
Verificar `NOVA PROPOSTA`, `R$ 42,50`, `Aceitar proposta` e `Recusar`.

- [ ] **Step 2: Executar o teste e confirmar RED**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/pages/price_offer_review_page_test.dart
```

Expected: falha porque a tela atual usa outros textos e formatação monetária.

- [ ] **Step 3: Implementar a proposta premium**

Usar `ScheduledFlowScaffold`, cartão de identidade, preço com formatação
brasileira, explicação de confirmação e ações empilhadas. Manter `_busy`,
tratamento de erro e navegação para `/active-trip?tripId=...`.

- [ ] **Step 4: Executar o teste e confirmar GREEN**

Run:

```powershell
flutter test test/features/scheduled_choose_driver/presentation/pages/price_offer_review_page_test.dart
```

Expected: todos aprovados.

### Task 6: Verificação e entrega no emulador

**Files:**
- Verify all modified files
- Build: `build/app/outputs/flutter-apk/app-release.apk`
- Copy: `C:/Projetos/apks/kz serviços.apk`

- [ ] **Step 1: Formatar somente arquivos alterados**

Run `dart format` com a lista explícita de arquivos desta feature.

- [ ] **Step 2: Executar testes direcionados**

Run:

```powershell
flutter test test/routes/app_router_test.dart test/features/scheduled_choose_driver
```

Expected: todos aprovados.

- [ ] **Step 3: Executar análise estática**

Run:

```powershell
flutter analyze lib/routes/app_router.dart lib/features/scheduled_choose_driver test/routes/app_router_test.dart test/features/scheduled_choose_driver
```

Expected: nenhuma nova ocorrência de erro.

- [ ] **Step 4: Compilar e copiar o APK**

Run:

```powershell
flutter build apk --release
Copy-Item build/app/outputs/flutter-apk/app-release.apk "C:/Projetos/apks/kz serviços.apk" -Force
```

Expected: build release concluído.

- [ ] **Step 5: Reinstalar e abrir no emulador**

Confirmar cold boot completo, executar `adb install -r`, abrir o package
`com.kzservicos.kz_servicos_app` e verificar `topResumedActivity` sem exceção
fatal de startup.
