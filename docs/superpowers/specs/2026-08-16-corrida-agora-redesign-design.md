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
- Wiring real de paradas (`trip_stops`) na criação da viagem — a tabela, RLS e leitura já existem no banco (migration `20260617120000_media_stops_proposals_notifications.sql`); falta só o caminho de escrita no client (`TripRequest`/`TripModel`/`TripRepositoryImpl.createTrip`). Sem migration nova.
- Passo de passageiros (ida e volta)
- Passo de pagamento
- Novo tema visual escuro para esses painéis (cores, tipografia, componentes)

**Fora do escopo (specs futuros):**
- Grupo "Agendada" (7 + 6 frames, ida e volta / somente ida)
- Grupo "Inserir endereços" (tela dedicada de busca, 3 frames)
- Grupo "Perfil motorista" (2 frames)
- **Passo de bagagem** — movido para spec/plano separado (`2026-08-16-trip-luggage-schema-redesign-design.md`), porque exige migration na tabela `trip_luggage` (novo tipo + peso) e mudanças nos 3 apps (client, prestador, web admin), não só reskin de UI.
- Qualquer outra mudança de backend/RPCs, ou no restante do app (splash, onboarding, profile, other_services) — essas telas mantêm o tema claro atual
- Navegação/roteamento (`go_router`) — as rotas existentes são mantidas

**Nota:** a skill `kz-database` (`.github/skills/kz-database/`) documenta o projeto Supabase errado (`wmlsiwjrgjygqdjtsayt`) e lista as tabelas de forma incompleta (não menciona `trip_stops`, que já existe). O projeto real, usado em `lib/main.dart`, é `mtsqeomctrqfyekyzapc`. Precisa de correção separada — não faz parte deste redesign.

## Mudança de modelo de interação

**Hoje:** a home mostra uma pílula compacta "Para onde vamos hoje?" (`_buildFakeSearchBar` em `trip_home_page.dart`). Ao tocar, abre `AddressSearchSheet` ou `RoundTripAddressSheet` como um sheet cheio de busca, deslizando de baixo para cima.

**Novo:** o painel já aparece expandido na home, mostrando direto o toggle Corrida Agora/Agendar e as linhas Partida/Destino (com botão "+" para adicionar paradas), como no Figma. Não há mais o passo intermediário de "tocar para abrir".

## Fundação visual

Screenshots reais dos 11 frames foram exportados do Figma e estão em `docs/superpowers/specs/figma-frames-corrida-agora/` (numerados na mesma ordem da tabela acima) — usados para calibrar os tokens abaixo visualmente (ainda não são valores de variável extraídos do Figma pixel a pixel, mas batem com o que se vê nas telas reais, não mais uma aproximação às cegas).

Novos tokens de cor em `AppColors`, para uso exclusivo dos painéis deste fluxo (o resto do app continua com o tema claro atual):

```dart
static const Color sheetBackground = Color(0xFF141414); // fundo do painel/app bar dos passos
static const Color sheetSurface = Color(0xFF262626);     // cards internos (linhas de endereço, paradas, toggle pill container)
static const Color sheetTextPrimary = Colors.white;
static const Color sheetTextSecondary = Color(0xFF8A8A8A); // labels "Partida", "Destino", "Parada N", "Passageiros"
```

`AppColors.highlight` (`#FEBF22`) é reaproveitado para as pills ativas (ex.: "Corrida Agora" selecionado, "Somente ida" selecionado, botão "+", botões "Avançar"/"Solicitar Corrida") — já bate com o amarelo do Figma. Texto sobre `highlight` é preto (`textPrimary`-like, bold), não branco. Tipografia mantém `OutfitBlack` (títulos) e `QuasimodoSemiBold` (corpo), sem indício de fonte diferente no Figma.

**Padrão de layout confirmado nos screenshots:**
- Painel raiz: cantos superiores arredondados (~28px), fundo `sheetBackground`, ocupa a parte inferior da tela sobre o mapa.
- Toggle Corrida Agora/Agendar: pill container `sheetSurface` com dois segmentos; o segmento ativo vira uma pill `highlight` com texto preto bold; o inativo fica transparente com texto branco.
- Card de endereço: container `sheetSurface` arredondado contendo, em sequência, a linha "Partida" (círculo cinza à esquerda como avatar/placeholder, label pequeno `sheetTextSecondary` + valor branco, botão "+" amarelo circular à direita), as linhas de parada já adicionadas (label "Parada N" + endereço, sem botão, mais compactas, separadas por linha divisória fina), e por fim a linha "Destino" (mesmo padrão da Partida, sem botão "+").
- Toggle Somente ida/Ida e volta: mesma pill de dois segmentos, mas colocado **entre** dois cards de endereço — não acima de tudo. Quando "Ida e volta" está ativo, um **segundo card de endereço** (mesma estrutura: Partida/Paradas/Destino) aparece abaixo do toggle, para a perna de volta; quando "Somente ida" está ativo, esse segundo card some.
- Telas de passo (Passageiros, Bagagem, Pagamento): trocam o painel raiz por um formato de app bar preta com seta "<" à esquerda e título centralizado branco bold, seguido do card `sheetSurface` do formulário e botão final `highlight` de largura total.
- Pagamento: lista simples de opções (PIX / Dinheiro / Máquina de cartão) dentro de um único card `sheetSurface`, cada opção é uma linha com radio circle à esquerda e texto branco, separadas por divisórias finas — não são pills/chips como no `PassengerDetailsPanel` atual.

## Arquitetura

`trip_home_page.dart` tem hoje mais de 4000 linhas e constrói o painel de endereço inline, misturado com toda a lógica de mapa, câmera, geocoding e state machine. Como parte deste redesign, extraímos a UI de apresentação de cada passo em widgets próprios — o `TripFlowStep` e os cubits existentes (`TripCreationCubit`, `PendingConfirmationsCubit`) continuam controlando o estado, só a apresentação muda de lugar:

- **`RideRequestPanel`** (novo, `lib/features/trip/presentation/widgets/`) — substitui a pílula (`_buildFakeSearchBar`) e o overlay `AddressSearchSheet`/`RoundTripAddressSheet` (`_buildSearchOverlay`) enquanto `_step == TripFlowStep.idle`. Os campos de busca (Partida/Destino/Paradas, com sugestões de autocomplete) ficam **inline dentro do próprio painel**, não atrás de um "tocar para abrir" — a UI de autocomplete hoje embutida em `AddressSearchSheet` (campos de texto + `PlacesAutocompleteService` + lista de sugestões) é movida/reaproveitada dentro do `RideRequestPanel`, mantendo os mesmos callbacks que a página já espera (`onDestinationSelected`, `onPickupSelected`, `onStopSelected`, `onConfirmAddresses`, `onSelectPickupOnMap`), sem duplicar a lógica de geocoding.
  - Toggle **Corrida Agora/Agendar**: "Corrida Agora" (padrão) mostra os cards de endereço inline descritos em "Fundação visual". "Agendar" **não** ganha UI nova neste plano — dispara a mesma cascata que hoje roda dentro de `_openSearch()` para o caminho não-flash (`SystemSettingsRepository.fetchScheduledQuoteOverride()` → `ScheduledModeChoiceSheet` → fluxo agendado existente, com o visual claro atual), via um callback `onScheduleRequested` que a página passa para o painel, reaproveitando a cascata já implementada hoje (sem alterá-la).
  - Toggle **Somente ida/Ida e volta**: alterna entre 1 e 2 cards de endereço (ver "Fundação visual"); ao trocar para "Ida e volta" com o card de volta vazio, os campos ficam em branco (sem copiar a perna de ida).
  - Paradas: mantém o limite de 3 por perna (mesmo limite do `AddressSearchSheet` atual), cada uma emitindo `onStopSelected` como hoje.
- **`PassengerDetailsPanel`** (existente) — restilizado para o tema escuro, mesma lógica de formulário (`PassengerFormData`).
- **Pagamento** — novo widget `PaymentMethodPanel`, usando o enum `payment_method` já existente (`pix`, `debit`/`credit` combinados como "Máquina de cartão", `cash` como "Dinheiro"; `billing` não aparece no Figma e fica de fora do seletor do cliente).

**Wiring de paradas:** `TripRequest` e `TripModel` ganham um campo `List<TripStop> stops` (vazio por padrão). `TripRepositoryImpl.createTrip` passa a, após criar a linha em `trips` (mesmo padrão hoje usado para `pickupAddress`/`dropoffAddress`: insere em `addresses` primeiro, pega o `id`, depois referencia), inserir uma linha em `trip_stops` por parada, com `stop_order` sequencial a partir de 1. Nenhuma RPC muda — é um insert direto client-side, igual ao que já acontece para o restante da viagem.

Nenhuma mudança de schema — todos os dados que essas telas coletam (endereços, paradas, passageiros, forma de pagamento) já têm colunas/tabelas correspondentes (`trips`, `trip_stops`, `trip_children`, `payment_method`).

## Testes

Seguindo TDD: para cada widget novo/restilizado (`RideRequestPanel`, `PaymentMethodPanel`, versão restilizada de `PassengerDetailsPanel`) e para a lógica de repositório estendida, testes cobrindo:
- Renderização dos estados visuais (pill ativa/inativa, ida vs. ida e volta)
- Callbacks disparados corretamente ao interagir (toque em endereço, adicionar parada, selecionar forma de pagamento)
- `TripRepositoryImpl.createTrip` insere as paradas na ordem correta e não insere nada quando `stops` está vazio
- Casos de borda: sem paradas, campos de passageiro vazios

## Riscos / pendências

- **Cores calibradas por inspeção visual, não por variável extraída do Figma:** o limite de chamadas do Figma MCP (plano Starter) impediu extrair as variáveis de cor exatas via API. Os tokens em "Fundação visual" foram calibrados olhando os 11 screenshots reais (`docs/superpowers/specs/figma-frames-corrida-agora/`), então devem estar próximos, mas não são hex exatos de variável Figma. Se necessário, ajustar depois de comparação lado a lado durante a implementação.
