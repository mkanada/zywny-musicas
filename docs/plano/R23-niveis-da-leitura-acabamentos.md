# R23 — Tela de níveis da leitura: acabamentos

**Repo:** zywny · **Depende de:** R22 · **Decisão necessária:** não

## Objetivo

Os seis acabamentos que a revisão do commit `48baf78` achou na tela de
níveis da leitura à vista (achado 16 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). O bug de gravação da
mesma tela já foi corrigido em 16/10.

## Ler antes (só isto)

- `lib/sight_reading/sight_levels_screen.dart` (inteiro, ~190 linhas).
- `lib/sight_reading/sight_steps.dart`: `SightStep` (L16) e `sightStep`
  (L549).
- `lib/sight_reading/sight_progress.dart`: `isBehind` (L65) e `startOf`.

## Contexto que você precisa

1. **Diálogo repetido.** `_goTo` (L36) monta o próprio `AlertDialog`; o
   R22 cria o `confirmAction`.
2. **Ordem dos passos em três lugares.** `sightStep(level, sub)` calcula o
   índice `(level - 1) * sightSubLevels + sub`; `isBehind` compara nível e
   subnível em duas partes; `_stepTile` (L150) acha o passo atual comparando
   `step.name`. Se o modelo mudar (um quinto subnível, um nome novo), os
   três podem discordar.
3. **Lista montada inteira.** `ListView(children: …)` (L89) constrói os 20
   cartões (80 linhas) a cada `setState`. `CoursesScreen` já usa
   `ListView.builder`.
4. **"Reiniciar" sempre ativo** (L114). Em 1a, sem rodada limpa e sem
   resposta de ouvido, reiniciar não muda nada mas pede confirmação. E o
   texto do diálogo ("O treino volta ao 1a…") não diz que as rodadas
   limpas e as respostas de ouvido do passo atual são apagadas
   (`SightProgress.startOf` zera as duas).
5. **Store guardado uma vez.** `_SightReadingCard`
   (`lib/course/ui/courses_screen.dart:111`, estado em L130) faz
   `late final _store = widget.store ?? SightReadingStore()` e não tem
   `didUpdateWidget`; a tela de níveis recebe esse store. Se um rebuild
   passar outro store, o cartão continua com o antigo. Em produção
   `sightStore` é sempre `null`, então hoje não aparece.
6. **Teste com espera real.** `_pumpLevels`
   (`test/sight_levels_screen_test.dart:10`) espera 10 ms reais pelo
   `load()`. Numa máquina lenta a lista ainda é o spinner e o teste falha
   às vezes.

## O que fazer

1. `_goTo` usa `confirmAction(…, destructive: true)`.
2. `int get index` em `SightStep` (o mesmo cálculo do `sightStep`);
   `isBehind` e `_stepTile` comparam índices. Teste: para todo par de
   passos, `isBehind` bate com a comparação de índices.
3. `ListView.builder` com um item por nível, e o cabeçalho e o botão como
   primeiro e último itens.
4. "Reiniciar" desabilitado em 1a sem rodada limpa e sem resposta de
   ouvido. O texto do diálogo diz o que se perde: "As rodadas limpas e as
   respostas de ouvido do passo atual são apagadas."
5. `_SightReadingCard`: `didUpdateWidget` troca o store quando
   `widget.store` muda (ou o store passa a vir dos serviços do app, se o
   R27 já estiver feito).
6. `_pumpLevels` faz `pump` em laço até o spinner sumir (com limite de
   tentativas e `runAsync` curto entre elas).

## Fora de escopo

O conteúdo dos níveis. A gravação (corrigida em 16/10).

## Critérios de aceite

1. `grep -n 'step.name ==' lib/sight_reading` não acha nada.
2. Em 1a sem nada feito, "Reiniciar" aparece desabilitado (teste).
3. `just analyze` e `just test` limpos; `flutter test
   test/sight_levels_screen_test.dart` passa dez vezes seguidas.
4. A tela de níveis rola sem travar no celular **(manual)**.

## Notas de execução

