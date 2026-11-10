# ==============================================================================
# PROJETO: Duelo de Robôs / AOCalipse (MIPS Assembly)
# DISCIPLINA: Arquitetura e Organização de Computadores - UNIFESP 2026.2
# ARQUIVO: src/main.asm
# DESCRIÇÃO: Jogo de combate tático em turnos simultâneos para 2 jogadores ou PvE.
#            Cada competidor escolhe um chassi (vetor de atributos).
#            Implementa convenções MIPS, modo CPU (RNG), ocultação e combate.
# ==============================================================================

.data
# --- MENSAGENS DE INTERFACE E MENUS ---
titulo_jogo:        .asciiz "====================================================\n               * * * AOCALIPSE * * *\n      Duelo Tatico em Assembly MIPS - UNIFESP\n====================================================\n\n"
menu_modo:          .asciiz "Selecione o Modo de Jogo:\n  1 - Dois Jogadores (1v1 Local)\n  2 - Um Jogador vs Computador (CPU)\nOpcao: "
msg_modo_invalido:  .asciiz "[ERRO] Opcao invalida! Digite 1 ou 2.\n\n"

msg_semente:        .asciiz "\nConfiguracao de Semente RNG:\nDigite um inteiro positivo para semente fixa\nOu digite -1 para semente via tempo real: "
msg_semente_invalida: .asciiz "[ERRO] Semente invalida! Digite um valor > 0 ou -1.\n"
msg_semente_tempo:  .asciiz "[RNG] Semente dinamica configurada via timestamp do sistema!\n\n"
msg_semente_fixa:   .asciiz "[RNG] Semente fixa configurada para testes reproduziveis!\n\n"

leitura_chassi:     .asciiz "Digite o chassi desejado (1-4): "
msg_cpu_chassi:     .asciiz "\n[COMPUTADOR] Escolheu o chassi sorteado: "
leitura_jogador:    .asciiz "Digite a sua jogada:\n"
msg_cpu_jogada:     .asciiz "\n[COMPUTADOR] Escolheu sua acao secreta.\n"

msg_desistencia_p1: .asciiz "\n[JOGADOR 1] Desistiu da partida!\n"
msg_desistencia_p2: .asciiz "\n[JOGADOR 2] Desistiu da partida!\n"
msg_vitoria_p1:     .asciiz ">>> FIM DE JOGO: VITORIA DO JOGADOR 1! <<<\n"
msg_vitoria_p2:     .asciiz ">>> FIM DE JOGO: VITORIA DO JOGADOR 2! <<<\n"
msg_vitoria_cpu:    .asciiz ">>> FIM DE JOGO: VITORIA DO COMPUTADOR! <<<\n"

aux_separador:      .asciiz " | "
aux_separador2:     .asciiz " ================== "
aux_jogador:        .asciiz "Jogador "
aux_rodada:         .asciiz "Rodada "
aux_custo_ataque:   .asciiz "C. Ataque: "
aux_dano:           .asciiz "Dano: "
aux_custo_defesa:   .asciiz "C. Defesa: "
aux_recarga:        .asciiz "Recarga: "
aux_energia:        .asciiz "Energia: "

fim:                .asciiz "Fim da partida.\n"
tabela_chassi:
    .ascii  "\nOp | Chassi          | C.Atq | Dano | C.Def | Recarga\n"
    .ascii  "1  | Equilibrado     |   4   |   8  |   2   |   10\n"
    .ascii  "2  | Canhoneiro      |   6   |  14  |   4   |    8\n"
    .ascii  "3  | Tanque          |   3   |   5  |   1   |   10\n"
    .asciiz "4  | Reator Instavel |   5   |   9  |   3   |   16\n"
inicio_partida:     .asciiz "\nChassis selecionados! Partida iniciando...\n"

# --- BUFFERS E ESTADO DO JOGO ---
modo_jogo:          .word 1             # 1 = PvP (Dois Jogadores), 2 = PvE (CPU)
semente_rng:        .word 0             # Valor da semente
p1_acao:            .word 0             # 1=Atacar, 2=Defender, 3=Recarregar, 0=Sair
p2_acao:            .word 0             # 1=Atacar, 2=Defender, 3=Recarregar, 0=Sair

# Array de 24 bytes (6 words): [Id_jogador, custo_atq, dano_atq, custo_def, recarga, energia]
chassi_j1:          .space 24
chassi_j2:          .space 24

menu_acao:
    .ascii  "1) Ataque\n"
    .ascii  "2) Defesa\n"
    .ascii  "3) Recarregar\n"
    .ascii  "0) Sair / Desistir\n"
    .asciiz "Acao: "

.text
.globl main

# ==============================================================================
# PROCEDIMENTO PRINCIPAL: main
# ==============================================================================
main:
    # Exibe cabeçalho do jogo
    li   $v0, 4
    la   $a0, titulo_jogo
    syscall

    # 1. Configura modo de jogo (1v1 ou CPU)
    jal  configurar_modo

    # 2. Se for contra Computador (modo 2), configura a semente RNG
    lw   $t0, modo_jogo
    bne  $t0, 2, pular_semente
    jal  configurar_semente

pular_semente:
    # Inicia ambos os jogadores com energia = 40
    li   $t5, 40

    # Auxiliar $t7: 1 = selecionando para Jogador 1, 2 = Jogador 2
    li   $t7, 1

seleciona_chassi:
    li   $v0, 4
    la   $a0, tabela_chassi
    syscall

    li   $v0, 4
    la   $a0, leitura_chassi
    syscall

ler_chassi:
    li   $v0, 5
    syscall
    move $t0, $v0

    beq  $t0, 1, chassi1
    beq  $t0, 2, chassi2
    beq  $t0, 3, chassi3
    beq  $t0, 4, chassi4
    j    ler_chassi            # Se opção inválida, repete

# Atribuição dos atributos com base no chassi selecionado
chassi1:
    li   $t1, 4
    li   $t2, 8
    li   $t3, 2
    li   $t4, 10
    j    salvar_chassi

chassi2:
    li   $t1, 6
    li   $t2, 14
    li   $t3, 4
    li   $t4, 8
    j    salvar_chassi

chassi3:
    li   $t1, 3
    li   $t2, 5
    li   $t3, 1
    li   $t4, 10
    j    salvar_chassi

chassi4:
    li   $t1, 5
    li   $t2, 9
    li   $t3, 3
    li   $t4, 16

salvar_chassi:
    la   $s0, chassi_j1
    beq  $t7, 1, salva_array
    la   $s0, chassi_j2

salva_array:
    sw   $t7, 0($s0)           # Id jogador
    sw   $t1, 4($s0)           # Custo ataque
    sw   $t2, 8($s0)           # Dano
    sw   $t3, 12($s0)          # Custo defesa
    sw   $t4, 16($s0)          # Recarga
    sw   $t5, 20($s0)          # Energia inicial (40)

    beq  $t7, 2, partida       # Se ambos já escolheram, inicia a partida

    # Jogador 1 acabou de escolher:
    lw   $t9, modo_jogo
    beq  $t9, 2, cpu_escolhe_chassi

    # Modo 1v1: oculta tela e passa a vez para o Jogador 2
    jal  ocultar_terminal
    li   $t7, 2
    j    seleciona_chassi

cpu_escolhe_chassi:
    # Modo CPU: sorteia automaticamente chassi entre 1 e 4 via syscall 42
    li   $t7, 2
    li   $v0, 42               # random int range
    li   $a0, 0                # id gerador
    li   $a1, 4                # limite exclusivo (gera 0..3)
    syscall
    addi $t0, $a0, 1           # converte para 1..4

    li   $v0, 4
    la   $a0, msg_cpu_chassi
    syscall

    li   $v0, 1
    move $a0, $t0
    syscall

    li   $v0, 11
    li   $a0, 10
    syscall

    beq  $t0, 1, chassi1
    beq  $t0, 2, chassi2
    beq  $t0, 3, chassi3
    beq  $t0, 4, chassi4

partida:
    li   $v0, 4
    la   $a0, inicio_partida
    syscall

    li   $t0, 0                # Contador de rodadas

loop_rodada:
    addi $t0, $t0, 1

    li   $v0, 4
    la   $a0, aux_separador2
    syscall

    li   $v0, 4
    la   $a0, aux_rodada
    syscall

    li   $v0, 1
    move $a0, $t0
    syscall

    li   $v0, 4
    la   $a0, aux_separador2
    syscall

    li   $v0, 11
    li   $a0, 10
    syscall

Jogador_1:
    # Exibe dados do Jogador 1 (passando endereço em $a0 pela convenção MIPS)
    la   $a0, chassi_j1
    jal  imprimir

    li   $v0, 4
    la   $a0, leitura_jogador
    syscall

    li   $v0, 4
    la   $a0, menu_acao
    syscall

ler_jogada1:
    li   $v0, 5
    syscall
    move $t5, $v0

    beq  $t5, 0, desistencia_p1
    beq  $t5, 1, jogada1_valida
    beq  $t5, 2, jogada1_valida
    beq  $t5, 3, jogada1_valida
    j    ler_jogada1

jogada1_valida:
    sw   $t5, p1_acao

fim_jogada1:
    # Se for modo 1v1, oculta o terminal para o Jogador 2 não ver a jogada de P1
    lw   $t9, modo_jogo
    bne  $t9, 1, pular_ocultar_p1
    jal  ocultar_terminal

pular_ocultar_p1:
    j    Jogador_2

Jogador_2:
    # Exibe dados do Jogador 2
    la   $a0, chassi_j2
    jal  imprimir

    lw   $t9, modo_jogo
    beq  $t9, 2, cpu_jogada    # Se for CPU, não pede entrada no teclado

    # Jogador 2 Humano (Modo 1v1)
    li   $v0, 4
    la   $a0, leitura_jogador
    syscall

    li   $v0, 4
    la   $a0, menu_acao
    syscall

ler_jogada2:
    li   $v0, 5
    syscall
    move $t6, $v0

    beq  $t6, 0, desistencia_p2
    beq  $t6, 1, jogada2_valida
    beq  $t6, 2, jogada2_valida
    beq  $t6, 3, jogada2_valida
    j    ler_jogada2

cpu_jogada:
    # CPU sorteia ação: 1=Atacar, 2=Defender, 3=Recarregar
    li   $v0, 42               # random int range
    li   $a0, 0
    li   $a1, 3                # gera 0..2
    syscall
    addi $t6, $a0, 1           # mapeia para 1..3

    li   $v0, 4
    la   $a0, msg_cpu_jogada
    syscall

jogada2_valida:
    sw   $t6, p2_acao

fim_jogada2:
    # ==============================================================
    # PONTO DE INTEGRAÇÃO DO ALUNO 2 (Arthur):
    # Aqui Arthur chamará: jal resolver_turno
    # ==============================================================
    j    loop_rodada

# --- TRATAMENTO LIMPO DE DESISTÊNCIA (CÓDIGO 0) ---
desistencia_p1:
    li   $v0, 4
    la   $a0, msg_desistencia_p1
    syscall

    lw   $t9, modo_jogo
    beq  $t9, 2, desistencia_p1_cpu

    li   $v0, 4
    la   $a0, msg_vitoria_p2
    syscall
    j    fim_partida

desistencia_p1_cpu:
    li   $v0, 4
    la   $a0, msg_vitoria_cpu
    syscall
    j    fim_partida

desistencia_p2:
    li   $v0, 4
    la   $a0, msg_desistencia_p2
    syscall

    li   $v0, 4
    la   $a0, msg_vitoria_p1
    syscall
    j    fim_partida

fim_partida:
    li   $v0, 4
    la   $a0, fim
    syscall

    li   $v0, 10
    syscall

# ==============================================================================
# PROCEDIMENTO: configurar_modo
# Descrição: Lê e valida o modo de jogo (1 - 2 Jogadores, 2 - CPU).
# ==============================================================================
configurar_modo:
    li   $v0, 4
    la   $a0, menu_modo
    syscall

    li   $v0, 5
    syscall
    move $t0, $v0

    beq  $t0, 1, modo_valido
    beq  $t0, 2, modo_valido

    li   $v0, 4
    la   $a0, msg_modo_invalido
    syscall
    j    configurar_modo

modo_valido:
    sw   $t0, modo_jogo
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: configurar_semente
# Descrição: Configura a semente do gerador pseudoaleatório (syscall 40).
#            Se semente == -1, obtém o tempo do sistema via syscall 30.
# ==============================================================================
configurar_semente:
    li   $v0, 4
    la   $a0, msg_semente
    syscall

    li   $v0, 5
    syscall
    move $t0, $v0

    beq  $t0, -1, semente_tempo
    bgtz $t0, semente_fixa

    li   $v0, 4
    la   $a0, msg_semente_invalida
    syscall
    j    configurar_semente

semente_tempo:
    li   $v0, 30               # syscall time (retorna timestamp em milissegundos em $a0)
    syscall
    move $a1, $a0              # semente em $a1
    li   $a0, 0                # id do gerador RNG (0)
    li   $v0, 40               # syscall set seed
    syscall

    sw   $a1, semente_rng

    li   $v0, 4
    la   $a0, msg_semente_tempo
    syscall
    jr   $ra

semente_fixa:
    move $a1, $t0              # semente fixa em $a1
    li   $a0, 0                # id do gerador RNG (0)
    li   $v0, 40               # syscall set seed
    syscall

    sw   $a1, semente_rng

    li   $v0, 4
    la   $a0, msg_semente_fixa
    syscall
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: ocultar_terminal
# Descrição: Emite 25 quebras de linha ('\n') para descer a tela no terminal
#            e impedir visão espia da jogada adversária no modo 1v1.
# ==============================================================================
ocultar_terminal:
    li   $t8, 0
    li   $v0, 11               # print_char
    li   $a0, 10               # ASCII '\n'
loop_ocultar:
    beq  $t8, 25, fim_ocultar
    syscall
    addi $t8, $t8, 1
    j    loop_ocultar
fim_ocultar:
    jr   $ra

# ==============================================================================
# PROCEDIMENTO: imprimir
# Parâmetros: $a0 = Endereço base do vetor de atributos (chassi_j1 ou chassi_j2)
# Convenção: Salva e restaura $s0 na pilha para manter conformidade MIPS.
# ==============================================================================
imprimir:
    addi $sp, $sp, -4
    sw   $s0, 0($sp)
    move $s0, $a0              # Guarda base do vetor em $s0 para não perder nas syscalls

    li   $v0, 4
    la   $a0, aux_separador2
    syscall

    li   $v0, 4
    la   $a0, aux_jogador
    syscall

    li   $v0, 1
    lw   $a0, 0($s0)           # ID do Jogador
    syscall

    li   $v0, 4
    la   $a0, aux_separador2
    syscall

    li   $v0, 11
    li   $a0, 10
    syscall

    li   $v0, 4
    la   $a0, aux_custo_ataque
    syscall

    li   $v0, 1
    lw   $a0, 4($s0)           # Custo Ataque
    syscall

    li   $v0, 4
    la   $a0, aux_separador
    syscall

    li   $v0, 4
    la   $a0, aux_dano
    syscall

    li   $v0, 1
    lw   $a0, 8($s0)           # Dano Ataque
    syscall

    li   $v0, 4
    la   $a0, aux_separador
    syscall

    li   $v0, 4
    la   $a0, aux_custo_defesa
    syscall

    li   $v0, 1
    lw   $a0, 12($s0)          # Custo Defesa
    syscall

    li   $v0, 4
    la   $a0, aux_separador
    syscall

    li   $v0, 4
    la   $a0, aux_recarga
    syscall

    li   $v0, 1
    lw   $a0, 16($s0)          # Recarga
    syscall

    li   $v0, 4
    la   $a0, aux_separador
    syscall

    li   $v0, 4
    la   $a0, aux_energia
    syscall

    li   $v0, 1
    lw   $a0, 20($s0)          # Energia Atual
    syscall

    li   $v0, 11
    li   $a0, 10
    syscall

    # Epílogo: restaura $s0 e desempilha
    lw   $s0, 0($sp)
    addi $sp, $sp, 4
    jr   $ra
