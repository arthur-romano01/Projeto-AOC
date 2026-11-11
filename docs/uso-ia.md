# Relatório de Uso de Inteligência Artificial: AOCalipse

Este documento registra a utilização de ferramentas de Inteligência Artificial ao longo do desenvolvimento do projeto **AOCalipse (Duelo de Robôs em MIPS Assembly)**, cumprindo os requisitos de transparência e prestação de contas da disciplina de Arquitetura e Organização de Computadores (AOC) — UNIFESP 2026.2.

---

## 1. Ferramenta Utilizada

- **Ferramenta/Ambiente:** Google Antigravity IDE
- **Modelo de Linguagem:** Gemini 3.8 Flash (Medium) — Google DeepMind
- **Papel no Projeto:** Assistente de pair programming para auxílio em raciocínio arquitetural, implementação atômica de rotinas MIPS com base no simulador em C e resolução semântica de conflitos de versão no Git.

---

## 2. Casos de Uso Relevantes

### Caso de Uso 1: Implementação Controlada de Código MIPS (Passo a Passo com Gabarito em C)

- **Contexto:**
  O projeto dispunha de um simulador funcional de referência escrito em C (`src/main.c`), projetado para espelhar a lógica de registradores, syscalls e variáveis em memória da arquitetura MIPS. No entanto, gerar blocos massivos de Assembly de uma única vez impediria o entendimento detalhado do código e a revisão didática pela equipe.
- **Abordagem com a IA:**
  A IA foi instruída a atuar de forma estritamente controlada e atômica: a implementação de cada funcionalidade foi dividida em pequenas tarefas isoladas. Cada tarefa foi implementada individualmente, gerando diffs curtos (10 a 30 linhas), inspecionáveis e compreensíveis antes de qualquer avanço.
- **Benefício Obtido:**
  Permitiu que os estudantes mantivessem o controle total sobre o fluxo do código, compreendessem o propósito exato de cada instrução MIPS gerada (`lw`, `sw`, `sll`, `syscall`) e validassem o alinhamento com a convenção de registradores exigida pelo professor.
- **Verificação Realizada:**
  Cada micro-implementação foi revisada visualmente via `git diff`, montada e depurada passo a passo no simulador MARS 4.5 e no SPIM, verificando o correto empilhamento/desempilhamento de registradores salvos (`$s0-$s5`) e o comportamento das chamadas de sistema.

---

### Caso de Uso 2: Resolução de Conflitos de Merge em Código Monolítico via Skill Especializada

- **Contexto:**
  O projeto foi desenvolvido em torno de um único arquivo monolítico em Assembly (`src/main.asm`). Para viabilizar a colaboração simultânea, Arthur implementou o motor de combate (`resolver_turno`, mecânica de Sobrecarga e rotina `verificar_vencedor`) na branch `feat/motor-de-combate`, enquanto o João desenvolveu os modos de jogo, semente RNG, sigilo de tela e menus na branch `feat/tarefas-joao`. Ao mesclar a branch do Arthur na `main` e tentar integrá-la na branch do João, múltiplos conflitos de merge ocorreram em seções críticas do código (definições na `.data`, laço principal `loop_rodada`, captura de ações e término de partida).
- **Abordagem com a IA:**
  Utilizou-se a IA combinada à skill de automação de resolução de conflitos (`resolving-merge-conflicts`). Em vez de uma resolução cega ou descarte de alterações (`ours`/`theirs`), a IA analisou os hunks conflitantes para compreender a intenção original de cada autor:
  1. Preservou a declaração única de buffers e constantes na `.data`, eliminando duplicatas sem perder mensagens visuais.
  2. Conciliou o fluxo de ações em `fim_jogada1` e `fim_jogada2`, garantindo que tanto a ocultação de tela (`ocultar_terminal`) quanto o disparo atômico do combate (`jal resolver_turno`) fossem acionados na ordem correta.
  3. Integrou os dois tipos de encerramento da partida: saída por combate com robô destruído (`blez` acionando `verificar_vencedor`) e saída voluntária limpa por desistência (opção `0` acionando `desistencia_p1`/`desistencia_p2`).
  4. Garantia de que a rotina `resolver_turno` convivesse harmoniosamente com a versão estrita de `imprimir` na seção `.text`.
- **Benefício Obtido:**
  Eliminou o risco de perda acidental de lógica de qualquer um dos integrantes durante a unificação do arquivo monolítico, mantendo todas as funcionalidades ativas e integradas.
- **Verificação Realizada:**
  Após a resolução:
  1. Scripts automáticos verificaram a inexistência de rótulos duplicados e confirmaram que todos os alvos de saltos (`j`, `jal`, `beq`, `blez`) eram válidos.
  2. Realizou-se uma varredura para garantir que todo o arquivo permanecesse em ASCII puro (0-127), sem caracteres acentuados que causassem falhas no interpretador SPIM/SPIN.
  3. A suíte de 3 casos de teste descritos em `docs/testes.md` foi executada para comprovar que nem o combate nem a navegação de menus sofreram regressões.

---

## 3. Síntese do Nível de Intervenção Humana e Aprendizado

| Atividade | Nível de Atuação Humana | Papel da IA |
| :--- | :--- | :--- |
| **Modelagem do Jogo e Regras** | 100% Humana | Nenhuma (regras de dano, chassis, atributos e sobrecarga foram concebidos pelo grupo). |
| **Simulador em C (`src/main.c`)** | 80% Humana | Auxílio na formatação de comentários de mapeamento MIPS. |
| **Implementação MIPS (`src/main.asm`)** | 50% Humana (Direção e Revisão) | Tradução atômica instrução por instrução, sob estrita demanda passo a passo. |
| **Resolução de Merge Conflitante** | 50% Humana (Verificação e Testes) | Reconciliação semântica dos hunks conflitantes no arquivo monolítico. |
| **Validação e Testes no MARS/SPIM** | 100% Humana | Execução dos casos de teste de borda no Code Test do SPIN e depuração visual. |
