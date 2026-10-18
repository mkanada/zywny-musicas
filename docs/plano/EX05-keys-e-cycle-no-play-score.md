# EX05 — `play-score` com `keys:` e `cycle:`: transpor por rodada

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Um exercício escrito em Dó passa a ser pedido em outros tons. A cada
rodada, o app escolhe um tom da lista, ou o próximo do ciclo, e renderiza
a partitura transposta. É a atividade mais repetida nos livros: 23 dos 29
pedem "em todas as tonalidades".

Exemplos dos livros:

- PFA 10: a rotina de cada tom;
- Harrison: II–V–I em todos os tons;
- Valerio: os licks pelos ciclos de quintas, tons inteiros e semitons;
- Pike 8: transpor Woodland Jaunt de Dó para Fá.

É barato porque a transposição já existe: a opção `transpose` do Verovio,
usada pela fase Q.

## Ler antes (só isto)

- `lib/course/exercise/timed_kinds.dart`: o `PlayScoreKind`.
- `lib/course/exercise/exercise_round.dart`: o `ScoreRound` e o
  `copyWith`.
- `lib/course/exercise/score_round_runner.dart`: o `load`, onde
  `ScoreRenderRequest(… options: layout.options)` é montado (perto da
  L163).
- `packages/zywny_music/lib/transposition.dart`: `Transposition.toFifths`
  e `interval`.
- `lib/app/score_render_session.dart:221`, só para ver que o `transpose`
  é uma opção do Verovio passada junto com o layout.

## O formato

````markdown
```zywny-exercise
id: n2-cinco-dedos
type: play-score
title: Cinco dedos em vários tons
abc: |
  X:1
  L:1/4
  K:C
  CDEF|GFED|C4|]
keys: [C, G, D, F]
pass: {accuracy: 90, rounds: 4}
```

```zywny-exercise
id: n5-lick-ciclo
type: play-score
title: O lick pelo ciclo de quintas
file: media/lick-ii-v.musicxml
cycle: 5ths
mode: realtime
pass: {accuracy: 85, rounds: 12}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `keys` | lista de tons (`[C, G, F]`), `all` (os 12, em ordem sorteada) ou `random` (um sorteado por rodada) | ausente = o tom escrito |
| `cycle` | `5ths`, `4ths`, `chromatic` ou `whole-tone`: a rodada N usa o N-ésimo tom do ciclo, a partir do tom escrito | ausente |
| `key-start` | `written` (o ciclo começa no tom escrito) ou `rotate` (começa num tom diferente a cada dia) | `written` |

- `keys` e `cycle` não valem juntos.
- O tom é sempre o da **armadura escrita**: a partitura em Dó com `keys:
  [G]` sobe uma 5ª ou desce uma 4ª, o que ficar mais perto, pela regra do
  `Transposition.toFifths` (a nota mais grave e a mais aguda da
  partitura, as do piano).
- **`key-start: rotate`** (Pike 7: "comece por um tom diferente a cada
  poucos dias, porque a atenção cai no fim"): o primeiro tom da rodada é
  `dia_do_ano % n`. Use a data local do aparelho.

## O que fazer

1. **Modelo, vocabulário e leitura:** `PlayScoreSpec` ganha `keys`
   (`KeyChoice`: `fixed(List<String>)`, `all` ou `random`), `cycle`
   (`KeyCycle?`) e `keyStart`. Erros:
   - `keys` com tom inválido (a mesma validação do `key:` dos outros
     tipos, seção 8 do formato);
   - `keys` e `cycle` juntos;
   - `cycle` sem armadura legível: a partitura de arquivo sem `<key>`.
     Esse erro sai no `course_render_check`, que já abre a partitura.
2. **A rodada:**
   - o `ScoreRound` ganha `transpose` (`String?`, o intervalo do Verovio)
     e `keyLabel` (`String?`, "Sol maior", para a tela);
   - o `PlayScoreKind.generate` recebe o **número da rodada**. Hoje o
     `generate` não o recebe: acrescente `int roundIndex` ao `generate`
     de **todos** os tipos (os outros ignoram) e passe-o do lugar que
     chama o `generateRound` (procure em `exercise_screen.dart` o
     `_newRound`);
   - o tom sai do `cycle` (o índice), da lista (o índice, em ordem) ou de
     um sorteio (`all`: uma permutação dos 12, sorteada uma vez por
     sessão do exercício e guardada no estado da tela).
3. **A partitura transposta:** o `ScoreRoundRunner.load` põe
   `'transpose': round.transpose` nas opções do `ScoreRenderRequest`.
   O `midi.json` já sai transposto (o pitch do `GenerateMIDIFunctor`
   inclui a transposição: Fatos do README; Q05). Por isso o casador
   confere o tom novo sem mudar nada.
   **Meça antes:** a transposição de um ABC com `K:C` para F♯ e para D♭
   sai com a grafia certa? Registre nas notas.
4. **A tela:** o título da rodada mostra o tom ("Em Sol maior · rodada 2
   de 4"). No fim, o resumo do exercício lista os tons tocados com o
   resultado de cada um ("Dó ✓ · Sol ✓ · Ré 82% · Fá ✓").
5. **O progresso por tom (preparo para o treino do dia):** o
   `ExerciseRecord` **não** muda. Grave um mapa à parte,
   `course_key_progress:<curso>:<exercício>`, com `tom → {melhor %,
   última data}`, no molde do `CourseProgressStore`. Ninguém lê ainda: é
   o "registro por escala com data" de Pike 25, para o futuro treino do
   dia.

## Testes

1. `course_reader_test.dart`: os dois exemplos; `keys: [H]` dá erro;
   `keys` com `cycle` dá erro.
2. `exercise_timed_test.dart`:
   - o `cycle: 5ths` a partir de C dá `transpose` P4, P4+P4 (B♭)…:
     confira os 12 primeiros `transpose`, e que a rodada 13 volta ao C;
   - `keys: all`, com semente fixa, cobre os 12 em 12 rodadas, sem
     repetir;
   - `key-start: rotate` com uma data falsa começa no tom
     `dia % 12`.
3. Um teste de render (`test/support/render_helper.dart`): o ABC do
   exemplo em `keys: [D]` dá um `midi.json` com F♯ (66) e C♯ (73), e o
   aluno simulado passa.

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. **(manual)** O exemplo 1 em 4 rodadas, no teclado do usuário: a
   partitura muda de tom e a conferência acompanha.

## Fora de escopo

Transpor exercícios gerados (`play-notes`, `rhythm`): eles já têm `key`.
O `play-pattern` (EX06) gera direto no tom.

## Notas de execução

(preencher)
