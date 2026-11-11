# ==============================================================================
# PROJETO: Duelo de Robôs (MIPS Assembly)
# DISCIPLINA: Arquitetura e Organização de Computadores - UNIFESP 2026.2
# ARQUIVO: src/main.asm
# DESCRIÇÃO: Jogo de combate em turnos simultâneos para 2 jogadores.
#            Cada jogador escolhe um chassi (vetor de atributos).
#            A cada rodada, escolhem ações secretas (Ataque, Defesa, Recarga).
#            Implementa mecânica de Sobrecarga (dobro de dano via 'sll').
# ==============================================================================
.data
leitura_chassi: .asciiz "Digite o chassi desejado:"
leitura_jogador_1: .asciiz "Jogador 1, Digite a sua jogada:\n"
leitura_jogador_2: .asciiz "Jogador 2, Digite a sua jogada:\n"
leitura_jogador: .asciiz "Digite a sua jogada:\n"
aux_separador: .asciiz " | "
aux_separador2: .asciiz " ================== "
aux_jogador: .asciiz "Jogador "
aux_rodada: .asciiz "Rodada "
aux_custo_ataque: .asciiz "C. Ataque: "
aux_dano: .asciiz "Dano: "
aux_custo_defesa: .asciiz "C. Defesa: "
aux_recarga: .asciiz "Recarga: "
aux_energia: .asciiz "Energia: "

fim: .asciiz "Fim da partida.\n"
menu_modo: .asciiz "Selecione o Modo de Jogo:\n  1 - Dois Jogadores (1v1 Local)\n  2 - Um Jogador vs Computador (CPU)\nOpcao: "
msg_modo_invalido: .asciiz "[ERRO] Opcao invalida! Digite 1 ou 2.\n\n"
msg_semente: .asciiz "\nConfiguracao de Semente RNG:\nDigite um inteiro positivo para semente fixa\nOu digite -1 para semente via tempo real: "
msg_semente_invalida: .asciiz "[ERRO] Semente invalida! Digite um valor > 0 ou -1.\n"
msg_cpu_chassi: .asciiz "\n[COMPUTADOR] Escolheu o chassi sorteado: "
msg_cpu_jogada: .asciiz "\n[COMPUTADOR] Escolheu sua acao secreta.\n"
msg_desistencia_p1: .asciiz "\n[JOGADOR 1] Desistiu da partida!\n"
msg_desistencia_p2: .asciiz "\n[JOGADOR 2] Desistiu da partida!\n"

modo_jogo: .word 1
semente_rng: .word 0
tabela_chassi:
    .ascii  "\nOp | Chassi          | C.Atq | Dano | C.Def | Recarga\n"
    .ascii  "1  | Equilibrado     |   4   |   8  |   2   |   10\n"
    .ascii  "2  | Canhoneiro      |   6   |  14  |   4   |    8\n"
    .ascii  "3  | Tanque          |   3   |   5  |   1   |   10\n"
    .asciiz "4  | Reator Instavel |   5   |   9  |   3   |   16\n"
inicio_partida: .asciiz "Chassi selecionado, partida iniciando\n"
custo_atq:  .word 0     
dano_atq:   .word 0     
custo_def:  .word 0     
recarga:    .word 0

#array[Id_jogador, custo_atq, dano_atq, custo_def, recarga, energia]
chassi_j1: .space 24

chassi_j2: .space 24

menu_acao:
    .ascii  "1) Ataque\n"
    .ascii  "2) Defesa\n"
    .ascii  "3) Recarregar\n"
    .ascii  "0) Sair\n"
    .asciiz "Acao: "

# ------------------------------------------------------------------------------
# MOTOR DE COMBATE (Arthur)
# ------------------------------------------------------------------------------
#acoes escolhidas na rodada atual (1 = Ataque, 2 = Defesa, 3 = Recarga)
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
msg_vitoria_cpu: .asciiz "\n========================================\n>>> VITORIA DO COMPUTADOR! <<<\n"

.text
.globl main

main:
# 1. Configura modo de jogo (1v1 ou CPU)
jal configurar_modo

# 2. Se for contra Computador (modo 2), configura a semente RNG
lw $t0, modo_jogo
bne $t0, 2, pular_semente
jal configurar_semente

pular_semente:
#inicia ambos os jogadores com energia = 40
li $t5, 40

li $t7, 1 #auxiliar para verificar qual jogador esta selecionado chassi
seleciona_chassi:
li $v0, 4
la $a0, tabela_chassi
syscall

li $v0, 4
la $a0, leitura_chassi
syscall


ler_chassi:
li $t0, 0

li $v0, 5
syscall
move $t0, $v0

beq $t0, 1, chassi1
beq $t0, 2, chassi2
beq $t0, 3, chassi3
beq $t0, 4, chassi4
j ler_chassi            # Em caso de mandar uma opção inválida, volta para a linha de leitura da opção, até que uma opção válida seja digitada

#Seta as variáveis de acordo com a opção escolhida
chassi1:
li $t1, 4
li $t2, 8
li $t3, 2
li $t4, 10
j salvar_chassi

chassi2:
li $t1, 6
li $t2, 14
li $t3, 4
li $t4, 8
j salvar_chassi

chassi3:
li $t1, 3
li $t2, 5
li $t3, 1
li $t4, 10
j salvar_chassi

chassi4:
li $t1, 5
li $t2, 9
li $t3, 3
li $t4, 16

salvar_chassi:
la $s0, chassi_j1
beq $t7, 1, salva_array
la $s0, chassi_j2

#salva info do chassi com endereco $s0
salva_array:
sw $t7, 0($s0) #Id jogador
sw $t1, 4($s0) #custo ataque
sw $t2, 8($s0) #dano
sw $t3, 12($s0) #custo defesa
sw $t4, 16($s0) #recarga
sw $t5, 20($s0) #energia

beq $t7, 2, partida #se anbos ja foram salvos incia partida

# Se for modo CPU, o computador sorteia o chassi
lw $t9, modo_jogo
beq $t9, 2, cpu_escolhe_chassi

addi $t7, $t7, 1 #incrementa para continuar loop
jal ocultar_terminal
j seleciona_chassi #volta ao inicio do loop

cpu_escolhe_chassi:
li $t7, 2
li $v0, 42         # random int range
li $a0, 0          # gerador 0
li $a1, 4          # limite 4 -> sorteia 0..3
syscall
addi $t0, $a0, 1   # converte para 1..4

li $v0, 4
la $a0, msg_cpu_chassi
syscall
li $v0, 1
move $a0, $t0
syscall
li $v0, 11
li $a0, 10
syscall

beq $t0, 1, chassi1
beq $t0, 2, chassi2
beq $t0, 3, chassi3
beq $t0, 4, chassi4

partida:
li $v0, 4
la $a0, inicio_partida
syscall

li $t0, 0

loop_rodada:
#verifica se algum robo foi destruido antes de iniciar uma nova rodada
#$t0 guarda o contador de rodadas, por isso nao e utilizado aqui
la $t8, chassi_j1
lw $t1, 20($t8) #$t1 = energia do jogador 1
la $t8, chassi_j2
lw $t2, 20($t8) #$t2 = energia do jogador 2

blez $t1, verificar_vencedor #energia P1 <= 0 -> fim de jogo
blez $t2, verificar_vencedor #energia P2 <= 0 -> fim de jogo

addi $t0, $t0, 1

li $v0, 4
la $a0, aux_separador2
syscall

li $v0, 4
la $a0, aux_rodada
syscall

li $v0, 1
move $a0, $t0
syscall

li $v0, 4
la $a0, aux_separador2
syscall


li $v0, 11
li $a0, 10
syscall

Jogador_1:
#imprime info do jogador 1
la $a0, chassi_j1
jal imprimir

li $v0, 4
la $a0, leitura_jogador
syscall

li $v0, 4
la $a0, menu_acao
syscall

ler_jogada1:
li $v0, 5
syscall
move $t5, $v0

beq $t5, 1, atacar
beq $t5, 2, defender
beq $t5, 3, recarregar
beq $t5, 0, desistencia_p1
j ler_jogada1

atacar:
li $t5, 1
sw $t5, p1_acao
j fim_jogada1

defender:
li $t5, 2
sw $t5, p1_acao
j fim_jogada1

recarregar:
li $t5, 3
sw $t5, p1_acao
j fim_jogada1

fim_jogada1:
sw $t5, p1_acao #salva a acao valida do jogador 1 na memoria
lw $t9, modo_jogo
bne $t9, 1, pular_ocultar_p1
jal ocultar_terminal
pular_ocultar_p1:
j Jogador_2 #Depois que o jogador 1 finalizar sua vez, passa a vez para o jogador 2


Jogador_2:
#imprime info do jogador 2
la $a0, chassi_j2
jal imprimir

lw $t9, modo_jogo
beq $t9, 2, cpu_jogada

li $v0, 4
la $a0, leitura_jogador
syscall

li $v0, 4
la $a0, menu_acao
syscall

ler_jogada2:
li $v0, 5
syscall
move $t6, $v0

beq $t6, 1, atacar_2
beq $t6, 2, defender_2
beq $t6, 3, recarregar_2
beq $t6, 0, desistencia_p2
j ler_jogada2

cpu_jogada:
li $v0, 42         # random int range
li $a0, 0
li $a1, 3          # gera 0..2
syscall
addi $t6, $a0, 1   # mapeia para 1..3

li $v0, 4
la $a0, msg_cpu_jogada
syscall

sw $t6, p2_acao
j fim_jogada2

atacar_2:
li $t6, 1
sw $t6, p2_acao
j fim_jogada2

defender_2:
li $t6, 2
sw $t6, p2_acao
j fim_jogada2

recarregar_2:
li $t6, 3
sw $t6, p2_acao
j fim_jogada2


fim_jogada2:
sw $t6, p2_acao #salva a acao valida do jogador 2 na memoria
jal resolver_turno #com as duas acoes escolhidas, resolve o combate da rodada
j loop_rodada #Depois que o jogador 2 finalizar sua vez, volta para inicio do loop


#verifica quem venceu a partida
#entrada: $t1 = energia P1, $t2 = energia P2 (carregados em loop_rodada)
verificar_vencedor:
bgtz $t1, vitoria_p1 #P1 ainda vivo (logo P2 <= 0) -> vitoria P1
bgtz $t2, vitoria_p2 #P2 ainda vivo (logo P1 <= 0) -> vitoria P2

#ambos <= 0 -> empate
li $v0, 4
la $a0, msg_empate
syscall
j encerrar_jogo

vitoria_p1:
li $v0, 4
la $a0, msg_vitoria_p1
syscall
j encerrar_jogo

vitoria_p2:
lw $t9, modo_jogo
beq $t9, 2, vitoria_cpu

li $v0, 4
la $a0, msg_vitoria_p2
syscall
j encerrar_jogo

vitoria_cpu:
li $v0, 4
la $a0, msg_vitoria_cpu
syscall

encerrar_jogo:
li $v0, 10 #encerra o programa
syscall

desistencia_p1:
li $v0, 4
la $a0, msg_desistencia_p1
syscall

lw $t9, modo_jogo
beq $t9, 2, desistencia_p1_cpu

li $v0, 4
la $a0, msg_vitoria_p2
syscall
j fim_partida

desistencia_p1_cpu:
li $v0, 4
la $a0, msg_vitoria_cpu
syscall
j fim_partida

desistencia_p2:
li $v0, 4
la $a0, msg_desistencia_p2
syscall

li $v0, 4
la $a0, msg_vitoria_p1
syscall
j fim_partida

fim_partida:

li $v0, 4
la $a0, fim
syscall

li $v0, 10
syscall


# ==============================================================================
# SUB-ROTINA: resolver_turno
# Resolve a rodada com base em p1_acao e p2_acao.
#   Etapa 1: aplica custos/recargas de energia
#   Etapa 2: verifica Sobrecarga (energia > 40) -> dobra dano emitido e sofrido
#   Etapa 3: resolve Ataque vs Defesa e aplica o dano na energia do oponente
# Registradores:
#   $s0 = dano emitido por P1        $s1 = dano emitido por P2
#   $s2 = multiplicador sofrido P1   $s3 = multiplicador sofrido P2
#   $s4 = endereco chassi_j1         $s5 = endereco chassi_j2
#   $t1 = p1_acao, $t2 = p2_acao, $t3/$t4 = temporarios
# Obs: $t0 (contador de rodadas) NAO e alterado.
# ==============================================================================
resolver_turno:
#---------------- Prologo: salva $ra e $s0-$s5 na pilha ----------------
addi $sp, $sp, -28
sw $ra, 24($sp)
sw $s0, 20($sp)
sw $s1, 16($sp)
sw $s2, 12($sp)
sw $s3, 8($sp)
sw $s4, 4($sp)
sw $s5, 0($sp)

la $s4, chassi_j1 #base do vetor do jogador 1
la $s5, chassi_j2 #base do vetor do jogador 2
lw $t1, p1_acao
lw $t2, p2_acao

#---------------- Etapa 1: custos e recargas de energia ----------------
#Jogador 1
lw $t3, 20($s4) #$t3 = energia P1
beq $t1, 1, rt_custo_atq_p1
beq $t1, 2, rt_custo_def_p1
beq $t1, 3, rt_recarga_p1
j rt_fim_custo_p1

rt_custo_atq_p1:
lw $t4, 4($s4) #custo de ataque
sub $t3, $t3, $t4 #energia -= custo_ataque
j rt_fim_custo_p1

rt_custo_def_p1:
lw $t4, 12($s4) #custo de defesa
sub $t3, $t3, $t4 #energia -= custo_defesa
j rt_fim_custo_p1

rt_recarga_p1:
lw $t4, 16($s4) #valor de recarga
add $t3, $t3, $t4 #energia += recarga

rt_fim_custo_p1:
sw $t3, 20($s4) #atualiza energia P1

#Jogador 2
lw $t3, 20($s5) #$t3 = energia P2
beq $t2, 1, rt_custo_atq_p2
beq $t2, 2, rt_custo_def_p2
beq $t2, 3, rt_recarga_p2
j rt_fim_custo_p2

rt_custo_atq_p2:
lw $t4, 4($s5)
sub $t3, $t3, $t4
j rt_fim_custo_p2

rt_custo_def_p2:
lw $t4, 12($s5)
sub $t3, $t3, $t4
j rt_fim_custo_p2

rt_recarga_p2:
lw $t4, 16($s5)
add $t3, $t3, $t4

rt_fim_custo_p2:
sw $t3, 20($s5) #atualiza energia P2

#---------------- Etapa 2: mecanica de Sobrecarga ----------------
#dano base: so existe se o jogador atacou
li $s0, 0
bne $t1, 1, rt_dano_base_p2
lw $s0, 8($s4) #$s0 = dano do chassi P1

rt_dano_base_p2:
li $s1, 0
bne $t2, 1, rt_multiplicadores
lw $s1, 8($s5) #$s1 = dano do chassi P2

rt_multiplicadores:
li $s2, 1 #multiplicador de dano sofrido por P1
li $s3, 1 #multiplicador de dano sofrido por P2

#Sobrecarga P1 (energia > 40)
lw $t3, 20($s4)
ble $t3, 40, rt_sobrecarga_p2
sll $s0, $s0, 1 #dobra o dano emitido (shift left = x2)
li $s2, 2 #P1 tambem passa a sofrer dano dobrado
li $v0, 4
la $a0, msg_sobrecarga_p1
syscall

rt_sobrecarga_p2:
#Sobrecarga P2 (energia > 40)
lw $t3, 20($s5)
ble $t3, 40, rt_etapa3
sll $s1, $s1, 1
li $s3, 2
li $v0, 4
la $a0, msg_sobrecarga_p2
syscall

#---------------- Etapa 3: Ataque vs Defesa ----------------
rt_etapa3:
#P1 atacou?
bne $t1, 1, rt_ataque_p2
beq $t2, 2, rt_bloqueio_p2 #P2 defendeu -> ataque bloqueado

mul $t3, $s0, $s3 #dano_final = dano P1 * multiplicador sofrido P2
lw $t4, 20($s5)
sub $t4, $t4, $t3 #energia P2 -= dano_final
sw $t4, 20($s5)

li $v0, 4
la $a0, msg_dano_p1
syscall
li $v0, 1
move $a0, $t3
syscall
j rt_ataque_p2

rt_bloqueio_p2:
li $v0, 4
la $a0, msg_bloqueio_p2
syscall

rt_ataque_p2:
#P2 atacou?
bne $t2, 1, rt_epilogo
beq $t1, 2, rt_bloqueio_p1 #P1 defendeu -> ataque bloqueado

mul $t3, $s1, $s2 #dano_final = dano P2 * multiplicador sofrido P1
lw $t4, 20($s4)
sub $t4, $t4, $t3 #energia P1 -= dano_final
sw $t4, 20($s4)

li $v0, 4
la $a0, msg_dano_p2
syscall
li $v0, 1
move $a0, $t3
syscall
j rt_epilogo

rt_bloqueio_p1:
li $v0, 4
la $a0, msg_bloqueio_p1
syscall

#---------------- Epilogo: restaura registradores ----------------
rt_epilogo:
li $v0, 11
li $a0, 10 #quebra de linha
syscall

lw $s5, 0($sp)
lw $s4, 4($sp)
lw $s3, 8($sp)
lw $s2, 12($sp)
lw $s1, 16($sp)
lw $s0, 20($sp)
lw $ra, 24($sp)
addi $sp, $sp, 28
jr $ra


# ==============================================================================
# PROCEDIMENTO: imprimir
# Parâmetros: $a0 = Endereço base do vetor de atributos (chassi_j1 ou chassi_j2)
# ==============================================================================
imprimir:
addi $sp, $sp, -4
sw $s0, 0($sp)
move $s0, $a0

li $v0, 4
la $a0, aux_separador2
syscall

li $v0, 4
la $a0, aux_jogador
syscall

li $v0, 1
lw $a0, 0($s0)
syscall

li $v0, 4
la $a0, aux_separador2
syscall

li $v0, 11
li $a0, 10
syscall

li $v0, 4
la $a0, aux_custo_ataque
syscall

li $v0, 1
lw $a0, 4($s0)
syscall

li $v0, 4
la $a0, aux_separador
syscall

li $v0, 4
la $a0, aux_dano
syscall

li $v0, 1
lw $a0, 8($s0)
syscall

li $v0, 4
la $a0, aux_separador
syscall

li $v0, 4
la $a0, aux_custo_defesa
syscall

li $v0, 1
lw $a0, 12($s0)
syscall

li $v0, 4
la $a0, aux_separador
syscall

li $v0, 4
la $a0, aux_recarga
syscall

li $v0, 1
lw $a0, 16($s0)
syscall

li $v0, 4
la $a0, aux_separador
syscall

li $v0, 4
la $a0, aux_energia
syscall

li $v0, 1
lw $a0, 20($s0)
syscall

li $v0, 11
li $a0, 10
syscall

lw $s0, 0($sp)
addi $sp, $sp, 4
jr $ra

# ==============================================================================
# PROCEDIMENTO: ocultar_terminal
# Descrição: Emite 25 quebras de linha ('\n') para descer a tela no terminal
#            e impedir visão espia da jogada secreta no terminal do MARS.
# ==============================================================================
ocultar_terminal:
li $t8, 0
li $v0, 11               # print_char
li $a0, 10               # ASCII '\n'
loop_ocultar:
beq $t8, 25, fim_ocultar
syscall
addi $t8, $t8, 1
j loop_ocultar
fim_ocultar:
jr $ra

# ==============================================================================
# PROCEDIMENTO: configurar_modo
# Descrição: Lê e valida o modo de jogo (1 - 2 Jogadores, 2 - CPU).
# ==============================================================================
configurar_modo:
li $v0, 4
la $a0, menu_modo
syscall

li $v0, 5
syscall
move $t0, $v0

beq $t0, 1, modo_valido
beq $t0, 2, modo_valido

li $v0, 4
la $a0, msg_modo_invalido
syscall
j configurar_modo

modo_valido:
sw $t0, modo_jogo
jr $ra

# ==============================================================================
# PROCEDIMENTO: configurar_semente
# Descrição: Configura semente RNG (syscall 40) direta ou via timestamp (syscall 30).
# ==============================================================================
configurar_semente:
li $v0, 4
la $a0, msg_semente
syscall

li $v0, 5
syscall
move $t0, $v0

beq $t0, -1, semente_tempo
bgtz $t0, semente_fixa

li $v0, 4
la $a0, msg_semente_invalida
syscall
j configurar_semente

semente_tempo:
li $v0, 30         # syscall time (retorna timestamp em $a0)
syscall
move $a1, $a0      # move para $a1
li $a0, 0          # id do gerador
li $v0, 40         # set seed
syscall
sw $a1, semente_rng
jr $ra

semente_fixa:
move $a1, $t0      # semente fixa em $a1
li $a0, 0          # id do gerador
li $v0, 40         # set seed
syscall
sw $a1, semente_rng
jr $ra
