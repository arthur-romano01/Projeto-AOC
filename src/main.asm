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
fim: .asciiz "Fim da partida."
tabela_chassi:
    .ascii  "Op | Chassi          | C.Atq | Dano | C.Def | Recarga\n"
    .ascii  "1  | Equilibrado     |   4   |   8  |   2   |   10\n"
    .ascii  "2  | Canhoneiro      |   6   |  14  |   4   |    8\n"
    .ascii  "3  | Tanque          |   3   |   5  |   1   |   10\n"
    .asciiz "4  | Reator Instavel |   5   |   9  |   3   |   16\n"
inicio_partida: .asciiz "Chassi selecionado, partida iniciando"
custo_atq:  .word 0     
dano_atq:   .word 0     
custo_def:  .word 0     
recarga:    .word 0
menu_acao:
    .ascii  "1) Ataque\n"
    .ascii  "2) Defesa\n"
    .ascii  "3) Recarregar\n"
    .ascii  "0) Sair\n"
    .asciiz "Acao: "



.text
.globl main

main:
# Seleção do Chassi
li $v0, 4
la $a0, tabela_chassi
syscall

li $v0, 11
li $a0, 10
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
sw $t1, custo_atq
sw $t2, dano_atq
sw $t3, custo_def
sw $t4, recarga

partida:

li $v0, 4
la $a0, inicio_partida
syscall

Jogador_1:

li $v0, 4
la $a0, leitura_jogador_1
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

li $v0, 4
la $a0, leitura_jogador_2
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

j fim_jogada2:

recarregar_2:



fim_jogada2:
j Jogador_1 #Depois que o jogador 2 finalizar sua vez, volta para o jogador 1


fim_partida:

li $v0, 4
la $a0, fim
syscall

li $v0, 10
syscall







