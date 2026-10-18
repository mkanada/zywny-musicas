# EX13 — `rhythm` com duas mãos: polirritmia, clave e acentos

**Repo:** zywny · **Depende de:** EX07, EX10, EX12 (o som do `listen-groove`) · **Decisão necessária:**
D-EXE-MAOS

## Objetivo

Hoje o `rhythm` toca **uma tecla só**. Os livros pedem:

- **ritmo nas duas mãos:**
  - 2 contra 3 e 3 contra 2 (Pearl 16);
  - surdo na esquerda e tamborim na direita (Willey 2);
  - clave contra tumbao (Martignon 4; Valerio *Latin* 1);
  - mão esquerda firme e direita sincopada (Vinter);
- **acentos:** o pulso de semicolcheias do ganzá com acento (Willey 4) e o
  acento no contratempo (Pearl 10).

Também pedem **reconhecer o groove** de ouvido:

- reto ou swingado;
- clave 3-2 ou 2-3;
- 12/8 ou tercinas (os "conceitos rítmicos" de cada Harrison).

Este passo estende o `rhythm` e cria a variante de ouvido como um tipo
pequeno, o `listen-groove`. Ela não entra como um modo do `listen-chord`
porque os botões e o som são outros.

## Ler antes (só isto)

- `lib/course/exercise/timed_kinds.dart`: o `RhythmKind`.
- `docs/licoes/formato-v1.md`, seção `### rhythm`.
- [EX10](EX10-timed-round-e-chart-session.md) (a `TimedRound` e a regra de
  mãos pelo `split`) e [EX07](EX07-gravacao-e-medidores.md) (o medidor
  `accents`).

## O formato

````markdown
```zywny-exercise
id: n3-dois-contra-tres
type: rhythm
title: Dois contra três
hands: two
abc: |
  X:1
  M:2/4
  L:1/8
  V:1
  (3zzz (3zzz | (3zzz (3zzz |]
  V:2
  z2 z2 | z2 z2 |]
bpm: 50
pass: {accuracy: 85}
```

```zywny-exercise
id: n4-clave-tumbao
type: rhythm
title: Clave 3-2 na direita, tumbao na esquerda
hands: two
groove: clave-son-3-2
bpm: 90
measures: 4
pass: {accuracy: 80}
```

```zywny-exercise
id: n4-ganza
type: rhythm
title: O ganzá: semicolcheias com acento
groove: ganza
bpm: 80
measures: 4
pass: {accuracy: 85, accents: 12}
```

```zywny-exercise
id: n3-reto-ou-swing
type: listen-groove
title: Reto ou swingado?
grooves: [straight-eighths, swing-eighths]
count: 8
pass: {accuracy: 80}
```
````

No ABC acima, `z` é um placeholder: com `hands: two`, as alturas não
importam. O autor pode escrever qualquer nota e a pauta mostra o ritmo
numa linha só, como o `rhythm` de hoje. Confira com o leitor de ABC como
escrever o ritmo de duas vozes. Se for mais simples, use a sintaxe
`right:` e `left:` com o molde do EX11 (`X . . X . . X .`). **Decida no
passo com o usuário e anote.**

| Chave nova no `rhythm` | Valor | Padrão |
| --- | --- | --- |
| `hands` | `one` (hoje) ou `two` | `one` |
| `groove` | um nome da tabela abaixo, no lugar de `abc`/`figures` | — |
| `split` | a divisão das mãos | `C4` |

| `groove` | Direita | Esquerda | Fonte |
| --- | --- | --- | --- |
| `two-against-three` | tercinas | colcheias (2 por tempo) | Pearl 16 |
| `three-against-two` | 2 por tempo | tercinas | Pearl 16 |
| `clave-son-3-2` / `clave-son-2-3` | a clave | o tumbao (o "e" do 2 e o 4) | Martignon 4 |
| `clave-rumba-3-2` | a clave de rumba | o tumbao | Martignon 4 |
| `bossa-clave` | a clave brasileira 3:2 | a fundamental na semínima pontuada e colcheia | Valerio *Latin* 5 |
| `samba-surdo` | as linhas de tamborim (Willey) | o surdo, longo no 2 | Willey 2 e 4 |
| `ganza` | semicolcheias, acento na 4ª de cada tempo | — (uma mão) | Willey 4 |
| `backbeat` | 2 e 4 | 1 e 3 | Cowling 7 ("palmas no 2 e no 4") |
| `charleston` | o 1 e o "e" do 2 | 1, 2, 3, 4 (o baixo) | Harrison *Intro* 2 |

`listen-groove`:

| Chave | Valor | Padrão |
| --- | --- | --- |
| `grooves` | 2 ou mais de `straight-eighths`, `swing-eighths`, `shuffle-12-8`, `clave-3-2`, `clave-2-3`, `bossa`, `samba`, `waltz`, `six-eight` | — (obrigatória) |
| `count` | perguntas | `8` |

O som de cada pergunta são 2 compassos da base do EX12, no estilo e no
andamento sorteados entre 80 e 120.

## O que fazer

1. **`rhythm` com duas mãos:**
   - com `hands: two` ou um `groove` de duas mãos, a rodada passa a ser
     uma `TimedRound` (EX10);
   - o juiz é a `ChartSession` sem grade: os ataques esperados são `X`
     (papel `any`), em cada mão pelo `split`, um slot por compasso;
   - a tela mostra a partitura do ritmo em duas linhas (a de cima para a
     direita), gerada pelo `rhythmScore` com duas pautas de uma linha.
     Escreva a variante, se não houver;
   - o `rhythm` de uma mão continua como está (`ScoreRound`), sem mudar
     nada.
2. **`groove`:** a biblioteca `rhythm_grooves.dart`, no molde do
   `comping_patterns.dart` (EX11), com a tabela acima. Os acentos do
   `ganza` vão nos `ExpectedAttack` (um campo `accent`) para o medidor
   `accents`.
3. **`listen-groove`:** um tipo de pergunta, no molde do `listen-chord`
   (EX04). O som vem do `generateBacking` (EX12) e é tocado com o
   `BeatClock`. Os rótulos dos botões ficam em português: "colcheias
   retas", "colcheias swingadas", "shuffle (12/8)", "clave 3-2", "clave
   2-3", "bossa nova", "samba", "valsa", "6/8".
4. **O curso de teste:** `test/fixtures/cursos/ritmo/`, com cada `groove` e
   o `listen-groove`.

## Testes

1. `exercise_timed_test.dart`:
   - `two-against-three` a 50 bpm com o aluno simulado passa;
   - um aluno que toca as tercinas na mão esquerda (trocou as mãos) tem
     menos de 50%;
   - o `ganza` com velocity fixa dá o aviso de teclado do `accents`, e
     com acento certo passa `accents: 12`.
2. `exercise_questions_test.dart`, `group('listen-groove')`: as perguntas
   têm o som da base no estilo certo (o canal 9 tem as notas da clave do
   estilo sorteado).

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` com o ritmo de duas
   linhas.
2. **(manual)** O 2 contra 3 e a clave no teclado do usuário; o
   `listen-groove` ouvido.

## Fora de escopo

A conferência de duração das notas (D-RITMO: duração não cobrada).

## Notas de execução

(preencher)
