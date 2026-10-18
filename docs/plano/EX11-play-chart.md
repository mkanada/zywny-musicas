# EX11 — `play-chart`: acompanhar a grade no andamento

**Repo:** zywny · **Depende de:** EX10 · **Decisão necessária:**
D-EXE-ACORDE

## Objetivo

O tipo que mais muda o curso. O aluno vê uma grade de acordes e a toca no
andamento, aplicando um **padrão rítmico** a cada acorde: o "ritmo é uma
fórmula" do PFA, livro 1. O app confere, tempo a tempo:

- o acorde, em qualquer voicing;
- o baixo na esquerda;
- o ritmo do padrão.

Sem parar no erro (Pike 3: "olhe adiante e retome"), e com reforço dos
compassos errados no fim.

Cobre as atividades C1, C2, C3 e C6 e parte da C4. Livros:

- PFA 1 a 5 (os 14 ritmos, as progressões de prática e as inversões);
- Pike 7 e 8;
- o cap. 4 de cada Hal Leonard (os grooves de cada estilo);
- Harrison *Blues*, cap. 3 e 4 (os padrões de mão esquerda e os
  turnarounds em etapas);
- Valerio (o comping de cada estilo).

## Ler antes (só isto)

- [EX09](EX09-grade-zywny-chart.md) e [EX10](EX10-timed-round-e-chart-session.md).
- [EX05](EX05-keys-e-cycle-no-play-score.md): `keys`, `cycle` e
  `key-start` valem aqui também.
- Para escrever os moldes, a tradução do PFA, livro 1:
  `~/IdeaProjects/music_books_grabber/traducao/Robin Hall - Pianoforall -
  Livro 1 - Rhythm Style.md`. E os exemplos de comping dos Hal Leonard, no
  mesmo diretório. Os moldes são **nossos**: o padrão rítmico é ideia, e
  não texto (`curso/curriculo.md`, seção 7).

## O formato

````markdown
```zywny-exercise
id: n2-oom-pah-c
type: play-chart
title: Oom-pah em Dó
chart: {progression: I-IV-V-I, key: C, bars: 8}
pattern: oom-pah
bpm: 80
pass: {accuracy: 85}
```

```zywny-exercise
id: n3-blues-boogie
type: play-chart
title: Blues em Sol com boogie na esquerda
chart: {progression: blues-12, key: G}
pattern: {grid: 8, left: "1 5 6 5 1 5 6 5", right: ". . C . . . C ."}
swing: 67
bpm: 90
choruses: 2
keys: [G, C, F]
pass: {accuracy: 80, steadiness: 50}
```

```zywny-exercise
id: n2-livre
type: play-chart
title: Escolha o ritmo
chart: "|: C | Am | F | G :|"
key: C
pattern: any
bpm: 70
pass: {accuracy: 80}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `chart` | a grade, no texto do EX09 (`"\|: C \| Am \| F \| G :\|"`), ou `{progression, key, bars}` | — (obrigatória) |
| `key`, `time` | o tom e a fórmula da grade (quando ela vem em texto) | `C`, `4/4` |
| `pattern` | um nome da biblioteca (tabela abaixo), um molde em linha `{grid, left, right}` ou `any` (vale qualquer ritmo: só o acorde e o baixo nos tempos 1 e 3 são cobrados) | — (obrigatória) |
| `bpm` | de 30 a 240 | `80` |
| `swing` | de 50 a 75 | `50` |
| `choruses` | quantas voltas da forma | `1` |
| `keys`, `cycle`, `key-start` | como no EX05; a grade é transposta com `ChordChart.transposedTo` | — |
| `split` | a divisão das mãos | `C4` |
| `voicing`, `strict`, `omit5` | como no `play-chord`, para os ataques `C` | — |
| `strict-rhythm` | `true`: ataques fora do padrão contam como erro | `false` |
| `metronome` | o clique durante a forma | `true` (sem base) |
| `show` | `chords` (as cifras) ou `degrees` (os graus) | `chords` |
| `backing` | (EX12) a base gerada | ausente |

### O molde de padrão

Um compasso de cada mão, dividido em `grid` partes iguais (4 = semínimas
em 4/4; 8 = colcheias; 12 = tercinas de colcheia em 4/4 ou colcheias em
12/8; 16 = semicolcheias). Os símbolos, separados por espaço:

| Símbolo | Quer dizer | Papel do juiz (EX10) |
| --- | --- | --- |
| `.` | nada (ou segura o que vinha) | — |
| `C` | o acorde inteiro | `chord` |
| `1`, `3`, `5`, `6`, `b7`, `7`, `8`, `9`, `10` | uma nota do acorde, pelo grau a partir da fundamental (`10` = a 3ª, uma oitava acima) | `degree` |
| `B` | o mesmo que `1` (baixo) | `degree` |
| `T` | qualquer nota do acorde | `tone` |
| `X` | qualquer nota (só o ritmo) | `any` |

Um acorde que ocupa **meio compasso** (`| F G |`) usa só a metade do molde
que cai nele: o juiz aplica o molde por tempo, e não por acorde.

### A biblioteca de padrões (`lib/course/exercise/comping_patterns.dart`)

Escreva cada molde a partir da descrição do livro e confira com o usuário
no aceite manual. Os nomes e a ideia de cada um:

| Nome | Compasso | Ideia (o que cada mão faz) | Fonte |
| --- | --- | --- | --- |
| `block` | 4/4 | acorde na direita no tempo 1, baixo na esquerda no 1 | Pike 7 |
| `left-note-right-chord` | 4/4 | baixo no 1 e acorde no 2, 3 e 4 | PFA 1, ritmo 1 |
| `straight-beat` | 4/4 | acorde em cada tempo na direita, baixo no 1 e no 3 | PFA 1, ritmo 2 |
| `half-beat-bounce` | 4/4 | acorde em colcheias na direita, com o baixo no 1 e no 3 | PFA 1, ritmo 3 |
| `oom-pah` | 4/4 | baixo no 1, acorde no 2, a 5ª no 3, acorde no 4 | PFA 1, ritmo 4; Pearl 10 |
| `oom-pah-pah` | 3/4 | baixo no 1, acorde no 2 e no 3 (valsa) | PFA 1, ritmo 5; Pearl 10 |
| `six-eight-split` | 6/8 | arpejo 1-5-8 na esquerda e 3-5 na direita | PFA 1, ritmo 6 |
| `split-chord` | 4/4 | acorde dividido entre as mãos: a fundamental e a 5ª na esquerda, a 3ª e a 8ª na direita | PFA 1, ritmo 7 |
| `country-shuffle` | 12/8 | baixo alternado 1-5 e acorde nas tercinas de trás | PFA 1, ritmo 8; Harrison *Country* 4 |
| `twist` | 4/4 | baixo em colcheias 1-1-5-5 e acorde no 2 e no 4 | PFA 1, ritmos 9 e 13 |
| `static-broken` | 4/4 | acorde quebrado 1-5-8-5 na esquerda e nota longa na direita | PFA 1, ritmo 10; Pearl 11 |
| `three-beat-bounce` | 3/4 | baixo no 1 e acorde no "e" do 1, no 2 e no 3 | PFA 1, ritmo 11 |
| `bossa-bounce` | 4/4 | baixo 1-5 em semínimas pontuadas e o acorde sincopado da bossa | PFA 1, ritmo 12; Valerio *Latin* 5 |
| `reggae` | 4/4 | acorde só nos contratempos, e baixo no 1 | PFA 1, ritmo 14 |
| `rock-eighths` | 4/4 | baixo em colcheias na esquerda e acorde em semínimas | Harrison *Beginning Rock* 2 |
| `boogie` | 4/4, swing | 1-5-6-5 em colcheias na esquerda e o acorde no 2 e no 4 | PFA 2; Harrison *Blues* 3 |
| `boogie-walking` | 4/4, swing | 1-3-5-6-b7-6-5-3 na esquerda | Harrison *Blues* 3; Vinter |
| `stride` | 4/4 | baixo no 1 e no 3 (grave), acorde no 2 e no 4 (médio) | Valerio *Stride* 4; PFA 8 (fake stride) |
| `charleston` | 4/4, swing | acorde no 1 e no "e" do 2 (sete-três na esquerda) | Harrison *Intro* 2 |
| `jazz-in-2` | 4/4, swing | baixo no 1 e no 3 e acorde no "e" do 2 e no 4 | Harrison *Intro* 3 |
| `montuno` | 4/4 | o montuno de 2 compassos em oitavas na direita e o tumbao na esquerda (antecipa o 4) | Martignon 4; Valerio *Latin* 1 |
| `ballad-arpeggio` | 4/4 | arpejo aberto 1-5-8-10 na esquerda em colcheias e acorde ou melodia na direita | PFA 6; Harrison *Smooth Jazz* 4 |

Um molde de 2 compassos (o montuno, a bossa) escreve as duas metades
separadas por `|` dentro da linha da mão:
`right: "C . C . . C . C | . C . C . C . ."`.

## O que fazer

1. **Formato:**
   - `ExerciseType.playChart('play-chart')`;
   - o `PlayChartSpec` com as chaves da tabela;
   - no vocabulário, `chart` é texto ou mapa, e `pattern` é texto ou
     mapa;
   - erros: um nome de padrão desconhecido (com sugestão, no molde do
     `suggest.dart`), uma linha de molde com número de símbolos diferente
     de `grid`, um molde de 3/4 numa grade de 4/4 e `swing` sem colcheias
     no molde.
2. **A biblioteca:** `comping_patterns.dart`, com a tabela acima como
   dados (`CompingPattern{name, time, grid, left, right, bars, swingDefault}`)
   e o leitor do molde em linha.
3. **A rodada:** o `PlayChartKind.generate` monta a `TimedRound`:
   - a grade, transposta pelo `keys`/`cycle`;
   - os ataques esperados (o molde aplicado aos `slots()` × `choruses`);
   - o juiz `ChartSession`;
   - o metrônomo.
4. **A tela:** `lib/course/ui/chart_round_view.dart`, usada pelo
   `exercise_screen.dart` quando a rodada é `TimedRound` (um terceiro
   caminho, ao lado de partitura e pergunta):
   - o `ChartView` (EX09) com o cursor do runner;
   - embaixo, o **molde desenhado**: duas linhas de quadradinhos (esquerda
     e direita), com o tempo atual aceso. É a "fórmula" do PFA à vista;
   - cada ataque julgado pinta a caixa do compasso, com verde para tudo
     certo e as cores do treino para o resto;
   - a mensagem do último erro numa linha fixa ("compasso 6: faltou a 3ª
     de F");
   - no fim, o resumo: a %, os compassos piores (`worstMeasures`, como no
     `PracticeReport`), os medidores pedidos e o botão "Repetir os
     compassos difíceis";
   - o botão faz uma rodada nova só com os compassos piores, como o J07.
     Ela não conta para o `pass`, que é da rodada inteira.
5. **O aluno simulado:** para cada `ExpectedAttack`, toca o voicing
   `close` do acorde na direita (C), o grau na esquerda (os graus) ou uma
   nota qualquer (X), na hora exata.
6. **O curso de teste:** `test/fixtures/cursos/grade/`, com uma lição por
   grupo da biblioteca (PFA, rock e blues, jazz, latino) e todas as chaves
   pelo menos uma vez.
7. **A especificação:** a seção `### play-chart` em
   `docs/licoes/formato-v1.md`, com a sintaxe do molde e a tabela da
   biblioteca (nome, compasso e ideia).

## Testes

1. `course_reader_test.dart`: os três exemplos e os erros do item 1.
2. `comping_patterns_test.dart`:
   - todos os moldes da biblioteca têm `grid` símbolos por linha e
     compasso coerente;
   - `oom-pah` numa grade de 1 compasso de C dá os ataques {1: esquerda
     grau 1; 2: direita C; 3: esquerda grau 5; 4: direita C}.
3. `exercise_timed_test.dart`:
   - `play-chart` com o aluno simulado passa;
   - com um aluno que toca sempre C, numa grade C-F-G-C, passa só nos
     compassos de C (25% mais ou menos, conforme o molde);
   - `keys: [G, C, F]` transpõe a grade.
4. Um teste de widget: a grade e o molde aparecem, o cursor anda com o
   relógio falso, e uma caixa fica vermelha depois de um erro.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com o `play-chart` no
   celular e no tablet.
2. **(manual)** Com o usuário, no teclado dele, um exercício de cada grupo
   da biblioteca. Para cada molde:
   - o padrão soa como o livro descreve;
   - o juiz é justo (nem duro, nem frouxo).
   Anote os ajustes nas notas e corrija os moldes.

## Fora de escopo

A base gerada (EX12): até lá, só o metrônomo. A melodia junto
(`play-lead-sheet`, EX17).

## Notas de execução

(preencher)
