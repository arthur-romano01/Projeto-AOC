# 🤖 AGENTS.md — Guia de Automação e "Vibecoding" (AOCalipse MIPS)

> **Instruções para o Desenvolvedor:**
> Este arquivo foi feito para você colar diretamente em um assistente de IA (Cursor, Antigravity, Claude, ChatGPT, etc.) ou usá-lo como contexto do projeto. Ele contém todas as regras de baixo nível, a arquitetura do simulador e o passo a passo exato para você **"vibecodar" sem alucinações da IA**.

---

## 🎯 1. Contexto e Missão do Projeto
- **Projeto:** AOCalipse — Duelo tático de robôs em turnos simultâneos na arquitetura **MIPS Assembly (MARS 4.5)**.
- **Disciplina:** Arquitetura e Organização de Computadores (AOC) — UNIFESP.
- **Arquivo Alvo:** [`src/main.asm`](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.asm).
- **Gabarito / Código de Referência em C:** [`src/main.c`](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c) (contém toda a lógica já testada).

---

## ⚙️ 2. Regras de Ouro do MIPS (Invariantes Arquiteturais)
Qualquer código gerado pela IA **DEVE** seguir estas regras estritas para não perder pontos com o professor:

1. **Convenção de Registradores:**
   - `$a0 - $a3`: Argumentos de funções e parâmetros de syscalls.
   - `$v0 - $v1`: Códigos de syscall e valores de retorno de funções.
   - `$t0 - $t9`: Temporários livres para cálculos locais.
   - `$s0 - $s7`: Registradores salvos. Se uma sub-rotina alterar qualquer `$sX`, ela **DEVE** obrigatoriamente salvá-lo no prólogo da pilha (`$sp`) e restaurá-lo no epílogo.
   - `$ra`: Endereço de retorno. **SEMPRE** salvar na pilha se a função chamar outra função via `jal`.
2. **Estrutura dos Dados em Memória (`.data`):**
   Os robôs usam blocos de 24 bytes (6 words contíguas de 32 bits):
   - `0($base)`  : ID do Jogador (1 ou 2)
   - `4($base)`  : Custo de Ataque
   - `8($base)`  : Dano de Ataque
   - `12($base)` : Custo de Defesa
   - `16($base)` : Recarga de Energia
   - `20($base)` : Energia Atual (Inicia em 40)
3. **Mecânica de Sobrecarga (Requisito Especial Obrigatório):**
   - Se a energia for `> 40`, o robô causa o **dobro** de dano e recebe o **dobro** de dano.
   - O dobro **DEVE** ser calculado usando shift binário para a esquerda: `sll $reg, $reg, 1`. Nunca use multiplicação para dobrar.
4. **Chamadas de Sistema Utilizadas (MARS):**
   - `syscall 1`: print_int (`$a0` = valor)
   - `syscall 4`: print_str (`$a0` = endereço da string)
   - `syscall 5`: read_int (retorno em `$v0`)
   - `syscall 10`: exit (término limpo)
   - `syscall 11`: print_char (`$a0` = caractere ASCII, ex: 10 para `\n`)
   - `syscall 30`: time (timestamp em milissegundos, bits baixos em `$a0`)
   - `syscall 40`: set seed (`$a0` = id gerador 0, `$a1` = valor semente)
   - `syscall 42`: random range (`$a0` = id gerador 0, `$a1` = limite exclusivo, sorteia em `$a0`)

---

## 🚀 3. PROMPT PARA O ALUNO 2 (Arthur): Combate, Sobrecarga e Vitória

Copie e cole o bloco abaixo na sua IA para implementar a sua parte:

````markdown
Você é um especialista em Assembly MIPS para o simulador MARS 4.5.
Estou trabalhando no projeto AOCalipse no arquivo `src/main.asm`.

Minha responsabilidade (Arthur) é implementar o MOTOR DE COMBATE e a RESOLUÇÃO DE TURNO:
1. Adicionar na seção `.data`:
   p1_acao: .word 0
   p2_acao: .word 0
   msg_sobrecarga_p1: .asciiz "\n-> [ALERTA] Jogador 1 em SOBRECARGA! Dano dobrado!"
   msg_sobrecarga_p2: .asciiz "\n-> [ALERTA] Jogador 2 em SOBRECARGA! Dano dobrado!"
   msg_bloqueio_p1: .asciiz "\n-> O escudo do Jogador 1 BLOQUEOU totalmente o ataque!"
   msg_bloqueio_p2: .asciiz "\n-> O escudo do Jogador 2 BLOQUEOU totalmente o ataque!"
   msg_dano_p1: .asciiz "\n-> Jogador 1 causou de dano: "
   msg_dano_p2: .asciiz "\n-> Jogador 2 causou de dano: "
   msg_empate: .asciiz "\n========================================\n>>> EMPATE TECNICO! Ambos robos destruidos! <<<\n"
   msg_vitoria_p1: .asciiz "\n========================================\n>>> VITORIA DO JOGADOR 1! Parabens! <<<\n"
   msg_vitoria_p2: .asciiz "\n========================================\n>>> VITORIA DO JOGADOR 2! Parabens! <<<\n"

2. No fluxo da partida em `Jogador_1` e `Jogador_2`:
   - Salvar a ação lida em `p1_acao` e `p2_acao`.
   - Após ler a ação do Jogador 2, chamar `jal resolver_turno`.

3. Implementar a sub-rotina `resolver_turno`:
   - Prólogo: salvar $ra e $s0-$s5 na pilha.
   - Etapa 1: Aplicar custos/recargas na energia de cada jogador (offset 20 de chassi_j1 e chassi_j2).
     - Ação 1 (Atacar): energia -= custo_ataque (offset 4)
     - Ação 2 (Defender): energia -= custo_defesa (offset 12)
     - Ação 3 (Recarregar): energia += recarga (offset 16)
   - Etapa 2: Mecânica de Sobrecarga (se energia > 40):
     - Inicializar $s0 com dano base P1 (offset 8 se acao==1, senao 0) e $s1 para P2.
     - Inicializar multiplicador de dano sofrido $s2 = 1 (P1) e $s3 = 1 (P2).
     - Se energia P1 > 40: sll $s0, $s0, 1 (dobra dano emitido) e li $s2, 2 (dobra dano recebido).
     - Se energia P2 > 40: sll $s1, $s1, 1 e li $s3, 2.
   - Etapa 3: Resolução de Ataque vs Defesa:
     - Se P1 atacou (p1_acao == 1):
       - Se P2 defendeu (p2_acao == 2): imprime msg de bloqueio.
       - Senão: calcula dano_final = $s0 * $s3 (usando mul) e subtrai de energia de P2.
     - Se P2 atacou (p2_acao == 1):
       - Se P1 defendeu (p1_acao == 2): imprime msg de bloqueio.
       - Senão: calcula dano_final = $s1 * $s2 e subtrai de energia de P1.
   - Epílogo: restaurar $s0-$s5 e $ra da pilha e jr $ra.

4. No início de `loop_rodada`:
   - Ler a energia de P1 e P2 (offset 20).
   - Se p1_energia <= 0 ou p2_energia <= 0, desviar para `verificar_vencedor`.
   - Se ambos <= 0: imprime msg_empate.
   - Se p1 <= 0: imprime msg_vitoria_p2.
   - Se p2 <= 0: imprime msg_vitoria_p1.
   - Encerrar com syscall 10.

Por favor, gere o código com comentários detalhados e mantendo o padrão do `src/main.asm`.
````

---

## 🚀 4. PROMPT PARA O ALUNO 1 (João): Interface, Convenção MIPS e CPU

Copie e cole o bloco abaixo na sua IA para implementar a sua parte:

````markdown
Você é um especialista em Assembly MIPS para o simulador MARS 4.5.
Estou trabalhando no projeto AOCalipse no arquivo `src/main.asm`.

Minha responsabilidade (João) é polir a arquitetura, convenções MIPS e adicionar o modo CPU:
1. Refatorar o procedimento `imprimir`:
   - Quem chama deve carregar o endereço base em $a0 (`la $a0, chassi_j1` ou `chassi_j2`).
   - A sub-rotina `imprimir` deve usar $a0 como base dos offsets (substituindo o uso fixo de $s0).

2. Implementar o procedimento `ocultar_terminal`:
   - Laço de repetição que imprime 25 vezes o caractere ASCII 10 ('\n') usando syscall 11.
   - Chamar `jal ocultar_terminal` logo após o Jogador 1 confirmar sua jogada, para que o Jogador 2 não veja a ação secreta.

3. Implementar a Seleção de Modo de Jogo e Semente RNG:
   - No início do `main`, perguntar:
     1 - Dois Jogadores (1v1 Local)
     2 - Contra o Computador (CPU)
   - Salvar em `modo_jogo`.
   - Se `modo_jogo == 2`:
     - Pedir a semente. Se o usuário digitar -1:
       - Chama syscall 30 (time), move $a0 para $a1, seta $a0 = 0 e chama syscall 40 (set seed).
     - Se o usuário digitar um valor > 0:
       - Move para $a1, seta $a0 = 0 e chama syscall 40.
     - Na vez do Jogador 2, não pedir entrada do teclado:
       - Chamar syscall 42 com $a1 = 3 (sorteia 0..2) e somar 1 (1=Atacar, 2=Defender, 3=Recarregar).
       - Salvar em `p2_acao`.

4. Tratamento Limpo de Desistência:
   - Se a ação digitada for 0, imprimir quem desistiu e declarar vitória do oponente antes do syscall 10.

Por favor, gere o código mantendo a convenção de registradores MIPS e com comentários claros.
````

---

## 🧪 5. Como Testar no MARS (Checklist Rápido)
1. Abra o **MARS 4.5**.
2. Abra `src/main.asm` e aperte **F3** (Assemble).
3. Aperte **F5** (Go / Run).
4. **Teste 1:** Partida normal escolhendo Chassis 1 e 2. Faça P1 atacar e P2 defender (verifique se o dano é zero).
5. **Teste 2:** Faça um robô recarregar até passar de 40 de energia (verifique se a mensagem de sobrecarga aparece e o dano emitido/recebido dobra).
6. **Teste 3:** Teste digitar 0 para garantir que o encerramento é limpo.

