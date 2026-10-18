# EX22 — Leitura e repertório: cortina, ensaio, `tempo-ladder`, mãos em sequência, prática acumulativa

**Repo:** zywny · **Depende de:** EX07 · **Decisão necessária:** não

## Objetivo

Pequenas melhorias em tipos que já existem. Cada uma vem de um conselho
de estudo dos livros que o app pode **executar**, em vez de só dizer:

| Melhoria | Onde | Livro |
| --- | --- | --- |
| **Cortina** na leitura: o compasso já tocado some, ou o seguinte só aparece no último tempo do atual. Isso força o olhar adiante | `play-score` em tempo real e o treino de leitura à primeira vista | Pike 34 ("ajuste os olhos não para onde você parou, mas adiante") |
| **Ensaio antes de ler**: uma rodada de ritmo (`rhythm`, qualquer tecla) com o ritmo da própria frase, depois a frase com as notas | o treino de leitura | Pike 11 (os 5 passos: "bata o ritmo; toque na sombra") |
| **Não parar**: na leitura em tempo real, a rodada não espera nem repete. O erro fica pintado e segue | o treino de leitura | Pike 3 ("não volte para corrigir; olhe adiante") |
| **`tempo-ladder`**: o andamento sobe a cada rodada limpa e desce quando falha, até a meta | `play-score`, `play-pattern`, `play-chart` | Pike 19 ("aumente o metrônomo até não conseguir; diminua um pouco") |
| **`hand: sequence`**: esquerda, depois direita, depois juntas a 80% do andamento | `play-score`, `play-pattern` | Pike 16 ("ao juntar as mãos, toque mais devagar do que separadas"); Valerio (ragtime) |
| **`practice: cumulative`**: do compasso N até o **tempo forte** do N+1, avançar, e depois juntar | `play-score` | Pike 27 (a German Dance de Haydn: "você não vai hesitar na barra de compasso") |
| **Começar pelo trecho difícil**: na passagem completa, o app sugere o andamento do pior compasso | `play-score` com `measures` ou a trilha J | Pike 26 ("você só consegue tocar tão rápido quanto a parte mais difícil") |

## Ler antes (só isto)

- `lib/course/exercise/score_round_runner.dart` e `pass_check.dart`.
- `lib/sight_reading/` (a tela do treino de leitura: `sight_reading_source.dart`
  e `sight_levels_screen.dart`).
- `lib/trail/` e [J07](J07-fase-final-e-reforco.md), para o reforço por
  compasso que já existe.
- [EX07](EX07-gravacao-e-medidores.md), para o medidor `steadiness` que o
  `tempo-ladder` usa.

## O formato

```yaml
pass: {accuracy: 90, tempo-ladder: {from: 60, to: 96, step: 4, back: 8}}
hand: sequence
practice: cumulative
curtain: true
```

| Chave | Vale em | Valor | Padrão |
| --- | --- | --- | --- |
| `tempo-ladder` (no `pass`) | `play-score`, `play-pattern` e `play-chart` em tempo real | `{from, to, step, back}` em bpm; o exercício passa quando uma rodada limpa sai em `to` | ausente |
| `hand: sequence` | `play-score`, `play-pattern` | as rodadas alternam esquerda → direita → juntas; as juntas saem a 80% do andamento das separadas | — |
| `practice: cumulative` | `play-score` | os trechos de 1 compasso mais o tempo forte do seguinte, depois de 2, depois a peça | ausente |
| `curtain` | `play-score` em tempo real; o treino de leitura | `true`/`false` | `false` (e `true` na leitura, a partir do nível 5 do treino) |

## O que fazer

1. **`tempo-ladder`:**
   - o estado do andamento por exercício fica salvo junto do
     `ExerciseRecord`, num mapa à parte (como o do EX05);
   - cada rodada **limpa** (passou em `accuracy` e nos medidores) sobe
     `step`, e cada rodada reprovada desce `back`, nunca abaixo de `from`;
   - o `speed` do `pass` é ignorado quando há `tempo-ladder`. O validador
     recusa os dois juntos;
   - a barra do exercício mostra "♩ 72 → meta 96".
2. **`hand: sequence`:**
   - o exercício vira três sub-rodadas (`Hand.esquerda`, `Hand.direita`,
     `Hand.ambas`);
   - a 3ª sai com `speed × 0,8` da velocidade das duas primeiras;
   - o `RoundResult` da rodada é o da 3ª, e as duas primeiras só precisam
     passar em `accuracy` para liberar a seguinte.
3. **`practice: cumulative`:** no molde do J07, monta os trechos com o
   `TrailPath`. A regra de Pike é parar no **tempo forte do compasso
   seguinte**: o fim do trecho é o primeiro ataque do compasso N+1, e não o
   fim do compasso N. É um modo da rodada, e o `pass` vale só para a
   passagem completa no fim.
4. **Cortina:**
   - no `ScoreView`, uma máscara sobre os compassos já tocados (a cor do
     fundo, com 90% de opacidade). O compasso seguinte fica coberto até o
     último tempo do atual;
   - use as posições da `ScoreTimeline` e da cena; não precisa de
     re-render;
   - na leitura, a cortina liga sozinha a partir do nível 5 (as semínimas),
     com a opção de desligar na gaveta.
5. **Ensaio na leitura:** no treino de leitura, a opção "ensaiar o ritmo
   antes" (ligada por padrão nos níveis 1 a 10) toca primeiro um `rhythm`
   com o ritmo da frase sorteada (o `sightRhythmXml` já existe: E09) e só
   depois a frase.
6. **Começar pelo difícil:** no resumo de uma passagem completa com
   `worstMeasures`, a linha nova "Para a próxima: comece a ♩ 66, o
   andamento em que o compasso 7 saiu limpo". Ela vem do andamento das
   rodadas do reforço daquele compasso, quando houve.

## Testes

1. `pass_check_test.dart` (`tempo-ladder`):
   - 3 rodadas limpas a partir de 60 com `step` 4 dão 72;
   - uma reprovada volta a 64;
   - a meta em 96 passa o exercício.
2. `exercise_timed_test.dart`:
   - `hand: sequence` gera 3 sub-rodadas, com a 3ª a 80%;
   - `practice: cumulative` numa peça de 4 compassos gera os trechos
     1→2↓, 2→3↓, 3→4↓, 4→fim e a passagem completa;
   - `↓` = o tempo forte do compasso seguinte.
3. Um teste de widget: com a `curtain`, o compasso 1 fica coberto quando o
   cursor passa ao 2, e o 3 só aparece no último tempo do 2.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com a cortina.
2. **(manual)** A cortina no treino de leitura no nível 5, com o usuário:
   ajuda, ou atrapalha demais?

## Fora de escopo

O treino do dia adaptativo (EX00, "Fora desta fase").

## Notas de execução

(preencher)
