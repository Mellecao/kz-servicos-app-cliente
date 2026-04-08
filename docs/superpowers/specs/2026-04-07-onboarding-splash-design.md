# Onboarding Splash Screen + Login — Design Spec

## Visão Geral

Tela de onboarding com 3 slides em PageView, seguida por tela de login genérica. Primeira interação do usuário com o app KZ Serviços.

## Identidade Visual

| Token            | Valor     |
|------------------|-----------|
| Background       | #F1F0F0   |
| Destaque         | #FEBF22   |
| Secundária       | #2261FE   |
| Texto            | #5C5956   |
| Fonte título     | Outfit Black |
| Fonte subtítulo  | Quasimoda SemiBold |

**Regra:** nunca usar a logo com fundo da cor destaque (#FEBF22).

## Onboarding — 3 Slides

### Layout comum de cada slide

```
┌──────────────────────────────┐
│                    [Pular]   │  ← canto superior direito (some no slide 3)
│                              │
│                              │
│      TÍTULO (Outfit Black)   │  ← centralizado
│   SUBTÍTULO (Quasimoda SB)   │
│                              │
│                              │
│        ● ○ ○                 │  ← dots indicadores
│      Próximo →               │  ← texto com seta (vira "Começar →" no slide 3)
└──────────────────────────────┘
```

### Slide 1

- **Fundo:** #FEBF22
- **Texto:** branco
- **Título:** "Solicitar serviços KZ ficou ainda mais fácil"
- **Subtítulo:** "Nosso novo APP conecta você ao motorista com poucos cliques. Rápido e prático."

### Slide 2

- **Fundo:** #2261FE
- **Texto:** branco
- **Título:** "Segurança e Confiabilidade"
- **Subtítulo:** "Continuamos moderando e monitorando 24h. Nossos afiliados passam por uma etapa rigorosa de aprovação."

### Slide 3

- **Fundo:** #F1F0F0
- **Texto:** #5C5956
- **Título:** "Agilidade para agendamento"
- **Subtítulo:** "Agendar viagens ficou rápido e prático. Conte com acompanhamento em tempo real do seu agendamento."

## Navegação e Interação

- Swipe lateral entre slides
- Botão "Pular" (canto superior direito): vai direto para `/login`. Some no slide 3.
- "Próximo →" (texto com seta, minimalista): avança para o próximo slide
- "Começar →" no slide 3: navega para `/login`
- Dots indicadores: ativo = maior/preenchido, inativo = menor/opaco
- Dots brancos nos slides 1-2, #5C5956 no slide 3

## Animação

Transição em degradê fluida entre cores de fundo ao mudar de slide:
- Interpolação de cor via `ColorTween` ou `Color.lerp`
- Duração: ~300-400ms
- A cor do fundo acompanha a posição do PageView (pixel-perfect com o scroll)

## Tela de Login (genérica)

```
┌──────────────────────────────┐
│                              │
│         [LOGO KZ]            │  ← logo centralizada no topo
│                              │
│   ┌──────────────────────┐   │
│   │  E-mail              │   │
│   └──────────────────────┘   │
│   ┌──────────────────────┐   │
│   │  Senha               │   │
│   └──────────────────────┘   │
│                              │
│   ┌──────────────────────┐   │
│   │      ENTRAR          │   │  ← botão preenchido #FEBF22, texto #5C5956
│   └──────────────────────┘   │
│                              │
│       Criar conta            │  ← link texto
│                              │
└──────────────────────────────┘
```

- **Fundo:** #F1F0F0
- **Logo:** LOGO COLORIDA PNG.png, centralizada
- **Campos:** e-mail e senha, apenas visual (sem lógica de autenticação)
- **Botão "Entrar":** fundo #FEBF22, texto #5C5956
- **"Criar conta":** texto link abaixo do botão

## Rotas (GoRouter)

| Rota          | Tela         |
|---------------|--------------|
| `/onboarding` | Onboarding   |
| `/login`      | Login        |

Rota inicial: `/onboarding`

## Estrutura de Arquivos

```
lib/
  core/
    constants/
      app_colors.dart        # constantes de cores
    theme/
      app_theme.dart          # ThemeData + fontes registradas
    widgets/                  # widgets compartilhados (vazio por ora)
  features/
    onboarding/
      presentation/
        pages/
          onboarding_page.dart
        widgets/
          onboarding_slide.dart
          onboarding_dots.dart
    auth/
      presentation/
        pages/
          login_page.dart
  routes/
    app_router.dart           # GoRouter config
  main.dart
```

## Fora de Escopo

- Lógica de autenticação
- Persistência de "já viu onboarding"
- Animações de entrada de texto/elementos dentro dos slides
- Tela de cadastro
