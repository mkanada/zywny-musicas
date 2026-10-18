# EX04 — `listen-chord`: ouvir a qualidade do acorde; "casa ou tensão?"

**Repo:** zywny · **Depende de:** EX01 · **Decisão necessária:** não

## Objetivo

O `listen-chord` era o tipo que o E00 deixou para depois ("um
`listen-chord` no molde do E04"). Ele tem duas formas:

1. **Qualidade:** o zywny toca um acorde e o aluno escolhe, num botão,
   "maior", "menor", "diminuto", "aumentado", "sétima de dominante"…
   (Ear Mastery; currículo 1.8, 2.10 e 4.9).
2. **Casa ou tensão** (`answer: function`): o zywny toca a tônica do tom
   e depois um acorde do campo harmônico, e o aluno diz se ele **repousa**
   (I, vi, às vezes IV) ou **pede resolução** (V, V7, vii°). É o primeiro
   ouvido de função, no Nível 1 (currículo 1.8; Pike 3, "tônica e
   dominante").

Funciona sem teclado.

## Ler antes (só isto)

- [E04](E04-intervalos.md): este passo repete o caminho dele.
  **Cada item vai no mesmo lugar em que o E04 pôs o do
  `listen-interval`.**
- [EX01](EX01-modelo-de-acordes.md) (`ChordSymbol`, `buildVoicing`,
  `ChordDegree`).

## O formato

````markdown
```zywny-exercise
id: n2-maior-menor
type: listen-chord
title: Maior ou menor?
qualities: [M, m]
roots: {random: C3-G4}
count: 10
play: block
pass: {accuracy: 80}
```

```zywny-exercise
id: n1-casa-ou-tensao
type: listen-chord
title: Casa ou tensão?
answer: function
key: C
degrees: [I, IV, V, V7, vi]
count: 8
pass: {accuracy: 75}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `answer` | `quality` (o nome do acorde) ou `function` (casa ou tensão) | `quality` |
| `qualities` | 2 ou mais qualidades (as mesmas do `play-chord`); os botões seguem esta ordem | — (obrigatória com `quality`) |
| `roots` | sorteio de fundamentais `{random: C3-G4}` ou uma lista de notas | `{random: C3-G4}` |
| `inversion` | `root`, `random` | `root` |
| `play` | `block` (juntas), `arpeggio` (de baixo para cima) ou `both` (arpejo e depois bloco) | `block` |
| `key` | com `function`: o tom (ou `random`, para sortear um por pergunta) | `C` |
| `degrees` | com `function`: os graus que podem soar | `[I, IV, V, vi]` |
| `count` | perguntas, de 1 a 40 | `10` |

Com `answer: function`, os botões são sempre **"Casa"** e **"Tensão"**.
A tabela do que é cada grau fica em código e na especificação:

| Graus | Botão |
| --- | --- |
| I, vi, iii | Casa |
| IV, ii | Casa (mas a revelação diz "afasta-se de casa, sem pedir volta") |
| V, V7, vii°, V7/x | Tensão |

Antes de cada pergunta soa a **cadência de referência** I–IV–V–I (curta,
a 100 bpm), como o acorde da tônica do `listen-score`. Depois soa o
acorde da pergunta.

## O que fazer

1. **Modelo, vocabulário e leitura** (como os itens 1 a 3 do E04):
   - `ExerciseType.listenChord('listen-chord')`;
   - os enums `ChordAnswerKind` (`quality`, `function`) e `ChordPlay`
     (`block`, `arpeggio`, `both`);
   - o `ListenChordSpec`.
   Erros: `qualities` com menos de 2 itens, ou repetidas; `degrees` com
   grau inválido (conferido no `course_render_check`, como no EX02);
   `qualities` junto com `answer: function`.
2. **A rodada** (`ListenChordKind`, em `chord_kinds.dart`):
   - **`quality`:**
     - sorteia a fundamental e a qualidade;
     - monta o voicing `close` na região de `roots` (`buildVoicing`);
     - `SoundCue` em bloco (1,5 s), ou um `TimedNote` por nota no arpejo
       (0,35 s cada e o bloco no fim, com `both`);
     - os rótulos dos botões vêm de uma tabela `kChordQualityLabels`
       ("maior", "menor", "diminuto", "aumentado", "sétima (dominante)",
       "sétima maior", "menor com sétima", "meio-diminuto", "diminuto com
       sétima", "sexta", "menor com sexta", "nona", "sus2", "sus4", "7sus4");
   - **`function`:**
     - a cadência de referência é uma lista de `TimedNote` (os quatro
       acordes, 0,6 s cada);
     - depois uma pausa de 0,4 s e o acorde da pergunta;
     - com `key: random`, o tom muda em cada pergunta.
3. **A tela** (`question_body.dart`, como o item 6 do E04):
   - o título é "Que acorde é este?" ou "Casa ou tensão?";
   - o botão "Ouvir de novo";
   - na revelação, o nome do grau ("V7 — pede para voltar ao I") e o
     botão "Ouvir a resolução", que toca o acorde e depois o I.
4. **Os outros lugares:** `exerciseSummary`, `course_render_check`,
   `isQuestion` e `exerciseNeedsMidi` (**não**, só botões).
5. **O curso de teste:** o `acordes/` do EX03 ganha `03-ouvido.md`, com as
   duas formas e todas as chaves.
6. **A especificação:** a seção `### listen-chord` em
   `docs/licoes/formato-v1.md`, com os dois exemplos e as tabelas.

## Testes

1. `course_reader_test.dart`: os dois exemplos e cada erro.
2. `exercise_questions_test.dart`, `group('listen-chord')`:
   - com uma semente fixa, as perguntas têm `answers` na ordem do arquivo
     e `correct` coerente com o `sound`. Confira as classes de altura do
     `SoundCue` contra a qualidade sorteada;
   - `function`: o V7 dá "Tensão", e o I, "Casa"; a cadência vem antes,
     em todas as perguntas;
   - `play: arpeggio`: as notas soam em instantes crescentes.
3. A cobertura e o aluno simulado com o `03-ouvido.md`.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com a pergunta nova.
2. **(manual)** Com som: ouvir 10 perguntas de cada forma e confirmar que
   o arpejo e a cadência soam bem a 100 bpm.

## Fora de escopo

O `listen-progression` (EX15) e acordes com tensões além da 9ª no ouvido.

## Notas de execução

(preencher)
