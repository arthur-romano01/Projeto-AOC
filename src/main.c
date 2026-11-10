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

.text
.globl main

main:
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
addi $t7, $t7, 1 #incrementa para continuar loop
j seleciona_chassi #volta ao inicio do loop

partida:
li $v0, 4
la $a0, inicio_partida
syscall

li $t0, 0

loop_rodada:
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
la $s0, chassi_j1
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
beq $t5, 0, fim_partida
j ler_jogada1

atacar:

j fim_jogada1

defender:

j fim_jogada1

recarregar:


fim_jogada1:
j Jogador_2 #Depois que o jogador 1 finalizar sua vez, passa a vez para o jogador 2


Jogador_2:
#imprime info do jogador 2
la $s0, chassi_j2
jal imprimir

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
beq $t6, 0, fim_partida
j ler_jogada2

atacar_2:

j fim_jogada2

defender_2:

j fim_jogada2

recarregar_2:

j fim_jogada2


fim_jogada2:
j loop_rodada #Depois que o jogador 2 finalizar sua vez, volta para inicio do loop


fim_partida:

li $v0, 4
la $a0, fim
syscall

li $v0, 10
syscall


#funcao auxiliar imprimr a info atual no vetor de chassi com endereco $s0
imprimir:

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

jr $ra

