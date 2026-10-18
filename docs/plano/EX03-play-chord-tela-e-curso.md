# EX03 — `play-chord`: a tela, o modo com tempo e um curso de teste

**Repo:** zywny · **Depende de:** EX02 · **Decisão necessária:**
D-EXE-CIFRA (a configuração da grafia)

## Objetivo

1. A tela da pergunta de acorde: a cifra grande, o teclado desenhado com o
   que o aluno segura, e uma mensagem do que faltou ou sobrou.
2. A configuração "Cifra: americana / brasileira" (D-EXE-CIFRA).
3. O **modo com tempo**: `bpm` e `beats` trocam o acorde no metrônomo (PFA
   10: "suba e desça o campo harmônico"; Harrison: II–V–I em todos os tons
   no andamento).
4. Um curso de teste em `test/fixtures/cursos/acordes/`, usado pela
   cobertura e pelo aluno simulado. Ele também serve de modelo para quem
   escrever o Nível 2.

## Ler antes (só isto)

- [EX02](EX02-play-chord-formato-e-sessao.md).
- [E02](E02-som-e-tela.md): a tela de pergunta com teclado.
- `lib/course/ui/question_body.dart`: `_usesKeyboard` (L130), `_onMidi`
  (L250), `_findKeyPrompt` (L645, que já desenha um `KeyboardMarkView`).

## O que fazer

### 1. Configuração da cifra

- Em `AppSettings`, um campo `chordNotation` (`american` ou `brazilian`,
  padrão `american`), salvo como os outros. O painel geral
  (`general_settings_panel.dart`) ganha a linha "Cifra" com as duas
  opções e um exemplo ao lado: `Cmaj7 · Cm7b5` / `C7M · Cm7(b5)`.
- No `course.md`, a chave opcional `chord-notation: brazilian` fixa a
  grafia do curso. Quando o curso fixa, a configuração do app não vale
  nele, e a tela diz isso no rodapé da pergunta ("Este curso usa cifra
  brasileira"). Leia a chave em `course_reader.dart` (`Course` ganha
  `chordNotation`), no molde de `version`.

### 2. A tela — `question_body.dart`

- `_usesKeyboard` passa a incluir `widget.spec is PlayChordSpec`.
- Para o acorde, troque o `_onMidi`: no lugar do `answerPitch`, alimente um
  `ChordAnswerTracker` (EX02) com `noteOn` e `noteOff` (hoje o `_onMidi`
  ignora o note-off: no acorde, ele importa). Quando o tracker fecha uma
  tentativa, chame `_session.answerChord(attempt.pitches)`. Um `Timer` de
  50 ms chama o `tracker.tick`.
- `_chordPrompt(question)`, um método novo:
  - o texto do `prompt`, em fonte grande (o tamanho do título da lição ×
    2), centralizado. Embaixo, as exigências em letra pequena: "1ª
    inversão", "mão esquerda", "sete-três";
  - um `KeyboardMarkView` de C2 a C7 com as teclas **seguradas agora**,
    em cinza. Use `midiInput.held` (já existe; é o que o monitor usa);
  - depois de uma tentativa errada, a mensagem do `ChordVerdict` em
    vermelho, por 3 s, e as teclas que sobraram em vermelho no teclado
    desenhado;
  - **revelação**: depois de 2 tentativas erradas na mesma pergunta, o
    teclado mostra a `reference` em verde por 2 s ("Assim:"). A pergunta
    já perdeu o acerto de primeira e segue esperando.
- Ao acertar, a pergunta segue para a próxima, como no `find-key`. O
  teclado pisca em verde por 300 ms.
- **Atalho de computador** (para testar sem teclado, como os outros tipos
  de pergunta): nenhum. O `play-chord` precisa do teclado MIDI, como o
  `find-key`.

### 3. O modo com tempo

Chaves novas no `PlayChordSpec` (vocabulário e leitura, como no EX02):

| Chave | Valor | Padrão |
| --- | --- | --- |
| `bpm` | andamento, de 30 a 200 | ausente = sem tempo |
| `beats` | tempos por acorde, de 1 a 8 | `4` |

- **Com `bpm`:**
  - um compasso de contagem e o clique do metrônomo
    (`metronome.dart`, `countInBeats`), pela saída de som já escolhida
    (`ensureEngine`, como o E02);
  - cada pergunta dura `beats` tempos;
  - a cifra seguinte aparece **um tempo antes**, menor, à direita da atual
    ("próximo: G7"). Isso dá tempo de preparar a mão (Pike 9: "posicione a
    mão antes de apertar");
  - o acorde vale se fechar **certo** dentro da janela da pergunta: do
    tempo anterior ao primeiro tempo dela até o último tempo dela;
  - se o tempo da pergunta acabar sem acerto, conta erro e a sessão
    avança sozinha, **sem revelação** (não parar: Pike 3).
- **Na sessão:** `QuestionSession` ganha um modo `timed`, com
  `questionSeconds = beats * 60 / bpm`. O `tick` avança sozinho no fim de
  cada pergunta, e o `time-limit` não vale junto (o validador recusa os
  dois juntos).
- **Na tela:** a barra do exercício mostra "♩ = 60" e o botão
  pausar/retomar, como nos tipos com tempo.

### 4. O curso de teste — `test/fixtures/cursos/acordes/`

Um `course.md` e duas lições, que usam todas as chaves do EX02 e deste
passo pelo menos uma vez:

- `01-triades.md`:
  - tríades maiores em teclas brancas;
  - maiores e menores em `roots: random`;
  - as inversões de C em lista;
  - `inversion: random` com `qualities: [M, m]`;
  - `show: name`;
  - `hand: right`.
- `02-setimas.md`:
  - `qualities: [maj7, m7, 7]`;
  - `degrees: [ii7, V7, Imaj7]` com `sequence: cycle-5`, `voicing: 7-3`,
    `hand: left` e `voice-leading: 4`;
  - `rootless-a` com `strict: true`;
  - `sequence: diatonic` em G com `bpm: 60` e `beats: 2`;
  - uma cifra brasileira escrita (`C7M`) com `chord-notation: brazilian`
    num segundo `course.md`, `acordes-br/`.

O texto das lições é curto e funcional: é fixture, não é o curso de
verdade.

## Testes

1. `exercise_question_screens_test.dart`: com MIDI falso, a pergunta
   `C` mostra "C" grande. Apertar 60, 64 e 67 e esperar 150 ms avança. Na
   pergunta seguinte, apertar 60 e 63 e soltar mostra "Faltou…" e não
   avança. Duas tentativas erradas mostram a revelação.
2. O modo com tempo, com relógio falso: a pergunta 1 sem acerto em 4
   tempos avança sozinha e conta erro, e a 2, certa no tempo 2, conta
   acerto. O `RoundResult` dá 1/2.
3. `course_coverage_test.dart`: as chaves `chords`, `inversion`,
   `voicing`, `hand`, `split`, `range`, `strict`, `omit5`, `show`,
   `voice-leading`, `bpm` e `beats` aparecem no curso de teste, e o
   `chord-notation` aparece num `course.md`.
4. `course_simulated_student_test.dart`: os dois cursos passam.
5. A configuração: trocar para brasileira muda o `prompt` de `Cmaj7` para
   `C7M` na pergunta seguinte (teste de widget).

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. `just telas`: as fotos novas da pergunta de acorde no celular e no
   tablet, nos dois temas, sem estouro de texto.
3. **(manual)** Com o teclado do usuário:
   - a lição 01 inteira;
   - a lição 02 com tempo a 60 bpm.
   Registre nas notas se o `holdMs` de 120 ms e a regra "uma tecla
   sozinha não conta" funcionaram, ou quanto mudou.

## Fora de escopo

O `listen-chord` (EX04), o acorde dentro de uma grade (EX11) e o curso de
verdade (a autoria fica com o usuário).

## Notas de execução

(preencher)
