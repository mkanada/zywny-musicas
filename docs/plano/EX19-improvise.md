# EX19 — `improvise`: improviso com regras e retorno

**Repo:** zywny · **Depende de:** EX14, EX18 · **Decisão necessária:**
D-EXE-IMPROVISO

## Objetivo

O aluno toca livre sobre a base, por um número dado de compassos. O app
**não** julga se ficou bonito. Ele confere a **regra do modo** e devolve um
**retorno** com números e frases.

Os modos seguem a escada que os livros usam, do mais fechado ao mais
livre:

| Modo (`mode:`) | O que o aluno faz | A regra | Livros |
| --- | --- | --- | --- |
| `fixed-notes` | só as notas dadas, variando o ritmo e a ordem | % das notas no conjunto dado | PFA 6, exercício 3 ("varie a estrutura ou o ritmo das notas seguras") |
| `chord-tones` | só notas do acorde do momento | % de notas do acorde | PFA 6, exercício 4; PFA 7 (D Minor Jazz: "as notas do acorde, garantidas") |
| `scale` | só notas de uma escala (a de blues do tom, a pentatônica, a do tom) | % de notas na escala | Pike 3, 10 e 17; Harrison *Beginning Rock* 5; Vinter |
| `call-response` | o app toca 2 compassos (a pergunta) e o aluno **responde** nos 2 seguintes, com outra frase | a resposta existe, termina numa nota do acorde e **não** é cópia da pergunta | PFA 6 ("conversa"); Valerio *Stride* (chamada e resposta) |
| `vary-melody` | a melodia dada, enfeitada: as notas da melodia nos seus tempos e o resto livre | % das notas da melodia nos tempos | PFA 7 (Frère Jacques jazz); Harrison *Intro* 5 ("comece variando a melodia") |
| `motif` | uma ideia de 2 a 4 notas, repetida e variada (deslocada, transposta, com o ritmo mudado) | se há repetição de motivo detectável | Miller (repetição e variação); Valerio *Post-Bop* 5 (Evans: motivos) |
| `free` | qualquer coisa | nenhuma (só o retorno) | — |

## Ler antes (só isto)

- [EX14](EX14-echo.md) (a forma alternada OUÇA/TOQUE, que o
  `call-response` reaproveita) e [EX18](EX18-target-notes.md) (a fonte de
  notas por acorde).
- [EX07](EX07-gravacao-e-medidores.md) (`PerformanceCapture`).

## O formato

````markdown
```zywny-exercise
id: n1-improviso-tonica
type: improvise
title: Improvise com 5 notas
mode: fixed-notes
notes: [C4, D4, E4, G4, A4]
chart: "| C | G | C | G |"
key: C
backing: {style: ballad, bass: root}
bars: 8
bpm: 70
pass: {rule: 90}
```

```zywny-exercise
id: n3-blues-pergunta-resposta
type: improvise
title: Responda à frase
mode: call-response
chart: {progression: blues-12, key: C}
source: {scale: blues}
backing: shuffle
swing: 67
bpm: 90
choruses: 2
pass: {rule: 80}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `mode` | um da tabela | `scale` |
| `notes` | com `fixed-notes`, as notas permitidas (qualquer oitava) | — |
| `source` | com `scale`: `{scale: blues \| minor-pentatonic \| major-pentatonic \| key-scale \| by-chord}`; com `call-response`, a fonte das perguntas do app (EX14) | `{scale: key-scale}` |
| `melody` | com `vary-melody`, a melodia (`file` ou `abc`) | — |
| `chart`, `key`, `bpm`, `swing`, `backing`, `choruses`, `split` | como no `play-chart` | — |
| `bars` | compassos de improviso (sem `chart`, sobre o acorde da tônica) | a forma da grade |
| `left` | `none` (a base faz tudo) ou um molde de padrão (EX11), conferido como no `play-chart` | `none` |
| `record` | guardar o improviso para "tocar de novo" e "virar eco" | `true` |

`pass`:

- `rule` é a % mínima da regra do modo (com `free`, não vale);
- `accuracy` vale só para a mão esquerda, quando `left` é um padrão;
- os medidores do EX08 valem, por exemplo `steadiness` ou `swing`.

## O retorno (para todos os modos)

Calculado na gravação da mão direita. Cada item tem um número e uma frase
curta, mostrados no fim da rodada:

| Item | Como se mede | Frase de exemplo | Por que (livros) |
| --- | --- | --- | --- |
| **Notas no lugar** | % de notas no conjunto do modo | "92% das notas na escala de blues" | todos |
| **Notas do acorde nos tempos fortes** | % dos ataques nos tempos 1 e 3 que são notas do acorde do momento | "nos tempos fortes, 60% notas do acorde" | Harrison: "as notas que não são do acorde devem cair em tempos fracos" |
| **Respiração** | % do tempo em silêncio e o número de frases (uma frase = notas separadas por menos de 1 tempo de silêncio) | "6 frases, 35% de silêncio" | PFA 6 ("use momentos de silêncio"); a conversa |
| **Tamanho das frases** | a média de compassos por frase | "frases de 1,5 compasso, em média" | — |
| **Variedade rítmica** | quantas durações diferentes, e quanto do total é a mais comum | "quase tudo em colcheias (80%): experimente notas longas" | PFA 6, exercício 5.2 |
| **Extensão** | a nota mais grave e a mais aguda | "de Dó4 a Sol5" | PFA 6, exercício 4 ("expanda a extensão") |
| **Motivo** | a sequência de intervalos (3 ou mais notas) que volta, deslocada no tempo ou transposta | "a ideia Mi–Sol–Lá voltou 3 vezes; ótimo" | Miller; Valerio (Evans) |
| **Final** | a última nota da forma é a tônica ou uma nota do acorde final | "terminou na tônica" | — |

As frases saem de uma tabela simples de limiares. Cada item tem uma frase
para baixo, uma para o meio e uma para alto. O retorno não tem nota: só
`rule` aprova (D-EXE-IMPROVISO).

## O que fazer

1. **O analisador:** `lib/course/exercise/improv_analysis.dart`, em Dart
   puro:
   - `ImprovAnalysis.of(capture, chart, mode, …)` dá os itens da tabela;
   - a detecção de motivo procura n-gramas de **intervalos** (3 a 5 notas)
     com 2 ou mais ocorrências que não se sobrepõem.
2. **O juiz:** `ImproviseJudge`, uma `TimedJudge` que dá os vereditos por
   nota para a tela (uma nota de fora pisca em vermelho; dentro, nada:
   não poluir o improviso) e, no fim, o placar `rule` e o `feedback`.
3. **`call-response`:**
   - a forma alternada do EX14;
   - a regra da resposta:
     - há pelo menos 2 notas no espaço da resposta;
     - a última nota é do acorde;
     - a resposta **não** repete a pergunta. A semelhança é a distância
       de edição entre as sequências de intervalos, normalizada; acima de
       0,8, conta como cópia.
   - a frase do retorno: "a resposta copiou a pergunta: mude o ritmo ou
     o final".
4. **`vary-melody`:** as notas da melodia, nos tempos escritos com janela
   de ±1/4 de tempo, precisam soar (qualquer duração). Tudo entre elas é
   livre, mas conta no item "notas no lugar" contra a escala do tom.
5. **Guardar o improviso** (Pike 10: "quando encontrar uma melodia de que
   goste, lembre-se para repetir"):
   - com `record`, o resumo tem "Ouvir o meu improviso" (a mesma função do
     EX08);
   - e "Praticar como eco": cria um exercício `echo` temporário com as
     frases do aluno, recortadas por compasso. Ele não entra no curso, e
     o progresso não é salvo.
6. **A tela:** a `ChartRoundView` com o retorno em cartões no fim, no
   molde dos cartões de medidor do EX08.
7. **O curso de teste:** `test/fixtures/cursos/improviso/02-livre.md`, com
   cada modo.

## Testes

1. `improv_analysis_test.dart`, com gravações montadas:
   - escala de blues de C: 10 notas, 1 fora, dá 90%;
   - o motivo E-G-A tocado 3 vezes (uma transposta) é detectado;
   - frases separadas por 2 tempos de silêncio dão 3 frases;
   - tudo em colcheias dá a frase de variedade baixa.
2. `exercise_timed_test.dart`:
   - `call-response`: um aluno que copia a pergunta não passa; um que
     responde com outra frase terminando na 3ª passa;
   - `vary-melody`: um aluno que toca a melodia com uma nota de passagem
     entre cada par passa.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas` do retorno.
2. **(manual)** Com o usuário, um improviso em cada modo. As frases de
   retorno são úteis e justas? Anote e ajuste os limiares.

## Fora de escopo

Julgar beleza, estilo ou "outside" (side-slipping, nível 6). O
desenvolvimento motívico avançado (transformação, inversão).

## Notas de execução

(preencher)
