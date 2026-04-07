# KZ Serviços - Agentes e Instruções

## Skills Disponíveis (Superpowers)

As skills do Superpowers estão instaladas em `.github/skills/`. Elas devem ser usadas automaticamente conforme o contexto:

| Skill | Quando Usar |
|-------|-------------|
| `brainstorming` | Antes de qualquer feature nova — explorar design e requisitos |
| `writing-plans` | Após brainstorming — criar plano detalhado de implementação |
| `executing-plans` | Executar plano em batch com checkpoints |
| `subagent-driven-development` | Executar plano com subagents (preferencial) |
| `test-driven-development` | SEMPRE durante implementação — RED-GREEN-REFACTOR |
| `systematic-debugging` | Qualquer bug ou comportamento inesperado |
| `verification-before-completion` | Antes de marcar QUALQUER trabalho como completo |
| `requesting-code-review` | Após completar tasks ou features |
| `receiving-code-review` | Ao receber feedback de review |
| `dispatching-parallel-agents` | Quando há 2+ tasks independentes |
| `using-git-worktrees` | Para isolar trabalho em branches |
| `finishing-a-development-branch` | Quando implementação está completa |
| `writing-skills` | Para criar novas skills personalizadas |
| `using-superpowers` | Referência sobre como o sistema de skills funciona |

## Agentes Disponíveis

### @kz-dev
Agente principal de desenvolvimento. Use para:
- Criar features completas (segue workflow brainstorm → plano → código)
- Corrigir bugs (usa systematic debugging)
- Code review
- Qualquer tarefa de desenvolvimento no projeto

## Regras Globais
1. **Skills são obrigatórias** — não opcionais. Invocar ANTES de agir.
2. **TDD é inegociável** — sem teste falhando, sem código de produção.
3. **Verificar antes de declarar completo** — rodar testes e analisar output.
4. **Comunicação em português** — código em inglês.
