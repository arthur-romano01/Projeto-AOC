# Proposta de Projeto: Duelo de Robôs (MIPS)

## 1. Identificação do Grupo e Produto
- **Nome Provisório do Produto:** Duelo de Robôs (Mecha Arena MIPS)
- **Disciplina:** Arquitetura e Organização de Computadores (AOC) — UNIFESP 2026.2
- **Link do Repositório no GitHub:** [https://github.com/arthur-romano01/Projeto-AOC](https://github.com/arthur-romano01/Projeto-AOC)
- **Integrantes:**

| Nome                        |   RA   |
| --------------------------- | :----: |
| Arthur Romano da Luz        | 168498 |
| Felipe ...                  |  ...   |
| João Victor Assaoka Ribeiro | 168863 |
| Luis ...                    |  ...   |
| Paulo ...                   |  ...   |

---

## 2. Objetivo, Público Previsto e Descrição da Interação Principal
- **Objetivo:** Criar um jogo tático de combate em turnos simultâneos para dois jogadores em assembly MIPS, onde cada competidor personaliza seu chassi, gerencia recursos de energia e tenta antecipar as ações do oponente para zerar seus pontos de vida.
- **Público Previsto:** Estudantes de computação, entusiastas de jogos de estratégia em terminal e interessados em arquiteturas RISC.
- **Interação Principal:**
  1. Na fase preparatória, cada jogador escolhe seu chassi entre 4 opções balanceadas.
  2. Em cada rodada, o Jogador 1 insere sua ação em segredo no terminal Run I/O.
  3. O sistema rola a tela para impedir espionagem tática.
  4. O Jogador 2 insere sua ação em segredo.
  5. O programa revela ambas as ações simultaneamente, calcula custos de energia, anulação por defesa e amplificação de dano via **Sobrecarga**, informando o novo estado dos combatentes.

---

## 3. Entradas, Processamento e Saídas Esperadas com Exemplo de Uso
- **Entradas:**
  - Seleção de chassi: inteiros de `1` a `4`.
  - Ação no turno: `1` (Atacar), `2` (Defender), `3` (Recarregar) ou `0` (Sair).
- **Processamento:**
  - Consulta aos vetores de atributos na seção `.data`.
  - Cálculo de custos de energia e acúmulo de recarga.
  - Teste de Sobrecarga: se energia `> 40`, duplica dano emitido e dano recebido via shift lógico à esquerda (`sll $reg, $reg, 1`).
  - Verificação de escudo/bloqueio defensivo (dano zerado se ação do defensor for `2`).
  - Atualização do estado e verificação de fim de jogo (`energia <= 0`).
- **Saídas:**
  - Painéis informativos com o estado da energia de cada jogador.
  - Alerta de `[SOBRECARGA ATIVA!]`.
  - Notificações de ação (`ATACAR`, `DEFENDER`, `RECARREGAR`), dano aplicado ou bloqueado.
  - Mensagem de vitória ou empate.
- **Exemplo de Uso:**
  ```text
  [JOGADOR 1] Selecione seu chassi: 1 (Equilibrado)
  [JOGADOR 2] Selecione seu chassi: 4 (Reator Instavel)
  [RODADA 1]
  P1 escolhe: 1 (Atacar)
  P2 escolhe: 3 (Recarregar)
  -> Revelacao: P1 atacou causando 8 de dano. P2 recarregou +16 de energia.
  -> Status P1: 36 de energia | Status P2: 48 de energia [SOBRECARGA ATIVA!]
  ```

---

## 4. Como os Requisitos de MIPS Serão Incorporados
1. **Estruturas de Dados:** Vetores de 4 inteiros (words de 32 bits) para representar os atributos dos chassis e matriz de ponteiros indexada via deslocamento (`sll`).
2. **Procedimentos Modulares:** Divisão em procedimentos dedicados (`obter_chassi_valido`, `obter_acao_valida`, `carregar_perfil_chassi`, `resolver_turno`, `exibir_status_jogadores`).
3. **Pilha e Convenção de Registradores:** Uso rigoroso da pilha (`$sp`) para salvar e restaurar `$ra` e registradores `$s0-$s5` em sub-rotinas não-folha.
4. **Instruções e Decisões:** Mínimo de 100 instruções úteis de máquina, com saltos condicionais (`beq`, `bgt`, `blez`) para validação de entrada e lógica do jogo.
5. **Mecânica com Shift Bitwise:** Uso do operador `sll` para dobrar eficientemente valores de dano na mecânica de sobrecarga.

---

## 5. Escopo Mínimo e Divisão Inicial de Tarefas
- **Escopo Mínimo:**
  - Jogo 1v1 funcional no MARS 4.5.
  - 4 chassis disponíveis.
  - 3 ações de combate por rodada + opção de saída limpa.
  - Tratamento de entradas inválidas.
  - Relatório de status e detecção de vitória/empate.
