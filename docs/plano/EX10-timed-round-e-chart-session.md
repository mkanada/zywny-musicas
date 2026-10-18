# EX10 — `TimedRound`, `TimedRoundRunner` e a `ChartSession`

**Repo:** zywny · **Depende de:** EX07, EX09 · **Decisão necessária:**
D-EXE-MAOS e D-EXE-SWING

## Objetivo

A terceira família de rodada. Existem hoje as de **partitura**
(`ScoreRound`: a nota certa na hora certa, pelo `midi.json`) e as de
**pergunta** (`QuestionRound`). Os tipos que não têm uma nota certa por
tempo pedem uma família nova:

- `play-chart`: qualquer voicing do acorde, no padrão rítmico;
- `echo`: a frase repetida de ouvido;
- `target-notes`: só os tempos fortes são cobrados;
- `improvise`: regras, e não notas.

Este passo faz:

1. a `TimedRound`: o que se mostra, o que o app toca em tempos e quem
   julga;
2. o `BeatClock`: tempos ↔ segundos do `SoundEngine`, com contagem,
   metrônomo, pausa e swing;
3. o `TimedRoundRunner`: o executor sem tela, no molde do
   `ScoreRoundRunner`;
4. a interface `TimedJudge` e a **`ChartSession`**, o primeiro juiz: o
   acorde e o padrão rítmico sobre uma grade. O EX11 a liga ao formato.

Sem formato de curso e sem tela neste passo: tudo testável com relógio
falso.

## Ler antes (só isto)

- [EX00](EX00-exercicios-do-curso-completo.md), seção **Família de rodada
  com tempo**.
- `lib/course/exercise/score_round_runner.dart` (inteiro): o ciclo de vida
  `load`, `start`, `cancel` e `dispose`, e o `autoTick`.
- `lib/practice/practice_session.dart`: a `RealtimeSession`, com as janelas
  `windowOkMs` e `windowMaxMs`, o `noteOn`, o `tick` e o `NoteVerdict`.
- `packages/zywny_audio/lib/sound_engine.dart` e `metronome.dart`.
- `lib/main.dart:314`: o `nowSeconds` do MIDI é o **relógio do
  `SoundEngine`** quando há motor. Por isso tempos e teclas estão no mesmo
  relógio.
- [EX02](EX02-play-chord-formato-e-sessao.md) (`checkChord`) e
  [EX07](EX07-gravacao-e-medidores.md) (`PerformanceCapture`).

## O que fazer

### 1. A rodada — `exercise_round.dart`

```dart
/// Um evento MIDI que o app toca, em tempos desde o início da forma
/// (depois da contagem). [channel] 9 = bateria GM (o "canal 10").
@immutable
class BeatNote {
  final double beat;
  final double beats;      // duração
  final int pitch;
  final int velocity;
  final int channel;
  final int? program;      // troca de instrumento antes da 1ª nota do canal
}

/// Rodada com tempo julgada por regras (EX10).
class TimedRound extends ExerciseRound {
  final ChordChart? chart;          // a grade que se mostra (EX09)
  final Uint8List? scoreBytes;      // uma partitura que se mostra (EX17), ou null
  final String? fileName;
  final int bpm;
  final String time;                // '4/4'…
  final int countInBars;            // 1 por padrão
  final double totalBeats;          // a forma inteira, sem a contagem
  final int swing;                  // 50 = reto (D-EXE-SWING)
  final List<BeatNote> appNotes;    // a base, a frase do eco… (EX12, EX14)
  final bool metronome;             // clique do metrônomo durante a forma
  final int split;                  // MIDI (D-EXE-MAOS)
  final TimedJudge Function() judge;
  final String? keyLabel;
}
```

### 2. O relógio — `lib/course/exercise/beat_clock.dart`

```dart
/// Tempos ↔ segundos do SoundEngine. Sem Ticker próprio: quem chama passa
/// o agora (teste com relógio falso).
class BeatClock {
  BeatClock({required this.bpm, required this.beatsPerBar,
      this.swing = 50});
  /// Ancora o tempo [beat] no instante [atSeconds] do motor.
  void anchor(double beat, double atSeconds);
  double secondsAt(double beat);   // com swing aplicado às colcheias
  double beatAt(double seconds);   // o inverso; sem swing (o juiz desfaz)
  /// Aplica swing à posição: uma colcheia no "e" (x.5) cai em
  /// x + swing/100.
  static double swung(double beat, int swing);
}
```

O swing vale **para o que o app toca** e **para as janelas do juiz**: a
colcheia do "e" esperada cai em `x + swing/100`. A partitura e a grade
continuam retas (D-EXE-SWING).

### 3. O executor — `lib/course/exercise/timed_round_runner.dart`

No molde do `ScoreRoundRunner`, com as mesmas dependências (`midiInput`,
`engine`, `inputLatencyMs`, `autoTick`) e o mesmo ciclo
(`load(round)` → `start()` → `Future<RoundResult?>` → `cancel()` →
`dispose()`):

- **`start`:**
  - ancora o `BeatClock` em `engine.earliestScheduleSeconds + 0,2 s`, no
    tempo `−countInBars × beatsPerBar`;
  - agenda a contagem (o clique; use o mesmo som do metrônomo do
    `ScoreAudioScheduler`: procure como ele toca as `beats`), o metrônomo
    (se `metronome`) e os `appNotes`;
  - agenda **em janelas** de 2 s à frente, num `Timer` de 100 ms (ou no
    `pump()` com `autoTick: false`), como o agendador da partitura faz;
    nunca a forma inteira de uma vez.
- **As teclas:** as do `midiInput.notes` e o `sustain` viram tempo com
  `clock.beatAt(note.atSeconds - inputLatencyMs / 1000)`. Elas vão para a
  `PerformanceCapture` (em ms musicais: `beat * 60000 / bpm`) e para o
  `judge`.
- **Saídas:**
  - `position`: um `ValueListenable<({int barOccurrence, double beat})?>`
    para o `ChartCursor` (EX09);
  - `verdicts`: a `Stream<BeatVerdict>` do juiz, para a tela pintar;
  - no fim, `RoundResult` com os `meters` (EX08) e o `feedback` do juiz.
- **Pausa:** `pause()` chama `engine.allNotesOff()` e `clearScheduled()` e
  guarda o tempo atual. `resume()` reancora no mesmo tempo, com um
  compasso de contagem.
- **Fim:** depois de `totalBeats`, ou quando o juiz diz `done` (o eco
  termina quando a última frase foi respondida).

### 4. O juiz — `lib/course/exercise/timed_judge.dart`

```dart
abstract class TimedJudge {
  /// Chamado a cada tecla e a cada tick, em tempos.
  void noteOn(int pitch, int velocity, double beat);
  void noteOff(int pitch, double beat);
  void tick(double beat);
  Stream<BeatVerdict> get verdicts;
  bool get done;
  /// hits/total para o RoundResult, e o retorno em frases (EX19 usa muito).
  ({int hits, int total}) get score;
  List<String> get feedback;
}

@immutable
class BeatVerdict {
  final int slot;                 // índice do que foi julgado (acorde, frase…)
  final PracticeVerdictKind kind; // correct, early, late, wrong, missed
  final String? message;          // "faltou a 3ª", "baixo errado: tocou G"
}
```

### 5. O primeiro juiz — `lib/course/exercise/chart_session.dart`

A `ChartSession` julga **ataques esperados**. Cada ataque esperado vem de
aplicar um **molde de padrão** (EX11) a cada `ChartSlot` da grade:

```dart
enum AttackRole {
  chord,   // o acorde inteiro na mão indicada (checkChord, inversion any)
  degree,  // uma nota: o grau [ExpectedAttack.degree] do acorde (1 = baixo da
           // cifra, ou a fundamental; 3, 5, 6, b7, 8, 9…), contado da fundamental
  tone,    // uma nota do acorde, qualquer, na mão indicada (arpejo livre)
  any,     // qualquer nota da mão indicada (o ritmo importa, a nota não)
}

@immutable
class ExpectedAttack {
  final double beat;          // já com swing
  final AttackRole role;
  final String? degree;       // com AttackRole.degree: '1', '5', 'b7'…
  final Hand hand;            // esquerda / direita (pelo split)
  final int slot;             // o ChartSlot
}
```

Regras:

1. **Janelas:** as do D-TREINO (±75 ms "certo", ±150 ms "quase"), em ms de
   parede, convertidas em tempos pelo `bpm`. Um ataque tocado é o grupo
   de notas da mesma mão que começam a menos de 60 ms umas das outras
   (o acorde não sai perfeitamente junto).
2. **Casamento:** cada ataque esperado casa com o grupo tocado mais
   próximo, dentro da janela máxima, na mão certa. O veredito:
   - `correct` ou `early`/`late`, pela distância, se o conteúdo bate com o
     papel;
   - `wrong`, se o conteúdo não bate ("baixo errado: tocou G, era C";
     "acorde: faltou a 3ª");
   - `missed`, se nenhum grupo caiu na janela.
3. **O conteúdo, por papel:**
   - `degree`: a nota **mais grave** do grupo (na esquerda) ou a **mais
     aguda** (na direita) tem a classe do grau pedido. O grau `1` é o baixo
     da cifra com barra, quando há, senão a fundamental. No grau `5` vale
     também a fundamental (muitos tocam só ela no "pah"): registre se o
     molde pede o contrário;
   - `chord`: `checkChord(grupo, alvo)` com `inversion: any` e a mão do
     ataque. O molde e o `strict` vêm do exercício (EX11);
   - `tone`: alguma nota do grupo é do acorde;
   - `any`: qualquer nota serve.
4. **Grupos tocados que não casam** com nenhum ataque esperado contam como
   **extras**. Eles não reprovam, a não ser com `strict-rhythm: true`
   (EX11), e o retorno os conta ("12 ataques fora do padrão, quase todos
   no tempo 4": o aluno enfeitou ou correu).
5. **O placar:** `hits` = vereditos `correct` (mais `early`/`late`, se a
   regra do `StageResult` os contar como acerto: siga a mesma regra);
   `total` = ataques esperados.
6. **Os medidores** (EX07) recebem a `capture`. Nos medidores que
   comparam com o escrito, os "pares casados" são os ataques casados: o
   `steadiness` funciona na grade, e o `swing` também.
7. **`choruses`:** uma volta da forma sem `wrong` nem `missed` conta uma
   volta limpa. O placar das voltas vai para o medidor `choruses`.

## Testes

1. `beat_clock_test.dart`:
   - a 120 bpm, o tempo 4 cai em 2 s depois da âncora;
   - com swing 67, o tempo 0,5 cai em 0,67 × 0,5 s;
   - `beatAt(secondsAt(x)) == x` para tempos inteiros.
2. `timed_round_runner_test.dart`, com o `FakeSoundEngine` e o relógio
   falso:
   - a contagem agenda 4 cliques antes do tempo 0;
   - os `appNotes` são agendados em janelas (nunca mais de 2 s à frente);
   - a pausa chama `allNotesOff`;
   - uma tecla em `atSeconds` vira o tempo certo, descontada a latência.
3. `chart_session_test.dart`, com uma grade `| C | F | G | C |` e o molde
   "baixo no 1 e no 3, acorde no 2 e no 4", a 60 bpm:
   - o aluno perfeito dá 16/16;
   - um acorde de F sem a 3ª dá um `wrong` com "faltou a 3ª";
   - um baixo 120 ms adiantado dá `early`;
   - um acorde que falta dá `missed`;
   - um ataque a mais no tempo 4,5 vira extra e não reprova;
   - o mesmo com `strict-rhythm` reprova;
   - o swing 67 aceita a colcheia do "e" em 0,67, e não em 0,5.

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. Nada aparece na tela ainda (EX11).

## Fora de escopo

O formato de curso, os moldes de padrão e a tela (EX11); a base gerada
(EX12).

## Notas de execução

(preencher)
