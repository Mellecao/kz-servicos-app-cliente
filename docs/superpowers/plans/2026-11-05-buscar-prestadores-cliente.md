# Buscar prestadores (Cliente) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A primeira tela do Cliente passa a ser "Buscar prestadores" (mapa + campo + autocomplete de categorias + pins de prestadores + modal + pedido direto), atrás do interruptor `trips_enabled`; a tela de viagens fica intacta.

**Architecture:** Feature nova `lib/features/provider_search/` (modelo, repositórios sobre RPC, cubits, página). A rota `/trip` continua a ser a "home" (muitos `context.go('/trip')`), mas o `builder` passa por um `HomeGate` que escolhe `TripHomePage` ou `ProviderSearchPage` conforme `TripsEnabledCubit` (falha ⇒ `false`). Nada de viagens é apagado.

**Tech Stack:** Flutter, flutter_bloc, go_router, supabase_flutter (`rpc`), google_maps_flutter (`KzMap`), geolocator, mocktail/bloc_test.

**Spec:** `docs/superpowers/specs/2026-11-05-busca-prestadores-design.md` (no repo do Painel, `tellin`), §3, §4 e §7.

## Global Constraints

- Textos visíveis em pt-AO; identificadores em inglês. Preços com `formatKz` (`1.500,00 Kz`); tempo em minutos.
- Cor da marca `AppColors.highlight` (`#FF9A52`). Sem banner no topo da home de busca.
- RPCs (já aplicados; **não** mexer no banco): `search_service_providers({p_category_id,p_lat,p_lng,p_limit=12})` e `client_request_service_from_provider({p_provider_profile_id,p_service_category_id,p_description,p_service_date,p_address_id,p_observations})` → `uuid`.
- Interruptor: `system_settings` chave `trips_enabled` (jsonb boolean); leitura falha ⇒ `false`.
- Sem localização: centro de Luanda `AppMaps.defaultCenter`.
- Zero segredos no git; sem push; `git add <caminhos>` (nunca `-A`); sem `restore/checkout/reset/clean`.

## Review Focus

- Categoria sem prestadores (lista vazia) ⇒ mensagem "Sem prestadores por perto…" e botão para outra pesquisa, sem crash.
- Erro de rede/RPC na procura ⇒ mensagem pt-AO + "Tentar novamente"; a animação não fica presa.
- Pedido duplicado/prestador indisponível ⇒ mostrar `message` do servidor tal como vem.
- Consulta com acentos/maiúsculas ("CANALIZADOR", "eletricista" ↔ "Electricista") encontra a categoria.
- Interruptor ainda a carregar ⇒ loader (nunca piscar a tela errada).

---

### Task 1: Lógica pura (filtro de categorias, intervalo em Kz, modelo do prestador)

**Files:**
- Create: `lib/features/provider_search/domain/category_search.dart`
- Create: `lib/features/provider_search/data/models/provider_search_result.dart`
- Modify: `lib/core/utils/kz_format.dart` (acrescentar `formatKzRange`)
- Test: `test/features/provider_search/domain/category_search_test.dart`, `test/features/provider_search/data/models/provider_search_result_test.dart`, `test/core/utils/kz_format_test.dart`

**Interfaces:**
- Produces: `String normalizeSearchText(String)`; `List<ServiceCategory> filterCategories(List<ServiceCategory>, String query)`;
  `String formatKzRange(num min, num max)` (`5.500 – 38.500 Kz` se inteiros, senão com centavos);
  `ProviderSearchResult.fromJson(Map<String,dynamic>)` com `providerProfileId, fullName, avatarUrl?, bio?, categoryId, categoryName, averageRating?, totalRatings, priceMin, priceMax, avgResponseMinutes, isDemo, lat, lng, distanceM` e getters `initials`, `priceRangeLabel`, `responseLabel` (`Responde em ~18 min`), `ratingLabel`.

- [ ] Teste do filtro: "canal" e "CANALIZADOR" → Canalizador; "ele" acha "Eletricista" pelo nome e a descrição "reparações elétricas" por "eletric"; query vazia → `[]`; ordem: nome que começa com a query primeiro.
- [ ] Teste do intervalo e do modelo (JSON com `num`/`String` nos números, `avatar_url` nulo, nome de uma palavra).
- [ ] Implementar os três; rodar `flutter test test/features/provider_search test/core/utils/kz_format_test.dart`.
- [ ] Commit: `git add lib/features/provider_search lib/core/utils/kz_format.dart test/...`.

### Task 2: Repositórios e cubits

**Files:**
- Create: `lib/features/provider_search/data/repositories/provider_search_repository.dart` (interface + `ProviderSearchException(message)` + impl `SupabaseProviderSearchRepository`)
- Create: `lib/features/provider_search/data/repositories/trips_enabled_repository.dart` (interface + impl; aceita `true`/`'true'`; erro ⇒ `false`)
- Create: `lib/features/provider_search/presentation/cubit/{provider_search_cubit,provider_search_state,trips_enabled_cubit}.dart`
- Test: `test/features/provider_search/presentation/cubit/*_test.dart`, `test/features/provider_search/data/repositories/*_test.dart`

**Interfaces:**
- `ProviderSearchRepository.search({required String categoryId, required double lat, required double lng, int limit = 12}) → Future<List<ProviderSearchResult>>`; `requestFromProvider({required String providerProfileId, required String categoryId, required String description}) → Future<String>`; erros viram `ProviderSearchException` com a `message` do servidor.
- `ProviderSearchCubit(repository, {Duration minSearchDuration = 2500ms})`: `search(ServiceCategory, LatLngValue)` emite `ProviderSearchSearching(category)` → (mín. 2,5 s) `ProviderSearchResults(category, providers)` ou `ProviderSearchFailure(message)`; `reset()`; `requestService(provider, description) → Future<String>`.
- `TripsEnabledCubit(repository)`: estados `TripsEnabledState.loading|enabled|disabled`; `load()`.

- [ ] Testes (bloc_test): sucesso, lista vazia, erro, duração mínima respeitada (fake async), `requestService` propaga a mensagem, `TripsEnabledCubit` com `true`, `false`, exceção ⇒ `disabled`.
- [ ] Teste do impl com `SupabaseClient` falso (mocktail) só nos parâmetros enviados ao RPC.
- [ ] Implementar; `flutter test`; commit.

### Task 3: Home pelo interruptor (rota, nav, main)

**Files:**
- Create: `lib/routes/home_gate.dart` (`HomeGate({tripBuilder, searchBuilder})`)
- Modify: `lib/routes/app_router.dart` (`/trip` → `HomeGate`; nova rota `/provider-search` fora do shell para o atalho), `lib/routes/persistent_app_shell.dart` + `lib/features/trip/presentation/widgets/trip_bottom_nav.dart` (1.º item: "Buscar"/`search` quando `trips_enabled=false`), `lib/main.dart` (provider do cubit e do repositório), `lib/features/other_services/presentation/pages/services_home_page.dart` (atalho "Buscar prestadores no mapa", só com `trips_enabled=true`)
- Test: `test/routes/home_gate_test.dart`

- [ ] Teste: `disabled` → mostra só o `searchBuilder`; `enabled` → `tripBuilder`; `loading` → indicador (nenhum dos dois); o cubit só é carregado uma vez.
- [ ] Implementar e ligar; `flutter analyze`.
- [ ] Commit.

### Task 4: Tela, animação, pins, modal e pedido

**Files:**
- Create: `lib/features/provider_search/presentation/pages/provider_search_page.dart`
- Create: `lib/features/provider_search/presentation/widgets/{service_search_bar,search_radar,provider_pin_icon,provider_details_sheet,request_description_sheet}.dart`
- Test: `test/features/provider_search/presentation/widgets/*_test.dart`

**Interfaces:**
- `ServiceSearchBar({required List<ServiceCategory> categories, required ValueChanged<ServiceCategory> onSelected})`: mesmo visual do `TripAddressSearchBar`, hint "Que serviço procura?", sugestões com ícone + nome + descrição curta.
- `SearchRadar({required String label})`: pulso concêntrico `#FF9A52` + texto "A procurar prestadores próximos…".
- `ProviderDetailsSheet({required ProviderSearchResult provider, required Future<String> Function(String description) onRequest, required void Function(String requestId) onDone})`.
- `ProviderPinIcon.build(ServiceCategory) → Future<BitmapDescriptor>` (canvas → PNG, cor da marca + ícone da categoria).

- [ ] Testes de widget: autocomplete (digita "canal", vê "Canalizador", sem acento/maiúscula; toque chama `onSelected`); sheet mostra `5.500 – 38.500 Kz`, "Responde em ~18 min", ★ e avaliações, iniciais sem foto; "Solicitar" exige descrição (botão desligado vazio) e mostra a mensagem do servidor em caso de erro; radar mostra o texto.
- [ ] Implementar a página: `KzMap` + `SafeArea` com a barra no topo (**sem** banner), localização (permissão; falha ⇒ `AppMaps.defaultCenter`), radar durante `Searching`, pins surgem em sequência (≈120 ms), `fitBounds` de todos, toque no pin abre o sheet, sucesso leva a `/services/requests/{id}`.
- [ ] `flutter analyze` (sem erros novos) + `flutter test`; commit.

### Task 5: Verificação real (emulator-5554)

- [ ] Build debug com a chave Maps via env var (nunca imprimir), instalar sem apagar dados, login `miguelm@cliente.com`.
- [ ] Fluxo: digitar "canal" → Canalizador → radar → pins → abrir um → Solicitar ao **Miguel Prestador** (descrição) → ver o pedido em Serviços/os meus pedidos; capturas de ecrã em `scratchpad`.
- [ ] Relatório ≤ 12 linhas à `tellin-52` com comandos e saídas reais.
