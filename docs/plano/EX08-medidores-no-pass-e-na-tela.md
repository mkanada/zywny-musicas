# EX08 — Medidores no `pass`, no resumo e "ouvir o que toquei"

**Repo:** zywny · **Depende de:** EX07 · **Decisão necessária:**
D-EXE-LIMIARES (este passo mede e propõe os números finais)

## Objetivo

1. Os medidores do EX07 entram no `pass` como chaves opcionais. Um
   exercício só passa se cumprir a precisão **e** os medidores que o
   autor pediu.
2. O resumo da rodada mostra cada medidor pedido, com o número, a frase e
   os compassos com problema.
3. **Ouvir o que toquei** (Pike 11 e 28: "grave-se e ouça: a dinâmica
   nunca soa como você imagina"). No fim da rodada, o app toca de volta a
   gravação do aluno, pelo som do app, com a curva de velocity desenhada
   embaixo da partitura.
4. **Calibrar os limiares** com o teclado do usuário.

## Ler antes (só isto)

- [EX07](EX07-gravacao-e-medidores.md).
- `lib/course/exercise/pass_check.dart` (inteiro): `speedApplies`,
  `roundPasses`, `evaluate` e a frase do `reason`.
- `packages/zywny_course_format/lib/vocabulary.dart`: `kPassKeys` e
  `PassKey`.
- `lib/course/exercise/exercise_round.dart`: `RoundResult`.
- `lib/practice/practice_report.dart` e a tela de resumo do treino, só para
  copiar o jeito de mostrar compassos piores (U12: "frases no lugar de
  milissegundos").

## O formato

Chaves novas no `pass`. Todas valem nos tipos com tempo:

- `rhythm`;
- `play-score` e `play-pattern` (mesmo no modo espera, para os medidores
  que não dependem do tempo);
- e, quando existirem, os tipos com `TimedRound`.

| Chave | Valor | Vale no modo espera? |
| --- | --- | --- |
| `legato` | % mínima de ligações limpas (1 a 100) | sim |
| `staccato` | % mínima de staccatos curtos | sim |
| `dynamics` | `true`: os trechos de dinâmica precisam estar certos (% mínima fixa em 80) | sim |
| `balance` | diferença mínima de velocity, melodia sobre acompanhamento (1 a 60) | sim |
| `pedal` | % mínima de trocas limpas | sim |
| `steadiness` | desvio-padrão máximo, em ms (10 a 200) | **não** (o espera não tem tempo) |
| `swing` | faixa da razão, `60-70` | não |
| `accents` | diferença mínima de velocity (1 a 60) | sim |
| `choruses` | voltas seguidas sem erro (1 a 20) | não |

O validador recusa as chaves marcadas "não" num `play-score` com `mode:
wait`, com a mesma frase do `speed`: "o modo espera não tem andamento".

## O que fazer

1. **O formato:**
   - `PassCriteria` ganha um campo opcional por chave (`int? legato`,
     `bool dynamics`…);
   - `kPassKeys` lista as chaves com a faixa e os tipos em que valem,
     como o `time-limit` já faz;
   - o leitor do `passMap` lê as faixas (`swing: 60-70`).
2. **O resultado:** `RoundResult` ganha `final Map<String, MeterResult>
   meters`. O `ScoreRoundRunner._finish` calcula os medidores pedidos com
   a `capture` e os pares casados do `PracticeController` (EX07, item 2).
3. **O veredito:** `PassCheck.roundPasses` passa a exigir também
   `meter.passed != false` para cada medidor pedido. Um medidor sem dado
   (`NaN`) não reprova. O `reason` acrescenta o primeiro medidor que
   falhou: "legato: 70% de 85%" ou "balance: a melodia está só 4 mais
   forte (alvo 10)".
4. **A tela do resumo** (o fim da rodada em `exercise_screen.dart`):
   - **o que mostra:** um cartão por medidor pedido, com o nome em
     português, o número, a meta, a frase e um ícone de passou ou não;
   - **nomes:** legato, staccato, dinâmica, equilíbrio, pedal,
     regularidade, swing, acentos e voltas;
   - **compassos:** os do medidor ficam marcados na partitura, como as
     notas erradas de hoje (`showReview`), numa cor própria;
   - **sem `pass`:** os medidores **não** pedidos não aparecem, para não
     poluir.
5. **Ouvir o que toquei:**
   - o botão "Ouvir o que toquei" no resumo das rodadas com gravação;
   - ele agenda os `CapturedNote` (e o pedal, como CC64) no `SoundEngine`,
     do início ao fim, pela saída escolhida;
   - durante a reprodução, uma linha embaixo da partitura desenha a
     velocity de cada nota no tempo (barras finas, com a altura pela
     velocity);
   - em seguida vem o botão "Ouvir o escrito", como na revelação do
     `listen-score`.
6. **A calibração (manual, com o usuário):**
   - um curso de teste `test/fixtures/cursos/medidores/` com um exercício
     por medidor: escala em legato e depois em staccato; uma melodia com p
     e f; um coral de duas mãos para o `balance`; uma progressão com
     pedal; 8 compassos de colcheias para `steadiness` e `swing`; uma
     clave com acentos;
   - o usuário toca cada exercício **bem** e **mal de propósito**;
   - registre nas notas os valores medidos e proponha os limiares finais
     na tabela do EX07. Atualize o EX07 e marque o D-EXE-LIMIARES como
     tomado, com a data, depois do aval do usuário.

## Testes

1. `pass_check_test.dart`:
   - um `RoundResult` com 95% e `legato` 70 não passa com `legato: 85` e
     passa sem a chave;
   - o `reason` cita o legato;
   - um medidor `NaN` não reprova.
2. `course_reader_test.dart`: cada chave nova é aceita com valor válido e
   recusada fora da faixa; `steadiness` num `play-score` em espera dá
   erro.
3. `exercise_timed_test.dart`: um `play-score` em tempo real com aluno
   simulado de velocity fixa e `dynamics: true` passa, com a frase do
   teclado sem velocity.
4. Um teste de widget: o resumo com dois medidores mostra dois cartões, e
   o "Ouvir o que toquei" agenda no `FakeSoundEngine` as notas da gravação.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com o resumo de
   medidores.
2. **(manual)** A calibração do item 6, com as notas preenchidas.

## Fora de escopo

Os medidores na trilha J (a etapa dos hinos). Só o resumo do treino livre
poderia mostrá-los; fica como ideia nas notas.

## Notas de execução

(preencher)
