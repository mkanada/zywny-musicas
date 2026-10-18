# EX20 — `follow-form`: não se perder na forma

**Repo:** zywny · **Depende de:** EX12 · **Decisão necessária:** não

## Objetivo

Tocar com banda pede saber **onde se está**:

- no blues de 12 compassos;
- no AABA de 32 compassos;
- no "turnaround nos compassos 11 e 12";
- e, no gospel, na forma flexível que o regente muda ao vivo (Cowling,
  cap. 7: "observe o regente; os sinais não são padronizados").

O `follow-form` treina isso com a base do EX12, em três modos:

1. **`where`** (na tela): a base toca, a grade fica **escondida**, e de
   tempos em tempos o app pergunta "em que compasso estamos?" (botões de 1
   a 12, ou A1, A2, B, A3 com o compasso). O aluno responde **sem parar a
   música**.
2. **`enter`** (no teclado): a base toca a forma, e o aluno só entra
   quando o exercício pede. Por exemplo, "toque o turnaround nos
   compassos 11 e 12" ou "entre na ponte". O app confere se o primeiro
   ataque caiu no compasso certo, e o que veio depois, como no
   `play-chart`.
3. **`cues`** (no teclado): o aluno acompanha o tempo todo, como no
   `play-chart`. Um compasso antes de cada mudança, o app manda um
   **sinal** ("de novo", "ponte", "final"), na tela e por voz curta do
   soundfont ou por um som distinto. O aluno precisa seguir o sinal: a
   forma tocada é a que os sinais pedem, sorteada.

## Ler antes (só isto)

- [EX09](EX09-grade-zywny-chart.md) (seções `A:`/`B:` e repetições),
  [EX11](EX11-play-chart.md) e [EX12](EX12-base-gerada.md).

## O formato

````markdown
```zywny-exercise
id: n3-onde-estamos
type: follow-form
title: Em que compasso estamos?
mode: where
chart: {progression: blues-12, key: F}
backing: {style: shuffle, bass: walking}
questions: 6
bpm: 100
pass: {accuracy: 70}
```

```zywny-exercise
id: n3-turnaround
type: follow-form
title: Entre no turnaround
mode: enter
chart: {progression: blues-12, key: G}
enter: {bars: 11-12, pattern: block}
choruses: 3
backing: shuffle
bpm: 90
pass: {accuracy: 80}
```

```zywny-exercise
id: n4-gospel-sinais
type: follow-form
title: Siga o regente
mode: cues
chart: |
  A: | C | F | C | G |
  B: | Am | F | G | G |
  C: | F | G | C | C |
cues: [again, next, back-to-A, end]
pattern: straight-beat
bpm: 84
pass: {accuracy: 75}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `mode` | `where`, `enter` ou `cues` | — (obrigatória) |
| `chart`, `key`, `backing`, `bpm`, `swing`, `split` | como no `play-chart` | — |
| `questions` | com `where`: quantas perguntas na forma | `6` |
| `answer-window` | com `where`: tempos para responder antes de valer errado | `4` |
| `enter` | com `enter`: `{bars, pattern}` ou `{section, pattern}` | — |
| `cues` | com `cues`: os sinais possíveis, de `again` (repete a seção), `next` (segue), `back-to-A`, `bridge` (vai para B) e `end` (o final: dois compassos e o acorde final) | `[again, next, end]` |
| `choruses` | voltas (com `where` e `enter`) | `2` |

## O que fazer

1. **`where`:** uma `TimedRound` com um juiz de **perguntas no tempo**, o
   `FormQuizJudge`:
   - as perguntas caem em compassos sorteados, nunca em seguida;
   - o botão certo é o compasso **no momento da pergunta**, e a resposta
     vale até `answer-window` tempos depois;
   - a grade fica escondida, e só a fórmula de compasso e o contador de
     tempos aparecem;
   - no fim, a grade aparece com os compassos perguntados marcados.
2. **`enter`:** o juiz é a `ChartSession` só nos compassos do `enter`.
   Fora deles, qualquer nota conta como "entrou antes": um erro, com a
   frase "entrou no compasso 9; era no 11".
3. **`cues`:**
   - a forma é sorteada **antes** de começar, seguindo os sinais (com um
     limite de 32 compassos), e o juiz conhece a forma real;
   - o sinal aparece um compasso antes: um cartão grande e uma cor, e a
     palavra soa como um som curto e distinto por sinal (escolha 3 notas
     GM de percussão diferentes e anote; voz falada fica para depois);
   - o placar é o da `ChartSession` sobre a forma real. Seguir o sinal
     errado gera vários `wrong` seguidos.
4. **O curso de teste:** `test/fixtures/cursos/forma/`, com os três modos.

## Testes

1. `exercise_timed_test.dart`:
   - `where`, com respostas simuladas certas no tempo, dá 100%, e com a
     resposta 5 tempos depois conta errado;
   - `enter`: o primeiro ataque no compasso 11 passa, e no 9 não;
   - `cues`, com semente fixa: a forma sorteada respeita os sinais, e o
     aluno simulado (que conhece a forma) passa.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` do cartão de sinal.
2. **(manual)** Os três modos com o usuário. O sinal com 1 compasso de
   antecedência basta?

## Fora de escopo

O sinal por voz falada e a forma AABA com letra (o O00, letra no telão,
pode servir depois).

## Notas de execução

(preencher)
