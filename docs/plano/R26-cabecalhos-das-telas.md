# R26 — Cabeçalhos das telas

**Repo:** zywny · **Depende de:** R25 · **Decisão necessária:** sim
(D-REV-CABEC)

## Objetivo

As telas secundárias (as que se abrem por cima da biblioteca e voltam
para ela) têm o mesmo cabeçalho: mesmo voltar, mesma fonte e mesmo fundo
(achado 19 da [revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 19.
- `lib/course/ui/course_chrome.dart` (`CourseScrollScaffold`, L175).

## Contexto que você precisa

| Tela | Cabeçalho de hoje |
|---|---|
| Cursos (`lib/course/ui/courses_screen.dart`) | `AppBar` |
| Curso, lição (`course_chrome.dart`, `CourseScrollScaffold`) | `AppBar` próprio do curso |
| Níveis da leitura (`lib/sight_reading/sight_levels_screen.dart`) | `AppBar` com `kPanelSideBg` e `serifDisplay(22)` |
| Sobre (`lib/about/about_screen.dart`) | `AppBar` |
| Rascunho e problemas do curso (`lib/course/draft/`) | `AppBar` |
| Exercício (`lib/course/ui/exercise_screen.dart`) | `AppBar` |
| Configurações gerais (`lib/app/general_settings_panel.dart`) | cabeçalho próprio |
| Biblioteca (`lib/app/library_screen.dart`) | cabeçalho próprio (tela principal) |
| Partitura (`lib/main.dart`) | `PhoneTitleBar` (`lib/ui/phone_chrome.dart:268`) |

- Os dois `_Header` privados (`about_screen.dart:186` e
  `general_settings_panel.dart:646`) **não** são cabeçalhos de tela: o
  primeiro é o cartão da marca no Sobre, o segundo é o rótulo de seção das
  configurações. Ficam como estão.
- `buildAppTheme` (`lib/ui/theme.dart:87`) não define `appBarTheme`: cada
  `AppBar` escolhe fundo, cor de superfície e fonte do título.

## Decisão necessária (D-REV-CABEC)

Pergunte ao usuário antes de escrever código:

- **(a) `AppBar` com tema.** Um `appBarTheme` em `buildAppTheme` (fundo,
  `surfaceTintColor` transparente, título em `serifDisplay`), e todas as
  secundárias usam `AppBar` sem estilo próprio. As configurações passam a
  usar `AppBar` também.
- **(b) Cabeçalho próprio.** Um widget `ScreenHeader` em `lib/ui/`, no
  desenho da biblioteca, usado por todas as secundárias.

Recomendação: **(a)**. É menos código, ganha o voltar do sistema e a
acessibilidade do Material de graça, e só a biblioteca e a partitura, que
são telas principais com cromo especial, ficam de fora.

## O que fazer

Com (a):

1. `appBarTheme` em `buildAppTheme`, com o fundo e o título da tela de
   níveis de hoje como referência.
2. Tire os estilos locais dos `AppBar` da tabela.
3. Configurações gerais com `AppBar` no lugar do cabeçalho próprio.

Com (b):

1. `lib/ui/screen_header.dart` (`ScreenHeader`: voltar, título, ações).
2. Troque o `AppBar` de cada tela da tabela por ele.

## Fora de escopo

Biblioteca e partitura. O conteúdo das telas.

## Critérios de aceite

1. Nenhuma tela secundária define cor de fundo ou fonte do título no
   próprio cabeçalho.
2. `just analyze` e `just test` limpos.
3. `just telas`: os cabeçalhos das telas da tabela iguais entre si, em
   retrato e paisagem **(manual)**.

## Notas de execução

