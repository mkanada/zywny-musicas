# EX00 — Exercícios do curso completo: acordes, grade, eco e improviso

**Fase EX** (de *exercícios*). As letras simples já estão todas em uso
somando este plano e o do bridge. Por isso o prefixo tem duas letras.

**Origem:** a avaliação dos 29 livros convertidos (Pike, Dummies, os 10
livros do Pianoforall e os 17 da Hal Leonard Keyboard Style Series), em
`~/IdeaProjects/music_books_grabber/curso/tipos-de-exercicio.md`. O
currículo que estes tipos servem está em `curso/curriculo.md`, no mesmo
repositório.

**Objetivo:** dar ao formato de cursos (fase I) os tipos de exercício que
os níveis 2 a 6 do currículo pedem. São eles:

- tocar acordes pela cifra;
- acompanhar uma grade de acordes no andamento;
- repetir de ouvido;
- harmonizar uma melodia;
- improvisar com regras;
- medir *como* o aluno toca (legato, dinâmica, pedal, swing), além de
  *o que* ele toca.

Quem executa um passo EX lê o [README](README.md) (seções **Como executar
um passo** e **Convenções**), este arquivo inteiro e o arquivo do passo.
Os passos que mexem num tipo da fase E repetem o caminho do
[E01](E01-formato-e-rodada.md) e do [E04](E04-intervalos.md). Nesses
casos, o passo diz para ler também esses arquivos.

## Por que estes tipos (o resumo da avaliação)

Os livros pedem estas atividades com frequência, e o zywny não tem
nenhuma delas:

| Atividade | Peso nos livros | Tipo desta fase |
| --- | --- | --- |
| Ver a cifra e tocar o acorde, inversões, voicings | 22 livros falam de inversões; o cap. 2 ou 3 de cada Hal Leonard trata de voicings | `play-chord` (EX02, EX03) |
| Aplicar um padrão rítmico ("fórmula") a uma grade de acordes, no andamento | o PFA inteiro (14 ritmos) e o cap. 4 de cada Hal Leonard | `play-chart` (EX09 a EX12) |
| Tocar o mesmo padrão em 12 tons ou pelos ciclos | 23 livros | `keys:`/`cycle:` (EX05) e `play-pattern` (EX06) |
| Tocar junto com a faixa (o piano tirado da gravação) | quase todo exemplo Hal Leonard | a base gerada (EX12) |
| Ouvir e repetir; tirar licks | Vinter, Valerio, Willey | `echo` (EX14) |
| Harmonizar a melodia (I, IV ou V7 pela nota da melodia) | Pike, lições 12, 16, 19, 20, 28 e 31 | `harmonize` (EX16) |
| Nota-alvo no tempo forte, depois as notas de ligação | Harrison (Smooth, Contemporary, Jazz-Blues), Valerio | `target-notes` (EX18) |
| Improvisar: notas seguras, depois variar o ritmo, depois pergunta e resposta | Pike, lições 3, 10 e 17; PFA, livros 6 e 7 | `improvise` (EX19) |
| Legato, dinâmica, a melodia mais forte, troca de pedal, regularidade, swing | Pike, lições 14, 22, 24 e 31; Pearl, cap. 9; Willey; Vinter | medidores (EX07, EX08) |

A leitura à primeira vista fica de fora como tipo novo: o zywny já supera
os livros nela, e só 3 dos 29 a tratam. O EX22 traz só melhorias.

## O que já existe (levantado em 2026-10-17)

| Peça | Onde | Para quê nesta fase |
| --- | --- | --- |
| Tipos de exercício | `ExerciseType` e uma subclasse de `ExerciseSpec` por tipo, em `packages/zywny_course_format/lib/course_model.dart` | cada tipo novo entra aqui |
| Chaves por tipo | `_typeKeys` em `packages/zywny_course_format/lib/vocabulary.dart`; o `pass` em `kPassKeys`, no mesmo arquivo | a validação e as mensagens de erro |
| Leitura | `_buildExercise` em `packages/zywny_course_format/lib/mark_parser.dart` (um `case` por tipo); `kMarkNames` para as marcas de conteúdo | os specs novos e a marca `zywny-chart` |
| Gerar a rodada | `ExerciseKind` e `exerciseKinds` em `lib/course/exercise/exercise_kind.dart` | um `Kind` por tipo novo |
| Duas famílias de rodada | `ScoreRound` (partitura no teclado) e `QuestionRound` (perguntas) em `lib/course/exercise/exercise_round.dart` | `play-chord`, `listen-chord` e `harmonize` (na tela) são de pergunta; `play-chart`, `echo` e `improvise` pedem uma família nova, a `TimedRound` (EX10) |
| Sessão de perguntas | `QuestionSession` em `lib/course/exercise/question_session.dart`: `answerChoice`, `answerPitch`, `answerNote`, acerto de primeira, `time-limit`, revelação | ganha `answerChord` (EX02) |
| Executor de partitura | `ScoreRoundRunner` em `lib/course/exercise/score_round_runner.dart`: renderiza, monta `PracticeController`, contagem, metrônomo, `bpm` | o molde do `TimedRoundRunner` (EX10) |
| Tempo real | `RealtimeSession` em `lib/practice/practice_session.dart`: `noteOn(pitch, musicalMs, velocity:)`, `tick` e as janelas; `PracticeReport` (desvio-padrão, média, compassos piores) em `lib/practice/practice_report.dart` | o molde da `ChartSession` (EX10) |
| Hora da tecla em tempo musical | `scheduler.musicalAtDevice(note.atSeconds - inputLatencyMs / 1000)` em `lib/practice/practice_controller.dart` (perto da L524) | a mesma conversão vale para tudo que é medido |
| Entrada MIDI | `MidiInputService` em `packages/zywny_midi/lib/midi_input_service.dart`: `notes` (`PlayedNote`: pitch, **velocity**, canal, **on/off**, `atSeconds`) e **`sustain`** (CC64, 0 a 127) | os medidores (EX07) precisam de tudo isso; hoje o treino não usa nem o note-off com hora nem o pedal |
| O app toca pautas | `ScoreAudioScheduler.setStaves(hand.appStaves)`; `Hand.appStaves` em `lib/practice/hand.dart` | o molde de "o app toca a outra mão". A base do EX12 **não** passa por aqui: ela é agendada direto no motor (`BeatNote`, EX10), sem Verovio |
| Som | `SoundEngine.schedule(List<ScheduledMidi>)` em `packages/zywny_audio/lib/sound_engine.dart`: MIDI cru, com canal | a base e a bateria no canal 10 (GM), agendadas pelo `TimedRoundRunner` |
| Metrônomo e contagem | `metronomeBeats`, `countInBeats` em `packages/zywny_audio/lib/metronome.dart` | todo tipo com tempo |
| Transpor ao renderizar | a opção `transpose` do Verovio (`Transposition.interval`, em `packages/zywny_music/lib/transposition.dart`), passada em `effectiveOptions` de `lib/app/score_render_session.dart:221` | `keys:` e `cycle:` (EX05) |
| Gerar MusicXML de rodada | `notesScore`, `rhythmScore`, `pickNotes`, `pickFigures` em `lib/course/score/round_score.dart`; `fromMusicXml` em `lib/course/score/lesson_score.dart` | a partitura de `play-pattern`, `play-chart` e `harmonize` |
| Frases geradas por grau | `generateSight`, `SightNote(units, degree)` em `lib/sight_reading/sight_generator.dart`; `sightTimedNotes` em `sight_phrase.dart` | as frases do `echo` (EX14) e as melodias do `harmonize` (EX16) |
| Sons de pergunta | `SoundCue`, `TimedNote` e `ScoreComparison` em `exercise_round.dart`; `cue_player.dart` | o `listen-chord` e o `listen-progression` |
| Progresso | `ExerciseRecord` (aprovado, sequência, melhor %, data) em `lib/course/course_progress.dart` | não muda nesta fase |
| Aluno simulado | `test/support/simulated_student.dart` | cada tipo novo ganha uma resposta simulada |
| Cobertura do curso | `test/course_coverage_test.dart` | cada chave nova precisa ser usada por algum curso de teste |

## Conceitos comuns da fase

Valem para vários passos. Cada passo diz quais usa.

### Cifra (`ChordSymbol`, EX01)

Uma cifra é **fundamental + qualidade + extensões + baixo opcional**. O
leitor aceita as duas grafias:

| Ideia | Americana | Brasileira (também aceita) |
| --- | --- | --- |
| maior | `C` | `C` |
| menor | `Cm`, `Cmin`, `C-` | `Cm` |
| diminuto | `Cdim`, `C°`, `Co` | `C°`, `Cdim` |
| aumentado | `Caug`, `C+` | `C+`, `C(#5)` |
| sétima de dominante | `C7` | `C7` |
| sétima maior | `Cmaj7`, `CM7`, `CΔ` | `C7M`, `C7+` |
| menor com sétima | `Cm7`, `C-7` | `Cm7` |
| meio-diminuto | `Cm7b5`, `Cø` | `Cm7(b5)`, `Cø` |
| diminuto com sétima | `Cdim7`, `C°7` | `C°7`, `C°` |
| sexta | `C6`, `Cm6`, `C6/9` | `C6`, `C6(9)` |
| nona e além | `C9`, `Cmaj9`, `Cm9`, `C11`, `C13`, `C7b9`, `C7#9`, `C7alt` | `C7(9)`, `C7M(9)`, `C7(b9)`, `C7(#11)`, `C7(13)` |
| suspensos e add | `Csus2`, `Csus4`, `C7sus4`, `Cadd9` | `C(add9)`, `C4`, `C7(4)` |
| baixo trocado | `C/E`, `F/G` | `C/E` |

`ChordSymbol.pitchClasses` dá o conjunto de classes de altura (0 a 11).
`ChordSymbol.label(notation)` escreve a cifra de volta na grafia escolhida
(D-EXE-CIFRA). Ver o **EX01**.

### Grau e tom

Um acorde também pode ser pedido por grau num tom: `ii`, `V7`, `IVm`,
`bVII`, `V7/vi`. Os romanos em maiúscula pedem acorde maior, e em
minúscula, menor. O resultado é um `ChordSymbol` ou uma lista deles, na
mesma biblioteca do EX01.

### Voicing

Um **molde** diz quais notas do acorde entram e em que ordem, de baixo
para cima:

| Molde (`voicing:`) | Notas | Livros |
| --- | --- | --- |
| `close` | posição fechada, na inversão pedida | PFA 3; Pike 9 |
| `shell-17` / `shell-13` | fundamental e 7ª / fundamental e 3ª (a mão esquerda do bebop) | Valerio *BeBop* 3 |
| `7-3` | 7ª e 3ª, ou 3ª e 7ª (as guide tones) | Harrison *Intro* 2 |
| `7-3-ext` | 7-3 com a 9ª ou a 13ª | Harrison *Intro* 3 |
| `rootless-a` / `rootless-b` | 3-5-7-9 / 7-9-3-5 | Valerio *Post-Bop* 1 |
| `block` | as quatro notas do acorde de sétima, fechadas | Harrison *Intro* 3 |
| `quartal` | três ou quatro notas empilhadas em 4ª, dentro da escala do acorde | Valerio *Post-Bop* 1 e 4; PFA 7 |
| `so-what` | três 4ªs e uma 3ª maior em cima | Valerio *Post-Bop* 2 |
| `tenth` | fundamental e 10ª na esquerda | Valerio *Stride*; PFA 6 |
| `upper-triad` | uma tríade na direita sobre a fundamental e a 7ª na esquerda | Harrison; Valerio *Post-Bop* 2 |

O EX01 constrói o voicing a partir de **cifra + molde + região**. A
conferência (EX02) aceita qualquer voicing que tenha as classes de altura
pedidas, e só exige o molde quando o exercício pede (D-EXE-ACORDE).

### Ciclos e sequência de tons (EX01)

| `sequence:` | Fundamentais, a partir de `from:` (padrão C) |
| --- | --- |
| `random` | sorteadas, sem repetir em seguida |
| `cycle-5` | C F B♭ E♭ A♭ D♭ G♭ B E A D G (descendo em quintas; o "círculo de quintas" de Harrison e do PFA) |
| `cycle-4` | C G D A E B F♯ D♭ A♭ E♭ B♭ F |
| `chromatic` | descendo por semitom (Valerio) |
| `whole-tone` | descendo por tom, as 6 da série e depois as outras 6, um semitom acima (Valerio) |
| `diatonic:<tom>` | os graus do campo harmônico do tom, subindo e descendo (PFA 10) |

### Mãos sem partitura (D-EXE-MAOS)

Nos tipos sem partitura escrita, a mão é decidida pela altura:

- tipos sem partitura: `play-chart`, `echo`, `improvise` e `rhythm` com
  duas mãos;
- regra: abaixo do ponto de divisão é a esquerda, e do ponto para cima, a
  direita;
- o ponto vem da chave `split:` do exercício (padrão `C4`).

Nos tipos com partitura, a mão continua a ser a pauta, como hoje.

### Medidores (EX07)

Tudo o que o teclado manda vira uma **gravação** (`PerformanceCapture`): as
notas com início e fim em ms musicais, a velocity e o pedal. Os medidores
leem essa gravação:

- legato;
- staccato;
- dinâmica;
- equilíbrio entre as mãos;
- pedal;
- regularidade;
- swing;
- acentos;
- resistência.

Cada medidor devolve um número e uma frase para a tela, e entra no `pass`
como chave opcional (EX08). Ver a tabela de limiares no EX07.

### Família de rodada com tempo e sem partitura de notas (EX10)

`play-chart`, `echo`, `target-notes` e `improvise` não têm "a nota certa
na hora certa". Eles têm regras. A rodada nova é a `TimedRound`, que
carrega:

- a partitura que se mostra: a grade, as cifras, ou nada;
- o que o app toca: a contagem, a base, a frase do eco;
- um **avaliador** (`TimedJudge`) que recebe a gravação ao vivo e devolve
  vereditos por tempo e, no fim, um `RoundResult` e um retorno.

O executor é o `TimedRoundRunner`, no molde do `ScoreRoundRunner`.

## Decisões (D-EXE)

Recomendações desta fase, propostas em 2026-10-17. **Nenhuma está
tomada.** Quem executa um passo que depende de uma decisão aberta para e
pergunta ao usuário (regra 3 do README).

| Id | Pergunta | Bloqueia | Recomendação | Status |
| --- | --- | --- | --- | --- |
| D-EXE-CIFRA | Como a tela escreve a cifra: americana (`Cmaj7`, `Cm7b5`) ou brasileira (`C7M`, `Cm7(b5)`)? Uma configuração do app ou do curso? | EX02 em diante | O leitor aceita as duas. A tela segue uma configuração geral nova, "Cifra: americana / brasileira" (padrão **americana**, a dos livros e dos sites de cifra), e o curso pode fixar uma com `chord-notation:` no `course.md` | aberta |
| D-EXE-ACORDE | Quanto o acorde é cobrado | EX02, EX11 | Por padrão, só as **classes de altura**: dobrar notas pode, e uma nota a mais ou a menos é erro. A inversão, o molde e a região só contam quando o exercício pede (`inversion:`, `voicing:`, `strict: true`). A 5ª justa pode faltar nos acordes de sétima ou mais (`omit5`, padrão `true`): Harrison e Valerio tiram a 5ª o tempo todo | aberta |
| D-EXE-QUANDO | Quando o `play-chord` sem tempo confere | EX02 | Confere assim que as teclas apertadas **juntas** formam o acorde, mantidas por 120 ms, e acerta na hora. Se o aluno **soltar tudo** sem ter formado o acorde, conta erro, e a pergunta segue esperando (a regra das perguntas) | aberta |
| D-EXE-MAOS | Como separar as mãos sem partitura | EX10, EX11, EX13, EX14, EX19 | Ponto fixo por exercício, `split:` (padrão `C4`): abaixo é a esquerda, do ponto para cima é a direita. Deduzir pela posição fica para depois | aberta |
| D-EXE-BASE | A base de acompanhamento | EX12 | **Gerada pelo app** a partir da grade e do estilo: bateria GM no canal 10 e baixo. Serve a qualquer tom e andamento, sem direitos. Faixas gravadas ficam para depois, se a base gerada soar pobre | aberta |
| D-EXE-IMPROVISO | O improviso tem nota de aprovação? | EX19 | Passa quem cumpre o mínimo da regra do modo (por exemplo, 80% das notas no conjunto permitido). O resto é **retorno**, sem nota: pausas, frases, variedade, motivo | aberta |
| D-EXE-SWING | Como o swing entra | EX10, EX12 | Só no que o app gera (a base, o eco e as janelas da grade), com `swing: 0..100` (50 = reto, 67 = tercina). A partitura escrita continua reta: o Verovio não aplica swing | aberta |
| D-EXE-LIMIARES | Os números dos medidores (legato, dinâmica, pedal) | EX07, EX08 | Os da tabela do EX07, provisórios. O EX08 os mede com o teclado do usuário e corrige | aberta |
| D-EXE-ORDEM | Por onde começar | ordem da fase | Pela ordem da tabela abaixo: o `play-chord` (EX01 a EX03) vem antes porque o `play-chart` precisa do mesmo modelo de acorde | aberta |

## O formato novo (resumo; os detalhes estão nos passos)

Tipos novos, com um exemplo cada:

````markdown
```zywny-exercise
id: n2-triades-maiores
type: play-chord
title: Toque o acorde
chords: {qualities: [M, m], roots: random, count: 10}
pass: {accuracy: 80}
```

```zywny-exercise
id: n5-ii-v-i-ciclo
type: play-chord
title: II–V–I pelo ciclo de quintas, sete-três
chords: {degrees: [ii7, V7, Imaj7], sequence: cycle-5, count: 12}
voicing: 7-3
hand: left
bpm: 60
beats: 4
pass: {accuracy: 85}
```

```zywny-exercise
id: n2-escala-sol
type: play-pattern
title: Escala de Sol maior, duas oitavas
pattern: scale
scale: major
keys: [G]
octaves: 2
hand: right
articulation: legato
mode: realtime
bpm: 72
pass: {accuracy: 90, legato: 85}
```

```zywny-exercise
id: n2-oom-pah
type: play-chart
title: Oom-pah em Dó
chart: {progression: I-IV-V-I, key: C, bars: 8}
pattern: oom-pah
bpm: 80
backing: drums
pass: {accuracy: 85, steadiness: 40}
```

```zywny-exercise
id: n3-eco-blues
type: echo
title: Repita a frase
source: {scale: blues, key: C}
notes: 4
measures: 1
bpm: 80
backing: shuffle
count: 6
pass: {accuracy: 70}
```

```zywny-exercise
id: n2-harmonize
type: harmonize
title: Harmonize com I, IV e V7
melody: {step: 7b, key: G}
chords: [I, IV, V7]
pass: {accuracy: 80}
```
````

Chaves novas em tipos que já existem:

| Tipo | Chave | Passo |
| --- | --- | --- |
| `play-score` | `keys:`, `cycle:` (transpor por rodada) | EX05 |
| `play-score` | `hand: sequence` (esquerda, direita e juntas mais devagar) | EX22 |
| `play-score` | `practice: cumulative` | EX22 |
| `rhythm` | `hands: two`, `abc` com duas vozes e `split:` | EX13 |
| `pass` (todos com tempo) | `legato`, `staccato`, `dynamics`, `balance`, `pedal`, `steadiness`, `swing`, `accents`, `choruses`, `tempo-ladder` | EX08, EX22 |

Marca de conteúdo nova: **`zywny-chart`**, uma grade de acordes desenhada
na lição (EX09).

## Passos

| Passo | Título | Depende de | Decisão | Status |
| --- | --- | --- | --- | --- |
| [EX01](EX01-modelo-de-acordes.md) | Acordes: cifra, grau, voicing e ciclos (Dart puro, `zywny_music`) | — | D-EXE-CIFRA | pendente |
| [EX02](EX02-play-chord-formato-e-sessao.md) | `play-chord`: formato, rodada e conferência do acorde (Dart puro) | EX01 | D-EXE-ACORDE, D-EXE-QUANDO | pendente |
| [EX03](EX03-play-chord-tela-e-curso.md) | `play-chord`: a tela, o modo com tempo e um curso de teste | EX02 | D-EXE-CIFRA | pendente |
| [EX04](EX04-listen-chord.md) | `listen-chord`: ouvir a qualidade do acorde; "casa ou tensão?" | EX01 | — | pendente |
| [EX05](EX05-keys-e-cycle-no-play-score.md) | `play-score` com `keys:` e `cycle:`: transpor por rodada | — | — | pendente |
| [EX06](EX06-play-pattern.md) | `play-pattern`: escalas, arpejos, acordes quebrados e padrões de 3 notas gerados | EX01, EX05 | — | pendente |
| [EX07](EX07-gravacao-e-medidores.md) | Medidores: gravação da execução e os nove medidores (Dart puro) | — | D-EXE-LIMIARES | pendente |
| [EX08](EX08-medidores-no-pass-e-na-tela.md) | Medidores no `pass`, no resumo e "ouvir o que toquei" | EX07 | D-EXE-LIMIARES | pendente |
| [EX09](EX09-grade-zywny-chart.md) | Grade: modelo, marca `zywny-chart` e a partitura da grade | EX01 | — | pendente |
| [EX10](EX10-timed-round-e-chart-session.md) | `TimedRound`, `TimedRoundRunner` e a `ChartSession` (avaliar a grade) | EX07, EX09 | D-EXE-MAOS, D-EXE-SWING | pendente |
| [EX11](EX11-play-chart.md) | `play-chart`: formato, moldes de padrão, a tela e um curso de teste | EX10 | D-EXE-ACORDE | pendente |
| [EX12](EX12-base-gerada.md) | Base gerada: bateria e baixo a partir da grade e do estilo | EX11 | D-EXE-BASE, D-EXE-SWING | pendente |
| [EX13](EX13-rhythm-com-duas-maos.md) | `rhythm` com duas mãos: polirritmia, clave, acentos; "qual é a clave?" | EX07, EX10, EX12 | D-EXE-MAOS | pendente |
| [EX14](EX14-echo.md) | `echo`: ouça e repita, com ou sem base | EX10, EX12 | D-EXE-MAOS | pendente |
| [EX15](EX15-listen-progression.md) | `listen-progression`: ouvir os graus de uma progressão | EX04, EX09 | — | pendente |
| [EX16](EX16-harmonize.md) | `harmonize`: harmonizar uma melodia (na tela e no teclado) | EX02, EX10, EX11 | — | pendente |
| [EX17](EX17-play-lead-sheet.md) | `play-lead-sheet`: melodia escrita e acorde pela cifra | EX11, EX16 | — | pendente |
| [EX18](EX18-target-notes.md) | `target-notes`: nota-alvo no tempo forte e as notas de ligação | EX11 | — | pendente |
| [EX19](EX19-improvise.md) | `improvise`: improviso com regras e retorno | EX14, EX18 | D-EXE-IMPROVISO | pendente |
| [EX20](EX20-follow-form.md) | `follow-form`: não se perder na forma | EX12 | — | pendente |
| [EX21](EX21-theory-quiz.md) | `theory-quiz`: perguntas de teoria geradas | EX01, EX02, EX06 | — | pendente |
| [EX22](EX22-leitura-e-repertorio.md) | Leitura e repertório: cortina, ensaio, `tempo-ladder`, `hand: sequence`, prática acumulativa | EX07 | — | pendente |

### Ordem e o que cada passo destrava

| Bloco | Passos | O aluno ganha | Nível do currículo |
| --- | --- | --- | --- |
| 1 | EX01 a EX04 | tríades, inversões, tétrades, voicings, ouvir a qualidade | 2 a 5 |
| 2 | EX05, EX06 | tudo em 12 tons; escalas e arpejos gerados | 2 em diante |
| 3 | EX07, EX08 | retorno de qualidade: legato, dinâmica, equilíbrio, pedal, regularidade | 1 em diante |
| 4 | EX09 a EX12 | tocar pela cifra com ritmo e base: o PFA e os grooves | 2 a 4 e os cursos de estilo |
| 5 | EX13, EX14 | groove nas duas mãos; tocar de ouvido | 3 em diante |
| 6 | EX15 a EX19 | harmonia funcional, lead sheet, improviso | 3 a 6 |
| 7 | EX20 a EX22 | acabamento | todos |

O bloco 2 não depende do 1 e pode ir em paralelo. O bloco 3 também.

## Fora desta fase

- **O treino do dia adaptativo** (seção 0.2 do currículo): o app ainda
  não monta sessões sozinho. As regras tiradas dos livros ficam
  registradas abaixo, para quando essa fase existir.
- **O dedilhado:** o MIDI não diz que dedo tocou. Fica no texto e na
  partitura.
- **Faixas gravadas e play-along com gravações de verdade** (D-EXE-BASE).
- **Teclado na tela** (D-LIC: o zywny não tem).

### Regras para o futuro treino do dia (dos livros)

1. Sessão em três partes (Vinter: 10 + 10 + 10 min): aquecimento, os
   pontos fracos isolados ("não perca tempo nos 95% que você já toca") e
   uma parte livre.
2. Triagem (Pike 16): os 2 ou 3 piores problemas, num trecho curto, e
   passar ao seguinte (combina com o reforço do J07).
3. O tom inicial muda todo dia (Pike 7), e só metade dos 12 tons entra por
   dia (Pike 13). O EX05 já grava o tom de cada rodada para isso.
4. Registro por tom com data (Pike 25), para a revisão espaçada por tom.
5. No estilo, a mão esquerda primeiro: o groove só ganha a direita quando
   a esquerda passa no medidor de regularidade (Vinter; Valerio; Harrison).
6. Mãos separadas, depois juntas a 80% do andamento (Pike 16; EX22).
7. Três peças em estágios diferentes ao mesmo tempo (Pike 34).
8. A peça descansa: sai do treino quando a meta não vem em N dias (Pike 33).
9. Começar no andamento do trecho mais difícil (Pike 26).
10. No `harmonize`, não mostrar a resposta da vez anterior (Pike 19).
11. Ouvir antes de tocar, em todo exercício de estilo (Valerio; Willey).
