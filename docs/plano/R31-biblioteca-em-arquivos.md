# R31 — Biblioteca em arquivos menores

**Repo:** zywny-musicas · **Depende de:** R28 · **Decisão necessária:** não

## Objetivo

`lib/app/library_screen.dart` (2115 linhas, achado 22 da
[revisão](../revisao/2026-10-15-revisao-geral.md)) vira uma tela com o
estado e a composição, e os pedaços vão para arquivos próprios. Extração
fiel.

## Ler antes (só isto)

- `graft skeleton lib/app/library_screen.dart` (as linhas abaixo são de
  15/10; R27 e R28 mexem no arquivo).

## Contexto que você precisa

| Pedaço | Linhas (15/10) | Destino sugerido |
|---|---|---|
| Linha da música: `_PieceRow`, `_highlighted`, `_SubtitleLine`, `_TrailCell`, `_SortChip` | L1784–L2115 | `lib/app/library/piece_row.dart` |
| Cartões: `_noLibraryCard`, `_initialCourseCard`, `_installCard`, `_continueCard`, `_startCard`, `_CoursesRowCard`, `_InitialCourseCard` | L1053–L1407, L1681–L1782 | `lib/app/library/library_cards.dart` |
| Busca e ordenação: `_searchField`, `_clearSearch`, `_sortChips`, `_updateMoreChips` | L1183–L1226, L1336–L1343, L1411–L1478 | `lib/app/library/library_search.dart` |
| Duas colunas (paisagem): `_contentSideBySide`, `_sideBySide` e as constantes `_kSideBySide…` | L123–L137, L833–L1015 | `lib/app/library/library_layout.dart` |
| Fila de `.zywny` recebidos: `_incomingQueue`, `_drainingIncoming`, `_incomingReady`, `_onIncoming`, `_drainIncoming` | campos ~L262; L513–L552 | `lib/incoming/incoming_queue.dart` (controller) |
| Cursos ao vivo: `_LiveCoursesScreen`, `_DraftAwareProgress` | L1543–L1678 | `lib/course/ui/live_courses_screen.dart` |
| Passeio: `_maybeStartTour`, `_runTour` | L608–L663 | fica, se for pequeno depois do resto |

- Os widgets privados viram públicos dentro da pasta nova (ou `part` —
  prefira arquivos com import, como o resto do app).
- O teste de camadas do R01 (`test/camadas_test.dart`) precisa conhecer
  `lib/app/library/` se for uma pasta nova.

## O que fazer

1. Mova cada pedaço da tabela, um commit lógico por linha (ou um passo de
   teste por linha), rodando `just test` entre eles.
2. `IncomingQueue` com teste próprio: um pacote por vez; o segundo espera o
   primeiro terminar; nada é instalado antes de `ready`.

## Fora de escopo

Mudar o desenho ou a lógica. Os serviços (R27) e o motor (R28).

## Critérios de aceite

1. `wc -l lib/app/library_screen.dart` ≤ 900.
2. `just analyze` e `just test` limpos, com o teste da fila.
3. `just telas`: biblioteca em retrato e em paisagem igual à de antes
   **(manual)**.

## Notas de execução

