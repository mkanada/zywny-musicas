<!-- graft:start -->
## Graft — repo context graph

This repo is indexed in `graft/`: small linked markdown nodes that explain each
system and carry exact file:line spans, kept in sync with the code through git.

For ANY task here — understanding how something works, finding where code lives,
or scoping a change — get context from the graph before grepping or opening
source files. Re-ask freely (it's cheap) and reuse literal identifiers you
already have (symbol, error string, file name) as the query. New to this repo?
Run `graft map` first — a token-budgeted orientation (dir clusters, hubs,
hotspots), no LLM, no key.

- Run `graft ask "<your question>" --source` → ranked nodes with the relevant
  code spans inlined (each hit's ≤8-line crux by default; `--full` for whole
  definitions when the crux isn't enough). Match the tool to the task shape:
  for understanding or editing, the top node IS the answer — cite its
  `covers:` file:line spans and edit straight from `--source`. For
  exhaustive tasks ("every occurrence / every caller of this pattern"), ranked
  results are top-N, not complete — run `graft grep "<literal>"` instead
  (exhaustive over indexed files, grouped by enclosing symbol), falling back
  to raw `grep -rn` only for unindexed files.
- `graft skeleton <file>` → every definition's signature + span, ~10× cheaper
  than reading the file; use it to skim an API surface.
- `graft callers <symbol>` gives precomputed, exact edges — who calls this.
  Add `--direction out` for what it calls, or `--depth N` to walk
  transitively for the full blast radius. For structural questions, skip
  ranking and use this directly.
- Or browse: `graft/INDEX.md` lists every node; follow the links.
- Monorepos and folders of multiple repos rank fairly across sub-projects —
  hits carry `[scope/]` labels naming which one they're from. Narrow with
  `graft ask "<task>" --in <scope>/` once you know where you're working.

If a returned span is truncated ("+N more lines"), open the file at that exact
range before finalizing. Only open source files when a node genuinely lacks a
needed detail, and then at the exact file:line the node points to — never
re-read whole files.

After big code changes, refresh the graph with `graft build` (deterministic,
no API key, $0).
<!-- graft:end -->

## Regra de trabalho: nada de branch

Este repositório não usa branch. A equipe trabalha **só no `main`**.

- **Não crie branch.** Nada de `git checkout -b`, `git switch -c`, `git branch <nome>` ou `git worktree add`.
- **Não troque de branch.** Nada de `git checkout <outra>` ou `git switch <outra>`.
- **Salve no `main`.** Faça o commit no `main` e envie com `git push origin main`.
- **Confira antes de começar.** `git branch --show-current` tem de mostrar `main`. Se mostrar outro nome, pare e pergunte antes de mexer em qualquer coisa.
- **Na dúvida, pergunte.** Se o trabalho parecer pedir uma branch ou um pull request, pergunte antes; não crie.

# Regra de projeto: estado e eventos pelo BLoC

Todo widget dos três repositórios (`zywny-comum`, `zywny-aprendizado`, `zywny-musicas`)
trata eventos e guarda estado pelo BLoC, inclusive os motores (MIDI, avaliação, som,
partitura). O guia completo, com as regras dos motores, está em
`zywny-aprendizado/docs/refatoracao/BL00-bloc-em-todos-os-widgets.md` ("O guia").

- **Nenhum `setState`, `ChangeNotifier` ou `ValueNotifier` de estado do app em `lib/`.**
  Importe `package:zywny_bloc/zywny_bloc.dart` (nunca `flutter_bloc` direto).
- **Cubit é o padrão**, ao lado do widget (`foo_screen.dart`, `foo_cubit.dart`,
  `foo_state.dart`); estado imutável com `Equatable` e `copyWith`. Cada Cubit tem o seu
  teste com `blocTest`.
- **StatefulWidget só** como dono de objeto do framework (`AnimationController`, `Ticker`,
  `TextEditingController`, `ScrollController`, `FocusNode`, `WidgetsBindingObserver`,
  `GlobalKey`…) ou de um Cubit que as ações da tela chamam, e sem `setState`.
- **Efeito colateral** (navegar, diálogo, `SnackBar`) em `BlocListener`, nunca no `builder`.
- **Motores:** métodos síncronos; o motor lê o `state` direto; `serial` no estado quando um
  aviso tem de repetir o mesmo valor; `BlocSelector` onde o motor emite por tique;
  `BlocRepaint` para `CustomPainter(repaint:)`; aviso de motor para motor por chamada
  síncrona (o `stream` é só para a tela); nada de `emit` depois de `close`.
- **Catraca:** `zywny-comum/tool/catraca_bloc.sh <repo>` roda no `just qualidade` e
  compara com `tool/catraca_bloc.txt`, que só tem linhas `# framework: …`. Arquivo novo
  com `setState`/`ValueNotifier`/`ListenableBuilder` quebra a catraca; um dono de objeto
  do framework entra com a marca e o motivo.
