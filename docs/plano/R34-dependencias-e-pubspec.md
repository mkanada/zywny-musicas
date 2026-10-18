# R34 — Dependências em dia e `pubspec.yaml` limpo

**Repo:** zywny · **Depende de:** R24 · **Decisão necessária:** não

## Objetivo

As dependências diretas na versão atual, e o `pubspec.yaml` sem os textos
do modelo do `flutter create` (achado 24 da
[revisão](../revisao/2026-10-15-revisao-geral.md)).

## Ler antes (só isto)

- `pubspec.yaml` e os `pubspec.yaml` de `packages/*/`.
- `flutter pub outdated` (rode no começo).

## Contexto que você precisa

- Em 17/10, 35 pacotes tinham versão nova fora das restrições. Entre os
  diretos do app: `flutter_midi_command` 1.3 → 1.4 (e os
  `flutter_midi_command_*`, incluindo o `_ble`), `package_info_plus`
  10.2.1 → 10.2.2, `shared_preferences` 2.5.5 → 2.5.6, `wakelock_plus`
  1.8.0 → 1.8.1. `google_fonts` (8 → 9) sai no R24. `universal_ble` 3 vem
  pelo `flutter_midi_command_ble`.
- O MIDI por Bluetooth (commit `53caeb0`) depende de
  `flutter_midi_command_ble`: a subida para 1.4 precisa do teste com
  teclado BLE.
- O `pubspec.yaml` tem `description: "A new Flutter project."` e dezenas
  de linhas de comentário do modelo (versão, `cupertino_icons`, fontes de
  exemplo `Schyler`/`Trajan Pro`, imagens).
- `cupertino_icons` está declarado; confira se algum `CupertinoIcons` é
  usado antes de manter.

## O que fazer

1. `description:` com uma frase do que o app é.
2. Tire os comentários do modelo; mantenha os comentários do projeto (os
   que explicam cada dependência e asset).
3. Suba as dependências diretas (`flutter pub upgrade --major-versions`
   com cuidado, uma família por vez), rodando `just test` a cada uma.
4. Tire `cupertino_icons` se não for usado.
5. Leia o changelog do `flutter_midi_command` 1.4 e anote nas notas o que
   mudou para USB e BLE.

## Fora de escopo

Trocar de pacote. O `score_bridge` (segue o bridge).

## Critérios de aceite

1. `flutter pub outdated` sem dependência direta atrasada (ou com o
   motivo anotado).
2. `just analyze` e `just test` limpos.
3. Android: teclado USB e teclado BLE conectam e tocam **(manual)**.
4. Linux e Web: o app abre, toca com som e recebe MIDI **(manual)**.

## Notas de execução

