# Plano de Implementação: AOCalipse (MIPS Assembly)

> **Status Atual:** O PR #3 do Felipe foi mesclado com sucesso na `main`. O armazenamento dos chassis em vetores (`chassi_j1` e `chassi_j2`) e a impressão básica já estão funcionando.
> 
> **Divisão Oficial da Dupla:**
> - 🧑‍💻 **Aluno 1 (João):** Refatoração da convenção MIPS, Ocultação de terminal, Modo Computador (CPU), Semente RNG (`syscall 30/40/42`) e Saída limpa.
> - 🧑‍💻 **Aluno 2 (Arthur):** Motor de Combate (`resolver_turno`), Dedução de Custos/Recarga, Mecânica de Sobrecarga com Shift Binário (`sll`), Interação Ataque x Escudo e Verificação de Vitória/Empate.

---

## 🏗️ 0. Estrutura Atual dos Dados na Memória (`.data`)
Após a integração do PR #3, os dados de cada jogador estão estruturados em blocos de 24 bytes (6 words de 32 bits contíguas):

```assembly
chassi_j1: .space 24   # Robô do Jogador 1
chassi_j2: .space 24   # Robô do Jogador 2 / CPU

# Mapeamento de offsets de cada vetor:
# offset 0  (+0)  : ID do jogador (1 ou 2)
# offset 4  (+4)  : Custo de Ataque
# offset 8  (+8)  : Dano de Ataque
# offset 12 (+12) : Custo de Defesa
# offset 16 (+16) : Recarga de Energia
# offset 20 (+20) : Energia Atual (Inicia em 40)
```

Variáveis auxiliares que devem ser adicionadas/padronizadas:
```assembly
p1_acao:     .word 0    # Ação escolhida por P1 (1=Atacar, 2=Defender, 3=Recarregar, 0=Sair)
p2_acao:     .word 0    # Ação escolhida por P2 (1=Atacar, 2=Defender, 3=Recarregar, 0=Sair)
modo_jogo:   .word 1    # 1 = PvP (Dois Jogadores), 2 = PvE (Contra Computador)
semente_rng: .word 0    # Semente usada pelo gerador de números aleatórios
```

---

## 🧑‍💻 ALUNO 2 (Arthur): O Motor de Combate, Sobrecarga e Vitória

Arthur cuidará da lógica mais tática do jogo: pegar as escolhas feitas pelos dois jogadores, resolver o combate simultâneo, aplicar danos, escudos e sobrecargas, e determinar quem venceu.

### Tarefa A.1: Salvar as Ações dos Jogadores
* **O que fazer:** Em vez de pular direto de `Jogador_1` para `Jogador_2`, salvar a opção digitada:
  - Na leitura do Jogador 1: `sw $t5, p1_acao`.
  - Na leitura do Jogador 2: `sw $t6, p2_acao`.
  - Após a leitura de ambos, chamar com `jal resolver_turno`.

### Tarefa A.2: Procedimento `resolver_turno` (Coração do Jogo)
* **Referência em C:** [`src/main.c` (linhas 423 a 539)](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c#L423-L539)
* **Como fazer:**
  1. **Prólogo:** Salvar `$ra` e registradores `$s0-$s5` na pilha (`addi $sp, $sp, -28`).
  2. **Etapa 1 - Custos e Recargas:**
     - Carrega `p1_acao` e o vetor `chassi_j1`:
       - Se ação == 1 (Atacar): `energia = energia - custo_atq` (`offset 20` -= `offset 4`).
       - Se ação == 2 (Defender): `energia = energia - custo_def` (`offset 20` -= `offset 12`).
       - Se ação == 3 (Recarregar): `energia = energia + recarga` (`offset 20` += `offset 16`).
     - Atualiza com `sw` no `offset 20($s0)`.
     - Repete exatamente a mesma dedução para `chassi_j2` usando `p2_acao`.
  3. **Etapa 2 - Mecânica de Sobrecarga (Requisito Obrigatório com `sll`):**
     - Registradores sugeridos:
       - `$s0`: Dano emitido por P1 (se `p1_acao == 1`, lê do offset 8; senão 0).
       - `$s1`: Dano emitido por P2 (se `p2_acao == 1`, lê do offset 8; senão 0).
       - `$s2`: Multiplicador de vulnerabilidade sofrida por P1 (inicia em 1).
       - `$s3`: Multiplicador de vulnerabilidade sofrida por P2 (inicia em 1).
     - Carrega energia de P1: se `energia > 40` (`bgt $reg, 40, sobrecarga_p1`):
       - Duplica dano emitido: `sll $s0, $s0, 1`
       - Duplica dano recebido: `li $s2, 2`
       - Imprime mensagem: `"[ALERTA] P1 em SOBRECARGA!"`
     - Carrega energia de P2: se `energia > 40`:
       - Duplica dano emitido: `sll $s1, $s1, 1`
       - Duplica dano recebido: `li $s3, 2`
       - Imprime mensagem: `"[ALERTA] P2 em SOBRECARGA!"`
  4. **Etapa 3 - Interações Ataque x Escudo:**
     - Ataque de P1:
       - Se `p1_acao == 1`:
         - Se `p2_acao == 2`: ataque bloqueado pelo escudo do P2!
         - Senão: calcula `dano_final = $s0 * $s3` (`mul`), subtrai da energia de P2 (`offset 20 de chassi_j2`) e grava.
     - Ataque de P2:
       - Se `p2_acao == 1`:
         - Se `p1_acao == 2`: ataque bloqueado pelo escudo do P1!
         - Senão: calcula `dano_final = $s1 * $s2` (`mul`), subtrai da energia de P1 (`offset 20 de chassi_j1`) e grava.
  5. **Epílogo:** Restaura `$s0-$s5` e `$ra` da pilha e retorna (`jr $ra`).

### Tarefa A.3: Condição de Vitória e Fim de Partida
* **Referência em C:** [`src/main.c` (linhas 183 a 200)](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c#L183-L200)
* **Como fazer:**
  - No início de `loop_rodada`, lê a energia de P1 (`lw $t1, 20(chassi_j1)`) e de P2 (`lw $t2, 20(chassi_j2)`).
  - Se `p1_energia <= 0` OU `p2_energia <= 0`, pula para `verificar_vencedor`.
  - Em `verificar_vencedor`:
    - Se ambos `<= 0`: Imprime `">> EMPATE TECNICO! <<"`
    - Se apenas `p1_energia <= 0`: Imprime `">> VITORIA DO JOGADOR 2! <<"`
    - Se apenas `p2_energia <= 0`: Imprime `">> VITORIA DO JOGADOR 1! <<"`
    - Chama `syscall 10` para encerrar graciosamente.

---

## 🧑‍💻 ALUNO 1 (João): Interface, Convenções MIPS, Ocultação e Modo CPU

João cuidará do polimento arquitetural (garantindo nota máxima nos critérios formais da disciplina), da ocultação de tela para o duelo local e da inteligência artificial/aleatoriedade do modo solo.

### Tarefa J.1: Refatoração da Convenção MIPS em `imprimir`
* **O que fazer:**
  - Atualmente, a sub-rotina `imprimir` acessa `$s0` diretamente.
  - Ajustar para que quem chama faça `la $a0, chassi_j1` (ou `chassi_j2`) e a sub-rotina leia a partir de `$a0`.
  - Isso garante o cumprimento da convenção oficial de parâmetros em MIPS.

### Tarefa J.2: Ocultação do Terminal (Sigilo das Jogadas)
* **Procedimento:** `ocultar_terminal`
* **Referência em C:** [`src/main.c` (linhas 382 a 391)](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c#L382-L391)
* **Como fazer:**
  - Sub-rotina simples com contador de 1 a 25 emitindo o caractere `\n` (ASCII 10 via `syscall 11`).
  - Chamada logo após o Jogador 1 confirmar sua ação e antes do Jogador 2 assumir o teclado.

### Tarefa J.3: Modo Computador (CPU) e Semente RNG
* **Procedimentos:** `configurar_jogo`, `configurar_semente` e `obter_acao_cpu`
* **Referência em C:** [`src/main.c` (linhas 202 a 278 e 365 a 380)](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c#L202-L278)
* **Como fazer:**
  1. Menu inicial perguntando se quer `1 - Dois Jogadores` ou `2 - Contra o Computador`.
  2. Se escolher 2:
     - Solicita a semente. Se o usuário digitar `-1`:
       - Chama `syscall 30` (time), pega os bits de `$a0`, move para `$a1`.
       - Define `$a0 = 0` (ID do gerador) e chama `syscall 40` (set seed).
     - Se o usuário digitar um número positivo:
       - Move o número para `$a1`, `$a0 = 0` e chama `syscall 40`.
  3. No turno do Jogador 2, se `modo_jogo == 2`:
     - Não pede entrada no teclado!
     - Sorteia a ação da CPU usando `syscall 42` (random range com limite 3, somando 1 para resultar em 1, 2 ou 3).
     - Grava em `p2_acao`.

### Tarefa J.4: Encerramento Limpo por Desistência (Opção `0`)
* **O que fazer:**
  - Garantir que se P1 ou P2 digitar `0`, o jogo informe quem desistiu e declare a vitória do adversário imediatamente antes de dar `syscall 10`.

---

## 🎯 Ordem de Integração Sugerida
1. **Arthur** implementa a gravação de `p1_acao`, `p2_acao` e a sub-rotina `resolver_turno`. (O jogo já passa a ter combate real!).
2. **João** refatora `imprimir` para usar `$a0` e adiciona `ocultar_terminal`.
3. **Arthur** adiciona a verificação de energia `<= 0` no `loop_rodada` e a tela de vitória.
4. **João** adiciona o menu de modo de jogo e o suporte à CPU/semente RNG.
5. **Ambos** rodam os testes do [`docs/testes.md`](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/docs/testes.md) no simulador MARS.
