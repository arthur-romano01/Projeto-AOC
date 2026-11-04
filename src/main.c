/**
 * ============================================================================
 * PROJETO: AOCalipse (Simulador em C para Conversão em MIPS Assembly)
 * DISCIPLINA: Arquitetura e Organização de Computadores - UNIFESP 2026.2
 * ARQUIVO: src/main.c
 * 
 * GUIA DE MAPEAMENTO PARA ASSEMBLY MIPS:
 * - Variáveis globais mapeiam diretamente para rótulos na seção .data (words de 32 bits).
 * - Vetores de atributos: chassi[4] mapeia para 4 words contíguas na .data:
 *     offset 0  (+0)  : custo_ataque
 *     offset 4  (+4)  : dano_ataque
 *     offset 8  (+8)  : custo_defesa
 *     offset 12 (+12) : recarga_energia
 * - Sobrecarga (energia > 40): dobro de dano via shift binário:
 *     C: dano <<= 1;  ->  MIPS: sll $reg, $reg, 1
 * - Syscalls utilizadas no MARS:
 *     Syscall 1  : print_int ($a0 = valor)
 *     Syscall 4  : print_str ($a0 = endereço da string)
 *     Syscall 5  : read_int (retorna em $v0)
 *     Syscall 10 : exit
 *     Syscall 30 : time (tempo em milissegundos, bits baixos em $a0)
 *     Syscall 40 : set seed ($a0 = id gerador, $a1 = valor da semente)
 *     Syscall 42 : random range ($a0 = id gerador, $a1 = limite superior exclusivo, retorna em $a0)
 * ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

/* ============================================================================
 * SEÇÃO DE DADOS (.data)
 * Equivalente aos rótulos e vetores estáticos em MIPS
 * ============================================================================
 */

/* Vetor com os 4 atributos de cada chassi [custo_atk, dano_atk, custo_def, recarga] */
static const int chassi_1[4] = {4,  8, 2, 10};  /* 1: Equilibrado */
static const int chassi_2[4] = {6, 14, 4,  8};  /* 2: Canhoneiro */
static const int chassi_3[4] = {3,  5, 1, 10};  /* 3: Tanque */
static const int chassi_4[4] = {5,  9, 3, 16};  /* 4: Reator Instavel */

/* Tabela de ponteiros de chassis (para indexação via sll $t0, $reg, 2) */
static const int* tabela_chassis[4] = {
    chassi_1,
    chassi_2,
    chassi_3,
    chassi_4
};

/* Nomes dos chassis para exibição */
static const char* nomes_chassis[4] = {
    "Equilibrado",
    "Canhoneiro",
    "Tanque",
    "Reator Instavel"
};

/* Nomes das ações para exibição */
static const char* nomes_acoes[4] = {
    "Desistir",
    "Atacar",
    "Defender",
    "Recarregar"
};

/*
 * Buffers de estado do jogo (alocados como .word na seção .data)
 */
static int modo_jogo;          /* 1 = 2 Jogadores (PvP), 2 = Contra Computador (PvE) */
static int semente_rng;        /* Valor da semente ou tempo */

static int p1_chassi_idx;      /* 0 a 3 */
static int p2_chassi_idx;      /* 0 a 3 */

static int p1_atributos[4];    /* Cópia dos 4 atributos do chassi do P1 */
static int p2_atributos[4];    /* Cópia dos 4 atributos do chassi do P2 / CPU */

static int p1_energia;         /* Energia do Jogador 1 (inicial: 40) */
static int p2_energia;         /* Energia do Jogador 2 / CPU (inicial: 40) */

static int p1_acao;            /* Ação do turno: 1=Atacar, 2=Defender, 3=Recarregar, 0=Sair */
static int p2_acao;            /* Ação do turno: 1=Atacar, 2=Defender, 3=Recarregar, 0=Sair */

static int rodada_atual;       /* Contador de rodadas */

/* ============================================================================
 * DECLARAÇÃO DE PROCEDIMENTOS (.text)
 * ============================================================================
 */
void configurar_jogo(void);
void configurar_semente(void);
int  obter_chassi_valido(const char* rotulo_jogador);
void carregar_perfil_chassi(int chassi_idx, int* destino_atributos);
int  obter_acao_valida(const char* rotulo_jogador);
int  obter_acao_cpu(void);
void ocultar_terminal(void);
void exibir_status_jogadores(void);
void resolver_turno(void);
void imprimir_nome_acao(int acao);
int  gerar_numero_aleatorio(int limite_exclusivo);

/* ============================================================================
 * PROCEDIMENTO: main
 * Mapeamento: Rótulo 'main' na seção .text do MIPS
 * Orquestra o fluxo geral do jogo e o loop principal de combate.
 * ============================================================================
 */
int main(void) {
    printf("====================================================\n");
    printf("               * * * AOCALIPSE * * *\n");
    printf("      Duelo Tatico em Assembly MIPS - UNIFESP\n");
    printf("====================================================\n\n");

    /* 1. Configurações iniciais: Modo de jogo e semente (se contra CPU) */
    configurar_jogo();

    /* Se o modo for contra Computador, solicita e configura a semente de sorteio */
    if (modo_jogo == 2) {
        configurar_semente();
    }

    /* 2. Seleção de Chassis */
    p1_chassi_idx = obter_chassi_valido("JOGADOR 1");
    carregar_perfil_chassi(p1_chassi_idx, p1_atributos);

    if (modo_jogo == 1) {
        /* Modo 2 Jogadores: P2 escolhe manualmente */
        ocultar_terminal();
        p2_chassi_idx = obter_chassi_valido("JOGADOR 2");
    } else {
        /* Modo CPU: sorteia chassi entre 0 e 3 (syscall 42 com limite 4) */
        p2_chassi_idx = gerar_numero_aleatorio(4);
        printf("[COMPUTADOR] Escolheu o chassi: %d - %s\n\n",
               p2_chassi_idx + 1, nomes_chassis[p2_chassi_idx]);
    }
    carregar_perfil_chassi(p2_chassi_idx, p2_atributos);

    /* 3. Inicialização dos status de energia */
    p1_energia = 40;
    p2_energia = 40;
    rodada_atual = 1;

    printf("\n*** COMBATE INICIADO! ENERGIA INICIAL: 40 pts ***\n");

    /* 
     * 4. Loop Principal de Duelo (rotulo MIPS: loop_duelo)
     */
    while (p1_energia > 0 && p2_energia > 0) {
        printf("\n----------------------------------------------------\n");
        printf(">>> RODADA %d <<<\n", rodada_atual);
        exibir_status_jogadores();

        /* Leitura da ação do Jogador 1 */
        p1_acao = obter_acao_valida("JOGADOR 1");
        if (p1_acao == 0) {
            printf("\n[JOGADOR 1] Desistiu da partida!\n");
            printf(">>> FIM DE JOGO: VITORIA DO %s! <<<\n", (modo_jogo == 1 ? "JOGADOR 2" : "COMPUTADOR"));
            return 0;
        }

        /* Leitura da ação do Jogador 2 ou CPU */
        if (modo_jogo == 1) {
            ocultar_terminal();
            p2_acao = obter_acao_valida("JOGADOR 2");
            if (p2_acao == 0) {
                printf("\n[JOGADOR 2] Desistiu da partida!\n");
                printf(">>> FIM DE JOGO: VITORIA DO JOGADOR 1! <<<\n");
                return 0;
            }
        } else {
            /* Modo CPU sorteia ação (1=Atacar, 2=Defender, 3=Recarregar) */
            p2_acao = obter_acao_cpu();
        }

        /* 5. Resolução atômica do turno */
        resolver_turno();

        rodada_atual++;
    }

    /* 
     * 6. Fim de jogo e declaração do vencedor
     */
    printf("\n====================================================\n");
    printf("                RESULTADO DA PARTIDA                \n");
    printf("====================================================\n");
    exibir_status_jogadores();

    if (p1_energia <= 0 && p2_energia <= 0) {
        printf(">>> EMPATE TECNICO! Ambos os robos foram destruidos simultaneamente! <<<\n");
    } else if (p1_energia <= 0) {
        printf(">>> VITORIA DO %s! Robô do Jogador 1 destruido! <<<\n", 
               (modo_jogo == 1 ? "JOGADOR 2" : "COMPUTADOR"));
    } else {
        printf(">>> VITORIA DO JOGADOR 1! Parabéns pela estratégia! <<<\n");
    }

    return 0;
}

/* ============================================================================
 * PROCEDIMENTO: configurar_jogo
 * Mapeamento: Pergunta modo de jogo e valida entrada [1 ou 2]
 * ============================================================================
 */
void configurar_jogo(void) {
    int escolha;
    while (1) {
        printf("Selecione o Modo de Jogo:\n");
        printf("  1 - Dois Jogadores (1v1 Local)\n");
        printf("  2 - Um Jogador vs Computador (CPU)\n");
        printf("Opcao: ");
        if (scanf("%d", &escolha) == 1) {
            if (escolha == 1 || escolha == 2) {
                modo_jogo = escolha;
                break;
            }
        } else {
            /* Limpa buffer se entrada não for inteira */
            int c;
            while ((c = getchar()) != '\n' && c != EOF);
        }
        printf("[ERRO] Opcao invalida! Digite 1 ou 2.\n\n");
    }
}

/* ============================================================================
 * PROCEDIMENTO: configurar_semente
 * Mapeamento MIPS:
 * - Se semente > 0: carrega em $a1 e chama syscall 40 (set seed).
 * - Se semente == -1: chama syscall 30 (time), move $a0 para $a1 e chama syscall 40.
 * ============================================================================
 */
void configurar_semente(void) {
    int seed_input;
    while (1) {
        printf("\nConfiguracao de Semente (RNG para CPU e reproducao de partidas):\n");
        printf("Digite um inteiro positivo para semente fixa (ex: 42, 1234)\n");
        printf("Ou digite -1 para semente automatica baseada no tempo: ");
        
        if (scanf("%d", &seed_input) == 1) {
            if (seed_input == -1) {
                /* Em MIPS: syscall 30 (retorna tempo em $a0), depois syscall 40 */
                semente_rng = (int)time(NULL);
                srand((unsigned int)semente_rng);
                printf("[RNG] Semente dinamica configurada via timestamp: %d\n\n", semente_rng);
                break;
            } else if (seed_input > 0) {
                /* Em MIPS: move $a1, $v0; syscall 40 */
                semente_rng = seed_input;
                srand((unsigned int)semente_rng);
                printf("[RNG] Semente fixa configurada: %d (Partida reproduzivel)\n\n", semente_rng);
                break;
            }
        } else {
            int c;
            while ((c = getchar()) != '\n' && c != EOF);
        }
        printf("[ERRO] Semente invalida! Digite um inteiro positivo ou -1.\n");
    }
}

/* ============================================================================
 * PROCEDIMENTO: gerar_numero_aleatorio
 * Mapeamento MIPS:
 * - Em MIPS usa a syscall 42 (random int range):
 *     li $v0, 42
 *     li $a0, 0                 # ID do gerador
 *     li $a1, limite_exclusivo  # Ex: 4 gera [0..3]
 *     syscall
 *     # Resultado fica em $a0
 * ============================================================================
 */
int gerar_numero_aleatorio(int limite_exclusivo) {
    if (limite_exclusivo <= 0) return 0;
    return rand() % limite_exclusivo;
}

/* ============================================================================
 * PROCEDIMENTO: obter_chassi_valido
 * Mapeamento MIPS:
 * - Exibe tabela de chassis (syscall 4).
 * - Lê inteiro (syscall 5).
 * - Valida se [1 <= valor <= 4].
 * - Subtrai 1 para indexação 0-based: sub $v0, $v0, 1.
 * ============================================================================
 */
int obter_chassi_valido(const char* rotulo_jogador) {
    int escolha;
    while (1) {
        printf("[%s] Escolha seu Chassi:\n", rotulo_jogador);
        printf("  1 - Equilibrado     [Custo Atk: 4 | Dano Atk:  8 | Custo Def: 2 | Recarga: 10]\n");
        printf("  2 - Canhoneiro      [Custo Atk: 6 | Dano Atk: 14 | Custo Def: 4 | Recarga:  8]\n");
        printf("  3 - Tanque          [Custo Atk: 3 | Dano Atk:  5 | Custo Def: 1 | Recarga: 10]\n");
        printf("  4 - Reator Instavel [Custo Atk: 5 | Dano Atk:  9 | Custo Def: 3 | Recarga: 16]\n");
        printf("Escolha (1-4): ");

        if (scanf("%d", &escolha) == 1) {
            if (escolha >= 1 && escolha <= 4) {
                printf("[%s] Chassi selecionado: %s\n\n", rotulo_jogador, nomes_chassis[escolha - 1]);
                return escolha - 1; /* Retorna índice 0 a 3 */
            }
        } else {
            int c;
            while ((c = getchar()) != '\n' && c != EOF);
        }
        printf("[ERRO] Opcao invalida! Digite um valor entre 1 e 4.\n\n");
    }
}

/* ============================================================================
 * PROCEDIMENTO: carregar_perfil_chassi
 * Parâmetros MIPS:
 *   $a0 = chassi_idx (0 a 3)
 *   $a1 = endereço base do buffer destino (ex: la $a1, p1_atributos)
 * Mapeamento:
 *   - sll $t0, $a0, 2               (offset na tabela de ponteiros: idx * 4)
 *   - lw  $t1, tabela_chassis($t0)  (endereço base do chassi escolhido)
 *   - lw  $t2, 0($t1) -> sw $t2, 0($a1)   # Custo Ataque
 *   - lw  $t2, 4($t1) -> sw $t2, 4($a1)   # Dano Ataque
 *   - lw  $t2, 8($t1) -> sw $t2, 8($a1)   # Custo Defesa
 *   - lw  $t2, 12($t1)-> sw $t2, 12($a1)  # Recarga
 * ============================================================================
 */
void carregar_perfil_chassi(int chassi_idx, int* destino_atributos) {
    const int* origem = tabela_chassis[chassi_idx];
    destino_atributos[0] = origem[0]; /* Custo Ataque */
    destino_atributos[1] = origem[1]; /* Dano Ataque  */
    destino_atributos[2] = origem[2]; /* Custo Defesa */
    destino_atributos[3] = origem[3]; /* Recarga      */
}

/* ============================================================================
 * PROCEDIMENTO: obter_acao_valida
 * Mapeamento MIPS:
 *   - Imprime menu de ações.
 *   - Lê inteiro do terminal.
 *   - Valida se [0 <= acao <= 3].
 *   - Retorna a ação válida em $v0.
 * ============================================================================
 */
int obter_acao_valida(const char* rotulo_jogador) {
    int acao;
    while (1) {
        printf("[%s] Selecione sua acao secreta:\n", rotulo_jogador);
        printf("  1 - Atacar\n");
        printf("  2 - Defender\n");
        printf("  3 - Recarregar\n");
        printf("  0 - Sair / Desistir da Partida\n");
        printf("Acao: ");

        if (scanf("%d", &acao) == 1) {
            if (acao >= 0 && acao <= 3) {
                return acao;
            }
        } else {
            int c;
            while ((c = getchar()) != '\n' && c != EOF);
        }
        printf("[ERRO] Acao invalida! Digite 1, 2, 3 ou 0 para desistir.\n\n");
    }
}

/* ============================================================================
 * PROCEDIMENTO: obter_acao_cpu
 * Mapeamento MIPS:
 *   - Sorteia um número de 0 a 2 via syscall 42 (limite 3).
 *   - Soma 1 para mapear no intervalo [1..3] (1: Atacar, 2: Defender, 3: Recarregar).
 * ============================================================================
 */
int obter_acao_cpu(void) {
    /* 
     * Sorteia entre 0 e 2, depois soma 1 => 1 a 3.
     * CPU nunca escolhe 0 (desistir).
     */
    int sorteio = gerar_numero_aleatorio(3);
    return sorteio + 1;
}

/* ============================================================================
 * PROCEDIMENTO: ocultar_terminal
 * Mapeamento MIPS:
 *   - Loop que emite quebras de linha ('\n') para descer o terminal do MARS.
 * ============================================================================
 */
void ocultar_terminal(void) {
    for (int i = 0; i < 25; i++) {
        putchar('\n');
    }
}

/* ============================================================================
 * PROCEDIMENTO: exibir_status_jogadores
 * Mapeamento MIPS:
 *   - Imprime energia do P1 e P2.
 *   - Compara se energia > 40 (bgt $reg, 40, flag_sobrecarga) para alerta visual.
 * ============================================================================
 */
void exibir_status_jogadores(void) {
    printf("[STATUS] JOGADOR 1: %d pts de energia %s\n", 
           p1_energia, (p1_energia > 40 ? ">> [SOBRECARGA ATIVA!] <<" : ""));
    printf("[STATUS] %s: %d pts de energia %s\n", 
           (modo_jogo == 1 ? "JOGADOR 2" : "COMPUTADOR"), 
           p2_energia, (p2_energia > 40 ? ">> [SOBRECARGA ATIVA!] <<" : ""));
}

/* ============================================================================
 * PROCEDIMENTO: imprimir_nome_acao
 * Mapeamento MIPS:
 *   - Switch/jump table baseado no código da ação para imprimir o texto.
 * ============================================================================
 */
void imprimir_nome_acao(int acao) {
    if (acao >= 0 && acao <= 3) {
        printf("%s", nomes_acoes[acao]);
    } else {
        printf("Desconhecida");
    }
}

/* ============================================================================
 * PROCEDIMENTO: resolver_turno
 * Mapeamento MIPS:
 *   Procedimento central que preserva $s0-$s5 e $ra na pilha ($sp).
 *   Lógica de execução:
 *     1. Revela as jogadas escolhidas.
 *     2. Aplica custos e recargas de energia.
 *     3. Avalia mecânica de SOBRECARGA (energia > 40 duplica dano via sll).
 *     4. Resolve interações de Ataque vs Defesa e aplica reduções de vida.
 * ============================================================================
 */
void resolver_turno(void) {
    printf("\n================ [ REVELACAO DAS ACOES ] ================\n");
    printf("Jogador 1 escolheu: ");
    imprimir_nome_acao(p1_acao);
    printf("\n");

    printf("%s escolheu: ", (modo_jogo == 1 ? "Jogador 2" : "Computador"));
    imprimir_nome_acao(p2_acao);
    printf("\n--------------------------------------------------------\n");

    /*
     * ETAPA 1: Processamento de Custos e Recargas
     */
    /* Jogador 1 */
    if (p1_acao == 1) {
        /* Custo Ataque (offset 0 de p1_atributos) */
        p1_energia -= p1_atributos[0];
        printf("-> P1 consumiu %d de energia no ataque.\n", p1_atributos[0]);
    } else if (p1_acao == 2) {
        /* Custo Defesa (offset 8 de p1_atributos) */
        p1_energia -= p1_atributos[2];
        printf("-> P1 consumiu %d de energia ativando escudo defensivo.\n", p1_atributos[2]);
    } else if (p1_acao == 3) {
        /* Recarga (offset 12 de p1_atributos) */
        p1_energia += p1_atributos[3];
        printf("-> P1 recarregou +%d de energia em sua bateria.\n", p1_atributos[3]);
    }

    /* Jogador 2 / CPU */
    if (p2_acao == 1) {
        /* Custo Ataque (offset 0 de p2_atributos) */
        p2_energia -= p2_atributos[0];
        printf("-> %s consumiu %d de energia no ataque.\n", 
               (modo_jogo == 1 ? "P2" : "CPU"), p2_atributos[0]);
    } else if (p2_acao == 2) {
        /* Custo Defesa (offset 8 de p2_atributos) */
        p2_energia -= p2_atributos[2];
        printf("-> %s consumiu %d de energia ativando escudo defensivo.\n", 
               (modo_jogo == 1 ? "P2" : "CPU"), p2_atributos[2]);
    } else if (p2_acao == 3) {
        /* Recarga (offset 12 de p2_atributos) */
        p2_energia += p2_atributos[3];
        printf("-> %s recarregou +%d de energia em sua bateria.\n", 
               (modo_jogo == 1 ? "P2" : "CPU"), p2_atributos[3]);
    }

    /*
     * ETAPA 2: Avaliação de Dano e Mecânica de SOBRECARGA
     * Registradores MIPS recomendados:
     *   $s0: dano_emitido_p1
     *   $s1: dano_emitido_p2
     *   $s2: mult_recebido_p1 (1 ou 2)
     *   $s3: mult_recebido_p2 (1 ou 2)
     */
    int dano_base_p1 = (p1_acao == 1) ? p1_atributos[1] : 0;
    int dano_base_p2 = (p2_acao == 1) ? p2_atributos[1] : 0;

    int mult_recebido_p1 = 1;
    int mult_recebido_p2 = 1;

    /* Sobrecarga do Jogador 1 (se energia > 40) */
    if (p1_energia > 40) {
        printf("-> [ALERTA] P1 em SOBRECARGA! Dano emitido e sofrido duplicados!\n");
        /* Em MIPS: sll $s0, $s0, 1 (duplica dano emitido) */
        dano_base_p1 <<= 1;
        mult_recebido_p1 = 2;
    }

    /* Sobrecarga do Jogador 2 / CPU (se energia > 40) */
    if (p2_energia > 40) {
        printf("-> [ALERTA] %s em SOBRECARGA! Dano emitido e sofrido duplicados!\n",
               (modo_jogo == 1 ? "P2" : "CPU"));
        /* Em MIPS: sll $s1, $s1, 1 (duplica dano emitido) */
        dano_base_p2 <<= 1;
        mult_recebido_p2 = 2;
    }

    /*
     * ETAPA 3: Resolução de Interações de Ataque vs Defesa
     */
    /* Dano de P1 em P2/CPU */
    if (p1_acao == 1) {
        if (p2_acao == 2) {
            printf("-> O escudo de %s BLOQUEOU totalmente o ataque de P1!\n", 
                   (modo_jogo == 1 ? "P2" : "CPU"));
        } else {
            int dano_final = dano_base_p1 * mult_recebido_p2;
            p2_energia -= dano_final;
            printf("-> P1 causou %d de dano a %s!\n", 
                   dano_final, (modo_jogo == 1 ? "P2" : "CPU"));
        }
    }

    /* Dano de P2/CPU em P1 */
    if (p2_acao == 1) {
        if (p1_acao == 2) {
            printf("-> O escudo de P1 BLOQUEOU totalmente o ataque adversario!\n");
        } else {
            int dano_final = dano_base_p2 * mult_recebido_p1;
            p1_energia -= dano_final;
            printf("-> %s causou %d de dano a P1!\n", 
                   (modo_jogo == 1 ? "P2" : "CPU"), dano_final);
        }
    }

    printf("========================================================\n");
}

