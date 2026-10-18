# EX09 — A grade: modelo, marca `zywny-chart` e o desenho da grade

**Repo:** zywny · **Depende de:** EX01 · **Decisão necessária:** não

## Objetivo

A **grade de acordes** é a forma de escrita do PFA (as caixas de
compasso), das progressões de Pike 7 e 8 e do "gráfico de acordes" de
Harrison. Ela vira:

1. um **modelo** (Dart puro): compassos, acordes por tempo, repetições,
   1ª e 2ª casa, seções (A, B), tom e fórmula de compasso;
2. uma **sintaxe de texto** curta, para o autor escrever a grade na lição
   e no exercício;
3. uma **marca de conteúdo**, `zywny-chart`, que desenha a grade na lição;
4. um **widget** (`ChartView`) que desenha a grade e acende o compasso e o
   tempo atuais. O `play-chart` (EX11) o usa.

A grade **não** passa pelo Verovio. É um desenho do Flutter, com caixas e
cifras: não há notas a gravar. Isso evita depender de como o Verovio
desenha `<harmony>` sobre pausas.

## Ler antes (só isto)

- [EX01](EX01-modelo-de-acordes.md) (`ChordSymbol`, `ChordDegree`,
  `KeySpec`, `progressions.dart`).
- `packages/zywny_course_format/lib/mark_parser.dart`: como uma marca de
  conteúdo vira bloco (`KeyboardMark` é o molde mais parecido) e o
  `kMarkNames`.
- `lib/course/ui/keyboard_mark_view.dart`: como uma marca é desenhada na
  lição.

## A sintaxe da grade

````markdown
```zywny-chart
key: C
time: 4/4
chart: |: C | Am | F G | C :|
caption: A progressão de "Blue Moon" (PFA, livro 1)
```

```zywny-chart
key: F
chart: |
  A: | F7 | Bb7 | F7 | Cm7 F7 |
     | Bb7 | Bdim7 | F7 | D7 |
     | Gm7 | C7 | F7 D7 | Gm7 C7 :|
```

```zywny-chart
key: G
progression: blues-12
degrees: true
```
````

Regras da sintaxe, as mesmas na marca e no `chart:` do exercício:

| Escrito | Quer dizer |
| --- | --- |
| `\| C \|` | um compasso inteiro de C |
| `\| F G \|` | dois acordes que dividem o compasso **em partes iguais** (em 4/4, 2 tempos cada; em 3/4, 2 + 1) |
| `\| F . G . \|` | um acorde por tempo; o ponto repete o acorde anterior (aqui, F F G G) |
| `\| % \|` | repete o compasso anterior |
| `\|: … :\|` | repetição; `:\| x3` = três vezes |
| `[1 … ]` e `[2 … ]` | 1ª e 2ª casa |
| `A:` / `B:` no começo da linha | rótulo de seção (aparece na grade) |
| `ii7`, `V7/vi`, `bVII` | graus no `key`, resolvidos pelo EX01; `degrees: true` **mostra** os graus em vez das cifras |
| `N.C.` | sem acorde (*no chord*) |

`progression:` usa um nome da biblioteca do EX01 (`blues-12`, `ii-V-I`…)
no lugar de `chart:`. Com `progression` e `bars: 8`, a progressão se
repete até completar os compassos.

## O que fazer

1. **O modelo:** `packages/zywny_music/lib/chord_chart.dart`.

   ```dart
   @immutable
   class ChordChart {
     final KeySpec key;
     final String time;               // '4/4', '3/4', '6/8', '12/8', '2/4'
     final List<ChartBar> bars;       // como escritos (com marcas de repetição)
     final List<ChartSection> sections;
     static ChordChart? parse(String text, {required KeySpec key,
         String time = '4/4', void Function(String error, int col)? error});
     static ChordChart fromProgression(String name, {required KeySpec key,
         String time = '4/4', int? bars});
     /// A forma tocada: compassos na ordem de execução (repetições e casas
     /// expandidas), cada um com o índice escrito e o número da volta.
     List<PlayedBar> expand();
     /// Os acordes no tempo: início em tempos (desde 0), duração em tempos.
     List<ChartSlot> slots();
     ChordChart transposedTo(KeySpec other); // para keys:/cycle:
   }

   @immutable
   class ChartSlot {
     final int barOccurrence;  // índice na forma tocada
     final int writtenBar;
     final double startBeat;
     final double beats;
     final ChordSymbol? chord; // null = N.C.
   }
   ```

   Os erros do leitor dão a **coluna** dentro do texto: "coluna 14: `Hm`
   não é uma cifra".
2. **O formato:**
   - `ChartMark` no `course_model.dart` (`key`, `time`, `chart` ou
     `progression`, `bars`, `degrees`, `caption`);
   - o nome `chart` em `kMarkNames`;
   - as chaves no `vocabulary.dart`.
   O pacote guarda o **texto** da grade, e a leitura é conferida no
   `course_render_check`, como as cifras do EX02.
3. **O widget:** `lib/course/ui/chart_view.dart`.
   - **Layout:** 4 compassos por linha no celular e 8 no tablet (D-SISTEMAS
     manteve o celular com um sistema; aqui é só texto). As linhas quebram
     nas seções.
   - **Cada compasso é uma caixa**, com as cifras dentro, na grafia do
     D-EXE-CIFRA (EX03) ou os graus. Dois acordes no compasso ficam lado a
     lado; quatro ficam em quatro colunas finas.
   - **Repetição e casas:** barras de repetição como as da partitura (`‖:`
     e `:‖`) e a 1ª e 2ª casa como um colchete em cima das caixas.
   - **`ChartCursor`:** um `ValueListenable<({int barOccurrence, double
     beat})?>` acende a caixa atual. Uma barrinha embaixo da caixa avança
     com os tempos. Na repetição, o cursor volta para a caixa escrita, e
     a volta aparece ("2ª vez").
   - **Cores por slot:** `ChartView` aceita um mapa `slot → Color`, para o
     EX11 pintar o acerto e o erro de cada acorde.
4. **A marca na lição:** `ChartMarkView`, no molde do `KeyboardMarkView`,
   e o caso no leitor de lição (`lesson_view.dart`). O botão "Ouvir"
   embaixo da grade toca a progressão em bloco, a 80 bpm, no som do app.
   Use a mesma função do EX15 (`chartAudio`): escreva-a aqui, numa versão
   simples (o acorde `close` na mão direita e a fundamental na esquerda),
   e o EX12 a substitui pela base.
5. **A especificação:** a seção `### zywny-chart — uma grade de acordes`
   em `docs/licoes/formato-v1.md`, com a tabela da sintaxe.

## Testes

1. `chord_chart_test.dart` (no `zywny_music`):
   - `|: C | Am | F G | C :|` expande em 8 compassos, com F e G de 2
     tempos cada;
   - `| F . G . |` dá F F G G;
   - `[1` e `[2` expandem certo;
   - `%` repete;
   - os graus em F resolvem;
   - `blues-12` com `bars: 24` repete duas vezes;
   - `transposedTo` de C para E♭ escreve `Ab` e não `G#`;
   - os erros com coluna.
2. `lesson_view_test.dart`: a marca desenha 12 caixas para `blues-12`; o
   botão "Ouvir" agenda 12 acordes no `FakeSoundEngine`.
3. `chart_view_test.dart`: o cursor no compasso 5 acende a 5ª caixa; na
   repetição, a mesma caixa com "2ª vez".

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com uma grade de
   blues na lição, no celular e no tablet, nos dois temas.
2. `just curso-validar` aceita os três exemplos e dá a coluna num erro.

## Fora de escopo

Tocar sobre a grade (EX10, EX11) e a base (EX12).

## Notas de execução

(preencher)
