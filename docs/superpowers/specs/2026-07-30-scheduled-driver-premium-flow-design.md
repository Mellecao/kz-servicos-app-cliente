# Fluxo Premium de Escolha de Motorista

## Objetivo

Corrigir a navegação após o aceite de uma proposta e modernizar as telas de
seleção de motorista, espera por resposta e revisão da proposta, preservando a
identidade visual clara do aplicativo KZ Serviços.

## Direção visual

O fluxo seguirá a linguagem **Editorial Premium Claro**:

- fundo gelo `AppColors.background`;
- superfícies brancas com cantos amplos, borda sutil e sombra consistente;
- amarelo KZ `AppColors.highlight` reservado para ações e indicadores;
- preto/grafite para títulos e alto contraste;
- azul `AppColors.secondary` apenas para informações auxiliares;
- tipografia do tema do aplicativo, com títulos fortes, corpo legível e escala
  coerente;
- espaçamento baseado em múltiplos de 8 dp;
- alvos de toque com no mínimo 48 dp;
- animações discretas entre 200 e 300 ms.

Não serão introduzidas novas fontes, dependências ou assets remotos.

## Navegação e comportamento

### Aceite da proposta

O caminho `/active-trip?tripId=<id>` precisa existir no `GoRouter`. A rota será
um alias autenticado para `TripHomePage`, preservando o parâmetro na URL e
permitindo que o fluxo existente recupere a corrida ativa. Essa solução também
corrige as referências já usadas pelo fluxo Flash.

Durante o aceite ou a recusa, os dois botões ficam desabilitados e o botão
acionado apresenta progresso. Falhas permanecem na própria tela com mensagem
legível, sem exibir uma página de exceção do roteador.

### Seleção de motorista

A tela terá:

1. cabeçalho editorial com botão de voltar, título e texto orientativo;
2. contador de motoristas disponíveis;
3. lista vertical de cartões amplos;
4. cada cartão exibirá foto/inicial, nome, avaliação, número de avaliações,
   veículo, cor, placa e CTA “Escolher motorista”;
5. carregamento com cartões skeleton e estado vazio com ação de voltar;
6. somente o cartão solicitado ficará em estado de progresso.

### Aguardando resposta

A tela terá:

1. cabeçalho compacto com ação de voltar para o início;
2. selo de status “Solicitação enviada”;
3. avatar e nome do motorista em um cartão central;
4. indicador de progresso visual discreto e texto explicando que o usuário
   pode continuar navegando;
5. CTA principal “Continuar navegando”;
6. ação secundária “Cancelar solicitação”, mantendo o diálogo de motivo
   opcional;
7. erro apresentado dentro do cartão, com contraste acessível.

### Proposta recebida

A tela terá:

1. selo “Nova proposta” e título de confirmação;
2. cartão do motorista com avatar e nome;
3. valor proposto como principal elemento tipográfico;
4. texto claro de que o valor só será confirmado ao aceitar;
5. CTA principal “Aceitar proposta”;
6. ação secundária “Recusar”;
7. progresso e erros no contexto da ação.

## Componentes

- `ScheduledFlowScaffold`: estrutura visual compartilhada com fundo gelo,
  cabeçalho editorial e largura adaptativa.
- `DriverIdentity`: avatar, nome e avaliação reutilizáveis.
- `DriverCard`: cartão premium da lista, mantendo a API atual.
- As páginas de espera e proposta usarão os componentes compartilhados sem
  alterar Cubits ou contratos de repositório além do necessário para feedback.

Os componentes compartilhados ficarão dentro da feature
`scheduled_choose_driver`, sem acoplar o restante do app ao novo visual.

## Responsividade e acessibilidade

- conteúdo limitado a uma largura confortável em tablets;
- uso de `SafeArea` e rolagem para telas pequenas e texto ampliado;
- nenhuma informação dependerá somente de cor;
- ícones Material terão rótulos semânticos quando forem ações;
- textos podem quebrar linha sem overflow;
- botões terão altura mínima de 52 dp.

## Testes

Serão criados testes que inicialmente falham para:

1. provar que `/active-trip?tripId=...` resolve para a tela de corrida;
2. verificar os principais textos e dados do novo cartão de motorista;
3. verificar o estado editorial de espera e suas ações;
4. verificar valor, CTAs e feedback de progresso da proposta;
5. garantir que as telas não apresentem overflow em viewport de telefone.

Depois da implementação serão executados os testes direcionados, análise
estática dos arquivos alterados, build release e instalação no emulador SDK.
