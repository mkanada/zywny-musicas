# EX21 — `theory-quiz`: perguntas de teoria geradas

**Repo:** zywny · **Depende de:** EX01, EX02, EX06 · **Decisão necessária:** não

## Objetivo

Hoje o `choice` é uma pergunta escrita à mão por bloco: uma rodada é uma
pergunta. A teoria que os livros ensinam é quase toda **fórmula fixa**, e
cabe num gerador que cria perguntas novas a cada rodada:

- a relativa menor fica 3 semitons abaixo (Pike 15);
- a ordem dos sustenidos, "FootballClub Goal…" (PFA 10);
- o acorde maior com a 3ª "à direita" e o menor "à esquerda" (PFA 4);
- o grau de cada acorde no tom (Pike 7; Cowling 1);
- os intervalos na pauta: "6ª e 8ª vão de linha para espaço" (Pike 15).

É o que o treino do dia precisa para revisar teoria sem o autor escrever
cem `choice`.

## Ler antes (só isto)

- `lib/course/exercise/question_kinds.dart`: o `ChoiceKind` e o
  `NameNoteKind` (a pergunta com partitura).
- [EX01](EX01-modelo-de-acordes.md) e o `scale.dart` do
  [EX06](EX06-play-pattern.md).

## O formato

````markdown
```zywny-exercise
id: n3-relativas
type: theory-quiz
title: Relativas
topics: [relative-minor, relative-major]
keys: [C, G, D, F, Bb, Eb]
count: 8
pass: {accuracy: 80, time-limit: 15}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `topics` | um ou mais da tabela abaixo | — (obrigatória) |
| `keys` | os tons das perguntas, ou `all` | `[C, G, F]` |
| `count` | perguntas, de 1 a 40 | `10` |
| `answer` | `buttons` ou `keyboard` (nos tópicos em que a resposta é nota ou acorde) | `buttons` |
| `qualities` | nos tópicos de acorde, as qualidades | `[M, m]` |

| Tópico | Pergunta (exemplo) | Resposta |
| --- | --- | --- |
| `key-signature` | "Quantos sustenidos tem Mi maior?" / a armadura desenhada: "Que tom é?" | número / tom |
| `sharps-order` | "Qual é o 3º sustenido?" | letra |
| `relative-minor` / `relative-major` | "Qual é a relativa de Lá maior?" | tom |
| `parallel` | "Qual é a homônima menor de Sol?" e "Quantos bemóis a mais?" | tom / número |
| `scale-degree` | "Qual é o 5º grau de Ré maior?" | nota (botões ou teclado) |
| `interval-name` | duas notas na pauta: "Que intervalo?" | intervalo (os botões do `listen-interval`) |
| `interval-build` | "Toque uma 6ª maior acima de Mi" | nota (teclado) |
| `chord-tones` | "Quais são as notas de F#m?" | o acorde no teclado (o `checkChord` do EX02) ou 3 botões de nota |
| `chord-degree` | "Que grau é Dm7 em Fá?" | grau |
| `degree-chord` | "Que acorde é o V7 em Si♭?" | cifra |
| `chord-from-staff` | um acorde na pauta: "Que cifra é esta?" | cifra (4 opções sorteadas, uma certa) |
| `circle-next` | "Qual é o próximo no ciclo de quintas depois de Mi♭?" | tom |
| `function` | "IV em Dó é tônica, subdominante ou dominante?" | função |

## O que fazer

1. **Os geradores:** `lib/course/exercise/theory_topics.dart`, um gerador
   por tópico, `(KeySpec, Random) → Question`. As opções erradas vêm de
   **erros comuns**, e não só de sorteio:
   - na relativa, o erro de subir 3 semitons;
   - na armadura, os tons vizinhos no ciclo;
   - no grau, a nota do grau vizinho.
   Registre os erros escolhidos em cada tópico.
2. **A rodada:** uma `QuestionRound`, misturando os tópicos em partes
   iguais, sem repetir pergunta igual. As perguntas com pauta usam o
   `notesScore` (como o `name-note`); as de teclado, o `expectedPitch`
   (como o `find-key`) ou o `ChordTarget` (como o `play-chord`).
3. **A revelação:** depois de errar, a explicação curta da regra:
   - "a relativa menor fica 3 semitons **abaixo**: Lá → Fá♯";
   - "o 5º grau é a dominante: conte Ré, Mi, Fá♯, Sol, **Lá**".
   A tabela fica no mesmo arquivo. O texto é nosso.
4. **O curso de teste:** `test/fixtures/cursos/teoria/`, com todos os
   tópicos.

## Testes

1. `theory_topics_test.dart`: para cada tópico, em 12 tons, a resposta
   certa bate com o EX01 e o EX06, e as opções erradas são diferentes da
   certa e entre si.
2. `exercise_questions_test.dart`: a mistura de 2 tópicos em 10 perguntas
   dá 5 e 5; o `answer: keyboard` no `scale-degree` aceita a nota em
   qualquer oitava.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` de uma pergunta com
   armadura.

## Fora de escopo

Teoria que não é fórmula (forma, história, estilos): fica no texto das
lições.

## Notas de execução

(preencher)
