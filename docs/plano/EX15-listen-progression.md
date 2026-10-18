# EX15 — `listen-progression`: ouvir os graus de uma progressão

**Repo:** zywny · **Depende de:** EX04, EX09 · **Decisão necessária:** não

## Objetivo

O zywny toca o acorde da tônica e, em seguida, uma progressão curta. O
aluno diz que progressão foi:

- por **botões**: "I–IV–V–I", "I–V–vi–IV"…;
- ou **tocando os baixos** no teclado, um por acorde, como um ditado de
  baixos.

É o ouvido de função dos níveis 2 a 5 do currículo:

- achar I, IV e V numa melodia (2.10);
- reconhecer I, IV, V e vi em gravações (3.11);
- ouvir a dominante secundária e o empréstimo (4.9);
- reconhecer II–V e SubV (5.13).

## Ler antes (só isto)

- [EX04](EX04-listen-chord.md): a rodada e a tela de ouvir acorde.
- [EX09](EX09-grade-zywny-chart.md): o `ChordChart` e o `chartAudio`.
- [E09](E09-ditado-com-ritmo.md): o ditado com o teclado, para a resposta
  `bass`.

## O formato

````markdown
```zywny-exercise
id: n3-qual-progressao
type: listen-progression
title: Qual progressão?
progressions: [I-IV-V-I, I-V-vi-IV, I-vi-IV-V]
key: random
count: 8
pass: {accuracy: 75}
```

```zywny-exercise
id: n3-ditado-de-baixos
type: listen-progression
title: Toque os baixos que você ouviu
answer: bass
progressions: [I-IV-V-I, I-vi-ii-V, I-V-vi-IV]
key: C
count: 6
pass: {accuracy: 70}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `progressions` | nomes da biblioteca do EX01, ou progressões escritas (`"I \| vi \| ii V \| I"`) | — (obrigatória, 2 ou mais com `answer: choice`) |
| `answer` | `choice` (botões com o nome da progressão em graus) ou `bass` (tocar a fundamental de cada acorde, em ordem, no teclado) | `choice` |
| `key` | um tom ou `random` | `C` |
| `style` | `block` (a mão direita em bloco e o baixo) ou um estilo da base (EX12) | `block` |
| `bpm` | de 50 a 140 | `90` |
| `count` | perguntas | `8` |

Os botões mostram os graus ("I – vi – IV – V"), e não as cifras: o tom
muda, mas a função é a mesma.

## O que fazer

1. **Formato e leitura** (como o EX04). Erros:
   - progressão desconhecida;
   - menos de 2 progressões com `choice`;
   - progressões iguais em graus;
   - mais de 8 acordes numa progressão (é longo demais para o ouvido).
2. **A rodada:**
   - o som é a tônica, uma pausa e a progressão (`chartAudio` do EX09, ou
     a base do EX12 quando há `style`);
   - com `choice`, o `correct` é o índice da progressão;
   - com `bass`, um `ScoreComparison` (E09) com uma pauta de fá que mostra
     só o ritmo (uma semibreve por acorde) e os `expected` sendo as
     fundamentais. Reaproveite o ditado: o aluno toca as fundamentais, em
     qualquer oitava.
3. **A tela:** a pergunta do EX04 com o título "Qual progressão?" e o
   botão "Ouvir de novo". Na revelação aparece a grade (`ChartView`) com as
   cifras no tom tocado e os graus embaixo.
4. **O curso de teste:** o `acordes/03-ouvido.md` (EX04) ganha os dois
   exemplos.

## Testes

1. `course_reader_test.dart` e os erros.
2. `exercise_questions_test.dart`, `group('listen-progression')`:
   - o som tem a tônica primeiro e os acordes na ordem;
   - com `key: random`, as perguntas variam de tom;
   - com `bass`, o `expected` são as fundamentais.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas`.
2. **(manual)** Ouvir 8 perguntas com o usuário. A progressão a 90 bpm é
   clara?

## Fora de escopo

Transcrever progressões de gravações e ouvir acordes com tensões.

## Notas de execução

(preencher)
