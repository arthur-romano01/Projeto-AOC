<h1 align="center"> 🚀 Duelo de Robôs - MIPS 🚀 <br>
  <img src="https://img.shields.io/badge/UNIFESP-Universidade%20Federal%20de%20S%C3%A3o%20Paulo-215a36" alt="UNIFESP">
  <img src="https://img.shields.io/badge/Arquitetura%20e%20Organiza%C3%A7%C3%A3o%20de%20Computadores-2026.2-215a36" alt="AOC 2026.2">
</h1>

## 📖 Descrição do Produto
**Duelo de Robôs** é um jogo tático de combate em turnos para dois jogadores (1v1 simultâneo em terminal), desenvolvido em linguagem Assembly MIPS para o simulador MARS.

Antes do combate iniciar, cada jogador escolhe o **Chassi** de seu robô entre 4 opções com custos e multiplicadores distintos. A cada rodada, ambos os jogadores selecionam suas ações em segredo (o terminal rola linhas em branco para ocultar a jogada anterior). Em seguida, o sistema revela simultaneamente os movimentos, processa as interações lógicas de ataque, defesa e recarga, avalia a mecânica de **Sobrecarga** e atualiza o estado de energia dos competidores até a vitória de um dos lados.

---

## 👥 Integrantes

| Nome                        |   RA   |
| --------------------------- | :----: |
| Arthur Romano da Luz        | 168498 |
| Felipe ...                  |  ...   |
| João Victor Assaoka Ribeiro | 168863 |
| Luis ...                    |  ...   |
| Paulo ...                   |  ...   |

---

## 🛠️ Instruções de Execução

---

## 🎮 Comandos de Interação

### 1. Seleção de Chassi (Início do jogo)
Cada jogador escolhe seu chassi digitando um número de `1` a `4`:
- `1`: **Equilibrado** `[Custo: 4 | Dano: 8 | Defesa: 2 | Recarga: 10]`
- `2`: **Canhoneiro** `[Custo: 6 | Dano: 14 | Defesa: 4 | Recarga: 8]`
- `3`: **Tanque** `[Custo: 3 | Dano: 5 | Defesa: 1 | Recarga: 10]`
- `4`: **Reator Instável** `[Custo: 5 | Dano: 9 | Defesa: 3 | Recarga: 16]`

### 2. Rodadas de Ação
A cada turno, o jogador ativo digita a sua ação secreta:
- `1`: **Atacar** — Consome `Custo_Ataque` de energia e causa `Dano_Ataque` ao oponente.
- `2`: **Defender** — Consome `Custo_Defesa` de energia e anula completamente qualquer dano recebido no turno.
- `3`: **Recarregar** — Sem custo; recupera `Recarga_Energia` pontos de energia.
- `0`: **Encerrar/Desistir** — Permite abortar a partida a qualquer momento de forma limpa.

### 3. Mecânica Especial: Sobrecarga (Overcharge)
- Se a energia do robô ultrapassar **40 pontos**, ele entra em estado de **Sobrecarga**.
- **Efeito:** Causa o dobro de dano em ataques e também recebe o dobro de dano de ataques sofridos.
- **Implementação em MIPS:** O cálculo do dobro é executado via shift binário para a esquerda (`sll $reg, $reg, 1`).

---

## ⚠️ Limitações Conhecidas
- Por rodar no terminal Run I/O do MARS, a ocultação de jogada secreta depende da emissão de caracteres de quebra de linha (`\n`), podendo ser rolada manualmente para cima caso o jogador quebre a regra de jogo limpo (fair play).
- O simulador não suporta threads reais; a simultaneidade é simulada por leitura sequencial das ações em buffer seguida do cálculo atômico de resolução da rodada.

---

## 📹 Link do Vídeo de Demonstração
- 🔗 **Vídeo no YouTube/Drive:** `[Link a ser adicionado após a gravação]`

---

## 📁 Estrutura do Repositório
```plaintext
Projeto-AOC/
├── README.md               # Apresentação geral, guia de execução e informações
├── Prompt.md               # Especificação e briefing original do trabalho
├── src/
│   └── main.asm            # Arquivo MIPS principal com o loop de jogo e procedimentos
└── docs/
    ├── ficha-tecnica.md    # Estruturas de dados, procedimentos e mapeamento de requisitos
    ├── testes.md           # 3 Casos de teste reproduzíveis detalhados
    └── uso-ia.md           # Registro de ferramentas, finalidades e verificações
```
