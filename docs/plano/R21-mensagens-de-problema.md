# R21 — Mensagens de problema

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Quando algo dá errado, o aluno lê uma frase que entende, sempre no mesmo
padrão, e o detalhe técnico vai para o `DiagLog` (achado 14 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 14.
- Os lugares da tabela abaixo.

## Contexto que você precisa

Lugares que mostram a exceção ao aluno (levantados em 15/10 com
`grep -rn '\$e' lib`; confira de novo, as linhas andam):

| Onde | Texto de hoje |
|---|---|
| `lib/app/library_screen.dart:740` | `Não deu para abrir "<título>": $e` |
| `lib/main.dart:1860` | `Não deu para abrir <o> <hino>: $error` (área da partitura) |
| `lib/app/sound_output_controller.dart:278` | `som: erro ao iniciar ($e)` (via `onMessage`) |
| `lib/app/sound_output_controller.dart:464` | `não consegui usar esse soundfont ($e)` |
| `lib/app/general_settings_panel.dart:568` | `não consegui usar esse soundfont ($e)` |
| `lib/course/course_installer.dart:55` e `:191` | `Não consegui abrir o seletor de arquivos: $e` |
| `lib/course/course_installer.dart:143` | `Não consegui guardar o curso: $e` |
| `lib/course/course_installer.dart:248` | `Não consegui ler "<nome>": $e` |
| `lib/app/libraries_section.dart:93` | `Não consegui remover <biblioteca>: $e` |
| `lib/app/courses_section.dart:104` | `Não consegui remover <curso>: $e` |

- `lib/app/score_render_session.dart:396-397` guarda `_status = 'erro: $e'`
  e `_error = '$e'`; é a origem do texto da `main.dart:1860`.
- `DiagLog.log(categoria, texto)` vem de `packages/zywny_diag`.
- Os controllers não têm `BuildContext`: falam pela callback `onMessage`.
- `lib/audio/sound_engine_debug_panel_native.dart:78` é painel de
  depuração; pode continuar mostrando o erro.

## O que fazer

1. `lib/ui/problem_message.dart`: `showProblem(context, message, error,
   [stackTrace])` mostra um `SnackBar` só com `message` e registra
   `DiagLog.log('erro', '$message: $error\n$stackTrace')`.
2. Padrão de redação: começa com maiúscula, verbo na primeira pessoa,
   "Não consegui …", e diz o que fazer quando houver o que fazer ("Confira
   se o arquivo é um .zywny."). Sem "Não deu para".
3. Troque cada linha da tabela. Nos controllers, a callback recebe só a
   frase; o controller registra o erro no `DiagLog` antes de chamá-la.
4. Na área da partitura (`main.dart:1860`), a frase amigável; o texto da
   exceção só com `--debug` (`widget.debugMode`).
5. Ajuste os testes que procuram os textos antigos.

## Fora de escopo

Diálogos de confirmação (R22). Mensagens que não são de erro.

## Critérios de aceite

1. `grep -rn '\$e\b\|\$error\b' lib --include=*.dart` só acha `DiagLog`,
   `debugPrint` e o painel de depuração.
2. Nenhum texto visível começa com minúscula nem usa "Não deu para".
3. `just analyze` e `just test` limpos.
4. Escolher um arquivo que não é `.zywny` em "Instalar" mostra a frase
   nova, sem texto técnico **(manual)**.

## Notas de execução

