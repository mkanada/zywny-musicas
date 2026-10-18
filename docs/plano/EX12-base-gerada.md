# EX12 — Base gerada: bateria e baixo a partir da grade e do estilo

**Repo:** zywny · **Depende de:** EX11 · **Decisão necessária:**
D-EXE-BASE e D-EXE-SWING

## Objetivo

Os 17 livros Hal Leonard pedem, em quase todo exemplo, "ouça a faixa e
toque junto". As lead sheets de Valerio vêm com o piano isolado num canal,
para o aluno tirar o piano e assumir o lugar dele. O app não tem as
faixas, mas pode **gerá-las**, da grade e do estilo:

- a bateria GM (canal 10);
- um baixo (fundamental e 5ª, ou walking).

É o que dá groove ao `play-chart`, ao `echo` (EX14), ao `target-notes`
(EX18), ao `improvise` (EX19) e ao `follow-form` (EX20).

## Ler antes (só isto)

- [EX10](EX10-timed-round-e-chart-session.md) (`BeatNote`,
  `TimedRound.appNotes`) e [EX11](EX11-play-chart.md).
- `packages/zywny_audio/lib/sound_engine.dart` e o `soundfont_store.dart`:
  qual soundfont o app usa (D-SF: GeneralUser GS, com kit de bateria GM).

## Medir antes de escrever

1. O soundfont do app tem o **banco 128** (bateria) e responde no canal
   10 (índice 9)? Toque, pelo `NativeSoundEngine` e pelo `WebSoundEngine`,
   as notas GM:
   - 36, o bumbo;
   - 38, a caixa;
   - 42, o chimbal fechado;
   - 46, o chimbal aberto;
   - 51, o prato de condução;
   - 37, o aro;
   - 75, as claves;
   - 70, o chocalho (maracas);
   - 56, o cowbell.
   Registre o que soa.
2. O baixo: o programa GM 33 (baixo elétrico com dedo) e o 32 (acústico)
   soam bem no soundfont? E no teclado externo (M03), que pode não ter
   bateria no canal 10?
3. **Saída pelo teclado externo:** muitos pianos digitais não têm bateria.
   A base pode ir **sempre** pelo som do app? Hoje a saída é uma só,
   escolhida nas configurações. Proponha nas notas: a base pelo som do app
   e o resto pela saída escolhida, ou a base desligada com saída externa e
   um aviso. Pergunte ao usuário antes de decidir.

## O formato

````markdown
```zywny-exercise
id: n3-blues-com-base
type: play-chart
title: Blues em Sol com a banda
chart: {progression: blues-12, key: G}
pattern: boogie
backing: {style: shuffle, bass: walking, drums: true}
bpm: 96
choruses: 3
pass: {accuracy: 80, choruses: 2}
```
````

| Chave de `backing` | Valor | Padrão |
| --- | --- | --- |
| `style` | um estilo da tabela abaixo | o `drums` do padrão |
| `drums` | `true` ou `false` | `true` |
| `bass` | `none`, `root` (a fundamental no 1), `root-fifth`, `walking` ou `pattern` (o baixo do estilo) | `root-fifth` |
| `volume` | de 0 a 100, relativo ao piano do aluno | `70` |
| `intro` | compassos de base antes da forma, no lugar da contagem | `1` |

`backing: drums` (só o texto) é o atalho de `{drums: true, bass: none}`.

### Os estilos (`lib/course/exercise/backing_styles.dart`)

Cada estilo é um molde de bateria de 1 ou 2 compassos (as notas GM em
`grid`, como no molde de padrão do EX11) e um molde de baixo opcional:

| Estilo | Bateria (ideia) | Baixo (ideia) | Fonte |
| --- | --- | --- | --- |
| `straight` | bumbo 1 e 3, caixa 2 e 4, chimbal em colcheias | fundamental e 5ª em semínimas | Harrison *Beginning Rock* 2 |
| `rock` | o mesmo, com mais bumbo | fundamental em colcheias | Miller; Harrison |
| `shuffle` | chimbal em tercinas (1 e 3 da tercina), caixa 2 e 4 | boogie 1-3-5-6 | Harrison *Blues*; PFA 2 (12/8 boogie shuffle) |
| `swing` | prato de condução "ding, ding-da-ding", chimbal com o pé no 2 e no 4 | walking em semínimas | Harrison *Intro*; Valerio |
| `two-beat` | bumbo 1 e 3, caixa 2 e 4, sem chimbal | fundamental e 5ª nos tempos 1 e 3 | Harrison *Country* 4 |
| `waltz` | bumbo 1, chimbal 2 e 3 | fundamental no 1 | PFA 1 (oom-pah-pah) |
| `ballad` | aro no 2 e no 4, chimbal em colcheias, suave | notas longas | Harrison *Smooth Jazz*; PFA 6 |
| `bossa` | aro na clave da bossa, chimbal em colcheias, bumbo 1 e "e" do 2 | fundamental e 5ª, semínima pontuada e colcheia | Valerio *Latin* 5; Willey 5 |
| `samba` | chocalho em semicolcheias (o ganzá), surdo no 2, tamborim no ritmo do Willey | o surdo: fundamental com a nota longa no 2 | Willey 2 e 4 |
| `salsa-2-3` / `salsa-3-2` | claves na clave escolhida, cowbell, conga | o tumbao (antecipa o 4) | Martignon 4; Valerio *Latin* 1 |
| `reggae` | o "one drop": bumbo e aro no 3 | fundamental no 1 e no "e" do 2 | PFA 1, ritmo 14 |
| `gospel-shuffle` | o shuffle, com palmas no 2 e no 4 | o boogie | Cowling 8 |
| `funk` | semicolcheias no chimbal, caixa no 2 e no 4 e notas fantasma | fundamental sincopada | Harrison *R&B* 4 |

Os moldes são nossos, escritos a partir da ideia. Confira cada um com o
usuário no aceite.

## O que fazer

1. **Gerador:** `generateBacking(ChordChart chart, BackingSpec spec, {int
   bpm, int swing, int choruses}) → List<BeatNote>`.
   - **A bateria:** o molde, repetido por compasso. Na última volta, um
     prato no tempo 1 do compasso final e o resto parado.
   - **O baixo:**
     - `root`: a fundamental (ou o baixo da cifra) no 1;
     - `root-fifth`: 1 e 5;
     - `walking`: 4 semínimas por compasso. O tempo 1 é a fundamental e
       o 4 é uma **nota de aproximação** (um semitom acima ou abaixo da
       fundamental do acorde seguinte, alternando), e o 2 e o 3 vêm do
       arpejo ou da escala (Harrison *Blues* 3, "linhas de walking
       bass");
     - `pattern`: o baixo do estilo.
     A região do baixo é de E1 (28) a G2 (43): transponha a oitava para
     caber.
   - **Swing:** os `BeatNote` saem em tempos retos; o `BeatClock` (EX10)
     aplica o swing.
   - **Humanização mínima:** velocity ±6 aleatória e acento no 2 e no 4
     da caixa. Sem microtiming, que é a fase H: anote o vínculo nas notas.
2. **Os instrumentos:** `program` 33 no canal do baixo (escolha um que não
   seja o do piano nem o 9); a bateria no canal 9.
3. **O formato:** `backing` no `PlayChartSpec`, como mapa ou texto. O
   validador recusa um estilo desconhecido e `bass: walking` em 3/4 (aviso:
   "walking em 3/4 soa estranho; use `root`").
4. **Na tela:**
   - o botão de base na barra do exercício (ligada ou desligada, como o
     metrônomo) e o volume;
   - com a base ligada, o metrônomo vem desligado por padrão;
   - o `intro` substitui a contagem: a banda toca 1 compasso e o aluno
     entra.
5. **A marca `zywny-chart` (EX09):** o "Ouvir" usa a base em `straight`,
   com o piano em bloco, no lugar da versão simples.

## Testes

1. `backing_test.dart`:
   - `straight` em 4 compassos de C dá 4 × (2 bumbos + 2 caixas + 8
     chimbais) na bateria, e o baixo C-G por compasso;
   - `walking` de C para F: o tempo 4 do compasso de C é E ou F♯;
   - a região do baixo fica entre 28 e 43;
   - `salsa-3-2` e `salsa-2-3` têm as claves em posições diferentes,
     conferidas contra a tabela da clave de son de Martignon, escrita no
     teste.
2. `exercise_timed_test.dart`: `play-chart` com `backing` agenda notas no
   canal 9 e no canal do baixo, e o aluno simulado passa.

## Critérios de aceite

1. `just test` e `just analyze` verdes.
2. **(manual)** Ouvir cada estilo a 80 e a 140 bpm com o usuário. Para
   cada um:
   - o groove é reconhecível?
   - o volume equilibra com o piano?
   - como sai pelo teclado externo? (item 3 de "Medir antes")
   Anote os moldes corrigidos.

## Fora de escopo

Faixas gravadas, outros instrumentos (sopros, guitarra) e humanização por
regras (fase H).

## Notas de execução

(preencher)
