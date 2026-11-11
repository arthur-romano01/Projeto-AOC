# Registro de Testes: AOCalipse (MIPS Assembly)

Este documento descreve os 3 casos de testes reproduziveis do projeto **AOCalipse**, abrangendo os tres cenarios exigidos pela disciplina de Arquitetura e Organizacao de Computadores (AOC) - UNIFESP:
1. **Entrada Invalida (Tratamento de Excecoes e Resiliencia)**
2. **Uso Normal (Duelo Tatico, Deducoes de Custos e Bloqueio por Escudo)**
3. **Situacao Limite (Mecanica de Sobrecarga, Dano Duplicado via `sll` e Fim por Bateria Zerada)**

---

## Caso de Teste 1: Entrada Invalida e Desistencia Limpa

### 1. Objetivo do Teste
Verificar se o programa valida as entradas do usuario em todas as etapas (modo de jogo, selecao de chassis e menu de combate), rejeitando valores fora do intervalo com mensagens de erro claras sem quebrar o fluxo, e confirmando se a opcao `0` encerra a execucao graciosamente com codigo de saida limpo (`syscall 10`).

### 2. Entradas Fornecidas
A sequencia exata de inteiros inserida na entrada padrao (stdin / caixa de Input):

```text
9
1
0
5
1
2
8
0
```

*Detalhamento das entradas:*
- `9`: Modo de jogo invalido (esperado: rejeitar).
- `1`: Modo de jogo valido (2 Jogadores / PvP).
- `0`: Chassi invalido para o Jogador 1 (esperado: rejeitar).
- `5`: Chassi invalido para o Jogador 1 (esperado: rejeitar).
- `1`: Chassi valido para o Jogador 1 (Equilibrado).
- `2`: Chassi valido para o Jogador 2 (Canhoneiro).
- `8`: Acao invalida para o Jogador 1 na Rodada 1 (esperado: rejeitar).
- `0`: Acao valida para desistir / sair da partida.

### 3. Resultado Esperado
- O sistema rejeita o `9` e exibe `[ERRO] Opcao invalida! Digite 1 ou 2.`
- O sistema aceita o `1` e solicita o chassi do Jogador 1.
- O sistema rejeita o `0` e o `5`, exibindo `[ERRO] Opcao invalida! Digite um valor entre 1 e 4.` para cada tentativa incorreta.
- O sistema aceita o `1` para o P1 e o `2` para o P2.
- Na Rodada 1, o sistema rejeita a acao `8` exibindo `[ERRO] Acao invalida! Digite 1, 2, 3 ou 0.`
- Ao receber `0`, o sistema exibe `[JOGADOR 1] Desistiu da partida!`, declara a vitoria do Jogador 2 e encerra a execucao com `syscall 10`.

### 4. Resultado Observado
O programa executou exatamente conforme o esperado tanto no simulador MARS quanto no SPIM/SPIN. As entradas fora da faixa permitida foram capturadas e re-solicitadas, enquanto a desistencia finalizou o programa sem erros de execucao.

### 5. Justificativa Tecnica
A resiliencia a entradas invalidas e garantida por loops de validacao com instrucoes de desvio condicional (`beq`, `bgtz`) e saltos incondicionais (`j`). Quando o valor lido via `syscall 5` nao atende aos predicados esperados, o fluxo desvia para a impressao da mensagem de erro e retorna ao rotulo de leitura sem alterar as variaveis de estado. A opcao `0` desvia diretamente para a rotina de desistencia que aciona a `syscall 10`.

---

## Caso de Teste 2: Uso Normal (Combate, Bloqueio por Escudo e Custos)

### 1. Objetivo do Teste
Validar o ciclo regular de jogo no modo 2 Jogadores: escolha de chassis, inicializacao com 40 pontos de energia para ambos, deducao exata de custos de ataque e escudo defensivo, e confirmacao de que a escolha da Defesa (acao `2`) bloqueia 100% do dano de um Ataque (acao `1`).

### 2. Entradas Fornecidas
```text
1
1
3
1
2
2
1
0
```

*Detalhamento das entradas:*
- `1`: Modo 2 Jogadores.
- `1`: P1 escolhe Chassi Equilibrado (Custo Atk: 4, Dano: 8, Custo Def: 2, Recarga: 10).
- `3`: P2 escolhe Chassi Tanque (Custo Atk: 3, Dano: 5, Custo Def: 1, Recarga: 10).
- **Rodada 1:**
  - P1 escolhe `1` (Atacar): gasta 4 de energia (40 - 4 = 36 pts). Dano emitido = 8.
  - P2 escolhe `2` (Defender): gasta 1 de energia (40 - 1 = 39 pts). Ativa escudo.
- **Rodada 2:**
  - P1 escolhe `2` (Defender): gasta 2 de energia (36 - 2 = 34 pts). Ativa escudo.
  - P2 escolhe `1` (Atacar): gasta 3 de energia (39 - 3 = 36 pts). Dano emitido = 5.
- **Rodada 3:**
  - P1 escolhe `0` (Encerra o teste).

### 3. Resultado Esperado
- Na Rodada 1: P1 consome 4 de energia e ataca; P2 consome 1 de energia ativando escudo. O escudo do Jogador 2 bloqueia totalmente o ataque de P1 (P2 permanece com 39 de energia, sem sofrer dano).
- Na Rodada 2: P1 consome 2 de energia ativando escudo; P2 consome 3 de energia e ataca. O escudo do Jogador 1 bloqueia totalmente o ataque de P2 (P1 permanece com 34 de energia).
- Na Rodada 3: Encerramento limpo por desistencia voluntaria.

### 4. Resultado Observado
A simultaneidade do turno e resolvida de forma atomica pela sub-rotina `resolver_turno`:
```text
-> O escudo do Jogador 2 BLOQUEOU totalmente o ataque!
-> O escudo do Jogador 1 BLOQUEOU totalmente o ataque!
```
Ambos os combatentes tiveram apenas seus custos de acao deduzidos, sem nenhuma reducao de vida decorrente do ataque adversario, comprovando a eficacia total do escudo.

### 5. Justificativa Tecnica
A rotina `resolver_turno` processa as acoes em tres etapas estritas:
1. Subtrai os custos fixos da energia base (`offset 20` de cada vetor).
2. Na etapa de dano, testa se o defensor escolheu a acao `2` (`beq $reg, 2, rt_bloqueio`). Em caso positivo, o calculo de dano e ignorado e a mensagem de bloqueio e impressa, preservando integralmente os pontos de bateria do defensor.

---

## Caso de Teste 3: Situacao Limite (Sobrecarga, Dano Dobrado via `sll` e Morte)

### 1. Objetivo do Teste
Verificar a situacao limite em que robos ultrapassam o teto de 40 pontos de energia via acao de Recarga (`3`), disparando o alerta de **Sobrecarga**, aplicando a duplicacao de dano emitido obrigatoriamente com shift binario (`sll $reg, $reg, 1`) e duplicacao de vulnerabilidade sofrida (multiplicador 2), culminando na eliminacao por energia `<= 0` e declaracao automatica de vitoria.

### 2. Entradas Fornecidas
```text
1
4
2
3
3
1
1
```

*Detalhamento das entradas:*
- `1`: Modo 2 Jogadores.
- `4`: P1 escolhe Reator Instavel (Custo Atk: 5, Dano: 9, Recarga: 16).
- `2`: P2 escolhe Canhoneiro (Custo Atk: 6, Dano: 14, Recarga: 8).
- **Rodada 1 (Disparo da Sobrecarga):**
  - P1 escolhe `3` (Recarregar): 40 + 16 = **56 pts** (> 40 -> Sobrecarga ativa!).
    - Dano emitido dobra de 9 para 18 via `sll`.
    - Vulnerabilidade dobra (multiplicador sofrido = 2x).
  - P2 escolhe `3` (Recarregar): 40 + 8 = **48 pts** (> 40 -> Sobrecarga ativa!).
    - Dano emitido dobra de 14 para 28 via `sll`.
    - Vulnerabilidade dobra (multiplicador sofrido = 2x).
- **Rodada 2 (Combate Devastador):**
  - P1 escolhe `1` (Atacar): gasta 5 de energia (56 - 5 = 51 pts). Causa 18 * 2 (vulnerabilidade P2) = **36 de dano** em P2!
    - Energia P2: 48 - 6 (custo ataque) = 42. Com 36 de dano, vai para **6 pts**.
  - P2 escolhe `1` (Atacar): gasta 6 de energia (48 - 6 = 42 pts). Causa 28 * 2 (vulnerabilidade P1) = **56 de dano** em P1!
    - Energia P1: 51 - 56 = **-5 pts** (atinge `<= 0`).
- **Verificacao de Fim de Jogo:**
  - P1 foi destruido (energia <= 0). Fim automatico de partida.

### 3. Resultado Esperado
- Na Rodada 1, ambas as baterias ultrapassam 40 pontos. Os alertas visuais `[ALERTA] Jogador 1 em SOBRECARGA!` e `[ALERTA] Jogador 2 em SOBRECARGA!` sao exibidos.
- Na Rodada 2, P1 causa 36 de dano em P2, e P2 causa 56 de dano em P1.
- No inicio da Rodada 3, a instrucao `blez` detecta que a energia de P1 e `-5` (`<= 0`) e desvia para `verificar_vencedor`, anunciando `>>> VITORIA DO JOGADOR 2! Parabens! <<<` e encerrando com `syscall 10`.

### 4. Resultado Observado
O programa ativou as mensagens de sobrecarga na Rodada 1. Na Rodada 2, ambos causaram o dano massivo duplicado. Ao iniciar a verificacao da rodada seguinte, a condicao `blez $t1, verificar_vencedor` disparou imediatamente, declarando a vitoria do Jogador 2 sem solicitar novas jogadas.

### 5. Justificativa Tecnica
A instrucao `sll $s0, $s0, 1` realiza o deslocamento logico de 1 bit para a esquerda, correspondendo a uma multiplicacao eficiente por 2 no hardware RISC sem sobrecarregar a ALU com ciclos de multiplicador. A saida da partida e coordenada pela instrucao `blez` (*Branch on Less than or Equal to Zero*) posicionada estrategicamente no inicio de `loop_rodada`, garantindo que um robo com energia esgotada nao possa agir em turnos subsequentes.
