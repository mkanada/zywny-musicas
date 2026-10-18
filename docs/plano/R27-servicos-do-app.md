# R27 — Serviços do app

**Repo:** zywny · **Depende de:** R19 · **Decisão necessária:** sim
(D-REV-DI)

## Objetivo

Os serviços que valem para o app inteiro (configurações, MIDI, stores) são
criados uma vez no `main()` e chegam às telas por um escopo, em vez de
nascerem dentro do estado da biblioteca e serem passados à mão (achado 20
da [revisão](../revisao/2026-10-15-revisao-geral.md)). Não muda nada que a
pessoa veja.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 20; e o achado
  6 da [primeira rodada](../revisao/2026-10-06-qualidade-e-divisao.md)
  (posse dupla), resolvido no R07 para a partitura.
- `lib/main.dart` L86–L183 (`main`, `MyApp`).
- `lib/app/library_screen.dart` L143–L290 (construtor e campos) e
  L455–L471 (`dispose`).

## Contexto que você precisa

- `main()` (`main.dart:86`) cria só `TourStore` e `IncomingPackages` e os
  passa a `MyApp` → `LibraryScreen`.
- `_LibraryScreenState` cria, se não vierem pelo construtor:
  `LibraryStore`, `PieceProgressStore`, `MidiDeviceManager` (com
  `bluetooth:` ligado só no Android), `AppSettings` (e
  `_settingsLoaded = _settings.load()`), `PieceSettingsStore`,
  `TrailProgressStore`, `CourseStore`, `CourseProgressStore`. O `dispose`
  descarta cada um só se não veio de fora (`if (widget.progress == null)
  _progress.dispose()`, etc.): posse dupla.
- A partitura recebe tudo isso pelo `OpenedPiece` (`library_screen.dart:60`),
  montado em `_open` (L667).
- 16 arquivos de teste montam a biblioteca; cada um tem o próprio
  `pumpLibrary` (por exemplo `test/library_progress_test.dart:65`,
  `test/incoming_install_test.dart:60`, `test/library_settings_test.dart:69`).
  5 arquivos de teste montam `OpenedPiece`.
- `SightReadingStore` é criado em cada tela (ver R23, item 5).

## Decisão necessária (D-REV-DI)

Pergunte ao usuário antes de escrever código:

- **(a) `provider`.** `MultiProvider` no `MyApp`; as telas leem com
  `context.read<T>()` e reconstroem com `context.watch<T>()` ou
  `Selector`. Um pacote a mais, muito usado, que combina com
  `ChangeNotifier`.
- **(b) `InheritedWidget` à mão.** Um `AppServices` (classe com os campos)
  e um `AppScope` (~60 linhas) com `AppScope.of(context)`. Nenhuma
  dependência nova; o rebuild continua com `ListenableBuilder`, como hoje.

Recomendação: **(a)**, pela leitura mais curta nas telas e porque o
`ChangeNotifierProvider` já cuida do `dispose`. (b) também resolve o
achado, se o usuário preferir não somar dependência.

## O que fazer

1. `lib/app/app_services.dart`: `AppServices` com os stores, o
   `AppSettings` e o `MidiDeviceManager`; `AppServices.create()` para o
   app e um `dispose()` que fecha tudo. As configurações são lidas antes do
   `runApp` (ou o `Future` do `load()` fica em `AppServices`).
2. `main()` cria o `AppServices` e o expõe acima do `MaterialApp`.
3. `LibraryScreen` perde os parâmetros de store e as criações condicionais;
   o `dispose` dela não fecha mais nenhum serviço.
4. `OpenedPiece` perde os campos que agora vêm do escopo (se a partitura
   ler do escopo) ou continua recebendo-os da biblioteca, o que der menos
   mudança; anote a escolha.
5. `test/support/app_services_fakes.dart`: monta `AppServices` com stores
   em memória e fakes de MIDI; os 16 `pumpLibrary` passam a usá-lo (e
   viram um só, se der).

## Fora de escopo

O motor de som dos cursos (R28). Rotas (R35). Dividir `library_screen.dart`
(R31).

## Critérios de aceite

1. `grep -n 'widget.progress == null\|widget.appSettings == null' lib`
   não acha nada.
2. Nenhum store nem `MidiDeviceManager` é criado dentro de uma tela.
3. `just analyze` e `just test` limpos.
4. Conectar o teclado na biblioteca, abrir uma música e um curso: o
   teclado continua conectado nos dois **(manual)**.

## Notas de execução

