# Agendamento direto: re-check explícito e retomada da negociação

**Data:** 2026-08-17
**Status:** Aprovado
**Fluxo:** `trip_type = 'scheduled_choose_driver'` (ida e ida-e-volta)

## Objetivo

Tornar a negociação direta entre cliente e motorista completa e retomável:

1. A proposta do motorista chega ao cliente sem passar pelo administrador.
2. Quando o cliente aceita o preço, o motorista recebe um re-check; se ele confirma, a viagem é agendada.
3. A viagem aparece na lista de agendamentos assim que a solicitação é enviada, com uma tag de fase, e tocar nela devolve o cliente à etapa correta — inclusive à lista de motoristas com o botão "Cotação".
4. Passageiros, bagagens e forma de pagamento passam a ser persistidos, separados por perna (ida e volta).

## Ponto de partida

Auditoria dos três repositórios (`kz-servicos-app-cliente`, `kz-servicos-app-prestador` e `kz-servicos-web-app-fork`, onde vivem as migrations):

- **Não existe aprovação do administrador neste fluxo.** `driver_accept_scheduled_direct` grava o preço e move a viagem para `awaiting_client_confirmation` sem intermediário. A coluna `trip_driver_candidates.admin_approved` só é lida no caminho de cotação. O objetivo 1 já está satisfeito pelo código atual e este spec apenas o preserva.
- **O re-check já acontece, mas por acidente.** O trigger `require_driver_recheck_before_scheduled` intercepta qualquer transição `awaiting_client_confirmation → scheduled` e a reescreve para `awaiting_driver_confirmation`. Ou seja: `client_accept_scheduled_price` diz gravar `scheduled` e grava outra coisa.
- **O app do cliente é o único que não lê essa fase.** `scheduledDirectStatusFrom` não tem o caso `awaiting_driver_confirmation` + candidato `accepted`; ele cai no `return` final e mostra "aguardando motorista aceitar", como se o cliente nunca tivesse aceitado o preço. O app do motorista já distingue as duas fases (`TripData.isDriverRecheck`).
- **O cliente não consegue sair da tela.** `ActiveScheduledDirectGate` intercepta a rota `/trip` e devolve o cliente à tela de espera enquanto houver solicitação em aberto. Um guard equivalente em `trip_home_page.dart` faz o mesmo ao tentar iniciar outro agendamento.
- **Passageiros, bagagens e pagamento se perdem.** A UI coleta tudo, mas a RPC recebe apenas `passenger_count` e `observation`. Os dados vivem só na memória do widget.
- **O motorista altera a viagem por `UPDATE` direto.** `confirmScheduledTrip` e `rejectTrip` escrevem em `trips` sem validar dono, estado do candidato ou lock. `rejectTrip` não limpa `final_price`.

## Decisões de arquitetura

### A fase de re-check é derivada, não é um status novo

Os fluxos flash e cotação também usam `awaiting_driver_confirmation` para o re-check. Introduzir `awaiting_driver_recheck` no enum `trip_status` obrigaria a mudar os três fluxos e os três apps de uma vez, ou a conviver com duas convenções para o mesmo conceito.

A fase passa a ser lida do par `trips.status` + `trip_driver_candidates.status` — a mesma convenção que o app do motorista já adota. Não há migration de enum, os outros fluxos não são tocados, e a regra fica centralizada numa função pura coberta por teste.

Alternativa descartada: coluna `recheck_requested_at` em `trips`. Explícita sem mexer no enum, mas cria uma terceira fonte de verdade que pode divergir das outras duas.

### A viagem é criada no envio da solicitação e reaproveitada dali em diante

Nenhum rascunho é criado antes: a lista de agendamentos só mostra viagens que o cliente de fato enviou. Depois disso a mesma linha de `trips` atravessa troca de motorista, recusa e conversão para cotação. Nada é duplicado, e passageiros e bagagens permanecem pendurados na viagem em todas essas transições.

### Vários agendamentos diretos em aberto por cliente

O guard `'Voce ja tem uma solicitacao pendente'` cai. A trava passa a ser por viagem, não por cliente: uma viagem tem no máximo um candidato pendente.

## Máquina de estados

| Fase | `trips.status` | `candidate.status` | `driver_profile_id` |
|---|---|---|---|
| Sem motorista | `searching_drivers` | `rejected` ou inexistente | `NULL` |
| Aguardando motorista | `awaiting_driver_confirmation` | `pending` | preenchido |
| Proposta recebida | `awaiting_client_confirmation` | `accepted` + `offered_price` | preenchido |
| Re-check | `awaiting_driver_confirmation` | `accepted` | preenchido + `final_price` |
| Agendada | `scheduled` | `accepted` | preenchido |
| Cancelada | `cancelled` | `rejected` | preenchido |

Transições:

```
[envio]            → aguardando motorista
aguardando         → proposta recebida      (motorista aceita e precifica)
aguardando         → sem motorista          (motorista recusa)
aguardando         → aguardando (outro)     (cliente troca de motorista)
proposta recebida  → re-check               (cliente aceita o preço)
proposta recebida  → sem motorista          (cliente recusa o preço)
re-check           → agendada               (motorista confirma)
re-check           → sem motorista          (motorista desiste)
sem motorista      → aguardando             (cliente escolhe outro motorista)
qualquer negociação→ cotação                (cliente aciona "Cotação")
qualquer negociação→ cancelada              (cliente cancela)
```

## Banco de dados

Todas as funções seguem o padrão vigente: `SECURITY DEFINER`, `SET search_path = public`, `pg_advisory_xact_lock` na viagem, `REVOKE ... FROM PUBLIC, anon` e `GRANT ... TO authenticated`.

### Alterações de schema

`trip_passengers` e `trip_luggage` ganham:

```sql
leg text NOT NULL DEFAULT 'outbound' CHECK (leg IN ('outbound', 'return'))
```

O default cobre as linhas existentes, que são todas de ida. Em `trip_passengers`, a restrição `UNIQUE (trip_id, sort_order)` é substituída por `UNIQUE (trip_id, leg, sort_order)`: sem isso o primeiro passageiro da ida colide com o primeiro da volta.

As políticas de RLS das duas tabelas não mudam — elas autorizam por linha de `trips`, e a coluna nova não altera essa relação.

### `client_send_scheduled_direct_request` (alterada)

Ganha sete parâmetros, **todos com `DEFAULT`**:

```
payment_method_input       payment_method DEFAULT NULL
children_count_input       integer        DEFAULT 0
luggage_count_input        integer        DEFAULT 0
passengers_input           jsonb          DEFAULT '[]'
luggage_input              jsonb          DEFAULT '[]'
return_passengers_input    jsonb          DEFAULT '[]'
return_luggage_input       jsonb          DEFAULT '[]'
```

Formato: `passengers_input` é `[{"name": text, "age": int}]`; `luggage_input` é `[{"type": text, "size": text, "weight_kg": numeric?, "quantity": int}]`.

A migration precisa dar `DROP FUNCTION` na assinatura de 11 argumentos antes de criar a nova. Como o `supabase_flutter` chama RPC por nome de parâmetro, os defaults garantem que versões do app já instaladas continuem resolvendo para a função nova sem quebrar — mesma precaução da migration de ida e volta.

A função passa a atribuir a perna ela mesma, em vez de aceitar um campo `leg` vindo do cliente. Os parâmetros de volta só são aceitos quando `is_round_trip_input` é verdadeiro; caso contrário a função levanta exceção.

Depois do `INSERT INTO trips`, as linhas filhas entram numa mesma transação com `jsonb_array_elements(...) WITH ORDINALITY` alimentando `sort_order`, preservando a ordem digitada pelo cliente.

O guard `'Voce ja tem uma solicitacao pendente'` é removido.

**Por que dentro da RPC e não reaproveitando `TripDetailsPersistence`.** O caminho padrão cria a viagem e depois insere passageiros e bagagens em chamadas separadas. Reusar isso aqui seria menos código, mas neste fluxo a viagem fica visível para o motorista no instante em que a RPC retorna: se o app morrer entre as chamadas, o motorista recebe um pedido sem passageiros e precifica no escuro. Uma transação única elimina a janela. O caminho padrão não é alterado.

### `client_accept_scheduled_price` (alterada)

Passa a gravar `status = 'awaiting_driver_confirmation'` diretamente, em vez de gravar `scheduled` e depender do trigger para reescrever. Mesmo resultado, com a existência do re-check legível na própria função. O trigger permanece, servindo cotação e flash.

### `driver_reject_scheduled_direct` (alterada)

Hoje exige candidato `pending`, o que impede o motorista de recusar um re-check. Passa a aceitar `pending` ou `accepted`, e ganha `reason_input text DEFAULT NULL` para preservar o `driver_observations` que a tela do motorista já exige.

Resultado em ambos os casos: candidato `rejected`, viagem em `searching_drivers`, `driver_profile_id` e `final_price` nulos.

### `client_retarget_scheduled_direct_request(trip_id_input, driver_profile_id_input)` (nova)

Troca de motorista reaproveitando a viagem.

- Exige viagem do cliente autenticado, `trip_type = 'scheduled_choose_driver'`.
- Aceita status `searching_drivers`, ou `awaiting_driver_confirmation` com candidato `pending`. **Rejeita durante o re-check**, quando o preço já foi fechado pelos dois lados.
- Valida que o motorista destino está `approved`.
- Marca o candidato atual como `rejected`.
- Faz `INSERT ... ON CONFLICT (trip_id, driver_profile_id) DO UPDATE` para o novo candidato com `status = 'pending'`, `offered_price = NULL` e `last_push_at = now()`. O upsert é obrigatório: sem ele, voltar a um motorista já recusado viola a `UNIQUE (trip_id, driver_profile_id)`.
- Grava `driver_profile_id` e `status = 'awaiting_driver_confirmation'`.

### `client_convert_scheduled_direct_to_quote(trip_id_input)` (nova)

- Exige viagem do cliente autenticado em `awaiting_driver_confirmation`, `awaiting_client_confirmation` ou `searching_drivers`.
- Marca todos os candidatos `pending` ou `accepted` como `rejected`.
- Grava `trip_type = 'scheduled_quote'`, `status = 'open'`, `driver_profile_id = NULL`, `final_price = NULL`.

Passageiros, bagagens e endereços permanecem intactos.

### `driver_confirm_scheduled_recheck(trip_id_input, driver_observation_input)` (nova)

- Exige que o autenticado seja o motorista da viagem.
- Exige `trip_type = 'scheduled_choose_driver'`, status `awaiting_driver_confirmation` e candidato `accepted`.
- Grava `status = 'scheduled'`.
- Aceita `driver_observation_input text DEFAULT NULL`, preservando o campo que a tela do motorista já oferece.

Não chama `advance_trip_execution`: isso é do fluxo flash e não faz sentido numa viagem marcada para outra data. `driver_flash_recheck_confirm` fica intocada.

### Sem alteração

`cancel_scheduled_choose_driver_trip` já cobre os três status de negociação.

`client_reject_scheduled_price` já devolve a viagem para `searching_drivers` com `driver_profile_id` nulo e o candidato `rejected`. Não precisa limpar `final_price`: nessa fase o preço ainda vive apenas em `trip_driver_candidates.offered_price`, e só vira `final_price` quando o cliente aceita.

`driver_accept_scheduled_direct` continua como está — é ela que garante o objetivo de não haver aprovação do administrador neste fluxo.

### Códigos de erro

As RPCs levantam com `ERRCODE` próprios e mensagens estáveis, para que o app traduza por código e não por substring:

| Código | Situação |
|---|---|
| `KZ001` | Viagem não está na fase esperada |
| `KZ002` | Motorista indisponível ou não aprovado |
| `KZ003` | Operação não permitida durante o re-check |
| `KZ004` | Parâmetros de volta incoerentes com `is_round_trip_input` |

A regra de `KZ004`: quando `is_round_trip_input` é falso, `return_passengers_input` e `return_luggage_input` precisam vir vazios. Quando é verdadeiro, podem vir vazios — a volta sem passageiros nomeados é válida, já que a UI permite pular esse preenchimento.

## App do cliente

### Leitura de fase

`ScheduledDirectStatus` ganha `awaitingRecheck`, e `scheduledDirectStatusFrom` ganha o caso `awaiting_driver_confirmation` + `accepted`. Toda a UI depende apenas dessa função.

### Resolvedor de rota

`ActiveScheduledDirectGate` perde a função de gate. O redirect forçado em `/trip` é removido, junto com o guard equivalente em `trip_home_page.dart` que redireciona para o pedido em aberto ao iniciar outro agendamento — com vários pedidos permitidos, ele deixou de fazer sentido.

No lugar entra `ScheduledDirectRoutes.pathFor({tripId, status, candidateStatus})`, função pura sem dependência de `Supabase`:

| Fase | Destino |
|---|---|
| Aguardando motorista | `/scheduled-choose-driver/select` (sessão existente) |
| Sem motorista | `/scheduled-choose-driver/select` (sessão existente) |
| Proposta recebida | `/scheduled-choose-driver/price-review/{tripId}` |
| Re-check | `/scheduled-choose-driver/awaiting/{tripId}` |
| Agendada | folha de detalhes da viagem (comportamento atual) |

Consumidores: o toque na lista de agendamentos e o push de mudança de status.

### Seleção de motorista com duas sessões

`DriverSelectionPage` hoje recebe os parâmetros da viagem via `extra` e sempre cria uma viagem nova. Quem chega pela lista de agendamentos tem apenas um `tripId`.

Em vez de condicionais espalhadas pela página, entra:

```dart
sealed class DriverSelectionSession {
  Future<String> request(String driverProfileId);
  Future<void> convertToQuote();
  String? get activeDriverProfileId;
}
```

- `NewScheduledDirectSession` carrega os parâmetros da viagem e chama `sendRequest`; `convertToQuote` mantém o comportamento atual (volta ao fluxo e cria uma viagem `scheduled_quote`).
- `ExistingScheduledDirectSession` carrega o `tripId` e chama `client_retarget_scheduled_direct_request`; `convertToQuote` chama `client_convert_scheduled_direct_to_quote` e leva à lista de agendamentos.

`DriverSelectionCubit` deixa de conhecer parâmetros de viagem: ele delega à sessão. A página fica idêntica nos dois modos, e cada sessão é testável isoladamente.

### Troca de motorista com confirmação

Na sessão existente, `ActiveRequestBanner` mostra o motorista atual e a fase. Tocar "Solicitar" em outro motorista abre um diálogo nomeando os dois ("Cancelar o pedido para {atual} e enviar para {novo}?") e só então chama o retarget. Durante o re-check os botões "Solicitar" ficam desabilitados, coerente com o guard da RPC.

### Lista de agendamentos

`getScheduledTrips` passa a trazer `trip_type` e `trip_driver_candidates(status, offered_price)`. `ScheduledTrip` ganha esses campos e `ScheduledTripWidget` ganha as tags:

| Fase | Tag |
|---|---|
| Aguardando motorista | Aguardando motorista |
| Proposta recebida | Proposta recebida (destaque) |
| Re-check | Confirmação final |
| Sem motorista | Escolher motorista |
| Agendada | Agendada |

"Proposta recebida" recebe destaque visual por ser a única fase que exige ação imediata do cliente.

Não é necessário assinar `trip_driver_candidates` no realtime: toda transição de fase deste fluxo altera também `trips.status`, e `ScheduledTripsCubit` já escuta `trips` filtrando por `client_id`.

### Tela de espera

`AwaitingDriverResponsePage` passa a ter duas versões de texto conforme a fase. No re-check exibe o preço já fechado, deixando claro que o cliente aguarda uma confirmação, não um valor.

A página serve as duas fases porque é alcançada de dois jeitos: em sessão, logo após o envio da solicitação (fase "aguardando motorista"), e por rota, vinda da lista de agendamentos (fase re-check). Quem volta pela lista durante o "aguardando motorista" cai na lista de motoristas, não aqui — é lá que ele pode trocar de motorista ou acionar "Cotação", que é justamente o objetivo 3.

### Envio dos dados de passageiros e bagagens

`ScheduledDirectRequestRepository.sendRequest` ganha os parâmetros novos. `trip_home_page.dart` passa a enviar `_outboundPassengerFormData` e `_returnPassengerFormData` separadamente — hoje ele descarta um dos dois. As colunas agregadas `passenger_count`, `children_count` e `luggage_count` em `trips` continuam descrevendo a ida, que é o que o app já envia; a verdade por perna vive nas tabelas filhas.

Paradas (`trip_stops`) ficam de fora: o fluxo não as coleta na UI.

## App do motorista

### Substituição dos `UPDATE` diretos por RPC

`TripService.confirmScheduledTrip` e `TripService.rejectTrip` escrevem em `trips` sem validar dono, estado do candidato ou lock, e `rejectTrip` deixa `final_price` sujo — a viagem volta à lista de motoristas carregando o preço combinado com quem desistiu.

No caminho `scheduled_choose_driver`, `confirmScheduledTrip` passa a chamar `driver_confirm_scheduled_recheck` e `rejectTrip` passa a chamar `driver_reject_scheduled_direct`. Os demais tipos de viagem continuam como estão: cotação e flash não fazem parte deste spec.

### Passageiros e bagagens por perna

`TripData.fromMap` particiona `trip_passengers` e `trip_luggage` por `leg`. Os getters `passengerLabels` e `luggageLabels` viram quatro: ida e volta para cada tabela.

Pontos de exibição afetados:

- `TripRequestCard` — seções `_DetailList`
- `PendingTripRequestsCarousel` — seções `_CompactDetailSection`
- `ScheduleDetailPage` — seção "Passageiro e detalhes"

Rótulos: "Passageiros na ida", "Passageiros na volta", "Bagagens na ida", "Bagagens na volta". As seções de volta só são renderizadas quando `is_round_trip` é verdadeiro; caso contrário toda corrida simples ganharia cabeçalhos vazios. A `ScheduleDetailPage` já tem uma linha "Retorno" na rota, então a separação por perna se apoia no layout existente.

## Erros

Todas as RPCs novas tomam `pg_advisory_xact_lock` na viagem, serializando o caso real: o cliente aceitando o preço no mesmo instante em que o motorista desiste. Quem chega depois encontra o estado alterado e recebe `KZ001`.

Nesse caso o app não exibe erro cru. Ele refaz a busca da viagem e navega para a fase corrente pelo resolvedor de rota — do ponto de vista do cliente nada falhou, a situação mudou.

`ScheduledDirectRequestRepository` hoje identifica "já cancelada" procurando a substring `'status cancelled'` na mensagem do Postgres, o que quebra silenciosamente a cada ajuste de texto no SQL. A tradução passa a ser por `ERRCODE`, num único ponto do app.

Falhas de rede mantêm o comportamento atual: a ação é revertida no estado do cubit e o cliente vê uma mensagem com possibilidade de repetir.

## Testes

**Dart puro** (o grosso da cobertura):

- `scheduledDirectStatusFrom` — matriz completa de `trips.status` × `candidate.status`, incluindo combinações impossíveis
- `ScheduledDirectRoutes.pathFor` — uma asserção por fase
- `NewScheduledDirectSession` e `ExistingScheduledDirectSession` — cada uma chama a RPC certa com os parâmetros certos
- Tradução de `ERRCODE` para mensagem
- Montagem do payload `jsonb` de passageiros e bagagens por perna, incluindo o caso de viagem só de ida (arrays de volta vazios)

**bloc_test:**

- `DriverSelectionCubit` nos dois modos, incluindo a troca de motorista
- `AwaitingResponseCubit` na sequência proposta recebida → re-check → agendada, e na desistência do motorista durante o re-check
- `ScheduledTripsCubit` produzindo as tags corretas

**Widget:**

- Tags na lista de agendamentos
- Diálogo de confirmação de troca de motorista, e botões desabilitados durante o re-check
- Textos da tela de espera nas duas fases

**SQL** (seguindo o padrão de `supabase/tests/flash/`):

- Retarget recusado durante o re-check
- Retarget para um motorista previamente recusado (exercita o upsert)
- Conversão para cotação limpando candidatos e `final_price`
- Recusa de re-check zerando `final_price` e `driver_profile_id`
- `sort_order` por perna respeitando a nova unicidade
- Chamada da RPC de envio com a assinatura antiga (só os parâmetros de 11 argumentos), garantindo compatibilidade com apps já instalados

## Fora de escopo

Fluxo de cotação, fluxo flash, o caminho padrão de criação de viagem e o painel administrativo. O admin não requer alteração: nenhum status novo é introduzido — é justamente a vantagem de derivar a fase em vez de estender o enum.

## Repositórios afetados

| Repositório | Conteúdo |
|---|---|
| `kz-servicos-web-app-fork` | Migrations: alterações de schema, RPCs alteradas e novas, testes SQL |
| `kz-servicos-app-cliente` | Fase, resolvedor de rota, sessões de seleção, lista de agendamentos, tela de espera, envio dos dados |
| `kz-servicos-app-prestador` | Troca dos `UPDATE` diretos por RPC, exibição por perna |
