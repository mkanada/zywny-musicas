# EX01 — Acordes: cifra, grau, voicing e ciclos (Dart puro)

**Repo:** zywny (pacote `packages/zywny_music`) · **Depende de:** — ·
**Decisão necessária:** D-EXE-CIFRA (só a grafia de saída; o leitor aceita
as duas)

## Objetivo

Uma biblioteca de acordes sem tela e sem som, na qual se apoiam todos os
passos da fase. Ela sabe:

1. ler uma cifra (`Am7`, `C7M`, `F/G`, `Bb7(#11)`) e dar o conjunto de
   classes de altura, a fundamental e o baixo;
2. escrever a cifra de volta, na grafia americana ou brasileira;
3. resolver um grau num tom (`ii7` em Fá é `Gm7`; `V7/vi` em Dó é `E7`);
4. construir um **voicing** a partir de cifra, molde, inversão e região;
5. gerar a **sequência de fundamentais** pelos ciclos;
6. medir o movimento entre dois voicings (condução de vozes);
7. guardar uma biblioteca de **progressões** conhecidas.

## Ler antes (só isto)

- [EX00](EX00-exercicios-do-curso-completo.md), seções **Cifra**,
  **Grau e tom**, **Voicing** e **Ciclos**.
- `packages/zywny_music/lib/note_name.dart` (`Pitch`, `midi`,
  `kLowestPianoMidi`) e `note_names.dart` (`NoteNaming`, `pitchFromMidi`,
  `kSharpSign`, `kFlatSign`), para usar a mesma grafia de notas do app.
- `packages/zywny_music/lib/transposition.dart`, só para ver como uma
  grafia é escolhida por quintas (Mi♭ e não Ré♯).

## O que fazer

### 1. `packages/zywny_music/lib/chord.dart`

```dart
/// A qualidade "de base" do acorde; as extensões vêm à parte.
enum ChordQuality {
  major, minor, diminished, augmented,
  dominant7, major7, minor7, halfDiminished7, diminished7, minorMajor7,
  major6, minor6,
  sus2, sus4, dominant7sus4,
  power, // C5
}

/// Uma extensão ou alteração: 9, b9, #9, 11, #11, 13, b13, add9, b5, #5.
enum ChordTension { nine, flat9, sharp9, eleven, sharp11, thirteen, flat13,
  add9, add11, flat5, sharp5, omit3, omit5 }

@immutable
class ChordSymbol {
  /// Classe de altura da fundamental (0 = Dó) e a grafia dela (C, C#, Db…).
  final int root;
  final String rootSpelling;
  final ChordQuality quality;
  final Set<ChordTension> tensions;
  /// `null` = baixo na fundamental.
  final int? bass;
  final String? bassSpelling;

  /// Lê `Am7`, `C7M`, `Cm7(b5)`, `F/G`, `Bb7(#11)`, `C6/9`, `C7alt`.
  /// Devolve `null` e preenche [error] se não entende.
  static ChordSymbol? parse(String text, {void Function(String)? error});

  /// Classes de altura (0..11), com o baixo incluído.
  Set<int> get pitchClasses;

  /// As notas que **precisam** estar (sem a 5ª justa quando [omit5] vale e
  /// o acorde tem sétima ou mais; D-EXE-ACORDE).
  Set<int> requiredPitchClasses({bool omit5 = true});

  /// Notas que **podem** estar além das exigidas (a 5ª omitida, a
  /// fundamental num voicing sem fundamental).
  Set<int> allowedPitchClasses();

  /// Grau de cada classe de altura (1, 3, 5, 7, 9, 11, 13; b3, #11…), para
  /// a tela dizer "faltou a 3ª".
  String degreeOf(int pitchClass);

  String label(ChordNotation notation);
}

enum ChordNotation { american, brazilian }
```

Regras do leitor:

- **Fundamental:** A–G com `#` ou `b` (também `♯` e `♭`).
- **Qualidade**, na ordem em que se testa: `m7b5`, `m7(b5)` e `ø` (meio
  diminuto); `dim7`, `°7` e `o7`; `dim`, `°` e `o`; `aug` e `+`;
  `maj7`, `M7`, `Δ`, `7M` e `7+`; `mMaj7`, `m(maj7)` e `m7M`; `m`, `min`
  e `-`; depois os números `7`, `6`, `9`, `11`, `13`, `5`, `sus2`,
  `sus4` e `4`.
- **Casos especiais:**
  - `C°` sozinho é **diminuto com sétima** na grafia brasileira e
    **tríade diminuta** na americana. Registre a escolha numa constante
    (`kDegreeSignMeansDim7 = false`) e documente.
  - `C4` e `C7(4)` são sus4 (grafia brasileira).
- **Tensões:** entre parênteses e separadas por vírgula (`7(b9,#11)`), ou
  coladas (`7b9#11`). `alt` vira `{flat9, sharp9, flat5, flat13}`
  (escolha registrada).
- **Baixo:** depois de `/`.
- **Erros:** texto vazio, fundamental inválida e sobra não entendida
  ("`Cxyz`: não entendi `xyz`").

`label(american)` gera `C`, `Cm`, `Cdim`, `Caug`, `C7`, `Cmaj7`, `Cm7`,
`Cm7b5`, `Cdim7`, `C6`, `C9`, `C7b9`, `Csus4`, `C/E`.

`label(brazilian)` gera `C`, `Cm`, `C°`, `C+`, `C7`, `C7M`, `Cm7`,
`Cm7(b5)`, `C°7`, `C6`, `C7(9)`, `C7(b9)`, `C4`, `C/E`.

As duas usam o `NoteNaming` do app só para a *fundamental*. Na grafia
Dó-Ré-Mi, `Lá m7` fica estranho, por isso a cifra fica sempre em letras
(registre nas notas).

### 2. `packages/zywny_music/lib/chord_degree.dart`

```dart
/// `ii7`, `V7`, `Imaj7`, `IVm`, `bVII`, `vii°`, `V7/vi`, `iiø7`.
@immutable
class ChordDegree {
  static ChordDegree? parse(String text, {void Function(String)? error});
  ChordSymbol inKey(KeySpec key); // KeySpec: tônica + maior/menor
  String get label; // o texto canônico
}

@immutable
class KeySpec {
  final int tonic;          // classe de altura
  final bool minor;
  final String spelling;    // 'G', 'Bb', 'F#m'…
  static KeySpec? parse(String text); // mesma sintaxe do `key:` do formato
}
```

- Os graus do campo harmônico maior e menor vêm de uma tabela: em menor,
  o V é **maior** (V7 da harmônica), como em Pike 21 e na Apostila.
- Algarismos em maiúscula pedem acorde maior, e em minúscula, menor.
  `°`, `ø` e `+` mudam a qualidade, e o sufixo `7`, `maj7` ou `6` acrescenta
  a sétima ou a sexta. Sem sufixo, fica a tríade.
- `/x` é a dominante secundária: o acorde é calculado no tom do grau `x`.
- A grafia das notas segue o tom: em Fá, o IV é **B♭**, e não A♯. Use a
  regra das quintas do `Transposition`.

### 3. `packages/zywny_music/lib/chord_voicing.dart`

```dart
enum VoicingShape { close, shell17, shell13, sevenThree, sevenThreeExt,
  rootlessA, rootlessB, block, quartal, soWhat, tenth, upperTriad }

/// `any` = qualquer inversão vale (só conferência); `root`, `first`,
/// `second`, `third`.
enum Inversion { any, root, first, second, third }

/// Constrói alturas MIDI concretas para o acorde.
List<int> buildVoicing(
  ChordSymbol chord, {
  VoicingShape shape = VoicingShape.close,
  Inversion inversion = Inversion.root,
  required int lowest,  // nota MIDI mais grave permitida
  required int highest,
  int? near,            // centro preferido (condução de vozes)
});
```

A tabela das notas de cada molde está no EX00, seção **Voicing**. Regras:

- O `rootless-a` é 3-5-7-9, e o `rootless-b` é 7-9-3-5, de baixo para
  cima. Num acorde sem 9ª escrita, usa-se a 9ª maior, ou a b9 se a cifra
  tiver `b9` (Harrison e Valerio atualizam a sétima para nona).
- O `quartal` empilha 4ªs justas a partir da 3ª ou da 7ª, pegando as notas
  da escala do acorde. Documente a escala de cada qualidade: dórico para
  m7, mixolídio para 7, lídio para maj7.
- O `tenth` é a fundamental mais a 10ª (3ª + 8ª). Se não couber entre
  `lowest` e `highest`, devolve a fundamental mais a 7ª (Valerio, *Stride*:
  "a nota de baixo pode ser omitida").
- Com `near`, entre os voicings válidos fica o de menor
  `voiceLeadingDistance` até `near`.

```dart
/// Soma dos menores deslocamentos (semitons) emparelhando as vozes de [a]
/// e [b] em ordem; vozes a mais ou a menos custam a distância até a mais
/// próxima. É o "mínimo de movimento" do PFA 3 e de Pike 9.
int voiceLeadingDistance(List<int> a, List<int> b);

/// O voicing tocado: [pitches] reais → inversão (pelo baixo), região
/// (centro), e se bate com um [VoicingShape] (para `strict`).
VoicingReading readVoicing(List<int> pitches, ChordSymbol chord);
```

### 4. `packages/zywny_music/lib/chord_sequence.dart`

```dart
enum RootSequence { random, cycle5, cycle4, chromatic, wholeTone, diatonic }

/// [count] fundamentais (classes de altura) a partir de [from]; `random`
/// nunca repete em seguida. `diatonic` precisa de [key] e sobe e desce os
/// sete graus (PFA 10: "suba e desça o campo harmônico").
List<int> rootSequence(RootSequence seq, {int from = 0, required int count,
  KeySpec? key, Random? rng});
```

Os ciclos estão na tabela da seção **Ciclos** do EX00. No `wholeTone`, as 6
fundamentais da série e depois as 6 outras, um semitom acima: "para obter
as doze tonalidades, o mesmo ciclo é repetido um semitom acima"
(Valerio, *BeBop*, cap. 5).

### 5. `packages/zywny_music/lib/progressions.dart`

Uma biblioteca com nome → graus por compasso, para a grade (EX09) e o
`listen-progression` (EX15). Uma barra `|` separa compassos, e um espaço
separa acordes dentro do compasso. Cada progressão guarda também de onde
vem (livro e capítulo), para os textos das lições.

| Nome | Graus | Fonte |
| --- | --- | --- |
| `I-IV-V-I` | `I \| IV \| V \| I` | Pike 7; PFA 1 |
| `I-V-vi-IV` | `I \| V \| vi \| IV` | PFA 1 |
| `I-vi-IV-V` | `I \| vi \| IV \| V` | PFA 1 ("Blue Moon") |
| `vi-IV-I-V` | `vi \| IV \| I \| V` | currículo 3.6 |
| `ii-V-I` | `ii7 \| V7 \| Imaj7 \| Imaj7` | Harrison *Intro* 2 |
| `ii-V-i` | `iiø7 \| V7 \| im7 \| im7` | Valerio *Latin* 2 |
| `blues-12` | `I7 \| IV7 \| I7 \| I7 \| IV7 \| IV7 \| I7 \| I7 \| V7 \| IV7 \| I7 \| V7` | Harrison *Blues* 3; PFA 2 |
| `blues-12-quick` | o mesmo, com IV7 no compasso 2 | Harrison *Blues* 3 |
| `minor-blues` | `i7 \| i7 \| i7 \| i7 \| iv7 \| iv7 \| i7 \| i7 \| bVI7 \| V7 \| i7 \| V7` | PFA 10; Harrison *Jazz-Blues* |
| `jazz-blues` | `I7 \| IV7 \| I7 \| v7 I7 \| IV7 \| #iv°7 \| I7 \| VI7 \| ii7 \| V7 \| I7 VI7 \| ii7 V7` | PFA 7 e 10; Harrison *Jazz-Blues* 4 |
| `circle-c` | `I \| IV \| vii° \| iii \| vi \| ii \| V \| I` | PFA 1 ("Amazing Broken Chord Ballad") |
| `montuno-i-iv-v` | `I IV \| V IV` | Martignon cap. 4 |
| `turnaround` | `I vi \| ii V` | PFA 3; Vinter |

Uma progressão também pode vir escrita no próprio exercício
(`progression: "ii7 V7 | Imaj7"`). O mesmo leitor serve aos dois casos.

## Testes (`packages/zywny_music/test/`)

1. `chord_test.dart`:
   - todas as linhas da tabela de cifras do EX00 viram o conjunto certo
     (`Cm7b5` → {0, 3, 6, 10}; `C7M` = `Cmaj7`; `F/G` tem 7 no
     `pitchClasses` e `bass == 7`);
   - `label` ida e volta nas duas grafias: `parse(label(x)) == x` para 40
     cifras;
   - erros com mensagem (`Cxyz`, `H7`, ``).
2. `chord_degree_test.dart`:
   - `ii7` em F → Gm7;
   - `V7/vi` em C → E7;
   - `bVII` em C → B♭ (grafia com bemol);
   - em Am, `V7` → E7 e `iv` → Dm;
   - `IV` em Gb → Cb (grafia pelas quintas).
3. `chord_voicing_test.dart`:
   - para cada molde e cada qualidade de sétima em 12 fundamentais, as
     notas estão entre `lowest` e `highest` e `readVoicing` reconhece o
     molde;
   - o `rootless-a` de Dm7 perto do Dó central é F-A-C-E;
   - `voiceLeadingDistance([60,64,67],[60,65,69]) == 3` (C → F na 2ª
     inversão);
   - com `near`, C → F escolhe a 2ª inversão de F.
4. `chord_sequence_test.dart`:
   - os 12 do `cycle5` a partir de C são todos diferentes e na ordem da
     tabela;
   - o `wholeTone` cobre os 12;
   - o `random` não repete em seguida (semente fixa, 1000 sorteios).
5. `progressions_test.dart`: todas as progressões da tabela resolvem em
   C, F♯ e B♭m sem erro, e a contagem de compassos bate.

## Critérios de aceite

1. `cd packages/zywny_music && flutter test` verde, e `just analyze` sem
   avisos.
2. Nenhuma dependência nova fora do Dart puro.

## Fora de escopo

Tela, som, formato de curso (EX02) e escalas (EX06 usa o
`chord_voicing` e acrescenta `scale.dart`).

## Notas de execução

(preencher)
