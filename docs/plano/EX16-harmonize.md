# EX16 — `harmonize`: harmonizar uma melodia

**Repo:** zywny · **Depende de:** EX02, EX10, EX11 · **Decisão necessária:** não

## Objetivo

Pike harmoniza melodias em seis lições (12, 16, 19, 20, 28 e 31). A
receita é:

1. tocar a melodia;
2. acorde em bloco na esquerda nos tempos 1 e 3;
3. trocar o acorde onde a melodia pede;
4. escrever os graus romanos;
5. depois, em oom-pah.

E a regra para escolher o acorde: "quando a maioria das notas da melodia
for Ré, Fá ou Lá, toque o i…". É o coração do pilar 2: dar harmonia a uma
melodia sem ninguém dizer qual é.

O `harmonize` tem três modos:

1. **`mode: degrees`** (na tela, sem teclado): a melodia aparece na
   pauta, e embaixo de cada trecho há botões com os graus permitidos. O
   aluno escolhe um grau por trecho (o passo 4 de Pike).
2. **`mode: play`** (no teclado, com tempo): a melodia aparece na pauta, e
   o aluno toca a **melodia na direita** e o **acorde na esquerda**, no
   ritmo pedido.
3. **`mode: by-ear`**: a melodia **só soa** (o app toca), e o aluno toca
   só os acordes, no tempo. É a prova de ouvido do currículo (0.1) em
   pequeno.

Não há resposta única: o app aceita **qualquer acorde permitido que caiba
na melodia** e mostra, no fim, uma escolha de referência.

## Ler antes (só isto)

- [EX02](EX02-play-chord-formato-e-sessao.md) (`checkChord`),
  [EX10](EX10-timed-round-e-chart-session.md) (`TimedRound` e
  `ChartSession`) e [EX11](EX11-play-chart.md) (o molde `block` e o
  `oom-pah`).
- `lib/sight_reading/sight_generator.dart` e `sight_score.dart`: a
  melodia sorteada por passo (`step`), que o `harmonize` reaproveita como
  fonte de melodias sem direitos.

## O formato

````markdown
```zywny-exercise
id: n2-harmonize-graus
type: harmonize
title: Escolha os acordes
mode: degrees
melody: {step: 7b, key: G}
chords: [I, IV, V7]
change: half-bar
count: 3
pass: {accuracy: 80}
```

```zywny-exercise
id: n2-harmonize-tocar
type: harmonize
title: Melodia e acordes
mode: play
melody: {file: media/folclore-1.musicxml}
chords: [I, IV, V7]
pattern: block
bpm: 70
pass: {accuracy: 80}
```

```zywny-exercise
id: n3-harmonize-ouvido
type: harmonize
title: Acompanhe de ouvido
mode: by-ear
melody: {file: media/folclore-2.musicxml}
chords: [I, ii, IV, V7, vi]
pattern: oom-pah
bpm: 80
pass: {accuracy: 75}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `mode` | `degrees`, `play` ou `by-ear` | `play` |
| `melody` | `{step, key}` (uma melodia gerada pela leitura à primeira vista, só a mão direita) ou `{file}` (uma melodia do autor, de domínio público; uma pauta) | — (obrigatória) |
| `chords` | os graus permitidos | `[I, IV, V7]` |
| `change` | onde o acorde pode trocar: `bar` (a cada compasso), `half-bar` (a cada meio compasso) ou `marked` (onde o autor marcou, com um texto `^chg` acima da nota no ABC ou uma `<words>` no MusicXML) | `bar` |
| `pattern` | com `play` e `by-ear`, um molde do EX11 | `block` |
| `bpm`, `split` | como no `play-chart` | `70`, `C4` |
| `count` | com `step`, quantas melodias | `1` |

### A regra do que "cabe"

Para cada trecho (o compasso, ou meio compasso, conforme o `change`):

1. as **notas fortes** do trecho são as que caem nos tempos 1 e 3 (em
   3/4, no 1), mais as notas longas (mínima ou mais);
2. um acorde **cabe** se contém a nota forte do tempo 1 do trecho **e**
   pelo menos metade das notas fortes do trecho;
3. a **referência** é, entre os que cabem, o acorde que contém mais notas
   do trecho (as fortes valem 2 e as outras 1). No empate:
   - a tônica no primeiro e no último compasso;
   - a dominante no penúltimo;
   - senão, a ordem da lista `chords`;
4. se **nenhum** acorde permitido cabe num trecho, o validador avisa o
   autor: "o compasso 5 não tem acorde em `chords` que contenha Fá♯".
   Isso é erro com `file` e não acontece com `step` (o gerador da leitura
   já cadencia no V e no I: confira).

## O que fazer

1. **Análise da melodia:** `lib/course/exercise/harmonize_check.dart`:
   - `melodySegments(…)` corta a melodia em trechos pelo `change`;
   - `fitting(…)` dá os acordes que cabem, pela regra acima;
   - `reference(…)` dá a escolha de referência.
   É Dart puro, e lê as notas do `PerformanceTrack` (com `file`) ou do
   `SightExercise` (com `step`).
2. **`mode: degrees`:** uma `QuestionRound` com uma pergunta por trecho:
   - a pauta mostra a melodia inteira, com o trecho atual em destaque
     (`highlightId` das notas);
   - os botões são os graus em `chords`;
   - **certo** = um dos que cabem (pode haver vários: `Question` ganha
     `correctSet`, e o `answerChoice` aceita qualquer índice do conjunto);
   - depois de cada resposta, o app toca o trecho com o acorde escolhido,
     para o aluno **ouvir** a escolha;
   - no fim, toca a melodia inteira com os acordes escolhidos e depois com
     os de referência.
3. **`mode: play`:** uma `TimedRound` com a melodia na pauta
   (`scoreBytes`):
   - **o juiz** é a `ChartSession` mais as notas da melodia. A direita
     confere a melodia nota a nota, como a `RealtimeSession` faz com a
     pauta 1. A esquerda confere o molde, mas o "acorde certo" de cada
     slot é **qualquer um dos que cabem** (uma `ChartSlot` com
     `candidates`, e não um acorde só);
   - **o placar** conta a melodia e os acordes juntos, e o retorno
     separa: "melodia 95%; acordes 80%; no compasso 6 o IV não soou bem:
     a melodia está em Fá♯";
   - **a revelação** desenha, embaixo da pauta, os graus que o aluno usou
     e os de referência.
4. **`mode: by-ear`:**
   - o app toca a melodia (a pauta 1, pelo som do app) e **não** mostra a
     partitura;
   - o aluno toca só os acordes, na esquerda ou nas duas mãos, abaixo da
     melodia;
   - o juiz é o mesmo, sem a parte da melodia;
   - antes de começar, a melodia toca uma vez inteira, sozinha ("Ouça
     primeiro"). O aluno pode pedir de novo antes de começar.
5. **Regra de Pike 19** (EX00, treino do dia): a referência **não** aparece
   antes de o aluno tocar, nem fica salva na tela entre as rodadas.
6. **O curso de teste:** `test/fixtures/cursos/harmonia/`, com os três
   modos, uma melodia `step` e duas melodias `file` de domínio público.
   Escreva-as você, ou use folclore em ABC simples (Cai, Cai, Balão;
   Atirei o Pau no Gato).

## Testes

1. `harmonize_check_test.dart`:
   - a melodia C-E-G | F-A-C | G-B-D | C (semínimas e mínima) em C, com
     `[I, IV, V7]`: os trechos dão {I}, {IV}, {V7} e {I};
   - uma nota de passagem fraca não muda o resultado;
   - um compasso só com E-G cabe em I e em vi, se `vi` estiver na lista,
     e a referência é I;
   - um compasso com F♯ sem acorde que caiba dá o aviso.
2. `exercise_questions_test.dart` (`degrees`): `correctSet` com dois
   graus; qualquer um vale de primeira.
3. `exercise_timed_test.dart`:
   - `play` com o aluno simulado (a melodia exata e os acordes de
     referência) passa;
   - com um acorde que cabe e não é o de referência, também passa;
   - com IV num compasso de V7, conta errado.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` dos três modos.
2. **(manual)** Com o usuário, as duas melodias de folclore. A regra do
   que "cabe" aceita o que soa bem e recusa o que soa mal? Anote os casos
   duvidosos.

## Fora de escopo

Harmonização em três vozes na mão direita (Cowling, cap. 6): pode virar
um `voicing:` no `play` depois. Rearmonização (nível 6).

## Notas de execução

(preencher)
