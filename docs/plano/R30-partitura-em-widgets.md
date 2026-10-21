# R30 — Partitura em widgets

**Repo:** zywny-musicas · **Depende de:** R29 · **Decisão necessária:** não

## Objetivo

Segundo passo do encolhimento da tela da partitura (achado 22 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). Os métodos que montam
pedaços da tela viram widgets em arquivos próprios em `lib/score/`, e o
estado fica com o que é estado. Extração fiel.

## Ler antes (só isto)

- `graft skeleton lib/score/score_screen.dart` (depois do R29).

## Contexto que você precisa

Métodos que só montam widgets (linhas de 15/10, em `lib/main.dart`):

| Método | Linhas | Destino sugerido |
|---|---|---|
| `_zoomControls`, `_zoomBy`, `_zoomTo` | L1117–L1190 | `score_zoom_controls.dart` |
| `_openMeasureJump` | L1228–L1283 | `measure_jump_dialog.dart` |
| `_buildPhoneTitleBar`, `_phoneSoundButton`, `_trailChip` | L1305–L1431 | `score_title_bar.dart` |
| `_buildTrailDrawer` | L1445–L1480 | `score_trail_drawer.dart` |
| `_buildPhoneBody` | L1482–L1597 | `score_phone_body.dart` |
| `_buildOptionsDrawer` | L1605–L1748 | `score_options_drawer.dart` |
| `_buildScoreArea`, `_scorePanel` | L1753–L1979 | `score_area.dart` |

- As peças comuns do celular já existem em `lib/ui/phone_chrome.dart`
  (`PhoneRail`, `PhoneTitleBar`, `PhoneOptionsDrawer`, `PhoneToggleRow`,
  `PhoneSliderRow`…). A `ExerciseScreen` usa as mesmas.
- Os widgets novos recebem dados e callbacks, não o estado inteiro. Se um
  deles precisar de mais de ~8 parâmetros, passe o controller
  (`PlaybackController`, `TrailRunner`…) em vez dos campos soltos.

## O que fazer

1. Um widget por linha da tabela, `StatelessWidget` sempre que der.
2. A tela chama os widgets no `build`.
3. Os testes de widget da partitura passam sem mudança de comportamento
   (só de `find`, se algum procurava por tipo privado).

## Fora de escopo

Mudar o desenho. Unificar com a `ExerciseScreen` (pode virar um passo
futuro, depois de ver o que ficou igual).

## Critérios de aceite

1. `_ScoreHomePageState` com ≤ 900 linhas.
2. `just analyze` e `just test` limpos.
3. `just telas`: telas da partitura iguais às de antes **(manual)**.

## Notas de execução

