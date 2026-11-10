# Registro de Uso de Inteligência Artificial

Este documento registra a utilização de assistentes e ferramentas de Inteligência Artificial ao longo do ciclo de concepção, especificação e prototipagem do projeto **AOCalipse**, conforme as diretrizes da disciplina de Arquitetura e Organização de Computadores (AOC) — UNIFESP.

---

## 1. Ferramentas Utilizadas
- **Assistente:** Gemini / Antigravity (Google DeepMind)
- **Ambiente:** IDE Antigravity / Interface de Agente Pair Programming
- **Finalidade Principal:** Auxílio na estruturação da documentação técnica, expansão e refinamento das regras de negócio, modelagem do fluxo de controle e prototipagem do código de referência em C com comentários focados em mapeamento MIPS.

---

## 2. Áreas de Aplicação e Finalidades

| Área | Finalidade | Nível de Intervenção Humana |
| :--- | :--- | :--- |
| **Documentação da Proposta** (`docs/proposta-ideia.md`) | Formatação da proposta de submissão da ideia, detalhamento de entradas, saídas, exemplos de interação e inclusão da complexidade adicional (modo Solo contra CPU com semente RNG). | O grupo definiu a mecânica de combate, chassis e a ideia da semente RNG/tempo; a IA auxiliou na redação técnica e alinhamento com syscalls MIPS. |
| **README do Repositório** (`README.md`) | Atualização da identidade visual do projeto ("AOCalipse"), tabela de membros e conversão de tópicos em tabelas de dados de chassis. | Revisado e aprovado diretamente pelo grupo. |
| **Prototipagem em C** (`src/main.c`) | Implementação de um simulador em C equivalente ao algoritmo final, com separação de procedimentos e mapeamento de variáveis para `.data` e `.text`. | Código projetado sob orientação do grupo para refletir a convenção de registradores e chamadas de sistema (syscalls do MARS). |

---

## 3. Exemplo Relevante de Uso

### Contexto
O grupo desejava adicionar uma camada de complexidade técnica ao trabalho além do duelo 1v1 local, permitindo ao usuário jogar contra o computador com controle sobre a aleatoriedade (partidas reprodutíveis para depuração e testes).

### Interação / Prompt
> *"Adicione uma explicação na proposta para adicionar uma complexidade. Pergunta se o usuário quer jogar com 2 jogadores ou contra o computador. Pelo que eu vi dá pra sortear um numero usando syscall. Então dá pra fazer com poucas mudanças. Vamos pedir uma semente aleatoria (inteiro positivo) para o usuario, permitindo partidas diferentes, mas reprodutiveis. Caso coloque -1, usa o tempo de chave (tem outro syscall pra isso)."*

### Solução Gerada e Incorporada
- Mapeamento das chamadas de sistema específicas do MARS:
  - `syscall 40`: define a semente (*set seed*);
  - `syscall 42`: sorteio dentro de limite superior (*random int range*);
  - `syscall 30`: captura de timestamp do sistema de 64 bits (*time*), utilizando os 32 bits menos significativos em `$a0` quando a semente informada for `-1`.
- Condicionamento do prompt: a pergunta da semente aleatória é ativada apenas se o modo contra o computador for selecionado, mantendo a experiência do modo PvP direta e sem atrito.

---

## 4. Verificação e Validação Realizadas
Todas as sugestões e códigos fornecidos pela IA passaram por verificação criteriosa pelo grupo:
1. **Verificação de Compilação e Sintaxe:**
   O arquivo [`src/main.c`](file:///c:/Users/joaov/Github/UNIFESP/Projeto-AOC/src/main.c) foi compilado com GCC (`gcc -Wall -Wextra`) e executado com simulações de entradas automatizadas para validar o fluxo lógico de decisão, limites de sobrecarga e anulação de dano por defesa.
2. **Checagem de Compatibilidade com o MARS 4.5:**
   Confirmou-se que as syscalls sugeridas (`1, 4, 5, 10, 30, 40, 42`) são nativamente suportadas pela versão do MARS indicada na disciplina, sem dependência de bibliotecas externas.
3. **Validação Arquitetural:**
   Garantido que as estruturas de dados no código em C seguem rigorosamente alinhamentos em words (32 bits), de modo que a tradução para labels na seção `.data` e instruções de acesso (`lw`, `sw`, `sll`) ocorra de maneira direta e inequívoca.
