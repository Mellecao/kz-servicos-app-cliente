# Redesign do fluxo "Corrida Agora" — Design

## Contexto

O Figma [KZ-SERVICOS](https://www.figma.com/design/U6KmKVv04WyDIH5nXbwRlB/KZ-SERVICOS) (fileKey `U6KmKVv04WyDIH5nXbwRlB`) traz um novo visual para o app cliente: painéis com fundo escuro, pills em amarelo para estados ativos, cards arredondados. O arquivo tem 29 frames no total, cobrindo quatro grupos de tela: **corrida agora**, **agendada**, **inserir endereços** e **perfil motorista**. Este design cobre só o primeiro grupo; os outros três viram specs separados (ver "Fora do escopo").

Dentro do grupo "corrida agora", os 11 frames não são variações da mesma tela — são os passos sequenciais do wizard de solicitar corrida, na ordem em que aparecem no Figma:

| # | Frame (node id) | Passo | Aplica a |
|---|---|---|---|
| 1 | `corrida agora ida e volta` (63:6) / `corrida agora somente ida 1` (63:380) | Toggle Corrida Agora/Agendar + Partida/Destino | ambos |
| 2 | `corrida agora ida e volta 2` (63:40) | + Paradas (Parada 1, Parada 2) | ambos |
| 2b | `corrida agora somente ida 2` (63:405) | Toggle Somente ida/Ida e volta em destaque | ambos |
| 3 | `corrida agora ida e volta 3` (63:88) | Passageiros (Ida) | ambos |
| 4 | `corrida agora ida e volta 4` (63:194) | Bagagem (Ida) | ambos |
| 5 | `corrida agora ida e volta 5` (63:221) | Detalhes da volta (passageiros) | só ida e volta |
| 6 | `corrida agora ida e volta 6` (63:251) | Pagamento (PIX / Dinheiro / Máquina de cartão) | ambos |
| 7 | `corrida agora ida e volta 7` (63:451) | Passageiros (volta) | só ida e volta |
| 8 | `corrida agora ida e volta 8` (63:473) | Bagagem (volta) | só ida e volta |
| 9 | `corrida agora ida e volta 9` (63:519) | Pagamento (confirmação final ida e volta) | só ida e volta |

Essa sequência bate com a máquina de estados que já existe em `TripFlowStep` (`trip_home_page.dart`): `idle → passengerDetails → ... → searchingDriver`. Ou seja, o redesign é uma troca de camada de apresentação sobre um fluxo que já existe — não introduz uma feature nova.

## Objetivo

Redesenhar as telas do fluxo "corrida agora" (ida e volta e somente ida) para o visual do Figma, incluindo o novo padrão de interação: painel de solicitação sempre expandido na home, em vez da pílula "Para onde vamos hoje?" que hoje abre um sheet à parte.

## Escopo

**Dentro do escopo:**
- Painel de endereço/paradas expandido direto na home (toggle Corrida Agora/Agendar, Partida/Destino/Paradas, toggle Somente ida/Ida e volta)
- Passo de passageiros (ida e volta)
- Passo de bagagem (ida e volta)
- Passo de pagamento
- Novo tema visual escuro para esses painéis (cores, tipografia, componentes)

**Fora do escopo (specs futuros):**
- Grupo "Agendada" (7 + 6 frames, ida e volta / somente ida)
- Grupo "Inserir endereços" (tela dedicada de busca, 3 frames)
- Grupo "Perfil motorista" (2 frames)
- Qualquer mudança em lógica de negócio, backend/RPCs, ou no restante do app (splash, onboarding, profile, other_services) — essas telas mantêm o tema claro atual
- Navegação/roteamento (`go_router`) — as rotas existentes são mantidas

## Mudança de modelo de interação

**Hoje:** a home mostra uma pílula compacta "Para onde vamos hoje?" (`_buildFakeSearchBar` em `trip_home_page.dart`). Ao tocar, abre `AddressSearchSheet` ou `RoundTripAddressSheet` como um sheet cheio de busca, deslizando de baixo para cima.

**Novo:** o painel já aparece expandido na home, mostrando direto o toggle Corrida Agora/Agendar e as linhas Partida/Destino (com botão "+" para adicionar paradas), como no Figma. Não há mais o passo intermediário de "tocar para abrir".

## Fundação visual

Novos tokens de cor em `AppColors`, para uso exclusivo dos painéis deste fluxo (o resto do app continua com o tema claro atual):

```dart
static const Color sheetBackground = Color(0xFF1C1C1C); // fundo do painel
static const Color sheetSurface = Color(0xFF2A2A2A);     // cards internos (linhas de endereço, etc.)
static const Color sheetTextPrimary = Colors.white;
static const Color sheetTextSecondary = Color(0xFFADADAD);
```

Os valores exatos de `sheetBackground`/`sheetSurface`/`sheetTextSecondary` são aproximados a partir do screenshot da home (não foi possível extrair as variáveis do Figma — ver "Riscos"); devem ser calibrados por comparação visual lado a lado durante a implementação de cada tela.

`AppColors.highlight` (`#FEBF22`) é reaproveitado para as pills ativas (ex.: "Corrida Agora" selecionado, "Somente ida" selecionado) — já bate com o amarelo do Figma. Tipografia mantém `OutfitBlack` (títulos) e `QuasimodoSemiBold` (corpo), sem indício de fonte diferente no Figma.

## Arquitetura

`trip_home_page.dart` tem hoje mais de 4000 linhas e constrói o painel de endereço inline, misturado com toda a lógica de mapa, câmera, geocoding e state machine. Como parte deste redesign, extraímos a UI de apresentação de cada passo em widgets próprios — o `TripFlowStep` e os cubits existentes (`TripCreationCubit`, `PendingConfirmationsCubit`) continuam controlando o estado, só a apresentação muda de lugar:

- **`RideRequestPanel`** (novo, `lib/features/trip/presentation/widgets/`) — substitui a pílula + `_showTripTypePicker`/parte do estado idle. Renderiza toggle Corrida Agora/Agendar, linhas Partida/Destino/Paradas, toggle Somente ida/Ida e volta, no tema escuro. Recebe callbacks (`onDestinationSelected`, `onPickupSelected`, `onStopSelected`, etc.) iguais aos que `AddressSearchSheet` já expõe hoje — a lógica de autocomplete/geocoding é reaproveitada, não duplicada.
- **`PassengerDetailsPanel`** (existente) — restilizado para o tema escuro, mesma lógica de formulário (`PassengerFormData`).
- **Bagagem** — hoje não há um passo de bagagem dedicado no fluxo atual; será um novo widget `LuggageDetailsPanel` (reaproveitando `QuantitySelector` restilizado), alimentando a tabela `trip_luggage` já existente no schema.
- **Pagamento** — novo widget `PaymentMethodPanel`, usando o enum `payment_method` já existente (`pix`, `debit`/`credit` combinados como "Máquina de cartão", `cash` como "Dinheiro"; `billing` não aparece no Figma e fica de fora do seletor do cliente).

Nenhuma mudança nos repositórios, entidades de domínio ou RPCs — os dados que essas telas coletam (endereços, paradas, passageiros, bagagem, forma de pagamento) já têm colunas/tabelas correspondentes no schema (`trips`, `trip_children`, `trip_luggage`, `payment_method`).

## Testes

Seguindo TDD: para cada widget novo/restilizado (`RideRequestPanel`, `LuggageDetailsPanel`, `PaymentMethodPanel`, versão restilizada de `PassengerDetailsPanel`), testes de widget cobrindo:
- Renderização dos estados visuais (pill ativa/inativa, ida vs. ida e volta)
- Callbacks disparados corretamente ao interagir (toque em endereço, adicionar parada, selecionar forma de pagamento)
- Casos de borda: sem paradas, bagagem opcional não preenchida, campos de passageiro vazios

## Riscos / pendências

- **Limite de chamadas do Figma MCP (plano Starter):** esgotado durante o brainstorming — não foi possível extrair variáveis de cor exatas nem screenshots de todos os 11 frames. As cores em "Fundação visual" são aproximadas; a implementação de cada tela deve validar visualmente contra o Figma (aguardando reset de cota ou upgrade de plano) antes de considerar a tela concluída.
- Passo de bagagem é funcionalidade nova na UI do cliente (a tabela já existe, mas não há tela hoje) — validar com o usuário se o comportamento de "opcional" (pular sem preencher) está correto durante a implementação.
