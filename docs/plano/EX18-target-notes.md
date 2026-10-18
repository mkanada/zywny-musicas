# EX18 — `target-notes`: nota-alvo no tempo forte

**Repo:** zywny · **Depende de:** EX11 · **Decisão necessária:** não

## Objetivo

O degrau de improviso mais fácil de avaliar, e o que mais ensina
harmonia. Sobre a grade e a base, o aluno toca **no tempo 1 de cada
compasso** (ou em cada troca de acorde) a nota-alvo pedida: a 3ª, a 7ª,
ou "a nota do acorde mais perto da anterior", que forma a linha de *guide
tones*. No resto do compasso, ele toca livre ou fica em silêncio.

Livros:

- Harrison *Smooth Jazz*, *Contemporary* e *Jazz-Blues*: "uma nota-alvo
  por compasso é um bom ponto de partida", ligada por notas de uma
  "fonte escalar";
- Valerio *BeBop* 5: "estabelecer notas-alvo em intervalos regulares e
  tocar figuras de ligação entre elas";
- a Apostila, "Notas alvo" (currículo 4.8).

O degrau seguinte, no mesmo tipo, exige que as notas **entre** os alvos
saiam de uma `source`. É o "tocar sobre as mudanças" (uma escala para a
progressão toda) contra o "tocar pelas mudanças" (uma escala por acorde)
de Harrison.

## Ler antes (só isto)

- [EX11](EX11-play-chart.md) e [EX10](EX10-timed-round-e-chart-session.md).
- [EX06](EX06-play-pattern.md): o `ScaleKind` e o `scaleDegrees`.

## O formato

````markdown
```zywny-exercise
id: n4-terca-no-um
type: target-notes
title: A 3ª de cada acorde no tempo 1
chart: {progression: ii-V-I, key: C, bars: 8}
target: 3
between: rest
backing: {style: swing, bass: walking}
left: shell-17
bpm: 80
pass: {accuracy: 80}
```

```zywny-exercise
id: n5-guide-tones
type: target-notes
title: A linha de guide tones
chart: {progression: jazz-blues, key: F}
target: guide-tone
between: free
source: by-chord
bpm: 100
pass: {accuracy: 75, source: 80}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `chart`, `key`, `bpm`, `swing`, `backing`, `keys`, `split` | como no `play-chart` | — |
| `target` | `1`, `3`, `5`, `7`, `9`, `chord-tone` (qualquer nota do acorde) ou `guide-tone` (a 3ª ou a 7ª mais perto da nota-alvo anterior: a 7ª de um acorde desce para a 3ª do seguinte) | `3` |
| `when` | `bar` (no tempo 1) ou `change` (em cada troca de acorde) | `change` |
| `between` | `rest` (silêncio entre os alvos), `free` (qualquer coisa) ou `source` (só notas da fonte) | `free` |
| `source` | com `between: source`: `key-scale` (a escala do tom: tocar **sobre** as mudanças), `blues` (a escala de blues do tom), `by-chord` (a escala de cada acorde: tocar **pelas** mudanças; dórico no m7, mixolídio no 7, jônio ou lídio no maj7, lócrio no m7b5, alterada no 7alt) | `key-scale` |
| `left` | o que a esquerda faz: `none` (a base faz o baixo), `root`, ou um molde de voicing (`shell-17`, `7-3`, `rootless-a`), conferido como no `play-chart` | `none` |
| `register` | faixa da mão direita | `C4-C6` |

Chave nova no `pass`: `source`, a % mínima de notas "entre" que saíram da
fonte (só com `between: source` ou `free`). Com `free`, ela só aparece no
retorno.

## O que fazer

1. **O juiz:** `TargetNotesJudge`, uma `TimedJudge`.
   - Um ataque esperado por compasso ou troca, papel `degree` (o grau do
     alvo) na mão direita, janela do D-TREINO.
   - **A guide-tone:** o primeiro alvo é a 3ª ou a 7ª (qualquer das duas).
     Os seguintes são a 3ª ou a 7ª do acorde novo, **a mais perto** (em
     semitons) da nota tocada antes. Se o aluno tocou outra que também é
     3ª ou 7ª, a mais longe, conta `early`/`late` normal mas com a frase "a
     mais perto era…", e **não** erro.
   - **Entre os alvos:**
     - com `rest`, uma nota na mão direita fora do tempo do alvo conta
       como erro;
     - com `source`, cada nota de fora da fonte conta no medidor `source`;
     - com `free`, nada conta, só o medidor.
   - **A esquerda:** se `left` não for `none`, a `ChartSession` confere a
     mão esquerda como no `play-chart`, com o molde `block` (o voicing no
     tempo 1).
2. **A tela:** a `ChartRoundView` (EX11).
   - Em cima de cada caixa da grade, o alvo ("3ª") e, depois de tocado, a
     **nota** que o aluno tocou ("Mi"), em verde ou vermelho.
   - Com `guide-tone`, uma linha liga as notas tocadas de caixa em caixa,
     para o aluno **ver** a linha descendo.
3. **O aluno simulado:** toca o alvo de referência no tempo e nada entre
   os alvos.
4. **O curso de teste:** `test/fixtures/cursos/improviso/01-alvos.md`, com
   cada `target`, cada `between` e cada `source`.

## Testes

1. `target_notes_test.dart`:
   - `target: 3` em ii-V-I de C: F, B, E;
   - `guide-tone` em Dm7-G7-Cmaj7 a partir de C (a 7ª de Dm7) aceita B (a
     3ª de G7), e depois B (a 7ª de Cmaj7, que fica) ou E;
   - com `between: rest`, uma nota no tempo 3 conta erro;
   - com `source: by-chord`, um F♯ sobre G7 conta fora, e sobre Cmaj7
     (lídio) conta dentro, se o lídio estiver na tabela da fonte.
2. `exercise_timed_test.dart`: o aluno simulado passa nos dois exemplos.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas`.
2. **(manual)** O ii-V-I com a 3ª no 1 e a linha de guide tones no
   jazz-blues, com o usuário.

## Fora de escopo

O improviso livre com retorno (EX19).

## Notas de execução

(preencher)
