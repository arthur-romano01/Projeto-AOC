# Proposta de Projeto: AOCalipse (MIPS)

## 1. Identificação do Grupo e Produto
- **Nome Provisório do Produto:** AOCalipse
- **Disciplina:** Arquitetura e Organização de Computadores (AOC) — UNIFESP 2026.2
- **Link do Repositório no GitHub:** [https://github.com/arthur-romano01/Projeto-AOC](https://github.com/arthur-romano01/Projeto-AOC)
- **Integrantes:**

| Nome                          |   RA   | Email Institucional        |
| :---------------------------- | :----: | :------------------------- |
| Arthur Romano da Luz          | 168498 | arthur.romano01@unifesp.br |
| João Victor Assaoka Ribeiro   | 168863 | joao.assaoka@unifesp.br    |
| Felipe Gabriel de Santana     | 163713 | felipe.santana@unifesp.br  |
| Paulo Felipe Crot Ramos       | 169055 | paulo.crot14@unifesp.br    |
| Luís Felipe Salgado Mitidieri | 158555 | mitidieri.luis@unifesp.br  |

---

## 2. Objetivo, Público Previsto e Descrição da Interação Principal
- **Objetivo:** Criar um jogo tático de combate em turnos simultâneos para dois jogadores ou um jogador contra o computador em assembly MIPS, onde cada competidor personaliza seu chassi, gerencia recursos de energia e tenta antecipar as ações do oponente para zerar seus pontos de vida.
- **Público Previsto:** Estudantes de computação, entusiastas de jogos de estratégia em terminal e interessados em arquiteturas RISC.
- **Interação Principal:**
  1. **Seleção de Modo de Jogo:** O usuário escolhe se deseja jogar no modo **PvP** (2 jogadores humanos) ou contra o **Computador (CPU/Bot)**.
  2. **Configuração de Semente Aleatória (Seed RNG):** Caso o modo contra a CPU seja escolhido (ou para eventos procedurais), o programa solicita ao usuário um número inteiro positivo como semente do gerador de números pseudoaleatórios, permitindo partidas variadas e ao mesmo tempo determinísticas/reproduzíveis (útil para testes). Se o usuário inserir `-1`, o sistema utiliza o tempo atual do sistema (`syscall 30 - time`) como semente dinâmica.
  3. **Seleção de Chassi:** Na fase preparatória, cada jogador escolhe seu chassi entre 4 opções balanceadas (se for contra a CPU, a escolha do robô adversário e suas ações no turno são geradas via sorteio pseudoaleatório).
  4. **Rodadas de Ação:** 
     - No modo 2 jogadores: o Jogador 1 insere sua ação em segredo, a tela rola para ocultar a jogada e o Jogador 2 insere a sua ação.
     - No modo contra CPU: o jogador insere sua ação e o computador sorteia sua jogada imediatamente via `syscall 42`.
  5. **Resolução de Turno:** O programa revela ambas as ações simultaneamente, calcula custos de energia, anulação por defesa e amplificação de dano via **Sobrecarga**, informando o novo estado dos combatentes.

---

## 3. Entradas, Processamento e Saídas Esperadas com Exemplo de Uso
- **Entradas:**
  - Modo de jogo: `1` (2 Jogadores) ou `2` (Contra o Computador).
  - Semente do gerador aleatório: inteiro positivo (ex: `1234`) para reprodutibilidade ou `-1` para semente baseada no tempo do sistema.
  - Seleção de chassi: inteiros de `1` a `4`.
  - Ação no turno: `1` (Atacar), `2` (Defender), `3` (Recarregar) ou `0` (Sair).
- **Processamento:**
  - Inicialização do gerador de números pseudoaleatórios com `syscall 40` (set seed) a partir do valor informado ou obtido via `syscall 30` (time).
  - Geração de jogadas da CPU via `syscall 42` (random range).
  - Consulta aos vetores de atributos na seção `.data`.
  - Cálculo de custos de energia e acúmulo de recarga.
  - Teste de Sobrecarga: se energia `> 40`, duplica dano emitido e dano recebido via shift lógico à esquerda (`sll $reg, $reg, 1`).
  - Verificação de escudo/bloqueio defensivo (dano zerado se ação do defensor for `2`).
  - Atualização do estado e verificação de fim de jogo (`energia <= 0`).
- **Saídas:**
  - Menu inicial de seleção de modo e configuração da semente.
  - Painéis informativos com o estado da energia de cada jogador.
  - Alerta de `[SOBRECARGA ATIVA!]`.
  - Notificações de ação (`ATACAR`, `DEFENDER`, `RECARREGAR`), dano aplicado ou bloqueado.
  - Mensagem de vitória ou empate.
- **Exemplo de Uso:**
  ```text
  [MODO DE JOGO] 1 - 2 Jogadores | 2 - Contra o Computador: 2
  [SEMENTE RNG] Digite um inteiro positivo (ou -1 para tempo real): -1
  [JOGADOR 1] Selecione seu chassi: 1 (Equilibrado)
  [COMPUTADOR] Chassi sorteado: 4 (Reator Instavel)
  [RODADA 1]
  P1 escolhe: 1 (Atacar)
  CPU escolhe: 3 (Recarregar)
  -> Revelacao: P1 atacou causando 8 de dano. CPU recarregou +16 de energia.
  -> Status P1: 36 de energia | Status CPU: 48 de energia [SOBRECARGA ATIVA!]
  ```

---

## 4. Como os Requisitos de MIPS Serão Incorporados
1. **Estruturas de Dados:** Vetores de 4 inteiros (words de 32 bits) para representar os atributos dos chassis e matriz de ponteiros indexada via deslocamento (`sll`).
2. **Procedimentos Modulares:** Divisão em procedimentos dedicados (`obter_modo_jogo`, `configurar_semente`, `obter_chassi_valido`, `obter_acao_valida`, `obter_acao_cpu`, `resolver_turno`, `exibir_status_jogadores`).
3. **Pilha e Convenção de Registradores:** Uso rigoroso da pilha (`$sp`) para salvar e restaurar `$ra` e registradores `$s0-$s5` em sub-rotinas não-folha.
4. **Chamadas de Sistema (Syscalls) Avançadas:**
   - `syscall 40` (`set seed`) para inicializar o gerador RNG.
   - `syscall 42` (`random int range`) para geração de decisões e seleções da CPU de forma eficiente.
   - `syscall 30` (`time`) para capturar o tempo de sistema de 64 bits (usando os 32 bits menos significativos em `$a0` como semente) caso o usuário opte por `-1`.
5. **Instruções e Decisões:** Mínimo de 100 instruções úteis de máquina, com saltos condicionais (`beq`, `bgt`, `blez`) para validação de entrada, fluxo de IA/CPU e lógica do jogo.
6. **Mecânica com Shift Bitwise:** Uso do operador `sll` para dobrar eficientemente valores de dano na mecânica de sobrecarga.

---

## 5. Escopo Mínimo e Divisão Inicial de Tarefas
- **Escopo Mínimo:**
  - Jogo funcional no MARS 4.5 com modos PvP e PvE (contra Computador).
  - Sistema de semente (RNG reproduzível ou semente dinâmica por timestamp via syscall).
  - 4 chassis disponíveis.
  - 3 ações de combate por rodada + opção de saída limpa.
  - Tratamento de entradas inválidas.
  - Relatório de status e detecção de vitória/empate.
