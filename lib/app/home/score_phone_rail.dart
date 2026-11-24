import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny/tutorial/score_tour.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/practice/practice_controller.dart';
import 'package:zywny_comum/trail/trail_cubit.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';

/// O que o trilho do celular usa da tela, no build em que é montado.
typedef PhoneRailHost = ({
  PlaybackCubit playback,
  TrailRunnerCubit runner,
  ScoreTourKeys tourKeys,
  bool keyboard,
  bool canPlay,
  bool canTrain,
  int? measureCount,
  Hand hand,
  PracticeMode practiceMode,
  VoidCallback togglePlay,
  VoidCallback restart,
  VoidCallback openMeasureJump,
  VoidCallback openStageDrawer,
  VoidCallback openOptions,
});

/// O trilho do celular: o botão de tocar, o compasso, o andamento e as
/// opções. [index] é o compasso que o player está tocando.
PhoneRail buildPhoneRail(PhoneRailHost h, int index) {
  final trail = h.runner.trailMode ? h.runner.trail : null;
  final keyboard = h.keyboard;
  return PhoneRail(
    tourKeys: h.tourKeys.rail,
    playing: h.playback.playing,
    onListen: trail != null && !trail.running
        ? () => unawaited(h.runner.listenStage())
        : null,
    listening: h.runner.listening,
    onPlayPause: _railPlayAction(h, trail, keyboard),
    playTooltip: _railPlayTooltip(h, trail, keyboard),
    playIcon: _railPlayIcon(h, trail),
    onRestart: h.canPlay ? h.restart : null,
    measure: h.measureCount == null
        ? null
        : (trail?.path.numberOf(index) ?? index + 1),
    totalMeasures: trail != null && trail.path.measureCount > 0
        ? trail.path.measureCount
        : h.measureCount,
    onMeasureTap: h.measureCount == null ? null : h.openMeasureJump,
    stageTempo: trail == null
        ? null
        : switch (trail.selected?.speed) {
            final speed? => '${(speed * 100).round()}%',
            null => 'livre',
          },
    stageTempoCaption: trail?.selected?.speed == null
        ? 'sem tempo'
        : 'da etapa',
    stageHand: trail?.selected?.phase.hand.shortLabel,
    onStageTap: trail == null ? null : h.openStageDrawer,
    tempoPercent: (h.playback.speed * 100).round(),
    handLabel: h.hand.shortLabel,
    onOptions: h.openOptions,
  );
}

/// O que o botão de tocar faz: na trilha, começa a etapa (com teclado) ou
/// ouve o trecho; no treino livre, pratica ou toca.
VoidCallback? _railPlayAction(
  PhoneRailHost h,
  TrailCubit? trail,
  bool keyboard,
) {
  if (trail != null) {
    return keyboard
        ? () => unawaited(h.runner.startStage())
        : () => unawaited(h.runner.listenStage());
  }
  if (h.canTrain) {
    return () =>
        unawaited(h.runner.togglePractice(hand: h.hand, mode: h.practiceMode));
  }
  return h.canPlay ? h.togglePlay : null;
}

/// O aviso do botão de tocar (ver `_railPlayAction`).
String? _railPlayTooltip(PhoneRailHost h, TrailCubit? trail, bool keyboard) {
  if (trail != null) {
    if (trail.running) return 'Parar etapa';
    if (keyboard) return 'Começar etapa';
    return h.runner.listening ? 'Parar de ouvir' : 'Ouvir o trecho';
  }
  if (!h.canTrain) return null;
  return h.runner.practice != null ? 'Pausar' : 'Praticar';
}

/// O ícone do botão de tocar (ver `_railPlayAction`).
Widget? _railPlayIcon(PhoneRailHost h, TrailCubit? trail) {
  if (trail != null) {
    if (trail.running) return null;
    return Icon(h.runner.listening ? Icons.stop : Icons.play_arrow, size: 24);
  }
  return h.canTrain && h.runner.practice == null
      ? const Icon(Icons.play_arrow, size: 24)
      : null;
}
