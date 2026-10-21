# R28 — Um motor de som para o app

**Repo:** zywny-musicas · **Depende de:** R27 · **Decisão necessária:** não

## Objetivo

A escolha e a abertura do motor de som (sintetizador do app ou teclado
MIDI) ficam num lugar só, do app inteiro, e não da tela (achado 21 da
[revisão](../revisao/2026-10-15-revisao-geral.md)). Hoje a tela da partitura
cria um `SoundOutputController` por abertura e o descarta junto com a tela:
abrir e fechar uma música reabre o motor.

> O achado 21 nasceu com duas cópias da lógica no mesmo app — a da partitura e
> a do fluxo de cursos. Com a [divisão em três
> repositórios](https://github.com/mkanada/zywny-comum), o fluxo de cursos foi
> para o zywny-aprendizado e esta cópia saiu daqui. No app de músicas sobrou
> o motor da partitura, que é o que este passo arruma.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 21.
- `lib/app/sound_output_controller.dart` (construtor ~L60, `ensureEngine`
  ~L257, `openAppEngine` ~L269, `ensureMidiOutEngine`, `applyOutput` ~L320,
  `dispose` ~L481).
- `lib/main.dart` (onde a tela da partitura cria o controller, ~L375) e
  `lib/app/trail_runner.dart` (~L504, `ensureEngine`).
- O R08 (notas de execução), que criou o controller.

## Contexto que você precisa

- **Partitura** (`main.dart`): cria um `SoundOutputController` por tela, com
  `settings`, `devices`, `input` (a entrada MIDI da tela, cujo relógio é
  `_sound.engine?.nowSeconds`), `monitorPitch` (do `PitchFrame` da partitura,
  depende do tom), `playback` (`SoundOutputPlayback`: prender/soltar o
  agendador da partitura) e `onMessage`.
- **Trilha** (`lib/app/trail_runner.dart`): usa o mesmo controller da
  partitura (`_sound.ensureEngine()`), mas o relógio do motor é o que
  compara a tecla tocada com o instante esperado — com outra origem toda
  nota cai fora da janela.
- O motor nativo abre um stream de áudio do sistema; dois abertos ao mesmo
  tempo gastam recurso e, em alguns Androids, brigam pela saída.
- O `.sf2` (`assets/soundfonts/TimGM6mb.sf2`) é do app, mas a lista de fontes
  e a abertura do motor são do núcleo (zywny-comum).

## O que fazer

1. Separe o que é do app do que é da tela:
   - **do app** (vai para o `AppServices` do R27): os dois motores, a saída em
     uso, o `.sf2`, `ensureEngine`, `applyOutput`, o descarte do motor MIDI
     quando o dispositivo muda;
   - **da tela**: o monitor MIDI (depende do `monitorPitch` da partitura), o
     `SoundOutputPlayback` e as mensagens.
   Um jeito: o controller do app ganha `attach(cliente)`/`detach(cliente)`,
   e a partitura se prende a ele enquanto está aberta.
2. A partitura deixa de criar motores; só se prende ao controller do app.
3. Testes: abrir e fechar uma música mantém o mesmo motor; trocar a saída
   nas configurações vale para a partitura e para a trilha; fechar a partitura
   não fecha o motor; o monitor só liga com a partitura presa.

## Fora de escopo

O agendador e o player (`PlaybackController`). Mudar o comportamento do
som: é uma extração; a única diferença esperada é um motor a menos.

## Critérios de aceite

1. Nenhum `SoundOutputController` é criado dentro de uma tela.
2. Um motor nativo aberto por vez (teste com fábrica contando aberturas).
3. `just analyze` e `just test` limpos.
4. No celular: abrir uma música e tocar, voltar à biblioteca e abrir outra:
   o som não corta entre uma e outra; trocar para "teclado MIDI" e repetir
   **(manual)**.

## Notas de execução
