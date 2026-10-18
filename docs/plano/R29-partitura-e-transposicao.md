# R29 — Partitura em `lib/score/` e fluxo de transposição

**Repo:** zywny · **Depende de:** R28 · **Decisão necessária:** não

## Objetivo

Primeiro de dois passos que encolhem `_ScoreHomePageState` (~1780 linhas,
achado 22 da [revisão](../revisao/2026-10-15-revisao-geral.md)). A tela da
partitura sai de `lib/main.dart` para uma pasta própria, e o fluxo de
transposição — o maior bloco de lógica que ainda mora na tela — vira um
`ChangeNotifier` testável sem widget. Extração fiel: nada muda para a
pessoa.

## Ler antes (só isto)

- [Revisão](../revisao/2026-10-15-revisao-geral.md): achado 22.
- `graft skeleton lib/main.dart` (as linhas abaixo são de 15/10; o R27 e o
  R28 mexem no arquivo).
- O R08 como modelo de extração de controller.

## Contexto que você precisa

- `lib/main.dart` tem `main` (L86), `MyApp` (L117), `ScoreHomePage`
  (L185) e `_ScoreHomePageState` (L223–L2007).
- Métodos da transposição na tela: `_chooseTranspose` (L553),
  `_pickTone` (L581), `_transposeSection` (L602), `_transposeSeal` (L630),
  `_onSealTap` (L649), `_onShiftDetected` (L941),
  `_maybeRemindTransposeReset` (L967), `_maybeCheckTranspose` (L988),
  `_openTransposeCheck` (L1008), `_playOwnTone` (L1043),
  `_playKeyboardTone` (L1052), `_beep` (L1058), e os campos
  `_shiftNotice`, `_shiftDetector` e `_pitchFrame` (perto de L664–L690).
- A escolha do tom fica na `ScoreRenderSession` (`transposeChoice`); a
  conferência no teclado é `lib/practice/transpose_check.dart`; o detector
  de deslocamento é usado pelo `TrailRunner` (`shiftDetector`, `onShift`).
- O teste de camadas do R01 (`test/camadas_test.dart`) lista as pastas e o
  que cada uma pode importar: uma pasta nova precisa entrar nele.

## O que fazer

1. `lib/score/score_screen.dart` recebe `ScoreHomePage` e o estado (pode
   manter o nome da classe, para não mexer nos testes). `lib/main.dart`
   fica só com `main`, `_cursoArg` e `MyApp`.
2. `lib/score/transpose_flow.dart` (`ChangeNotifier`): a lógica dos
   métodos acima, sem `BuildContext`. O que abre diálogo ou toca som entra
   por callbacks (como o `SoundOutputPlayback` do R08). A tela fica com os
   widgets (`_transposeSection`, `_transposeSeal`) e chama o fluxo.
3. Registre `lib/score/` no teste de camadas.
4. `test/transpose_flow_test.dart`: escolher um tom pede a conferência só
   com teclado conectado; o lembrete de voltar o TRANSPOSE aparece uma vez;
   um deslocamento detectado avisa.

## Fora de escopo

Os widgets de zoom, gaveta, barra e corpo (R30). Mudar o comportamento da
transposição.

## Critérios de aceite

1. `wc -l lib/main.dart` ≤ 150.
2. Nenhum dos métodos de transposição listados (menos os dois widgets)
   existe na tela.
3. `just analyze` e `just test` limpos, com o teste novo.
4. Escolher "abrir sem acidentes" numa música, conferir no teclado e
   voltar ao original: como antes **(manual)**.

## Notas de execução

