# R28 — Um motor de som para o app

**Repo:** zywny · **Depende de:** R27 · **Decisão necessária:** não

## Objetivo

A escolha e a abertura do motor de som (sintetizador do app ou teclado
MIDI) ficam num lugar só, compartilhado pela partitura e pelo fluxo de
cursos (achado 21 da [revisão](../revisao/2026-10-15-revisao-geral.md)).
Hoje há duas cópias da lógica, e com uma música aberta o motor dos cursos
continua aberto por baixo.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 21.
- `lib/app/sound_output_controller.dart` (493 linhas; construtor ~L60,
  `ensureEngine` ~L257, `openAppEngine` ~L269, `ensureMidiOutEngine`,
  `applyOutput` ~L320, `dispose` ~L481).
- `lib/app/library_screen.dart` L262–L323 (o motor e a entrada MIDI dos
  cursos).
- O R08 (notas de execução), que criou o controller.

## Contexto que você precisa

- **Cursos** (`library_screen.dart`): `_courseEngine` (sintetizador,
  memoizado com `_courseEngineOpening`), `_courseMidiOutEngine` (recriado
  se o dispositivo mudar, guardado com `_courseMidiOutDeviceId`),
  `_ensureCourseEngine`/`_openCourseEngine` (L293–L323) e
  `_courseCurrentEngine`, que dá o relógio ao `_courseMidi`
  (`FlutterMidiInputService`, L272). Descartados no `dispose` da
  biblioteca.
- **Partitura** (`main.dart`, `initState` ~L366): cria um
  `SoundOutputController` por tela, com `settings`, `devices`, `input`
  (a entrada MIDI da tela, cujo relógio é `_sound.engine?.nowSeconds`),
  `monitorPitch` (do `PitchFrame` da partitura, depende do tom),
  `playback` (`SoundOutputPlayback`: prender/soltar o agendador da
  partitura) e `onMessage`.
- O relógio importa: o tempo real compara a tecla com o relógio do motor
  em uso; com outra origem toda nota cai fora da janela (comentário em
  `library_screen.dart:264-271`).
- O motor nativo abre um stream de áudio do sistema; dois abertos ao mesmo
  tempo gastam recurso e, em alguns Androids, brigam pela saída.

## O que fazer

1. Separe o que é do app do que é da tela:
   - **do app** (vai para `AppServices`): os dois motores, a saída em uso,
     o `.sf2`, `ensureEngine`, `applyOutput`, o descarte do motor MIDI
     quando o dispositivo muda;
   - **da tela**: o monitor MIDI (depende do `monitorPitch` da
     partitura), o `SoundOutputPlayback` e as mensagens.
   Um jeito: o controller do app ganha `attach(cliente)`/`detach(cliente)`,
   e a partitura e o fluxo de cursos se prendem a ele enquanto estão
   abertos.
2. O fluxo de cursos usa o controller do app no lugar de
   `_courseEngine`/`_courseMidiOutEngine`; o relógio do `_courseMidi` vem
   do motor do controller.
3. A partitura deixa de criar motores; só se prende ao controller do app.
4. Testes: partitura e curso abertos em sequência usam o mesmo motor;
   trocar de saída nas configurações vale para os dois; fechar a partitura
   não fecha o motor; o monitor só liga com a partitura presa.

## Fora de escopo

O agendador e o player (`PlaybackController`). Mudar o comportamento do
som: é uma extração; a única diferença esperada é um motor a menos.

## Critérios de aceite

1. `grep -n '_courseEngine\|_courseMidiOutEngine' lib` não acha nada.
2. Um motor nativo aberto por vez (teste com fábrica contando aberturas).
3. `just analyze` e `just test` limpos.
4. No celular: tocar uma lição com som, abrir uma música e tocar, voltar
   à lição e tocar; trocar para "teclado MIDI" e repetir; o exercício de
   ritmo continua acertando as notas **(manual)**.

## Notas de execução

