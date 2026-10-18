# EX06 — `play-pattern`: escalas, arpejos, acordes quebrados e padrões gerados

**Repo:** zywny · **Depende de:** EX01, EX05 · **Decisão necessária:** não

## Objetivo

Um tipo novo, `play-pattern`. O app **gera a partitura** de um padrão
técnico em qualquer tom, com dedilhado escrito e com variações de
articulação e de agrupamento rítmico. O aluno toca no modo espera ou em
tempo real, como no `play-score`.

O que os livros pedem e hoje só existe como partitura fixa (atividades
A2, A3, A4 e B5):

| Padrão (`pattern:`) | O que gera | Livros |
| --- | --- | --- |
| `five-finger` | posição de cinco dedos, subindo e descendo | Pike 2, 13 e 15; Pearl 3 |
| `scale` | escala de 1 a 4 oitavas | Pearl 7; PFA 10; Pike 15 e 21; Valerio *BeBop* 6 ("quatro oitavas, cada mão") |
| `arpeggio` | arpejo de tríade ou tétrade, de 1 a 4 oitavas | Pearl 11; PFA 10; Pike 26 e 27 |
| `broken-chord` | acorde quebrado (1-3-5-3, Alberti, 1-5-8-10) | Pearl 11; PFA 1 (Amazing Broken Chord Ballad) |
| `diatonic-chords` | as tríades ou tétrades do campo harmônico, subindo e descendo, em bloco ou quebradas | PFA 10 (treino de tríades e sétimas em cada tom); Pike 7 |
| `three-note` | os 12 padrões de 3 notas do PFA 10: as 6 ordens, acordais ou por grau, subindo uma oitava e descendo | PFA 10 |
| `sequence` | um motivo curto, escrito em graus, repetido subindo a escala (sequência) | Pike 11; Valerio *BeBop* 6 (padrões de escala) |
| `chromatic` | escala cromática | Pearl 7 |

## Ler antes (só isto)

- [EX01](EX01-modelo-de-acordes.md) e [EX05](EX05-keys-e-cycle-no-play-score.md)
  (o `keys:` e o `cycle:` valem aqui também).
- `lib/course/score/round_score.dart`: `_score`, `_writeStaff`,
  `_writeTempo` e `_writtenAccidental` (como uma rodada gerada vira
  MusicXML, com a armadura).
- `lib/course/exercise/exercise_kind.dart`: o `PlayNotesKind` (o molde de
  rodada gerada).

## O formato

````markdown
```zywny-exercise
id: n3-escalas-maiores
type: play-pattern
title: Escala maior, duas oitavas
pattern: scale
scale: major
keys: [C, G, D, A, E]
octaves: 2
hand: right
mode: realtime
bpm: 72
grouping: 4
articulation: legato
pass: {accuracy: 90, rounds: 5}
```

```zywny-exercise
id: n2-campo-de-sol
type: play-pattern
title: As tríades de Sol, quebradas
pattern: diatonic-chords
chords: triads
style: broken
keys: [G]
hand: left
pass: {accuracy: 90}
```

```zywny-exercise
id: n4-tres-notas
type: play-pattern
title: Padrão de 3 notas, por grau
pattern: three-note
order: 132
source: scale
keys: all
pass: {accuracy: 90, rounds: 12}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `pattern` | uma linha da tabela acima | — (obrigatória) |
| `scale` | `major`, `natural-minor`, `harmonic-minor`, `melodic-minor`, `blues`, `major-pentatonic`, `minor-pentatonic`, os modos (`dorian`… `locrian`), `whole-tone`, `diminished-hw`, `diminished-wh`, `bebop-dominant`, `altered`, `lydian-dominant` | `major` |
| `chord` | com `arpeggio` e `broken-chord`: a qualidade (`M`, `m`, `7`, `maj7`, `m7`, `dim7`…) | `M` |
| `chords` | com `diatonic-chords`: `triads` ou `sevenths` | `triads` |
| `style` | com `diatonic-chords`: `block` ou `broken` | `block` |
| `figure` | com `broken-chord`: `1353`, `alberti` (1-5-3-5), `15810`, `guitar` (1-5-8-5), `blues` (1-5-6-5) (Pearl 11) | `1353` |
| `order` | com `three-note`: `123`, `132`, `213`, `231`, `312` ou `321` | `123` |
| `source` | com `three-note`: `chord` (acordal) ou `scale` (por grau) | `scale` |
| `motif` | com `sequence`: os graus do motivo (`[1, 2, 3, 1]`) | — |
| `keys`, `cycle`, `key-start` | como no EX05 | o tom em `key:` |
| `key` | o tom de um padrão só | `C` |
| `octaves` | de 1 a 4 | `1` |
| `direction` | `up-down`, `up` ou `down` | `up-down` |
| `hand` | `right`, `left` ou `both` (as duas em oitavas, em movimento paralelo) ou `contrary` (as duas em movimento contrário, a partir da mesma tônica; Pearl 8) | `right` |
| `fingering` | escrever o dedilhado (`true`/`false`) | `true` |
| `articulation` | `legato`, `staccato`, `two-slurred` (duas ligadas e duas soltas) ou `accent-first` (acento na 1ª de cada grupo); Pearl 7, "articulação variada" | `legato` |
| `grouping` | `4` (semicolcheias), `3` (tercinas), `2` (colcheias), `dotted` (pontuada e semicolcheia) ou `swing` (colcheias com swing escrito como tercina de semínima e colcheia); Pearl 7, "agrupamentos rítmicos variados" | `2` |
| `mode`, `bpm` | como no `play-score` | `wait` |

## O que fazer

1. **Escalas:** `packages/zywny_music/lib/scale.dart`:
   - `enum ScaleKind` com os valores da chave `scale`, cada um com os
     intervalos em semitons;
   - `scaleDegrees(kind, KeySpec)` dá as classes de altura **com a
     grafia** (letra e alteração), pela regra das quintas do tom. A
     cromática sobe com sustenidos e desce com bemóis.
   Teste as 12 tonalidades de cada escala contra uma tabela escrita à mão
   para C, F♯ e B♭.
2. **Dedilhado:** `packages/zywny_music/lib/fingering.dart`, com uma
   tabela das **escalas maiores e menores harmônicas** (as duas mãos, uma
   e duas oitavas) e dos **arpejos maiores e menores**. A fonte é o
   apêndice de Pike ("Escalas maiores", "Escalas menores harmônicas
   selecionadas", "Arpejos de duas oitavas") e PFA 10. Os dedilhados
   são fato técnico, e não texto do livro. Para padrões sem tabela
   (`three-note`, `sequence`, as escalas do jazz), `fingering: true`
   **não escreve nada** e as notas registram a lacuna. O validador avisa
   (aviso, não erro) quando o `fingering: true` cai num padrão sem tabela.
3. **Gerar a sequência de notas:** `lib/course/score/pattern_score.dart`.
   Cada padrão vira uma lista de `(pitch, figura, dedo?, articulação)` e
   depois MusicXML, com as funções do `round_score.dart`:
   - o `_writeStaff` ganha o `<fingering>`, o `<staccato/>`, o `<accent/>`,
     as ligaduras de expressão (`<slur>`) e as tercinas
     (`<time-modification>`). Confira no render que o Verovio desenha
     cada um;
   - com `hand: both`, a esquerda fica uma oitava abaixo, na pauta de fá;
   - com `contrary`, as duas começam na tônica (a direita em C4 e a
     esquerda em C3) e se afastam;
   - os compassos se fecham sozinhos: completar o último com uma nota
     longa na tônica.
4. **A rodada:** o `PlayPatternKind` gera o `ScoreRound` (o molde do
   `PlayNotesKind`, com `pitches` e `noteIds` preenchidos). O tom sai do
   `keys`/`cycle` (EX05, mesma função) e escreve a armadura certa. Nada é
   transposto pelo Verovio: o padrão já nasce no tom.
5. **O medidor de legato (depois do EX08):** com `articulation: legato`
   ou `staccato`, o resumo mostra o medidor correspondente. Até o EX08
   existir, isso fica pendente (anote na tabela de passos).
6. **Os outros lugares:**
   - `exerciseSummary`: "Escala maior · 2 oitavas · 5 tons";
   - `course_render_check`: renderiza um tom de cada exercício;
   - `exerciseNeedsMidi`: sim;
   - o aluno simulado, como no `play-notes`.
7. **O curso de teste:** `test/fixtures/cursos/tecnica/`, com um
   exercício por padrão e cada valor de `articulation`, `grouping`, `hand`
   e `figure` pelo menos uma vez.
8. **A especificação:** a seção `### play-pattern` em
   `docs/licoes/formato-v1.md`, com as tabelas deste arquivo.

## Testes

1. `scale_test.dart` e `fingering_test.dart` (no `zywny_music`).
2. `pattern_score_test.dart`:
   - a escala de Ré maior em 2 oitavas tem 29 notas (15 subindo e 14
     descendo), e F♯ e C♯ com armadura de 2 sustenidos;
   - o arpejo de Am7 em 1 oitava, subindo e descendo: A C E G A G E C A;
   - `three-note` com `order: 132` e `source: scale` em C, só subindo:
     C E D, D F E, E G F…;
   - com `grouping: 3`, os compassos em 4/4 têm tercinas e fecham certo;
   - `hand: contrary` em C: a direita sobe e a esquerda desce, com notas
     espelhadas.
3. O render: cada exercício do curso de teste renderiza sem erro e o
   `midi.json` bate com os `pitches` da rodada (o mesmo teste do
   `play-notes`).

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just curso-validar --render`
   aceita o curso de teste.
2. `just telas` com uma escala de 2 oitavas e dedilhado, no celular (a
   escala de 2 oitavas cabe em 2 sistemas?).
3. **(manual)** Tocar a escala de Sol em 2 oitavas no modo espera, com o
   dedilhado na tela.

## Fora de escopo

A conferência do dedilhado (o MIDI não sabe que dedo tocou) e o medidor
de legato (EX07 e EX08).

## Notas de execução

(preencher)
