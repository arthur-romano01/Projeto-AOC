# Ficha Técnica: Duelo de Robôs (MIPS Assembly)

## 1. Objetivo do Produto
O **Duelo de Robôs** é um jogo tático de combate em turnos simultâneos para dois jogadores, implementado na arquitetura MIPS e executável no simulador MARS. O objetivo do jogo é derrotar o robô oponente zerando seus pontos de energia através de gerenciamento estratégico de recursos, leitura de movimentos do adversário e manipulação da mecânica de **Sobrecarga**.

---

## 2. Organização da Lógica
A arquitetura do software divide-se em três etapas bem definidas:
1. **Fase de Inicialização e Escolha de Chassis:**
   - Exibição de menu com atributos balanceados.
   - Leitura protegida e cópia dos dados para a memória de trabalho de cada jogador.
   - Atribuição da energia inicial (40 pontos para ambos).
2. **Loop Principal de Combate:**
   - Exibição do status das baterias e alerta visual de sobrecarga.
   - Leitura da ação secreta do Jogador 1 com rolagem de terminal para preservação do sigilo.
   - Leitura da ação secreta do Jogador 2 com rolagem de terminal.
   - Execução atômica da resolução de turno pelo procedimento `resolver_turno`.
3. **Resolução de Turno e Atualização de Estado:**
   - Revelação pública das jogadas.
   - Aplicação de custos de energia ou ganho de recarga.
   - Verificação de estado de sobrecarga (`> 40` pontos) com cálculo de dobro via `sll`.
   - Comparação de ações (Ataque vs Defesa vs Recarga).
   - Dedução de dano na energia e avaliação das condições de vitória (`<= 0`).

---

## 3. Estruturas de Dados
Os dados são armazenados na seção `.data` de forma estruturada:
- **Vetores de Atributos de Chassis:**
  Cada chassi é armazenado como um vetor contíguo de 4 inteiros (words de 32 bits):
  - Índice `0` (offset 0): `Custo_Ataque`
  - Índice `1` (offset 4): `Dano_Ataque`
  - Índice `2` (offset 8): `Custo_Defesa`
  - Índice `3` (offset 12): `Recarga_Energia`
  - Instâncias: `chassi_1`, `chassi_2`, `chassi_3`, `chassi_4`.
- **Tabela de Ponteiros:**
  - `tabela_chassis`: Vetor com 4 words contendo os endereços base dos chassis cadastrados, permitindo indexação dinâmica via deslocamento binário (`sll $t0, $a0, 2`).
- **Buffers de Estado dos Jogadores:**
  - `p1_atributos` e `p2_atributos`: Vetores de 4 words que recebem uma cópia dos atributos do chassi selecionado para cada jogador.
  - `p1_energia` e `p2_energia`: Words de 32 bits que mantêm o estado dinâmico dos pontos de energia.
  - `p1_acao` e `p2_acao`: Words que guardam temporariamente a intenção do jogador na rodada.

---

## 4. Procedimentos e Boas Práticas
O programa foi projetado respeitando a convenção de registradores MIPS e preservação de contexto via pilha (`$sp`):

| Procedimento              | Responsabilidade                                                       | Parâmetros ($a0-$a3)                                      | Retorno ($v0-$v1)                 | Preservação na Pilha ($sp)    |
| :------------------------ | :--------------------------------------------------------------------- | :-------------------------------------------------------- | :-------------------------------- | :---------------------------- |
| `main`                    | Coordena a máquina de estados global e término.                        | Nenhum                                                    | Nenhum                            | Raiz de execução              |
| `obter_chassi_valido`     | Apresenta opções, lê inteiro e valida range `[1..4]`.                  | Nenhum                                                    | `$v0`: Índice zero-based `(0..3)` | Preserva `$ra`                |
| `carregar_perfil_chassi`  | Copia os 4 words do chassi selecionado ao buffer de destino.           | `$a0`: Índice `(0..3)`<br>`$a1`: Endereço base de destino | Nenhum                            | Utiliza `$t0-$t3` temporários |
| `obter_acao_valida`       | Apresenta prompt específico e valida range `[0..3]`.                   | `$a0`: Endereço da string do prompt                       | `$v0`: Ação válida                | Preserva `$ra`, `$s0`         |
| `ocultar_terminal`        | Emite quebras de linha para ocultação visual no terminal.              | Nenhum                                                    | Nenhum                            | Procedimento folha            |
| `exibir_status_jogadores` | Imprime energia e flag de sobrecarga dos competidores.                 | Nenhum                                                    | Nenhum                            | Preserva `$ra`                |
| `resolver_turno`          | Revela ações, deduz custos, calcula sobrecarga (`sll`) e aplica danos. | Nenhum                                                    | Atualiza dados na memória         | Preserva `$ra`, `$s0` a `$s5` |
| `imprimir_nome_acao`      | Traduz código numérico (1, 2, 3) para texto legível.                   | `$a0`: Código da ação                                     | Nenhum                            | Procedimento folha            |

---

## 5. Localização dos Requisitos Técnicos no Código

| Requisito do Projeto                                        | Atendimento no Código                                                                                                                                                                           | Localização em `src/main.asm`                                             |
| :---------------------------------------------------------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------ |
| **Executar no MARS**                                        | Syscalls padrão (1: print_int, 4: print_str, 5: read_int, 10: exit).                                                                                                                            | Ao longo de todo o arquivo                                                |
| **Entradas e Saídas interativas**                           | Leitura de chassi e ações numéricas; mensagens detalhadas de combate.                                                                                                                           | `obter_chassi_valido`, `obter_acao_valida`, `exibir_status_jogadores`     |
| **Decisões e Repetições com função real**                   | Loops de validação de dados e loop contínuo do jogo (`loop_duelo`); desvios condicionais para resolução de ações (`beq`, `blez`, `bgt`).                                                        | `loop_duelo`, `repete_leitura_chassi`, `resolver_turno`                   |
| **Vetor ou Estrutura de dados**                             | Vetores de palavras com atributos dos robôs e tabela de ponteiros indexada via deslocamento.                                                                                                    | Seção `.data` (`chassi_1` a `chassi_4`, `p1_atributos`, `tabela_chassis`) |
| **Pelo menos 3 procedimentos com responsabilidades claras** | Possui 7 procedimentos modulares (`obter_chassi_valido`, `carregar_perfil_chassi`, `obter_acao_valida`, `ocultar_terminal`, `exibir_status_jogadores`, `resolver_turno`, `imprimir_nome_acao`). | Seção `.text`                                                             |
| **Parâmetros, retornos e preservação de registradores**     | Passagem de parâmetros em `$a0-$a1`, retornos em `$v0`, preservação de `$s0-$s5` e `$ra`.                                                                                                       | Convenção estrita em todos os `jal`                                       |
| **Emprego justificado da pilha ($sp)**                      | Salvamento e restauração de contexto em chamadas aninhadas para evitar sobrescrita de registradores.                                                                                            | Prólogos e epílogos com manipulação explícita de `$sp`                    |
| **Tratamento de entradas inválidas e encerramento limpo**   | Rejeição de valores fora do intervalo permitido com re-solicitação; suporte à opção `0` para desistência/saída limpa.                                                                           | `erro_chassi`, `erro_acao`, `encerra_desistencia`                         |
| **Mínimo de 100 linhas úteis de instruções MIPS**           | Mais de 130 instruções úteis de máquina implementadas diretamente na lógica principal.                                                                                                          | Totalidade do `.text`                                                     |

---

## 6. Contribuição dos Integrantes
- 

---

## 7. Síntese do Feedback Recebido
*(Espaço reservado para registro de observações e recomendações feitas pelo professor ou monitores durante as etapas de validação intermediária).*
- **Ajuste de Mecânica:** Inclusão da opção de saída limpa (código `0`) para garantir o encerramento gracioso a qualquer instante.
- **Usabilidade no Terminal:** Implementação de rolagem por linhas em branco no MARS para mitigar visão espia durante a escolha das jogadas secretas.
