import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';
import 'package:zywny/app/home/score_mode_cubit.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/sound_output_controller.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny/tutorial/score_tour.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/midi/midi_device_picker.dart';
import 'package:zywny_comum/practice/practice_controller.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/stage_result.dart' show kTrailPassAccuracy;
import 'package:zywny_comum/trail/trail_widgets.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';
import 'package:zywny_comum/ui/transpose_widgets.dart';
import 'package:zywny_library/piece.dart';
import 'package:zywny_midi/midi_device_manager.dart';
import 'package:zywny_music/tone_choices.dart';

/// A barra do título do celular: voltar, número e título do hino e, no
/// treino, os selos de modo/mão e de acertos e erros. Lê da tela os Cubits
/// que mostra; o que a tela faz (voltar, o selo, a conferência do teclado)
/// vem por callback.
class ScorePhoneTitleBar extends StatelessWidget {
  const ScorePhoneTitleBar({
    super.key,
    required this.piece,
    required this.tourKeys,
    required this.midi,
    required this.onBack,
    required this.onSealTap,
  });

  final Piece piece;
  final ScoreTourKeys tourKeys;
  final MidiDeviceManager midi;
  final VoidCallback onBack;

  /// Tocar no selo de transposição (a conferência do TRANSPOSE, Q06).
  final VoidCallback onSealTap;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => BlocBuilder<PlaybackCubit, PlaybackState>(
          builder: (context, _) {
            final runner = context.read<TrailRunnerCubit>();
            final hasPlayer = context.read<PlaybackCubit>().player != null;
            return PhoneTitleBar(
              number: piece.number,
              title: piece.title,
              onBack: onBack,
              backKey: tourKeys.back,
              center: _center(context, runner, hasPlayer),
              trailing: [
                _ScoreTitleTrailing(
                  piece: piece,
                  tourKeys: tourKeys,
                  midi: midi,
                  onSealTap: onSealTap,
                ),
              ],
            );
          },
        ),
      );

  /// A trilha na barra do título (U01): no lugar da faixa, que cobria o topo
  /// da pauta. Só o chip de uma etapa é o alvo do tutorial.
  Widget? _center(
    BuildContext context,
    TrailRunnerCubit runner,
    bool hasPlayer,
  ) {
    final chip = _trailChip(context, runner, hasPlayer);
    if (chip == null) return null;
    return KeyedSubtree(
      key: runner.trailMode ? tourKeys.trail : null,
      child: chip,
    );
  }
}

/// Os selos à direita da barra. Cada um traz o seu espaço à esquerda, como
/// os selos de antes (`PhoneTitleBar` põe um espaço antes do primeiro): um
/// selo ausente não ocupa lugar.
class _ScoreTitleTrailing extends StatelessWidget {
  const _ScoreTitleTrailing({
    required this.piece,
    required this.tourKeys,
    required this.midi,
    required this.onSealTap,
  });

  final Piece piece;
  final ScoreTourKeys tourKeys;
  final MidiDeviceManager midi;
  final VoidCallback onSealTap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _SoundButtonSlot(tourKeys: tourKeys, midi: midi),
      _TransposeSealSlot(piece: piece, onTap: onSealTap),
      _KeyboardNoticeSlot(midi: midi),
      _TrainingPillSlot(midi: midi),
      const _PracticeScoreSlot(),
    ],
  );
}

/// Alto-falante da barra do título (U04): mostra o som de agora; o toque
/// muda também a preferência. Saída no teclado MIDI sem teclado: explica e
/// leva ao seletor. Desabilitado com o treino rodando (desligar o som o
/// encerraria).
class _SoundButtonSlot extends StatelessWidget {
  const _SoundButtonSlot({required this.tourKeys, required this.midi});

  final ScoreTourKeys tourKeys;
  final MidiDeviceManager midi;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<SoundOutputCubit, SoundOutputState>(
    builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
      builder: (context, _) => BlocBuilder<MidiDeviceManager, MidiDeviceState>(
        bloc: midi,
        builder: (context, midiState) {
          final device = midiState.connected;
          final sound = context.read<SoundOutputCubit>();
          final practicing = context.read<TrailRunnerCubit>().practice;
          final noKeyboard =
              sound.output == SoundOutput.midiKeyboard && device == null;
          if (noKeyboard) {
            return PhoneSoundButton(
              key: tourKeys.sound,
              on: false,
              tooltip: 'Som no teclado: nenhum conectado',
              onPressed: () => unawaited(showMidiDevicePicker(context, midi)),
            );
          }
          return PhoneSoundButton(
            key: tourKeys.sound,
            on: sound.soundOn,
            loading: sound.loadingSoundFont,
            tooltip: sound.soundOn ? 'Som ligado' : 'Som desligado',
            onPressed: practicing != null
                ? null
                : () => unawaited(sound.userToggleSound()),
          );
        },
      ),
    ),
  );
}

/// O selo da partitura transposta: "Mi♭ → Dó · teclado +3". Mostra o tom da
/// gravura na tela. Sem transposição, não ocupa lugar.
class _TransposeSealSlot extends StatelessWidget {
  const _TransposeSealSlot({required this.piece, required this.onTap});

  final Piece piece;
  final VoidCallback onTap;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
    builder: (context, _) => BlocBuilder<SoundOutputCubit, SoundOutputState>(
      builder: (context, _) => BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) {
          final transposition = context
              .read<ScoreRenderCubit>()
              .renderedTransposition;
          if (transposition == null) return const SizedBox.shrink();
          final fifths = piece.fifths;
          final text = fifths == null
              ? 'Transposta · teclado ${transposition.keyboardLabel}'
              : transposeSealText(
                  fifths,
                  transposition,
                  appIsSound: context.read<SoundOutputCubit>().midiMonitorOn,
                  naming: settings.noteNaming,
                );
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TransposeSeal(text: text, onTap: onTap),
          );
        },
      ),
    ),
  );
}

/// O aviso de teclado desligado, na trilha (só o ícone, na barra estreita).
class _KeyboardNoticeSlot extends StatelessWidget {
  const _KeyboardNoticeSlot({required this.midi});

  final MidiDeviceManager midi;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) {
          if (!context.read<TrailRunnerCubit>().trailMode) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: BlocBuilder<MidiDeviceManager, MidiDeviceState>(
              bloc: midi,
              builder: (context, midiState) => midiState.connected != null
                  ? const SizedBox.shrink()
                  : PhoneKeyboardNotice(
                      // Barra estreita (celular em pé): só o ícone.
                      compact:
                          MediaQuery.sizeOf(context).width <
                          kPhoneTitleBarCompactWidth,
                      onTap: () =>
                          unawaited(showMidiDevicePicker(context, midi)),
                    ),
            ),
          );
        },
      );
}

/// O selo de modo e mão, no treino armado.
class _TrainingPillSlot extends StatelessWidget {
  const _TrainingPillSlot({required this.midi});

  final MidiDeviceManager midi;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ScoreModeCubit, ScoreModeState>(
        builder: (context, mode) => BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) =>
              BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
                builder: (context, _) {
                  if (!mode.trainingMode) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: PhoneStatusPill(
                      text: trainingPillTextOf(
                        hand: mode.hand,
                        realtime:
                            settings.practiceMode == PracticeMode.realtime,
                        practicing:
                            context.read<TrailRunnerCubit>().practice != null,
                        keyboard: midi.state.connected != null,
                      ),
                    ),
                  );
                },
              ),
        ),
      );
}

/// O placar do treino em curso: os dois contadores (espera livre) ou a
/// porcentagem do resumo, com a meta na trilha (U05).
class _PracticeScoreSlot extends StatelessWidget {
  const _PracticeScoreSlot();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) {
          final practice = context.read<TrailRunnerCubit>().practice;
          if (practice == null) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: practice.mode == PracticeMode.wait && practice.range == null
                // Modo espera livre não tem resultado: os dois contadores.
                ? BlocSelector<
                    PracticeCubit,
                    PracticeState,
                    ({int correct, int wrong})
                  >(
                    bloc: practice,
                    selector: (s) =>
                        (correct: s.correctCount, wrong: s.wrongCount),
                    builder: (context, c) => PhoneCountersPill(
                      correct: c.correct,
                      mistakes: c.wrong,
                    ),
                  )
                // Com resultado (trilha ou tempo real livre): a porcentagem
                // do resumo, com a meta na trilha.
                : BlocSelector<
                    PracticeCubit,
                    PracticeState,
                    ({int hits, int total})
                  >(
                    bloc: practice,
                    selector: (s) => s.liveScore,
                    builder: (context, score) => PhoneScorePill(
                      hits: score.hits,
                      total: score.total,
                      goalPercent: practice.range != null
                          ? (kTrailPassAccuracy * 100).round()
                          : null,
                    ),
                  ),
          );
        },
      );
}

/// O texto do selo de modo: "Tempo real · mão d", "Espera · mão e"; sem
/// teclado, a instrução de conectar; no treino em curso, o que ele faz.
String trainingPillTextOf({
  required Hand hand,
  required bool realtime,
  required bool practicing,
  required bool keyboard,
}) {
  final handText = hand.shortLabel.toLowerCase();
  if (practicing) {
    return realtime
        ? 'Tempo real · mão $handText'
        : 'Esperando · mão $handText';
  }
  if (!keyboard) return 'Conecte o teclado MIDI';
  return realtime ? 'Tempo real · mão $handText' : 'Espera · mão $handText';
}

/// A trilha no lugar do título: o chip da etapa, "Treino livre" (com um toque
/// que volta à trilha) ou o aviso de trilha indisponível.
Widget? _trailChip(
  BuildContext context,
  TrailRunnerCubit runner,
  bool hasPlayer,
) {
  if (!hasPlayer) return null;
  final unavailable = runner.unavailable;
  if (unavailable != null && runner.trail == null) {
    return TrailTitleChip(text: unavailable);
  }
  final trail = runner.trail;
  if (trail == null) return null;
  if (trail.freeMode) {
    return TrailTitleChip(
      text: 'Treino livre',
      onTap: () => trail.setFreeMode(false),
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
    onTap: () => context.read<HomePanelsCubit>().openStageDrawer(),
  );
}
