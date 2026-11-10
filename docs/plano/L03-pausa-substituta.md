# L03 — `score_bridge`: pausa substituta colorida

**Repo:** **zywny-comum** (`score_bridge/`) · **Depende de:** L02, G09 do bridge ·
**Decisão necessária:** nenhuma

> **Onde este passo roda (corrigido em 04/11/2026).** O `score_bridge` já não
> mora no zywny-musicas: os dois apps (zywny-musicas e zywny-aprendizado) o
> importam de `../zywny-comum/score_bridge`. Por isso **o código, os testes e o
> commit deste passo são no `zywny-comum`** (`main`, sem branch); este arquivo
> fica aqui porque a fase L nasceu aqui. O zywny-aprendizado usa a **mesma**
> API no treino "Notas escondidas" (`T16-notas-escondidas.md`, lá): nada
> específico do decorar entra no `score_bridge`. Os caminhos `zywny-comum/…`
> abaixo são relativos a `/home/mauricio/IdeaProjects`; os números de linha
> são de 01/10/2026 e o código andou (T08, T11): reconfira antes de citar.
> Não há `justfile` no `zywny-comum`: as receitas `just test-comum` e
> `just analyze-comum` rodam de dentro do zywny-musicas, e a `libverovio` se
> refaz com `just native` / `just native-android` de qualquer um dos apps
> (eles chamam `zywny-comum/tool/build_verovio_*.sh`).

## Objetivo

Desenhar, no lugar de cada coluna escondida, **uma pausa** com a figura
certa, numa cor que o chamador controla — e que pisca com o veredito.

## De onde vêm os dados e a regra

Glifos, figura da nota e posição da pausa são do **formato**. O trabalho no
fork (glifos de pausa sempre no dicionário, `dur`/`dots` no
`pitchpos.json`), a regra normativa (§11 da especificação, regras 4–7), a
prova contra o Verovio e os vetores de teste estão no plano do bridge
(`/home/mauricio/rust_projects/verovio_flutter_bridge/docs/plano/`, passos
G07–G09). Este passo é a **porta Dart**. Se G09 ainda não está `concluído`
lá, pare.

## Ler antes (só isto)

- [L00](L00-trilha-do-decorar.md): "O que some", "Durante a passagem".
- No bridge: `docs/nota-para-zywny-sumico.md` (G09, escrita em 04/11/2026) e a §11 de
  `docs/formato/especificacao-v1.md`, regras 4–7, mais a §2.8 (`dur`,
  `dots`).
- `zywny-comum/score_bridge/lib/src/ghost.dart` L28-L114 (`GhostGlyph`, `GhostNote`) e
  L116-L172 (índice por página).
- `zywny-comum/score_bridge/lib/src/ghost_layer.dart` inteiro (268 linhas):
  `GhostController`, `GhostPainter` — a camada por cima da página é o
  modelo a copiar.
- `zywny-comum/score_bridge/lib/src/model.dart` L279-L312 (`StaffGeometry`) e o modelo
  de `pitchpos.json`.
- `zywny-comum/score_bridge/test/fixtures/sumico/` (vetores e `.vsb`, copiados em G09).

## Contexto que você precisa

- **Antes de tudo: bibliotecas novas.** O `.vsb` é gerado no aparelho;
  sem refazer a `libverovio` (`just native` no Linux **e** `just native-android`,
  que chamam `zywny-comum/tool/build_verovio_*.sh`) os glifos de pausa e o `dur` não
  existem. `.vsb` sem eles (lib antiga): a coluna some sem pausa, sem
  exceção.
- **Figura**: `dur` e `dots` da nota mais curta da coluna, lidos do
  `pitchpos.json`. Não deduza do timemap. Quiáltera usa a figura escrita.
- **Glifo**: `E4E3` (semibreve) a `E4E9` (semifusa). Estão sempre em
  `VsbDocument.glyphs` (reservados, com `E1E7`, que a pausa **não** usa:
  o ponto de aumento é um **círculo** `{cx, cy, rx, ry}`, §11).
- **Posição**: a da regra 6 da §11 — x da cabeça mais à esquerda da
  coluna; `loc` da linha do meio (`n − 1`; menos 1 se for ímpar e `dur ≤ 2`),
  +2 para a semibreve; escala `gs` da pauta; pontos pela conta da §11, com a
  largura do glifo da pausa **truncada** (`⌊·⌋`). O `x` não tem oráculo no
  Verovio (trocar nota por pausa muda o espaçamento): é o da cabeça por
  definição. Pauta com `n ≠ 5`: `null`.
- **Uma pausa por (pauta de desenho, instante)**, mesmo com duas vozes na
  coluna.
- **Cor.** A camada tem uma cor de repouso (parâmetro; o app passa
  `kMemoRestColor`, **definida neste passo** em
  `zywny-comum/lib/practice/practice_colors.dart`: o treino "Notas escondidas" do
  zywny-aprendizado, T16, a usa sem esperar o L05; distinta de verde, azul,
  vermelho, âmbar, cinza e do laranja da fantasma, um violeta serve) e aceita um "piscar" por coluna (cor, ataque,
  sustentação, soltura), nos moldes de `ScoreController.highlight`. Cor e
  piscar são do host: não estão na §11.
- A camada vive dentro da página, como a das fantasmas: é recortada na
  virada por haste e acompanha zoom e pan.

## O que fazer

1. Parser/modelo: `dur` e `dots` no evento de `pitchpos.json` (ausentes →
   `null`/`0`).
2. `zywny-comum/score_bridge/lib/src/stand_in.dart`: `StandInRest {page, staffId,
   glyphs, x, y}` e `VsbDocument.standInFor(List<String> noteIds)` — a
   pausa de uma coluna (`null` se não der para calcular).
3. `zywny-comum/score_bridge/lib/src/stand_in_layer.dart`: `StandInController`
   (`setColumns(Map<chave, List<String> noteIds>)`, `remove(chave)`,
   `flash(chave, cor, …)`, `clear()`) e o painter; parâmetro novo em
   `ScorePageView`/`ScoreView`, `null` por padrão (custo zero, como
   `ghosts`).
4. Exportar em `zywny-comum/score_bridge/lib/score_bridge.dart`.
5. `kMemoRestColor` em `zywny-comum/lib/practice/practice_colors.dart` (a cor da
   pausa, parágrafo "Cor" acima).
6. Testes em `zywny-comum/score_bridge/test/`.

## Fora de escopo

- Qualquer mudança no fork ou na especificação (G08a–G08c, no bridge).
- Decidir quais colunas somem (L01) e quando piscar ou revelar (L05).
- Pausas por voz; pausa em pauta que não tem 5 linhas (devolva `null`).

## Critérios de aceite

1. Teste: os casos de `fixtures/sumico/vetores.json` — glifo, x, y, escala
   e pontos de cada pausa (`esperado.standIn`), tolerância de 0,5 unidade de
   viewBox; inclui a página alternativa (`pagina: "alt0.0"`).
2. Teste: `pitchpos.json` com e sem `dur`/`dots` é lido sem erro; os
   testes da nota fantasma continuam verdes com as fixtures novas.
3. Teste: coluna com duas vozes de figuras diferentes → uma pausa, com a
   figura da mais curta.
4. Teste de pintura: `flash` muda a cor da pausa e volta à de repouso;
   `remove` apaga só aquela.
5. Teste: `.vsb` antigo (fixture sem os glifos ou sem `dur`) →
   `standInFor` devolve `null` e nada quebra.
6. **(manual)** `just native` feito; hino 1 com metade das colunas
   escondidas: as pausas não colidem com as notas visíveis vizinhas nem
   com a letra. Anote os casos feios (semicolcheias coladas, por exemplo)
   com captura de tela — é retorno para o bridge.
7. **(manual, Android)** A lib nova está no APK: a mesma tela no celular
   mostra as pausas.
8. `cd zywny-comum/score_bridge && flutter test`, `just analyze-comum` e
   `just test-comum` (no zywny-musicas) limpos; `just test` do zywny-musicas e do
   zywny-aprendizado continuam verdes.

## Notas de execução

**Executado em 04/11/2026, no `zywny-comum` (`main`), sem commit. Critério 6 conferido; falta o 7 (Android).**

- **Arquivos.** Novos: `score_bridge/lib/src/stand_in.dart` (`StandInRest`, `StandInDot`,
  `VsbDocument.standInFor`), `stand_in_layer.dart` (`StandInController`, `StandInPainter`),
  `test/stand_in_test.dart` (11 vetores + 6), `test/stand_in_layer_test.dart` (14),
  `test/memo_rest_color_test.dart`. Alterados: `score_page_view.dart` e `score_view.dart`
  (parâmetro `standIns`, `null` por padrão: sem ele a árvore não ganha camada; a das pausas
  fica por baixo da das fantasmas), `lib/practice/practice_colors.dart` (`kMemoRestColor`,
  púrpura `0xFF8E24AA`; o violeta azulado de `kPracticeMeterMarkColor` já existia, então o
  teste exige distância de cor maior que 40 de todas as outras).
- **API.** `standInFor(noteIds, {page})` devolve `null` sem `pitchpos`, sem `dur`, com `dur` ≥ 128,
  sem o glifo no dicionário, pauta que não tem 5 linhas, ids fora da página ou de pautas
  diferentes. `StandInController(restColor:)`: `setColumns(Map<Object, List<String>>)`,
  `remove(key)`, `flash(key, cor, {attack, hold, release, curve})`, `clear()`, `visible`,
  `colorOf`, `restOf`.
- **Critérios 1 a 5.** Os 11 vetores batem (glifo, x, y, escala, `loc`, pontos, tolerância 0,5,
  inclusive a página alternativa). `pitchpos` com e sem `dur`/`dots` é lido sem erro e a fantasma
  segue verde. Duas vozes de figuras diferentes dão uma pausa, a da mais curta (vetor 1). Pintura:
  `flash` troca a cor e volta ao repouso; `remove` apaga só a dela; o ponto de aumento é um
  círculo na cor da pausa. `.vsb` antigo, sem `dur` ou sem glifos: `null`, nada quebra.
- **Critério 6 (manual, feito em 04/11/2026).** As bibliotecas foram refeitas no bridge depois
  do G08b (`6aa532d`, 20:02): Linux 21:35, Android arm64-v8a 21:46, Web 21:58, Android x86_64
  22:03. Com a `libverovio.so` do Linux renderizei o **hino 1 real**
  (`Hymn_Grabber/musicxml/001.musicxml`, 2100x2970) pelo mesmo caminho do app
  (`renderScoreToVsb`): os 217 eventos de `pitchpos.json` saem com `dur`, os 7 glifos de pausa
  estão no dicionário e as 57 colunas escondidas (metade, alternadas) ganharam pausa. Olhei a
  página: figuras certas (semínima, mínima, semibreve, pontuada), as pausas não colidem com as
  notas vizinhas nem com a letra. Repeti com os hinos 010 e 056 das fixtures: no 056, em trechos
  de semicolcheias, a pausa fica colada na nota visível vizinha (limitação da §11). Não foi na
  tela do app, porque a tela do decorar (L06) ainda não existe: foi um teste de widget com
  `ScorePageView`, `ScoreController.setHidden` e `StandInController`.
- **Critério 7 (Android) — pendente.** As `.so` Android novas estão no bridge
  (`verovio/bindings/dart/android-libs/`), mas os apps ainda têm as de 22/10 em
  `android/app/src/main/jniLibs/`: falta `just native-android` em cada app (copia para o
  `jniLibs`), gerar o APK e ver as pausas no celular. Idem a Web (`tool/build_verovio_web.sh
  --no-build` copia o `.js`).
- **Verificação.** Mesma do L02 (365 e 473 testes passando, análise do `zywny-comum` limpa).
