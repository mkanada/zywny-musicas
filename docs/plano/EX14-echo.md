# EX14 — `echo`: ouça e repita

**Repo:** zywny · **Depende de:** EX10, EX12 · **Decisão necessária:**
D-EXE-MAOS

## Objetivo

O tipo central do **pilar 2** (tocar de ouvido). O app toca uma frase
curta, sobre a base ou sobre o metrônomo, e o aluno a **repete** logo em
seguida, sem partitura. Depois vem a frase seguinte, sem parar.

É o "ouça e repita" da seção 6 do currículo, e também:

- o "tire os licks das gravações" (Vinter: "não tenha medo do clichê";
  Valerio; Willey);
- a mecânica de **pergunta e resposta** com o app (o EX19 usa a mesma
  base com resposta livre).

O ditado do `listen-score` (E09) é o degrau anterior: lá o ritmo fica à
vista e as notas vêm uma de cada vez, sem tempo. O `echo` tira a partitura
e põe o tempo.

## Ler antes (só isto)

- [EX10](EX10-timed-round-e-chart-session.md) e [EX12](EX12-base-gerada.md).
- `lib/sight_reading/sight_generator.dart` (`generateSight`, `SightNote`,
  `_melody`): o gerador de melodias por grau, com saltos ponderados. O
  `echo` reaproveita a ideia, mas com fontes de notas do jazz e do blues.
- [E09](E09-ditado-com-ritmo.md): o ditado, para a conferência nota a
  nota.

## O formato

````markdown
```zywny-exercise
id: n2-eco-cinco-notas
type: echo
title: Repita: três notas
source: {scale: major, key: C, range: C4-G4}
notes: 3
figures: [quarter, half]
measures: 1
bpm: 70
count: 8
pass: {accuracy: 70}
```

```zywny-exercise
id: n3-eco-blues
type: echo
title: Repita o lick de blues
source: {scale: blues, key: G, range: G3-G5}
notes: 5
figures: [eighth, quarter]
measures: 1
swing: 67
backing: shuffle
chart: {progression: blues-12, key: G}
count: 12
pass: {accuracy: 70}
```

```zywny-exercise
id: n5-eco-licks-ciclo
type: echo
title: O lick de II–V nos 12 tons
source: {licks: ii-v-major}
transpose: cycle-5
bpm: 90
count: 12
pass: {accuracy: 75}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `source` | de onde vêm as notas: `{scale, key, range}` (uma escala do EX06), `{chord-tones: true}` (as notas do acorde da grade, em cada momento), `{licks: <biblioteca>}` ou `{melody: file.musicxml}` (frases recortadas de uma melodia do autor, para tirar uma canção por partes) | — (obrigatória) |
| `notes` | notas por frase, de 1 a 12 | `4` |
| `figures` | figuras permitidas (as do `rhythm`) | `[quarter]` |
| `measures` | compassos por frase, de 1 a 2 | `1` |
| `leaps` | o maior salto, em graus da escala | `3` |
| `start` | `tonic` (a primeira nota é sempre a tônica, mais fácil), `chord-tone` ou `any` | `tonic` |
| `bpm`, `swing`, `backing`, `chart` | como no `play-chart`; sem `chart`, a base fica num acorde só, o da tônica | `80`, `50`, ausente |
| `transpose` | `none`, `cycle-5`, `cycle-4`, `chromatic` ou `random`: cada frase em outro tom (o lick em 12 tons) | `none` |
| `count` | quantas frases | `8` |
| `octave` | `exact` ou `any` (vale repetir uma oitava acima ou abaixo) | `any` |
| `split`, `hand` | a mão que responde | `C4`, `right` |

A **forma no tempo** é uma alternância. Com `measures: 1`, é 1 compasso de
frase do app e 1 compasso de resposta do aluno, e assim por diante. Antes
da primeira frase vêm a contagem ou a introdução da base. O cursor
mostra "OUÇA" e "TOQUE" em cada compasso.

### Bibliotecas de licks (`lib/course/exercise/lick_library.dart`)

Frases curtas **nossas**, escritas em graus e figuras, por estilo. Os
estilos são os capítulos de solo dos Hal Leonard:

- `blues-basic`: escala de blues, notas esmagadas, drone (Harrison *Blues*
  5);
- `blues-crossover`: os "crossover licks" (Harrison *Blues* 5);
- `rock-pentatonic` (Harrison *Beginning Rock* 5);
- `country-major-pent` (Harrison *Country* 5);
- `ii-v-major` e `ii-v-minor` (Valerio *BeBop* 5: arpejo ascendente,
  prefixo de semitom, linha descendente);
- `bebop-enclosure` (Valerio *BeBop* 5);
- `gospel-fills` (Cowling 6);
- `montuno-figures` (Martignon).

Uns 8 licks por biblioteca, cada um com no máximo 2 compassos. **Não
copie** frases dos livros: escreva no espírito e confira com o usuário.

## O que fazer

1. **O gerador de frases:** `lib/course/exercise/echo_phrases.dart`.
   - `scale` e `chord-tones`: uma melodia por grau no molde do `_melody`
     do `sight_generator.dart`, com saltos até `leaps`, figuras de
     `figures` e o tamanho de `notes`. A última nota cai num tempo forte e
     é uma nota do acorde. Escreva a função nova; não mexa no gerador da
     leitura.
   - `licks`: sorteia da biblioteca. Com `transpose`, cada frase seguinte
     anda no ciclo.
   - `melody`: recorta a partitura do autor em frases de `measures`
     compassos, na ordem, para "tirar a canção" por partes.
2. **A rodada:** uma `TimedRound`.
   - Os `appNotes` são as frases do app nos compassos "OUÇA" e a base.
   - O juiz é o `EchoJudge`: para cada compasso "TOQUE", compara a
     sequência tocada com a frase. O alinhamento é por ordem, como no
     ditado (E09), mas com tempo:
     - cada nota esperada casa com a nota tocada mais próxima na ordem;
     - a altura certa, com a regra do `octave`;
     - o ritmo conta só se `rhythm: strict` (chave opcional; padrão
       `loose`, em que vale o contorno e a ordem, e o tempo tem janela de
       ±1/4 de tempo).
   - Os vereditos são um por nota da frase.
3. **A tela:** a `ChartRoundView` do EX11, sem grade quando não há
   `chart`, com o cartão grande "OUÇA" ou "TOQUE" e o contador "frase 3 de
   12". Ao fim de cada resposta, a frase certa aparece por 1 compasso numa
   pauta pequena (`zywny-score` em ABC), com as notas erradas pintadas.
   Isso é a **revelação no tempo**, sem parar a forma.
4. **O aluno simulado:** repete a frase exata, um compasso depois.
5. **O curso de teste:** `test/fixtures/cursos/eco/`, com cada `source`,
   `transpose`, `backing` e `octave`.

## Testes

1. `echo_phrases_test.dart`:
   - com uma semente fixa, a frase de `scale: major` em C, `notes: 3` e
     `start: tonic`, começa em C, tem 3 notas e não salta mais de 3 graus;
   - `transpose: cycle-5` leva o lick de C para F e depois para B♭.
2. `exercise_timed_test.dart`:
   - o aluno simulado passa;
   - um aluno que toca a frase uma oitava acima passa com `octave: any` e
     não passa com `exact`;
   - um aluno que não toca nada dá 0%, e a forma termina sozinha.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com "OUÇA" e
   "TOQUE".
2. **(manual)** 8 frases de cada exemplo com o usuário. Responda nas notas:
   - 1 compasso de resposta basta?
   - a janela `loose` é justa?

## Fora de escopo

A resposta livre (pergunta e resposta, EX19) e o eco de acordes (pode vir
depois: um `echo` com `source: {chords}`, conferido pelo `checkChord`).

## Notas de execução

(preencher)
