# R32 — Exercício, pergunta e configurações em arquivos menores

**Repo:** zywny · **Depende de:** — · **Decisão necessária:** não

## Objetivo

Os três arquivos grandes que sobram (achado 22 da
[revisão](../revisao/2026-10-15-revisao-geral.md)) são divididos. Extração
fiel.

## Ler antes (só isto)

- `graft skeleton` dos três arquivos abaixo.

## Contexto que você precisa

**`lib/course/ui/exercise_screen.dart` (1267 linhas)**

- Widgets privados no fim: `_KeyboardGate` (L865–L902), `_ScoreControls`
  (L904–L994), `_RoundBody` (L996–L1127), `_ErrorChip` (L1130–L1154),
  `_ResultPanel` (L1159–L1267).
- `_newRound` (L244–L384) tem 140 linhas: prepara a rodada, gera a
  partitura, monta o player e o corredor de notas.

**`lib/course/ui/question_body.dart` (1126 linhas)**

- Um `State` só (L70–L1126). Um prompt por tipo de pergunta:
  `_findKeyPrompt` (L645), `_listenPrompt` (L694), `_intervalPrompt`
  (L752), `_scorePrompt` (L778), `_dictationPrompt` (L812),
  `_dictationReview` (L843); mais o painel de revisão `_reviewPanel`
  (L886) e os botões (L1079–L1125).
- `_keyToButton` (L596–L637) é lógica pura (tecla → botão), escondida no
  estado.

**`lib/app/general_settings_panel.dart` (758 linhas)**

- `GeneralSettingsPanel` (L82–L464), um `StatelessWidget` de 380 linhas.
- `_ColorRow` (L660) e `_SliderRow` (L706) parecem com `PhoneSliderRow` e
  `PhoneToggleRow` (`lib/ui/phone_chrome.dart:728` e `:764`): compare
  antes de criar outra peça.

## O que fazer

1. Exercício: os cinco widgets privados para
   `lib/course/ui/exercise_widgets.dart`; `_newRound` em funções menores
   (preparar, gerar, montar o player).
2. Pergunta: cada prompt vira um widget em
   `lib/course/ui/question_prompts.dart`; `_keyToButton` vira função pura
   com teste próprio.
3. Configurações: cada seção do painel (som, teclado MIDI, cores, treino…)
   num widget; as linhas de cor e slider reaproveitam as de `phone_chrome`
   se forem equivalentes.

## Fora de escopo

Mudar o desenho ou a lógica dos exercícios.

## Critérios de aceite

1. Nenhum dos três arquivos passa de 700 linhas.
2. `test/` ganha um teste para a função de tecla → botão.
3. `just analyze` e `just test` limpos.
4. `just telas`: exercício, pergunta e configurações iguais aos de antes
   **(manual)**.

## Notas de execução

