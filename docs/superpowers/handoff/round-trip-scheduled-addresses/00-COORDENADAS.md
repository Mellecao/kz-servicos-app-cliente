# Coordenadas para retomar o trabalho — Ida e volta em agendamentos

> Handoff criado em 2026-08-14 porque a sessão anterior ficou sem tokens antes de iniciar a implementação. **Nenhum código foi implementado ainda** — apenas pesquisa + plano foram concluídos. Este documento é o ponto de entrada para uma nova IA/sessão continuar exatamente daqui.

## Nesta pasta

1. `01-design-spec.md` — spec original do problema (cópia de `kz-servicos-app-cliente/docs/superpowers/specs/2026-08-13-round-trip-scheduled-addresses-design.md`, que **ainda existe no local original** também, pois é um arquivo já commitado no git).
2. `02-implementation-plan.md` — plano completo de implementação, 23 tarefas, formato `writing-plans` do superpowers (checkbox `- [ ]`, código completo, sem placeholders). Este era o arquivo `kz-servicos-app-cliente/docs/superpowers/plans/2026-08-14-round-trip-scheduled-addresses-plan.md` — **foi removido do local original** (era novo/não commitado) e vive só aqui agora. Se quiser, recoloque-o em `docs/superpowers/plans/` antes de continuar (é onde a skill `writing-plans`/`subagent-driven-development` espera encontrá-lo).
3. `00-COORDENADAS.md` — este arquivo.

## Pedido original do usuário (verbatim, ainda válido)

> "eu lembro de voce ter me ajudado nisso ja, mas acessei o app e essas alterações nao estao la. ao selecionar 'ida e volta' no app cliente (temos isso em 2 lugares), o cliente se depara com uma tela de insersão de endereços, porem ele seleciona apenas um endereço, ele deve inserir manualmente, 2 endereços de ida e 2 de volta (ja que é ida e volta), o fallback padrao é o mesmo endereço de destino como de embarque e vice versa, mas o cliente pode querer alterar, alem disso, quando passa para a proxima tela de detalhes da corrida, o usaurio deve selecionar detalhes da ida e detalhes da volta, isso nao acontece ou nao é bem detalhado no app"

> "1 criar plano. adicione nas tarefas que no app prestador deve aparecer que é ida e volta, endereços de ida e endereços de volta, data e hora de ida e de volta."

O usuário depois escolheu **execução Subagent-Driven Development** (dispatch de subagentes, um por tarefa, com dupla revisão spec+qualidade) quando perguntado.

## Estado exato de onde parei

Eu tinha acabado de:
1. Escrever o plano completo (23 tarefas, ver `02-implementation-plan.md`).
2. Rodar o self-review do plano (sem placeholders, cobertura completa, nomes de campos consistentes) — **aprovado**.
3. Perguntado ao usuário Subagent-Driven vs Inline → usuário escolheu **Subagent-Driven**.
4. Invocado a skill `superpowers:subagent-driven-development`, depois `superpowers:using-git-worktrees`.
5. **Achado crítico durante a checagem de estado do git**: os 3 repositórios (`kz-servicos-web-app-fork`, `kz-servicos-app-cliente`, `kz-servicos-app-prestador`) têm mudanças não commitadas na branch `develop`. Em especial, o **kz-servicos-app-cliente** tem ~15 arquivos modificados + vários novos não rastreados que são **exatamente os arquivos que o plano trata como "já existentes"** (`price_offer_details.dart`, `awaiting_driver_content.dart`, `price_offer_content.dart`, `scheduled_direct_request_repository.dart`, `driver_selection_cubit.dart`, etc.) — aparenta ser trabalho em andamento de uma feature anterior ("fluxo premium de motorista agendado", ver `docs/superpowers/plans/2026-07-30-scheduled-driver-premium-flow.md`).
6. Perguntei ao usuário como proceder. Ele escolheu: **"Trabalhar direto na develop, sem worktree"** — ou seja, **não criar um worktree isolado**; os subagentes devem implementar diretamente em cima do estado atual (com as mudanças não commitadas preservadas) de cada repo, na branch `develop`.
7. Criei 23 tasks no TaskCreate (uma por tarefa do plano, A1-A3, B1-B15, C1-C5) para rastrear progresso.
8. Marquei a Task A1 como `in_progress` e estava prestes a despachar o primeiro subagente implementador (Task A1 — migração das colunas de retorno em `trips`) quando a sessão foi interrompida pelo usuário por falta de tokens.

**Nenhum subagente chegou a executar. Nenhum arquivo de código foi criado ou modificado por esta feature ainda.** As únicas mudanças em disco são as 23 tasks no task tracker (que não persistem entre sessões/IAs diferentes — precisam ser recriadas ou apenas usar o checklist `- [ ]` dentro do próprio plano) e este arquivo de handoff.

## Estado dos 3 repositórios (confirmado nesta sessão, pode estar desatualizado — revalide)

Todos os 3 estão na branch `develop`.

**`kz-servicos-web-app-fork`** (backend, `C:\Projetos\kz-servicos-web-app-fork\kz-servicos-web-app-fork`):
```
M src/app/layout.tsx
M supabase/.temp/cli-latest
```
Mudanças pré-existentes não relacionadas a esta feature — não mexer nelas.

**`kz-servicos-app-cliente`** (app cliente, `C:\Projetos\kz-servicos-app-cliente`):
```
M lib/features/scheduled_choose_driver/data/repositories/available_drivers_repository.dart
M lib/features/scheduled_choose_driver/data/repositories/scheduled_direct_request_repository.dart
M lib/features/scheduled_choose_driver/domain/entities/scheduled_direct_request.dart
M lib/features/scheduled_choose_driver/presentation/cubits/awaiting_response_cubit.dart
M lib/features/scheduled_choose_driver/presentation/cubits/driver_selection_cubit.dart
M lib/features/scheduled_choose_driver/presentation/pages/awaiting_driver_response_page.dart
M lib/features/scheduled_choose_driver/presentation/pages/driver_selection_page.dart
M lib/features/scheduled_choose_driver/presentation/pages/price_offer_review_page.dart
M lib/features/scheduled_choose_driver/presentation/widgets/driver_card.dart
M lib/features/trip/presentation/pages/flash_searching_page.dart
M lib/features/trip/presentation/pages/trip_home_page.dart
M lib/features/trip/presentation/widgets/driver_selection_panel.dart
M test/features/scheduled_choose_driver/domain/entities/available_driver_test.dart
M test/features/scheduled_choose_driver/domain/entities/scheduled_direct_request_test.dart
M test/features/trip/presentation/widgets/driver_selection_panel_test.dart
?? lib/features/scheduled_choose_driver/data/services/
?? lib/features/scheduled_choose_driver/domain/entities/price_offer_details.dart
?? lib/features/scheduled_choose_driver/domain/navigation/
?? lib/features/scheduled_choose_driver/presentation/widgets/awaiting_driver_content.dart
?? lib/features/scheduled_choose_driver/presentation/widgets/price_offer_content.dart
?? test/features/scheduled_choose_driver/data/
?? test/features/scheduled_choose_driver/domain/navigation/
?? test/features/scheduled_choose_driver/presentation/widgets/
?? test/features/trip/presentation/widgets/scheduled_trip_card_tap_test.dart
```
**IMPORTANTE:** esse estado não commitado é PRÉ-REQUISITO para o plano — várias tarefas do plano (B13, B14, B15, B10, B11) assumem que esses arquivos já existem com o conteúdo que foram lidos durante a pesquisa (ver seção "Arquivos já pesquisados" no plano/spec). **Não descarte, não faça `git checkout --` nem `git clean` nesses arquivos.** Antes de continuar, revalide com `git status`/`git diff` se esse estado ainda é o mesmo — pode ter mudado desde então.

**`kz-servicos-app-prestador`** (app motorista, `C:\Projetos\kz-servicos-app-prestador`):
```
M .gitignore
M android/app/google-services.json
D android/app/kz-notifica-firebase-adminsdk-fbsvc-d16e7215db.json
M android/app/src/main/AndroidManifest.xml
M android/app/src/main/res/drawable-hdpi/ic_launcher_foreground.png
(+ mais arquivos, não totalmente listados nesta sessão)
```
Parecem mudanças de configuração/assets não relacionadas à feature (possivelmente locais/geradas). Não foi investigado a fundo — revalide antes de mexer.

## Decisão de execução confirmada pelo usuário

- **Sem git worktree isolado.** Trabalhar diretamente em cada repo, na branch `develop` atual, preservando as mudanças não commitadas já existentes.
- **Subagent-Driven Development**: um subagente implementador por tarefa (do arquivo `02-implementation-plan.md`), seguido de revisão de spec compliance e depois revisão de qualidade de código, antes de marcar a tarefa como concluída e passar para a próxima. Ver a skill `superpowers:subagent-driven-development` (prompts em `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.1.0/skills/subagent-driven-development/`: `implementer-prompt.md`, `spec-reviewer-prompt.md`, `code-quality-reviewer-prompt.md`).

## Próximos passos exatos para retomar

1. Releia `02-implementation-plan.md` nesta pasta (ou mova-o de volta para `kz-servicos-app-cliente/docs/superpowers/plans/2026-08-14-round-trip-scheduled-addresses-plan.md` — é onde a skill espera encontrá-lo por convenção).
2. Revalide o `git status` dos 3 repositórios — confirme se o estado descrito acima ainda bate. Se o app cliente não tiver mais aquelas mudanças não commitadas (por ex. se foram commitadas ou descartadas entretanto), reavalie as tarefas B10, B11, B13, B14, B15 do plano, pois elas foram escritas assumindo que aqueles arquivos já existem.
3. Confirme com o usuário se a decisão "sem worktree, direto na develop" ainda vale.
4. Recrie o tracking de progresso (23 tarefas: A1-A3 backend, B1-B15 cliente, C1-C15... digo C1-C5 motorista) — pode usar o checklist `- [ ]` dentro do próprio `02-implementation-plan.md` como fonte de verdade, marcando cada passo conforme concluído.
5. Comece por **Task A1** (backend, `kz-servicos-web-app-fork`): migração + teste pgTAP para as colunas `return_pickup_address_id`/`return_dropoff_address_id` em `trips`. É a primeira tarefa do plano, sem dependências.
6. Siga a ordem do plano: Fase A (backend, 3 tarefas) → Fase B (app cliente, 15 tarefas, depende de A2 para o RPC) → Fase C (app motorista, 5 tarefas, depende conceitualmente dos dados persistidos em B mas é código Flutter independente).
7. Ao concluir a Fase A (migração do RPC), **lembre-se de atualizar a skill `kz-database`** (submodule git em `.github/skills/kz-database/`) — isso é a Task A3, já detalhada no plano, incluindo os comandos de commit/push dentro do submodule.

## Achados técnicos importantes (não redescobrir)

- A RPC atual `client_send_scheduled_direct_request` (ver `supabase/migrations/20260730140000_fix_client_send_scheduled_direct_request_scheduled_datetime.sql` no backend) tem **exatamente 7 parâmetros e ZERO consciência de ida e volta** — nem a flag `is_round_trip` é aceita hoje nesse fluxo. O plano corrige isso adicionando 4 novos parâmetros opcionais (Task A2).
- `TripRequest`/`TripModel` (fluxo scheduled_quote/agendamento automático) **já têm** `isRoundTrip`/`returnDatetime` funcionando — falta só os 2 campos de endereço de retorno (Task B4/B5/B6).
- `DriverSelectionCubit`/`ScheduledDirectRequestRepository.sendRequest()` (fluxo "escolher motorista") **não recebem nem `isRoundTrip` nem `returnDatetime` nem endereços** — bug relatado pelo usuário, corrigido nas Tasks B9-B12.
- App motorista (`TripData`) já tem `isRoundTrip`/`returnAt`, falta só endereços de retorno (Task C1) e toda a UI (`ScheduledDirectRequestCard`, `schedule_detail_page.dart`) não mostra nada de ida/volta hoje (Tasks C2-C5).
- Arquitetura do novo formulário de endereços (`RoundTripAddressForm`): reutiliza `TripAddressSearchBar` existente (ganha `hintText`/`initialText` novos — Task B1) em 4 campos empilhados, com auto-preenchimento do par de volta a partir do par de ida (e vice-versa) até o usuário editar manualmente — usa um truque de `ValueKey` derivado do `placeId` para forçar reset do `TextEditingController` interno quando o default muda (documentado em detalhe na Task B3 do plano).

## Se algo neste handoff parecer desatualizado

Este documento reflete o estado da sessão em 2026-08-14. Sempre prefira `git log`/`git status`/leitura direta dos arquivos ao que está escrito aqui se houver conflito — este handoff é um snapshot, não fonte de verdade contínua.
