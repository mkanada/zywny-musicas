# EX02 — `play-chord`: formato, rodada e conferência do acorde (Dart puro)

**Repo:** zywny · **Depende de:** EX01 · **Decisão necessária:**
D-EXE-ACORDE e D-EXE-QUANDO ([EX00](EX00-exercicios-do-curso-completo.md))

## Objetivo

Um tipo novo, `play-chord`. A tela mostra uma cifra (ou um grau num tom,
ou o nome por extenso), o aluno toca o acorde no teclado MIDI, e o app
confere o **conjunto de notas**. Quando o exercício pede, confere também a
inversão, o molde de voicing, a mão e a condução de vozes. É da família
das **perguntas** (`QuestionRound`), com acerto de primeira e
`time-limit`, como o `find-key`.

Este passo faz o formato, a rodada e a conferência, sem tela. A tela vem
no EX03.

Cobre as atividades B1, B2, B3, B4 e B5 da avaliação. Livros: PFA 1 a 5
e 10; Pike 5, 7, 9 e 10; Cowling 1; o cap. 2 e 3 de cada Hal Leonard.

## Ler antes (só isto)

- [EX00](EX00-exercicios-do-curso-completo.md) e
  [EX01](EX01-modelo-de-acordes.md).
- [E01](E01-formato-e-rodada.md): este passo faz um tipo novo de pergunta
  pelo mesmo caminho. **Cada item vai no mesmo lugar em que o E01 pôs o
  do `listen-note`.**
- `lib/course/exercise/question_session.dart` (inteiro) e
  `lib/course/exercise/exercise_round.dart` (`Question`, `QuestionRound`).

## O formato

````markdown
```zywny-exercise
id: n2-triades
type: play-chord
title: Toque o acorde
chords: {qualities: [M, m], roots: random, count: 10}
pass: {accuracy: 80}
```

```zywny-exercise
id: n2-inversoes-de-do
type: play-chord
title: Dó maior nas três posições
chords: [C, C, C]
inversion: [root, first, second]
pass: {accuracy: 100}
```

```zywny-exercise
id: n5-ii-v-i
type: play-chord
title: II–V–I em todos os tons, sete-três
chords: {degrees: [ii7, V7, Imaj7], sequence: cycle-5, count: 12}
voicing: 7-3
hand: left
voice-leading: 4
pass: {accuracy: 85}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `chords` | **lista fixa** de cifras (`[C, Am, F, G7]`), **sorteio por qualidade** (`{qualities, roots, count}`) ou **graus** (`{degrees, key, sequence, count}`) | — (obrigatória) |
| `inversion` | `any`, `root`, `first`, `second`, `third`, `random`, ou uma **lista** (uma por acorde, em ciclo) | `any` |
| `voicing` | um molde do EX00 (`close`, `shell-17`, `7-3`, `rootless-a`…); ausente = qualquer voicing | ausente |
| `hand` | `left`, `right` ou `any`; `left` pede todas as notas abaixo de `split`, e `right`, todas a partir dele | `any` |
| `split` | uma nota | `C4` |
| `range` | faixa permitida (`C3-C6`) | `A0-C8` |
| `strict` | `true`: além das classes de altura, o molde e a inversão pedidos têm de bater exatamente | `false` |
| `omit5` | a 5ª justa pode faltar nos acordes de sétima ou mais | `true` |
| `show` | o que a tela pede: `symbol` (a cifra), `degree` ("ii7 em Fá"), `name` ("Ré menor com sétima") | `symbol` |
| `voice-leading` | movimento máximo em semitons de um acorde para o seguinte (`voiceLeadingDistance`); acima disso, conta como erro de primeira | ausente |

Chaves do sorteio, em `chords: {…}`:

| Chave | Valor | Padrão |
| --- | --- | --- |
| `qualities` | lista de `M`, `m`, `dim`, `aug`, `7`, `maj7`, `m7`, `m7b5`, `dim7`, `6`, `m6`, `9`, `sus2`, `sus4`, `7sus4` | — |
| `roots` | `random`, uma lista (`[C, F, G]`) ou `white` (só teclas brancas) | `random` |
| `degrees` | lista de graus (`[ii7, V7, Imaj7]`), no lugar de `qualities` | — |
| `key` | o tom dos graus; com `sequence`, o tom de partida | `C` |
| `sequence` | `random`, `cycle-5`, `cycle-4`, `chromatic`, `whole-tone`, `diatonic` | `random` |
| `count` | com `qualities`, quantos acordes (1 a 40); com `degrees`, **quantos tons** (cada tom gera um acorde por grau) | `10` / `1` |

Com `degrees` e `sequence`, a sequência gira as **fundamentais dos tons**:
`ii7 V7 Imaj7` em C, depois em F, depois em B♭… (Harrison, *Intro*: "II–V–I
em todos os tons pelo Círculo de Quintas"). Com `qualities` e `sequence`,
a sequência gira as fundamentais dos acordes.

`pass`: os mesmos das perguntas (`accuracy`, `rounds` e `time-limit`).

## O que fazer

### 1. Modelo — `course_model.dart`

- `ExerciseType.playChord('play-chord')`.
- Enums novos, no molde do `AnswerInput`:
  - `ChordInversionChoice` (`any`, `root`, `first`, `second`, `third`,
    `random`);
  - `ChordHand` (`left`, `right`, `any`);
  - `ChordPrompt` (`symbol`, `degree`, `name`).
  O molde de voicing é **texto validado** contra os nomes do
  `VoicingShape` do EX01. O pacote do formato não importa o
  `zywny_music`? Confira no `pubspec.yaml` do `zywny_course_format`. Se
  não importa, valide por uma lista de nomes copiada, com um teste que
  compara as duas.
- `sealed class ChordsSpec` com:
  - `FixedChords(List<String> symbols)`;
  - `RandomChords(qualities, roots, count, sequence, from)`;
  - `DegreeChords(degrees, key, sequence, count)`.
  O pacote guarda **texto**. Quem lê a cifra e confere é o app: o
  `ListenScoreSpec.step` segue a mesma regra.
- `class PlayChordSpec extends ExerciseSpec` com `chords`, `inversions`
  (`List<ChordInversionChoice>`, com um item só quando não é lista), `voicing`
  (`String?`), `hand`, `split` (`Pitch`), `range` (`NoteRange`), `strict`,
  `omit5`, `show` e `voiceLeading` (`int?`).

### 2. Vocabulário — `vocabulary.dart`

- `ExerciseType.playChord` em `time-limit` (`kPassKeys`).
- Em `_typeKeys`, as chaves da tabela. O `chords` precisa de um
  `ValueType` novo, `chordsSpec`: aceita uma lista de textos ou um mapa com
  as chaves do sorteio. Escreva o leitor dele no `field_reader.dart`, no
  molde do `notes` (`ValueType.notes`, que também aceita lista ou mapa).
- A `inversion` é `option` ou lista de `option`. Se o `KeyDef` não tiver
  esse caso, crie o `ValueType.optionOrList`.

### 3. Leitura — `mark_parser.dart`, caso novo em `_buildExercise`

Erros, cada um com a linha da chave:

- cifra que o `ChordSymbol.parse` (EX01) não entende: "``Cxyz`` não é uma
  cifra: não entendi `xyz`". O validador do pacote não conhece o EX01. A
  conferência das cifras fica no `course_render_check.dart` do app (como
  os passos do `listen-score`), e o `just curso-validar --render` a
  executa. Se o pacote já depender do `zywny_music`, confira direto no
  parser;
- `qualities` e `degrees` juntos: "use `qualities` **ou** `degrees`";
- `inversion: third` com uma tríade fixa: "tríade não tem 3ª inversão";
- `voicing` com `inversion` diferente de `any`: "o molde já decide a
  ordem das notas; tire `inversion`";
- `hand: left` com `voicing: so-what`, `upper-triad` ou `block` (duas
  mãos): aviso, não erro.

### 4. A rodada — `lib/course/exercise/chord_kinds.dart` (arquivo novo)

```dart
/// O que a pergunta de acorde exige. Montado pelo `PlayChordKind`.
@immutable
class ChordTarget {
  final ChordSymbol chord;        // EX01
  final Set<int> required;        // classes de altura obrigatórias
  final Set<int> allowed;         // que podem estar além das obrigatórias
  final Inversion inversion;      // any = não confere
  final VoicingShape? shape;      // null = não confere
  final bool strict;
  final ChordHand hand;
  final int split;                // MIDI
  final int lowest, highest;      // range
  final int? voiceLeadingMax;
  /// O voicing de referência (buildVoicing), para mostrar na revelação.
  final List<int> reference;
}
```

- `Question` ganha `final ChordTarget? chord;` e o texto da pergunta em
  `prompt`:
  - `show: symbol` → `chord.label(notation)` (a grafia vem da configuração
    do D-EXE-CIFRA; até ela existir, a americana);
  - `degree` → "ii7 em Fá";
  - `name` → "Ré menor com sétima". Escreva a função `chordName` com a
    tabela de nomes por qualidade.
- `PlayChordKind.generate`:
  1. monta a lista de `ChordSymbol` por `FixedChords`, `RandomChords` ou
     `DegreeChords`, usando `rootSequence`, `ChordDegree.inKey` e
     `KeySpec` (EX01);
  2. resolve a `inversion` de cada um. Com `random`, sorteia entre as
     possíveis e escreve no `prompt` ("C, 1ª inversão");
  3. calcula a `reference` com `buildVoicing` (`near` = a referência
     anterior, para a revelação mostrar a condução boa);
  4. devolve `QuestionRound([...])`.
- Registre em `exerciseKinds`.

### 5. A conferência — `lib/course/exercise/chord_check.dart` (arquivo novo)

```dart
/// O veredito de uma tentativa (um conjunto de notas tocadas juntas).
@immutable
class ChordVerdict {
  final bool ok;
  final Set<int> missing;   // classes de altura que faltaram
  final Set<int> extra;     // classes que sobraram
  final bool wrongInversion, wrongShape, wrongHand, outOfRange;
  final int? voiceLeading;  // distância até o acorde anterior
  /// "Faltou a 3ª (Mi)." · "Sobrou Fá." · "Está na 2ª inversão; pedi a 1ª."
  final String message;
}

ChordVerdict checkChord(List<int> pitches, ChordTarget target,
    {List<int>? previous, NoteNaming naming = NoteNaming.letters});
```

Regras, de acordo com o D-EXE-ACORDE:

1. `pcs = pitches.map((p) => p % 12).toSet()`.
2. `missing = target.required - pcs`; `extra = pcs - target.required -
   target.allowed`. Há erro se algum dos dois não estiver vazio.
3. Se a inversão foi pedida, ela vem da classe da **nota mais grave**,
   comparada à nota do acorde que a inversão põe no baixo. Numa cifra com
   barra, o baixo pedido é o da barra.
4. Se o molde foi pedido, `readVoicing(pitches, chord).shape == shape`.
   Com `strict: false`, basta que as classes de altura do molde estejam
   presentes e que a ordem de baixo para cima respeite o molde. Com
   `strict: true`, a ordem tem de ser exata (sem dobras).
5. A mão: com `left`, todas as notas `< split`; com `right`, todas
   `>= split`.
6. A região: todas as notas entre `lowest` e `highest`.
7. A condução de vozes: com `voiceLeadingMax` e `previous`, a
   `voiceLeadingDistance(previous, pitches) <= max`. Acima disso, o
   acorde **vale**, mas conta como erro de primeira. A mensagem diz
   "o acorde está certo, mas a mão andou 9 semitons; tente ficar perto do
   anterior".

### 6. Quando conferir — `lib/course/exercise/chord_answer.dart` (arquivo novo)

A regra do D-EXE-QUANDO, em Dart puro e com relógio injetável:

```dart
/// Junta as teclas tocadas em tentativas de acorde.
class ChordAnswerTracker {
  ChordAnswerTracker({required this.target, this.holdMs = 120,
      double Function()? nowMs});

  /// Devolve uma tentativa quando ela fecha: o conjunto **segurado** casa
  /// com o alvo e se mantém por [holdMs] (fecha certo, e quem chama avança),
  /// ou o aluno solta **todas** as teclas sem ter casado (fecha errado,
  /// com o maior conjunto segurado de uma vez).
  ChordAttempt? noteOn(int pitch, double atMs);
  ChordAttempt? noteOff(int pitch, double atMs);
  ChordAttempt? tick(double atMs);
  void reset(ChordTarget next);
}
```

- O "maior conjunto segurado de uma vez" vale porque o aluno costuma
  soltar as teclas uma a uma: o veredito usa o acorde inteiro que ele
  segurou, e não o último resto.
- Uma tecla apertada e solta sozinha antes de formar 2 notas **não** conta
  como tentativa. É o aluno procurando a posição. Registre nas notas se,
  no teclado, isso conta erro demais ou de menos.

### 7. Sessão — `question_session.dart`

```dart
/// Tentativa de acorde (`play-chord`). Mesma convenção de retorno de
/// [answerChoice]. [previous] é o acorde aceito na pergunta anterior
/// (condução de vozes).
bool? answerChord(List<int> pitches) { … }
ChordVerdict? lastChordVerdict; // para a tela
List<int>? lastAcceptedVoicing;
```

Ela usa o `checkChord`. Com o acorde certo e a condução de vozes acima do
máximo, avança, mas marca a pergunta como errada de primeira.

### 8. Os outros lugares (os mesmos do E01, item 5)

- `exerciseSummary`: "Toque o acorde · 10" ou "II–V–I · 12 tons".
- `course_render_check.dart`: confere todas as cifras e graus com o EX01 e
  devolve o erro com a linha.
- `exercise_source.dart` → `isQuestion`: acrescente `playChord`.
- `exerciseNeedsMidi`: **sim**.
- O aluno simulado (`test/support/simulated_student.dart`): para uma
  pergunta com `chord`, toca a `reference` (todas as notas juntas) e solta
  tudo depois de 200 ms.

## Testes

1. `course_reader_test.dart`: os três exemplos do topo viram
   `PlayChordSpec` com os campos certos. Cada erro do item 3 tem a sua
   mensagem.
2. `chord_check_test.dart`:
   - `C` com [60, 64, 67] certo, com [60, 64] errado ("Faltou a 5ª") e
     com [48, 60, 64, 67, 72] certo (dobras);
   - `C7`: [60, 64, 70] certo com `omit5` e errado sem;
   - a inversão: [64, 67, 72] é a 1ª;
   - `7-3` de G7: [65, 71] certo, e [71, 77] certo (3ª embaixo);
   - `hand: left` com uma nota em C4 dá erro;
   - a condução de vozes: C [60, 64, 67] → F [60, 65, 69] dá 3.
3. `chord_answer_test.dart`, com relógio falso:
   - apertar C-E-G juntas e segurar 120 ms fecha certo;
   - apertar C-E, soltar, apertar C-E-G fecha certo, sem erro (soltar só
     parte não fecha);
   - apertar C-E-A e soltar tudo fecha errado com {C, E, A};
   - uma tecla sozinha, solta, não fecha.
4. `exercise_questions_test.dart`, `group('play-chord')`:
   - semente fixa: `qualities: [M]`, `count: 5` dá 5 perguntas com
     `chord.required` de tríade maior;
   - `degrees: [ii7, V7, Imaj7]`, `sequence: cycle-5`, `count: 2` dá 6
     perguntas: Dm7 G7 Cmaj7 Gm7 C7 Fmaj7.
5. `course_simulated_student_test.dart`: um curso de teste com os três
   exemplos passa com o aluno simulado.
6. `course_coverage_test.dart`: as chaves novas entram na cobertura do
   curso de teste (fixture), e não no curso inicial.

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. `just curso-validar` aceita um curso com os três exemplos e recusa uma
   cifra inválida com a linha certa.

## Fora de escopo

A tela (EX03), o modo com tempo (EX03), o som do acorde e o
`listen-chord` (EX04).

## Notas de execução

(preencher)
