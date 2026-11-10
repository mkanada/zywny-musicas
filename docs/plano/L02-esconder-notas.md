# L02 — `score_bridge`: esconder colunas (nota, barra, linha suplementar)

**Repo:** **zywny-comum** (`score_bridge/`) · **Depende de:** G09 do bridge (regra
normativa e vetores) · **Decisão necessária:** nenhuma

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

Uma API no `score_bridge` para **esconder um conjunto de notas** e
devolvê-las, sem recompilar a página a cada mudança e sem deixar pista da
altura. Ainda sem a pausa substituta (L03).

## De onde vem a regra

O que apagar para uma nota sumir de verdade é regra do **formato**, não
deste passo: está na §11 da especificação do `.vsb`, escrita, provada contra
o Verovio e entregue com vetores de teste pelo repo do bridge
(`/home/mauricio/rust_projects/verovio_flutter_bridge`, passos G07–G09 de
`docs/plano/`). Este passo é a **porta Dart** dela. Se G09 ainda não está
`concluído` lá, pare: não invente a regra aqui.

## Ler antes (só isto)

- [L00](L00-trilha-do-decorar.md): "O que some" e "Fatos medidos".
- No bridge: `docs/nota-para-zywny-sumico.md` (G09, escrita em 04/11/2026) e a §11
  de `docs/formato/especificacao-v1.md`, regras 1–3; a referência executável é
  `compare/scripts/hide_ref.py` (`hidden_shapes`).
- `zywny-comum/score_bridge/lib/src/score_controller.dart` L1-L50 (modelo de cor e ids
  não-animáveis) e L163-L221 (`setColor`, `setColors`, `clearColor`).
- `zywny-comum/score_bridge/lib/src/scene_walk.dart` inteiro (percurso, cor herdada,
  `kOverrideExemptClasses`).
- `zywny-comum/score_bridge/lib/src/segmentation.dart` (itens estáticos × dinâmicos) e
  `zywny-comum/score_bridge/lib/src/page_layers.dart` (`_pictureAt`, `paint`).
- `zywny-comum/score_bridge/lib/src/ghost.dart` L116-L172 (índice por página: como
  achar o `staff` e o `notehead` de uma nota — reaproveite).
- `zywny-comum/score_bridge/test/ghost_test.dart` (como os vetores do bridge são lidos
  num teste) e `zywny-comum/score_bridge/test/fixtures/sumico/` (copiados em G09).

## Contexto que você precisa

- Esconder a **nota** solta já funciona hoje: `setColor(id, transparente)` no
  id do nó `note` leva junto cabeça, haste, colchete, acidente, articulação e
  pontos (são filhos). A letra (`verse`) fica, por `kOverrideExemptClasses`.
  Ids do timemap são animáveis: não há recompilação de `Picture`.
- **Acorde: não basta** (corrigido em G08c/G09, 04/11/2026). Haste, colchete,
  pontos e articulações de um acorde são filhos do nó `chord`, não de cada
  `note`. O nó `chord` some quando **toda** `note` descendente dele está
  escondida (§11, regra 1). Vale para os hinos: o Verovio junta numa `chord` as
  notas de uma mesma voz que começam juntas (hino 010: 95 `chord` para 425
  notas), embora o MusicXML não tenha `<chord/>`. Só um acorde cross-staff
  dividido entre duas pautas pode ficar pela metade (a haste fica; limitação
  da v1).
- **Duas pistas sobram**, e este passo existe por causa delas:
  1. **Barra de ligação** (regra 2 da §11): as formas filhas diretas do
     grupo `beam` somem quando toda `note` descendente está escondida.
     Pintar o `id` do `beam` de transparente **não serve**: pinta as notas
     filhas por herança. É preciso apagar só as folhas diretas.
  2. **Linhas suplementares** (regra 3 da §11): cada traço é uma forma
     própria, sem id, dentro de `ledgerLines above`/`below`, filho de
     `staff`. Um traço pertence às notas da mesma pauta cuja cabeça ele
     cobre em x e cujo `loc` (`pitchpos.json`) alcança a linha dele; some
     quando todas as donas estão escondidas. **A pausa deslocada (de
     verdade) também é dona** e nunca é escondida: um traço que tem uma
     pausa entre as donas fica. O bridge varreu 7 381 traços de 36 peças:
     0 sem dona e 0 com donas de colunas diferentes (D-SUM-NATIVO: sem dado
     novo na cena) — números na nota de G09. `beamSpan` (barra que
     atravessa compasso ou sistema) **não** é `beam` e não some.
- Barra e traços estão em segmentos **estáticos** (`Picture`): apagá-los
  recompila a página, ou exige promovê-los a dinâmicos. Meça
  (`pictureBuilds`) e escolha; o L05 esconde no começo da etapa e revela
  uma coluna por erro, então o custo por revelação é o que importa.
- Cor transparente **não** é "ausente": halo e toque (`onElementTap`) ainda
  enxergam o nó. Nota escondida não tem halo e não responde a toque.
- A continuação de uma nota ligada é uma `note` como outra qualquer e some
  pelo id (o chamador passa cabeça e continuações).

## O que fazer

1. API pública (exportada em `zywny-comum/score_bridge/lib/score_bridge.dart`), no
   `ScoreController` ou num controlador irmão:
   `setHidden(Set<String> noteIds)`, `reveal(String id)`, `clearHidden()`,
   `isHidden(id)`. Uma notificação por chamada, como o resto do
   controller. Ids expandidos (`-rend<N>`) resolvem pela regra de sempre.
2. Formas de barra e traços a apagar **derivados** do conjunto de notas,
   pela §11 — o chamador passa só notas.
3. Destaque sobre nota escondida: `highlight` num id escondido **não**
   pinta a nota (o L05 pisca a pausa, não a nota). Revelar devolve o
   comportamento normal.
4. Testes contra `fixtures/sumico/vetores.json` (copiado em G09: 11 casos;
   `esperado.hidden` traz `notes`, `chords`, `beams` e `ledgers`; tolerância
   0,5) e testes de pintura.

## Fora de escopo

- A pausa substituta (L03).
- Escolher o que esconder (L01) e quando revelar (L05).
- Mudar a §11 ou o formato: divergência entre a regra e o que se vê na
  tela é achado para o bridge (registre e avise), não para remendar aqui.

## Critérios de aceite

1. Teste: os casos de `vetores.json` — para cada conjunto escondido, as
   notas, os nós `chord`, as formas de barra e os traços apagados são os do
   vetor.
2. Teste de pintura: esconder uma nota fora de barra → nenhum pixel da
   nota (cabeça, haste, acidente) na imagem; a letra dela continua.
3. Teste de pintura: barra com 2 notas, uma escondida → barra visível; as
   duas → barra some; revelar uma → barra volta.
4. Teste de pintura: coluna com linha suplementar escondida ao lado de
   coluna visível com linha suplementar → só o traço da escondida some.
5. Teste: `clearHidden()` devolve a página pixel a pixel ao estado sem
   esconder nada.
6. Teste: esconder 50 notas de uma página de uma vez e revelar uma a uma →
   o número de recompilações de `Picture` está nas notas.
7. Teste: `highlight` em nota escondida não a mostra; depois de `reveal`,
   mostra.
8. `cd zywny-comum/score_bridge && flutter test` e `just analyze-comum` (rodado
   no zywny-musicas) limpos; `just test` do zywny-musicas e do zywny-aprendizado
   continuam verdes com o `zywny-comum` novo.

## Notas de execução

**Executado em 04/11/2026, no `zywny-comum` (`main`), sem commit.**

- **Arquivos.** Novos: `score_bridge/lib/src/hide.dart` (índice da página e regras 1-3),
  `test/hide_test.dart` (os 11 vetores), `test/hide_controller_test.dart` (contrato do
  controller, 11 testes), `test/hide_paint_test.dart` (pintura, 9 testes). Alterados:
  `score_controller.dart` (`setHidden`, `reveal`, `clearHidden`, `isHidden`, `hiddenIds`,
  `hiddenShapesOf`, `hiddenLeavesOf`), `segmentation.dart` e `page_layers.dart` (parâmetro
  `skipLeaves`), `score_page_view.dart` (recompila quando o conjunto de folhas muda; toque em
  nota escondida é ignorado), `model.dart` e `parser.dart` (`PitchEvent.dur`/`dots`, que o L03
  também usa), `score_bridge.dart` (exportações).
- **Como funciona.** O controller guarda `H` e deixa transparentes as notas e os nós `chord`
  cujas notas estão todas em `H` (regra 1; o L02 original esquecia o acorde). A barra e os traços
  não têm id: saem da segmentação da página (`skipLeaves`, por identidade). Nota escondida vence
  cor fixa e destaque: `highlight` é ignorado e não há halo; `setColor` só vale ao revelar;
  `clearAll` não revela (`clearHidden` revela); trocar de documento esquece `H`.
- **Critério 1.** 11 de 11 vetores batem (notas, `chord`, barras com nº de formas, traços com
  pauta/lado/ordem/x, tolerância 0,5), inclusive a página alternativa `alt0.0`.
- **Critério 6 (medido, `test/hide_paint_test.dart`, hino 010, página 0 de 2100x2970).** Uma
  geração de `Picture` = 139 estáticos (125 depois que os acordes viram dinâmicos). Esconder 50
  notas de uma vez = **1 geração** (125 `Picture`). Revelar as 50 uma a uma = **16 gerações**
  (só as revelações que devolvem barra ou traço; nota e acorde não recompilam nada). Custo:
  116 ms de gravação para 2 299 `Picture` no micro de desenvolvimento, cerca de 7 ms por
  geração. **Decisão:** recompilar a página, sem promover barra e traço a dinâmicos. Se no
  aparelho a revelação engasgar, a saída é um segmento dinâmico de "folhas escondíveis".
- **Desvios.** (1) O acorde, acima. (2) `clearAll` preserva o escondido. (3) O critério 6 diz
  só "está nas notas": o teste afirma as contagens exatas acima.
- **Limitações que seguem** (§11): `beamSpan` não some; acorde cross-staff dividido entre duas
  pautas fica com a haste; ligadura, dedilhado e apojatura ficam.
- **Verificação.** `cd score_bridge && flutter test`: 365 passam, 7 ignorados, 0 falham.
  `flutter analyze` no `zywny-comum`: limpo. `flutter test` no `zywny-comum`: 473 passam.
  Não rodei `just test` dos dois apps; o `flutter analyze` deles tem erros que não vêm daqui
  (`FakeMidiInput.sustain` com tipo antigo nos testes, `node_modules` do firebase).
