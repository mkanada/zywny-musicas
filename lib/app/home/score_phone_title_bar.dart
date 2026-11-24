import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny/tutorial/score_tour.dart';
import 'package:zywny_comum/midi/midi_device_picker.dart';
import 'package:zywny_comum/practice/practice_controller.dart';
import 'package:zywny_comum/settings/settings_state.dart' show SoundOutput;
import 'package:zywny_comum/trail/stage_result.dart' show kTrailPassAccuracy;
import 'package:zywny_comum/trail/trail_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';
import 'package:zywny_library/piece.dart';
import 'package:zywny_midi/midi_device_manager.dart';

/// O que a barra do título do celular usa da tela, no build em que é montada.
typedef PhoneTitleBarHost = ({
  Piece piece,
  ScoreTourKeys tourKeys,
  TrailRunnerCubit runner,
  SoundOutputCubit sound,
  MidiDeviceManager midi,
  bool hasPlayer,
  bool trainingMode,
  String trainingPillText,
  Widget? transposeSeal,
  VoidCallback backToLibrary,
  void Function(TrailCubit trail) leaveFreeMode,
  VoidCallback openStageDrawer,
});

/// A barra do título do celular: voltar, número e título do hino e, no
/// treino, os selos de modo/mão e de acertos e erros.
Widget buildPhoneTitleBar(PhoneTitleBarHost h) {
  final piece = h.piece;
  final chip = _trailChip(h);
  return PhoneTitleBar(
    number: piece.number,
    title: piece.title,
    onBack: h.backToLibrary,
    backKey: h.tourKeys.back,
    center: chip == null
        ? null
        : KeyedSubtree(
            // Só o chip de uma etapa da trilha é o alvo do tutorial: o de
            // "Treino livre" e o de trilha indisponível dizem outra coisa.
            key: h.runner.trailMode ? h.tourKeys.trail : null,
            child: chip,
          ),
    trailing: [
      _phoneSoundButton(h),
      ?h.transposeSeal,
      if (h.runner.trailMode) _keyboardNotice(h.midi),
      if (h.trainingMode) PhoneStatusPill(text: h.trainingPillText),
      if (h.runner.practice case final practice?)
        practice.mode == PracticeMode.wait && practice.range == null
            // Modo espera livre não tem resultado: os dois contadores.
            ? ListenableBuilder(
                listenable: Listenable.merge([
                  practice.correctCount,
                  practice.wrongCount,
                ]),
                builder: (context, _) => PhoneCountersPill(
                  correct: practice.correctCount.value,
                  mistakes: practice.wrongCount.value,
                ),
              )
            // Com resultado (trilha ou tempo real livre): a
            // porcentagem do resumo, com a meta na trilha (U05).
            : ValueListenableBuilder(
                valueListenable: practice.liveScore,
                builder: (context, score, _) => PhoneScorePill(
                  hits: score.hits,
                  total: score.total,
                  goalPercent: practice.range != null
                      ? (kTrailPassAccuracy * 100).round()
                      : null,
                ),
              ),
    ],
  );
}

/// Alto-falante da barra do título (U04): mostra o som de agora; o toque
/// muda também a preferência. Saída no teclado MIDI sem teclado: explica e
/// leva ao seletor. Desabilitado com o treino rodando (desligar o som o
/// encerraria).
Widget _phoneSoundButton(PhoneTitleBarHost h) => ValueListenableBuilder(
  valueListenable: h.midi.connected,
  builder: (context, device, _) {
    final noKeyboard =
        h.sound.output == SoundOutput.midiKeyboard && device == null;
    if (noKeyboard) {
      return PhoneSoundButton(
        key: h.tourKeys.sound,
        on: false,
        tooltip: 'Som no teclado: nenhum conectado',
        onPressed: () => unawaited(showMidiDevicePicker(context, h.midi)),
      );
    }
    return PhoneSoundButton(
      key: h.tourKeys.sound,
      on: h.sound.soundOn,
      loading: h.sound.loadingSoundFont,
      tooltip: h.sound.soundOn ? 'Som ligado' : 'Som desligado',
      onPressed: h.runner.practice != null
          ? null
          : () => unawaited(h.sound.userToggleSound()),
    );
  },
);

/// A trilha na barra do título do celular (U01): no lugar da faixa, que
/// cobria o topo da pauta. No treino livre com trilha, "Treino livre" e um
/// toque volta à trilha.
Widget? _trailChip(PhoneTitleBarHost h) {
  if (!h.hasPlayer) return null;
  final unavailable = h.runner.unavailable;
  if (unavailable != null && h.runner.trail == null) {
    return TrailTitleChip(text: unavailable);
  }
  final trail = h.runner.trail;
  if (trail == null) return null;
  if (trail.freeMode) {
    return TrailTitleChip(
      text: 'Treino livre',
      onTap: () => h.leaveFreeMode(trail),
    );
  }
  final stage = trail.selected;
  if (stage == null) return const TrailTitleChip(text: 'Fase final em breve');
  return TrailTitleChip(
    text: stage.isReinforcement
        ? stage.label
        : trailStripTextFor(
            trail.plan.segmentCount,
            stage.segment,
            stage.label,
          ),
    stateText: stage.isReinforcement
        ? ''
        : trailStateText(trail.progress, stage.id),
    onTap: h.openStageDrawer,
  );
}

/// O aviso de teclado desligado, na trilha (só o ícone, na barra estreita).
Widget _keyboardNotice(MidiDeviceManager midi) => ValueListenableBuilder(
  valueListenable: midi.connected,
  builder: (context, device, _) => device != null
      ? const SizedBox.shrink()
      : PhoneKeyboardNotice(
          // Barra estreita (celular em pé): só o ícone.
          compact:
              MediaQuery.sizeOf(context).width < kPhoneTitleBarCompactWidth,
          onTap: () => unawaited(showMidiDevicePicker(context, midi)),
        ),
);
