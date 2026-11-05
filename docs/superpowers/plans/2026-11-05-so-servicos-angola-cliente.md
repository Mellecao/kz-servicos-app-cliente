# Só Serviços — Angola no App Cliente (F3) Implementation Plan

> **For agentic workers:** execução inline (contrato §3.5: sem perguntas). Steps com checkbox; TDD onde o repo já tem testes.

**Goal:** App Cliente em português de Angola: Kz, +244, fuso Luanda, mapa/Places em Angola, pagamentos locais, vocabulário pt-AO.

**Architecture:** Helpers únicos em `lib/core/utils/` (`formatKz`, `AngolaPhone`, `AngolaTime`) e uma constante única de suporte (`support_contact.dart`, já criada). Os pontos de uso passam a chamar esses helpers; nenhuma lógica duplicada.

**Tech Stack:** Flutter 3.41 / Dart 3.11, `intl 0.20.3`, `flutter_localizations`, `timezone`.

**Spec:** `C:\Users\v27me\orca\workspaces\kz-servicos-web-app-fork\tellin\docs\superpowers\specs\2026-11-05-so-servicos-reativacao-design.md` (§3, §5)

## Global Constraints

- Moeda: `1.500,00 Kz` (milhar `.`, decimal `,`, sufixo ` Kz`); um único `formatKz(num)`; zero `R$`.
- Telefone: `+244 9XX XXX XXX`; móvel = 9 dígitos começados por 9; fixo de Luanda = 9 dígitos começados por 2; DDI padrão +244, sem +55/DDD.
- `intl 0.20.3` NÃO tem `pt_AO` (só `pt`, `pt_BR`, `pt_PT`) → usar `pt_PT` como fallback.
- Datas `dd/MM/yyyy`, 24 h, fuso `Africa/Luanda` (UTC+1).
- Mapa: centro `(-8.8383, 13.2344)`; Places `includedRegionCodes:["ao"]` / `components=country:ao`, idioma `pt-PT`; geocoding `region=ao`.
- Pagamento: esconder `pix`; `debit` "Multicaixa / cartão de débito"; `credit` "Cartão de crédito"; `cash` "Numerário"; `billing` "Faturação". Valores do enum não mudam.
- Vocabulário: ecrã, telemóvel, utilizador, palavra-passe, ficheiro, "Terminar sessão", "Eliminar", "viagem" (não corrida/carona), "a aguardar/à procura" (não aguardando/buscando), "equipa", "o seu". Marca "KZ" → "Só Serviços".
- NÃO renomear identificadores (`users.cpf`, slugs, `kz_trip_channel`), nem `applicationId`, nem `firebase_options.dart`.
- SEM commit/push. Não reverter alterações pré-existentes.

## Review Focus

- Arredondamento de `formatKz` (999,999 → `1.000,00 Kz`), negativos e zero.
- Colar telefone com `+244` ou com espaços: o formatter não pode duplicar o prefixo nem passar de 9 dígitos.
- Horas agendadas: `AngolaTime` soma +1 h (hoje subtrai 3 h); testes de modelos assertam o deslocamento.
- Default de pagamento `pix` em `PassengerFormData`/`TripRequest` passa a `cash` (o banco aceita `cash`).
- Textos de mocks/exemplos com cidade/instituição brasileira (Rio de Janeiro, SENAI, São Paulo).

---

### Task 1: `formatKz` (TDD)
**Files:** Create `lib/core/utils/kz_format.dart`, `test/core/utils/kz_format_test.dart`; Modify os 8 pontos com `R$` (price_offer_content, trip_history_card, driver_arrived_sheet, flash_proposal_card, flash_driver_profile_modal, trip_home_page, driver_selection_panel ×2).
**Interfaces:** Produces `String formatKz(num value)`.
- [ ] Testes: `1500 → '1.500,00 Kz'`, `0 → '0,00 Kz'`, `1234567.891 → '1.234.567,89 Kz'`, `999.999 → '1.000,00 Kz'`, `-1500 → '-1.500,00 Kz'`.
- [ ] RED → implementar → GREEN → trocar os usos; `grep -rn 'R\\$' lib` vazio.

### Task 2: Telefone angolano (TDD)
**Files:** Create `lib/core/utils/angola_phone.dart`, test; Modify `phone_input_formatter.dart` (substituir), `auth_bottom_sheet.dart`, `register_bottom_sheet.dart`.
**Interfaces:** `class AngolaPhoneInputFormatter extends TextInputFormatter` (máx. 9 dígitos, remove `244` inicial, agrupa `9XX XXX XXX`); `bool isValidAngolaPhone(String)`; `String toE164Angola(String)`.
- [ ] Testes de formatação, colagem com `+244`, e validação (9xx móvel, 2xx fixo, rejeita 8 dígitos e começos 1/3-8).
- [ ] RED → GREEN → ligar nos formulários com prefixo `+244` e rótulo "Telemóvel".

### Task 3: Fuso e datas
**Files:** Rename `brazil_time.dart` → `angola_time.dart` (`AngolaTime.fromBackend` = UTC+1); `trip_model.dart`, `scheduled_trip_model.dart`, `trip_home_page.dart` (`Africa/Luanda`), testes de modelos.
- [ ] Ajustar testes existentes para +1 h (RED) → implementar → GREEN.

### Task 4: Locale e `intl`
**Files:** `pubspec.yaml` (`flutter_localizations`), `main.dart` (`locale`, `supportedLocales`, `localizationsDelegates`, `Intl.defaultLocale='pt_PT'`).
- [ ] Teste: `MaterialApp` resolve `pt_PT`; `flutter test` verde.

### Task 5: Mapa e Places
**Files:** `places_autocomplete_service_{mobile,web}.dart`, `geocoding_*`, `directions_service_mobile.dart`, `trip_home_page.dart` (centro), mocks de coordenadas.
- [ ] Atualizar `places_autocomplete_service_mobile_test.dart` (assert `ao`/`pt-PT`) → RED → implementar → GREEN.

### Task 6: Pagamentos
**Files:** `payment_method_panel.dart`, `passenger_form_data.dart`, `trip_request.dart`, `return_details_panel.dart`, `trip_home_page.dart`.
- [ ] Esconder `pix`, rótulos §5, default `cash`; testes de entidades atualizados.

### Task 7: Vocabulário pt-AO e mocks
**Files:** todos os textos visíveis (grep por `corrida|aguardando|buscando|você|equipe|celular|usuário|senha|Sair|Excluir|tela`), `service_request_freeform_page.dart` (hint de categorias), mocks (`service_request.dart`, `mock_provider.dart`, `mock_scheduled_trip.dart`).
- [ ] Trocar texto, atualizar testes que o assertam; identificadores intactos.

### Task 8: Verificação F3
- [ ] `flutter analyze` ≤ baseline (24); `flutter test`: sem falhas novas além das 4 do baseline.
- [ ] Relatório a `tellin-52` (F2+F3).
