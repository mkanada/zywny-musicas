# EX17 — `play-lead-sheet`: melodia escrita, acorde pela cifra

**Repo:** zywny · **Depende de:** EX11, EX16 · **Decisão necessária:** não

## Objetivo

A ponte entre ler e tocar por cifra: a lead sheet, ou fake book. A pauta
traz a **melodia** escrita e as **cifras** em cima. O aluno toca a
melodia na direita, conferida nota a nota, e faz a harmonia com a
esquerda (ou embaixo da melodia, na direita), conferida como na grade.

Livros:

- Harrison *Intro*, cap. 4: "sete-três abaixo da melodia" e "voicing de
  bloco abaixo da melodia";
- PFA 6: o estilo balada em 3 passos;
- PFA 7: os standards fáceis;
- Willey: tocar solo mantendo o baixo, os acordes e a melodia;
- *How to Play from a Fake Book* (no currículo).

## Ler antes (só isto)

- [EX11](EX11-play-chart.md) e [EX16](EX16-harmonize.md), item 3: o juiz
  "melodia + slots" do `mode: play` é o mesmo daqui.
- `lib/course/score/round_score.dart` e o MusicXML que o app já gera.

## Medir antes de escrever

O Verovio desenha **`<harmony>`** do MusicXML (a cifra acima da pauta)?
Com que fonte? E a cifra brasileira (`7M`, `(b5)`)? Faça três testes no
`render_helper` e registre:

1. um MusicXML com `<harmony><root>C</root><kind>major-seventh</kind>`;
2. o mesmo com o texto livre `<kind text="7M">`;
3. o mesmo com um `<harmony>` sobre uma pausa.

Se a cifra brasileira não sair, a tela desenha as cifras **por cima** da
partitura, com as posições dos compassos da cena (a `ScoreTimeline` dá o
início de cada compasso). Anote a escolha.

## O formato

````markdown
```zywny-exercise
id: n2-lead-sheet-1
type: play-lead-sheet
title: Melodia e acordes
file: media/canção-dp.musicxml
pattern: block
bpm: 70
pass: {accuracy: 80}
```

```zywny-exercise
id: n5-sete-tres-embaixo
type: play-lead-sheet
title: Sete-três abaixo da melodia
file: media/contrafato-1.musicxml
style: 7-3-under-melody
bpm: 80
swing: 62
pass: {accuracy: 80}
```
````

| Chave | Valor | Padrão |
| --- | --- | --- |
| `file` ou `abc` | a lead sheet: uma pauta de melodia com cifras (`<harmony>` no MusicXML; `"C"` entre aspas antes da nota no ABC, a sintaxe padrão de cifra em ABC) | — (obrigatória) |
| `pattern` | o molde da mão esquerda (EX11) | `block` |
| `style` | regras de estilo, no lugar de `pattern`: `7-3-under-melody` (Harrison), `block-under-melody` (Harrison), `ballad` (PFA 6: esquerda 1-5-8 aberta e melodia por cima) ou `stride` | ausente |
| `melody` | `check` (confere a melodia), `free` (só os acordes contam; a melodia pode ser enfeitada) | `check` |
| `bpm`, `swing`, `split`, `keys`, `backing` | como no `play-chart` | — |

### As regras de estilo

- **`7-3-under-melody`** (Harrison *Intro* 4):
  - na troca de acorde, a **direita** toca a melodia com a 3ª e a 7ª do
    acorde **abaixo** dela, no mesmo ataque;
  - as notas da melodia entre as trocas saem sozinhas;
  - a **esquerda** toca a fundamental, ou fundamental e 7ª, ou
    fundamental e 5ª.
  O juiz confere, na troca:
  - a nota mais aguda da direita = a melodia;
  - entre as outras notas da direita, a 3ª e a 7ª;
  - a nota mais grave da esquerda = a fundamental.
  As condições de exceção de Harrison (melodia que já é a 3ª ou a 7ª)
  aceitam o voicing sem a nota repetida.
- **`block-under-melody`:** a melodia e as 3 ou 4 notas do acorde abaixo
  dela, na troca.
- **`ballad`:** a esquerda faz o arpejo 1-5-8 (o molde
  `ballad-arpeggio`), e a direita faz a melodia, com uma nota do acorde
  abaixo opcional.
- **`stride`:** o molde `stride` na esquerda, e a melodia na direita.

## O que fazer

1. **A leitura das cifras da partitura:** depois do render, leia os
   `<harmony>`. Talvez seja preciso ler o MusicXML de novo no Dart, porque
   o `.vsb` pode não ter a cifra como dado: confira. Com as cifras e os
   tempos, monte um `ChordChart` (EX09). No ABC, as cifras entre aspas. O
   leitor de ABC do zywny (`docs/licoes/formato-v1.md`, seção 9) aceita as
   aspas? Se não, acrescente.
2. **A rodada:** uma `TimedRound` com `scoreBytes` (a partitura renderizada
   pelo `ScoreRenderer`, como no `ScoreRoundRunner`, para a tela desenhar a
   pauta com o cursor). O juiz é o "melodia + slots" do EX16, com os
   slots vindos das cifras e o molde ou o estilo.
3. **A tela:** a partitura com o cursor do compasso (o `ScorePlayer`
   acompanhando o `BeatClock`), as notas da melodia pintadas como no
   treino e o acorde de cada compasso pintado na cifra.
4. **O validador:** uma lead sheet sem cifra dá erro ("a partitura não tem
   cifras"), e uma cifra que o EX01 não lê dá erro com o compasso.
5. **O curso de teste:** `test/fixtures/cursos/lead-sheet/`, com uma canção
   de domínio público com cifras e um **contrafato** nosso: uma melodia
   nova sobre a progressão de um standard (`curriculo.md`, seção 7).

## Testes

1. `exercise_timed_test.dart`:
   - o aluno simulado (a melodia e o acorde de referência) passa nos dois
     exemplos;
   - no `7-3-under-melody`, um aluno sem a 7ª na direita erra só nas
     trocas.
2. A leitura das cifras: o MusicXML de teste dá a grade certa, com os
   tempos.

## Critérios de aceite

1. `just test` e `just analyze` verdes; `just telas`.
2. **(manual)** As duas lead sheets no teclado do usuário.

## Fora de escopo

Melodia com variação livre (o `improvise` com `vary-melody`, EX19) e
reconhecimento automático de forma.

## Notas de execução

(preencher)
