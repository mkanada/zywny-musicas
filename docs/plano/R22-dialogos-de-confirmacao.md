# R22 — Diálogos de confirmação

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Um só diálogo de confirmação no app, em que a ação que apaga ou reinicia
aparece com cor de perigo (achado 15 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 15.
- `lib/trail/trail_widgets.dart:265` (`confirmTrailReset`, ~20 linhas).

## Contexto que você precisa

| Onde | Pergunta | Botão | Destrutivo? |
|---|---|---|---|
| `lib/trail/trail_widgets.dart:265` (`confirmTrailReset`) | título e texto do chamador | `confirmLabel` | sim (reinicia a trilha) |
| `lib/app/courses_section.dart:80` | "Remover <curso>?" | Remover | sim |
| `lib/app/libraries_section.dart:68` | "Remover <biblioteca>?" | Remover | sim |
| `lib/sight_reading/sight_levels_screen.dart:38` | "Voltar ao <passo>?" / "Reiniciar a leitura?" | Voltar / Reiniciar | sim |
| `lib/course/ui/course_screen.dart:322` | lição bloqueada | Abrir assim mesmo | não |

- `confirmTrailReset` é chamado por `lib/main.dart` (`_confirmNewCut`,
  L507), `lib/app/general_settings_panel.dart` e o próprio
  `trail_widgets.dart`.
- Todos usam `TextButton('Cancelar')` + `FilledButton(<verbo>)` e tratam
  `ok != true` como cancelar. Os testes procuram os rótulos pelo texto:
  mantenha os rótulos.
- As cores do app estão em `lib/ui/theme.dart`. A cor de perigo já existe:
  `kBadColor`, que é o `error` do `kAppColorScheme` (`theme.dart:67`). Use
  `Theme.of(context).colorScheme.error`.
- Os outros `AlertDialog` (`course_installer.dart`, `midi_device_picker.dart`,
  `practice_tools.dart`, `transpose_check.dart`, `libraries_section.dart:103`)
  são avisos ou têm conteúdo próprio; ficam como estão.

## O que fazer

1. `lib/ui/confirm_dialog.dart`: `Future<bool> confirmAction(context,
   {required title, required message, required confirmLabel, bool
   destructive = false})`. Com `destructive`, o `FilledButton` usa a cor de
   perigo.
2. `confirmTrailReset` passa a chamar `confirmAction(…, destructive:
   true)` (ou os três chamadores chamam direto; escolha o que deixar menos
   código).
3. Troque os outros quatro diálogos da tabela.
4. Teste de widget do `confirmAction`: devolve `true` só no botão de
   confirmar; fechar por fora devolve `false`; o destrutivo usa a cor de
   perigo.

## Fora de escopo

Os avisos e diálogos com conteúdo próprio. O texto das perguntas.

## Critérios de aceite

1. `grep -rn 'AlertDialog(' lib` não acha mais os cinco lugares da tabela.
2. `just analyze` e `just test` limpos, com o teste novo.
3. Remover uma biblioteca mostra "Remover" na cor de perigo **(manual)**.

## Notas de execução

