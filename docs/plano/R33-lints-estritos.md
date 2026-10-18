# R33 — Regras estritas do analisador

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

O analisador passa a pegar `dynamic` escondido e `Future` esquecido, no
app e nos pacotes (achado 23 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- `analysis_options.yaml` da raiz e os de `packages/*/`.

## Contexto que você precisa

- Hoje a raiz só inclui `package:flutter_lints/flutter.yaml` (a lista
  `rules:` está vazia). Cada pacote em `packages/` tem o próprio
  `analysis_options.yaml`.
- Medição de 17/10, só `lib/`, com as regras abaixo ligadas: **27
  achados**.

  | Regra | Achados |
  |---|---|
  | `discarded_futures` | 20 |
  | erros de `dynamic` (`strict-casts`/`strict-inference`) | 3: `lib/course/ui/markdown_view.dart:245` e `:318` (`dynamic` → `Node`), `lib/main.dart:1130` (`dynamic` → `Matrix4`) |
  | `avoid_dynamic_calls` | 2 |
  | `strict_raw_type` | 1: `lib/course/ui/audio_mark_view.dart:43` (`StreamSubscription` sem tipo) |
  | `unawaited_futures` | 1 |
  | `prefer_final_locals` | 0 |

  Por pasta: 21 em `lib/course`, 3 em `lib/main.dart`, 1 em `lib/midi`,
  1 em `lib/practice`, 1 em `lib/settings`.
- `use_build_context_synchronously` já vem no `flutter_lints`.
- O código já usa `unawaited(...)` de `dart:async` para o que é de
  propósito; é a correção certa para a maior parte dos `discarded_futures`.

## O que fazer

1. Na raiz:

   ```yaml
   analyzer:
     language:
       strict-casts: true
       strict-inference: true
       strict-raw-types: true
   linter:
     rules:
       - unawaited_futures
       - discarded_futures
       - avoid_dynamic_calls
       - prefer_final_locals
   ```

2. Corrija os 27 achados do `lib/` (tipos explícitos nos três erros,
   `unawaited` onde o futuro é solto de propósito, `await` onde não é).
3. Um `analysis_options_shared.yaml` na raiz com essas regras, incluído
   pelos `analysis_options.yaml` dos pacotes; meça e corrija cada pacote.
   Anote as contagens nas notas.
4. `score_bridge/` fica de fora (é subtree do bridge e segue as regras de
   lá).

## Fora de escopo

Outras regras. Mudar comportamento: cada `unawaited` novo mantém o que o
código já fazia.

## Critérios de aceite

1. `just analyze` limpo com as regras ligadas, no app e em cada pacote.
2. `just test` limpo.

## Notas de execução

