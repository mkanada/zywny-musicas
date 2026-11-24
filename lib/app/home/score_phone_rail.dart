import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/home/score_mode_cubit.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny/tutorial/score_tour.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/trail_cubit.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';
import 'package:zywny_midi/midi_device_manager.dart';

/// Quantos compassos a música tem (`null` sem partitura).
int? scoreMeasureCountOf(PlaybackCubit playback) {
  final n = playback.player?.timeline.measureCount ?? 0;
  return n == 0 ? null : n;
}

/// O trilho do celular: o botão de tocar, o compasso, o andamento e as
/// opções. [index] é o compasso que o player está tocando. Lê os Cubits que
/// mostra; tocar a música e reiniciá-la são da tela ([onTogglePlay],
/// [onRestart]).
class ScorePhoneRail extends StatelessWidget {
  const ScorePhoneRail({
    super.key,
    required this.index,
    required this.tourKeys,
    required this.midi,
    required this.onTogglePlay,
    required this.onRestart,
    required this.onOpenMeasureJump,
  });

  final int index;
  final ScoreTourKeys tourKeys;
  final MidiDeviceManager midi;
  final VoidCallback onTogglePlay;
  final VoidCallback onRestart;
  final VoidCallback onOpenMeasureJump;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PlaybackCubit, PlaybackState>(
        builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
          builder: (context, _) =>
              BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
                builder: (context, _) =>
                    BlocBuilder<ScoreModeCubit, ScoreModeState>(
                      builder: (context, _) =>
                          BlocBuilder<SettingsCubit, SettingsState>(
                            builder: (context, _) => _rail(context),
                          ),
                    ),
              ),
        ),
      );

  Widget _rail(BuildContext context) {
    final playback = context.read<PlaybackCubit>();
    final runner = context.read<TrailRunnerCubit>();
    final panels = context.read<HomePanelsCubit>();
    final hand = context.read<ScoreModeCubit>().state.hand;
    final trail = runner.trailMode ? runner.trail : null;
    final keyboard = midi.connected.value != null;
    final measureCount = scoreMeasureCountOf(playback);
    return PhoneRail(
      tourKeys: tourKeys.rail,
      playing: playback.playing,
      onListen: trail != null && !trail.running
          ? () => unawaited(runner.listenStage())
          : null,
      listening: runner.listening,
      onPlayPause: _playAction(context, trail, keyboard),
      playTooltip: _playTooltip(context, trail, keyboard),
      playIcon: _playIcon(context, trail),
      onRestart: _canPlay(context) ? onRestart : null,
      measure: measureCount == null
          ? null
          : (trail?.path.numberOf(index) ?? index + 1),
      totalMeasures: trail != null && trail.path.measureCount > 0
          ? trail.path.measureCount
          : measureCount,
      onMeasureTap: measureCount == null ? null : onOpenMeasureJump,
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
      onStageTap: trail == null ? null : () => panels.openStageDrawer(),
      tempoPercent: (playback.speed * 100).round(),
      handLabel: hand.shortLabel,
      onOptions: () => panels.openOptions(),
    );
  }

  /// Dá para tocar: há partitura com compassos e nenhum render em curso.
  bool _canPlay(BuildContext context) {
    final session = context.read<ScoreRenderCubit>();
    return (session.document?.timemap?.isNotEmpty ?? false) && !session.busy;
  }

  /// Dá para treinar: [_canPlay], o modo treino armado e um teclado.
  bool _canTrain(BuildContext context) =>
      _canPlay(context) &&
      context.read<ScoreModeCubit>().state.trainingMode &&
      midi.connected.value != null;

  /// O que o botão de tocar faz: na trilha, começa a etapa (com teclado) ou
  /// ouve o trecho; no treino livre, pratica ou toca.
  VoidCallback? _playAction(
    BuildContext context,
    TrailCubit? trail,
    bool keyboard,
  ) {
    final runner = context.read<TrailRunnerCubit>();
    if (trail != null) {
      return keyboard
          ? () => unawaited(runner.startStage())
          : () => unawaited(runner.listenStage());
    }
    if (_canTrain(context)) {
      final hand = context.read<ScoreModeCubit>().state.hand;
      final mode = context.read<SettingsCubit>().state.practiceMode;
      return () => unawaited(runner.togglePractice(hand: hand, mode: mode));
    }
    return _canPlay(context) ? onTogglePlay : null;
  }

  /// O aviso do botão de tocar (ver [_playAction]).
  String? _playTooltip(
    BuildContext context,
    TrailCubit? trail,
    bool keyboard,
  ) {
    final runner = context.read<TrailRunnerCubit>();
    if (trail != null) {
      if (trail.running) return 'Parar etapa';
      if (keyboard) return 'Começar etapa';
      return runner.listening ? 'Parar de ouvir' : 'Ouvir o trecho';
    }
    if (!_canTrain(context)) return null;
    return runner.practice != null ? 'Pausar' : 'Praticar';
  }

  /// O ícone do botão de tocar (ver [_playAction]).
  Widget? _playIcon(BuildContext context, TrailCubit? trail) {
    final runner = context.read<TrailRunnerCubit>();
    if (trail != null) {
      if (trail.running) return null;
      return Icon(
        runner.listening ? Icons.stop : Icons.play_arrow,
        size: 24,
      );
    }
    return _canTrain(context) && runner.practice == null
        ? const Icon(Icons.play_arrow, size: 24)
        : null;
  }
}
