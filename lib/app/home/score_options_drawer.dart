import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/home/score_mode_cubit.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/practice/study_mode.dart';
import 'package:zywny_comum/settings/piece_settings.dart' show kTransposeNone;
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/trail_stage.dart' show kTrailMinMeasures;
import 'package:zywny_comum/trail/trail_widgets.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';
import 'package:zywny_comum/ui/theme.dart';
import 'package:zywny_comum/ui/transpose_widgets.dart';
import 'package:zywny_library/library_package.dart' show LibraryTerm;

/// A gaveta "⋯" do celular: modo, mão, andamento, a trilha, o trecho, a
/// partitura e as configurações gerais. Cada seção lê os Cubits de que
/// precisa; o que a tela faz (regravar, trocar de tom, o trecho em
/// repetição) vem por callback.
class ScoreOptionsDrawer extends StatelessWidget {
  const ScoreOptionsDrawer({
    super.key,
    required this.simplified,
    required this.fifths,
    required this.term,
    required this.chooseVersion,
    required this.confirmNewCut,
    required this.onStudyChanged,
    required this.onHandChanged,
    required this.onSpeedChanged,
    required this.onToggleTrailFree,
    required this.onChooseTranspose,
    required this.onPickTone,
    required this.onOpenLoopSheet,
    required this.onCommitLayout,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  /// A versão simplificada do hino (a outra versão troca por ela).
  final bool simplified;

  /// A armadura da música; `null` sem ela (não há transposição).
  final int? fifths;
  final LibraryTerm term;

  /// Troca entre as versões do hino; `null` se ele tem uma só.
  final void Function(bool)? chooseVersion;

  /// Pergunta antes de trocar o corte do hino (J06).
  final Future<bool> Function() confirmNewCut;
  final ValueChanged<StudyMode> onStudyChanged;
  final ValueChanged<Hand> onHandChanged;

  /// O andamento da partitura, de 0,5 a 1,5.
  final ValueChanged<double> onSpeedChanged;
  final VoidCallback onToggleTrailFree;
  final ValueChanged<String> onChooseTranspose;
  final VoidCallback onPickTone;
  final VoidCallback onOpenLoopSheet;
  final VoidCallback onCommitLayout;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ScoreModeCubit, ScoreModeState>(
        builder: (context, mode) => BlocBuilder<PlaybackCubit, PlaybackState>(
          builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
            builder: (context, _) => BlocBuilder<SettingsCubit, SettingsState>(
              builder: (context, _) => _shell(context, mode),
            ),
          ),
        ),
      );

  Widget _shell(BuildContext context, ScoreModeState mode) {
    final runner = context.read<TrailRunnerCubit>();
    final playback = context.read<PlaybackCubit>();
    final panels = context.read<HomePanelsCubit>();
    final practiceMode = context.read<SettingsCubit>().state.practiceMode;
    final trailActive = runner.trailMode;
    return PhoneOptionsDrawer(
      mode: StudyMode.of(training: mode.trainingMode, mode: practiceMode),
      onModeChanged: runner.practice != null ? null : onStudyChanged,
      trailMode: trailActive,
      hand: mode.hand,
      onHandChanged: onHandChanged,
      tempoPercent: (playback.speed * 100).round(),
      onTempoChanged: (v) => onSpeedChanged(v / 100),
      onClose: panels.closeOptions,
      // A trilha vem primeiro: na trilha a gaveta abre por ela, e no treino
      // livre "Voltar à trilha" fica no topo, à vista (U11).
      top: _top(context, trailActive),
      children: [
        // Na trilha a etapa manda no modo, no metrônomo e no trecho.
        if (!trailActive) _TrainingSection(onOpenLoopSheet: onOpenLoopSheet),
        _TranspositionSection(
          fifths: fifths,
          onChoose: onChooseTranspose,
          onPick: onPickTone,
        ),
        _CutSection(term: term, confirmNewCut: confirmNewCut),
        _ScoreSection(
          onCommitLayout: onCommitLayout,
          onPreviousPage: onPreviousPage,
          onNextPage: onNextPage,
        ),
        // O que vale para todos os hinos fica num painel só.
        const PhoneSectionLabel('GERAL'),
        PhoneActionRow(
          icon: Icons.settings_outlined,
          label: 'Configurações gerais',
          trailing: const Text(
            'som, MIDI, cores',
            style: TextStyle(fontSize: 13, color: kInkCaption),
          ),
          onTap: panels.openGeneral,
        ),
      ],
    );
  }

  /// O topo da gaveta: a versão (se o hino tem as duas) e a trilha.
  List<Widget> _top(BuildContext context, bool trailActive) {
    final runner = context.read<TrailRunnerCubit>();
    final panels = context.read<HomePanelsCubit>();
    return [
      if (chooseVersion case final choose?) ...[
        const PhoneSectionLabel('VERSÃO'),
        PhoneActionRow(
          icon: Icons.swap_horiz,
          label: simplified
              ? 'Simplificada — ver a completa'
              : 'Completa — ver a simplificada',
          onTap: () {
            panels.closeOptions();
            choose(!simplified);
          },
        ),
      ],
      if (runner.trail != null) ...[
        const PhoneSectionLabel('TRILHA'),
        PhoneActionRow(
          icon: trailActive ? Icons.school_outlined : Icons.route,
          label: trailActive ? 'Treino livre' : 'Voltar à trilha',
          onTap: onToggleTrailFree,
        ),
      ],
    ];
  }
}

/// O treino livre: o metrônomo e o trecho que se repete.
class _TrainingSection extends StatelessWidget {
  const _TrainingSection({required this.onOpenLoopSheet});

  final VoidCallback onOpenLoopSheet;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settings) => BlocBuilder<PlaybackCubit, PlaybackState>(
          builder: (context, _) {
            final playback = context.read<PlaybackCubit>();
            final loop = playback.loop;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const PhoneSectionLabel('TREINO'),
                PhoneToggleRow(
                  label: 'Metrônomo (com som)',
                  value: settings.metronomeOn,
                  onChanged: (_) => playback.toggleMetronome(),
                ),
                PhoneActionRow(
                  icon: Icons.repeat,
                  label: loop == null
                      ? 'Repetir um trecho'
                      : 'Trecho: compassos ${loop.a + 1}–${loop.b + 1} — mudar',
                  onTap: playback.player == null ? null : onOpenLoopSheet,
                ),
              ],
            );
          },
        ),
      );
}

/// A transposição do hino ("Transpor", Q08): sem acidentes, o tom escolhido
/// e "Escolher…". Sem armadura conhecida, não há seção.
class _TranspositionSection extends StatelessWidget {
  const _TranspositionSection({
    required this.fifths,
    required this.onChoose,
    required this.onPick,
  });

  final int? fifths;
  final ValueChanged<String> onChoose;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final armadura = fifths;
    if (armadura == null) return const SizedBox.shrink();
    return BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
      builder: (context, _) => BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) {
          final session = context.read<ScoreRenderCubit>();
          final current = session.transposition;
          final none = session.noAccidentals;
          return TransposeSection(
            fifths: armadura,
            mode: transposeModeOf(current, none),
            noAccidentals: none,
            currentTone: current,
            alsoStudied: context.read<TrailRunnerCubit>().alsoStudied,
            onNone: () => onChoose(kTransposeNone),
            onNoAccidentals: () {
              if (none != null) onChoose(none.interval);
            },
            onPick: onPick,
          );
        },
      ),
    );
  }
}

/// Os trechos deste hino: o padrão do geral ou um N escolhido.
class _CutSection extends StatelessWidget {
  const _CutSection({required this.term, required this.confirmNewCut});

  final LibraryTerm term;
  final Future<bool> Function() confirmNewCut;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) {
            final runner = context.read<TrailRunnerCubit>();
            final general = settings.trailMeasures;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PhoneSectionLabel('${term.este} ${term.singular}'.toUpperCase()),
                PhoneToggleRow(
                  label: 'Trechos de $general compassos (padrão)',
                  value: runner.pieceN == null,
                  onChanged: (v) => unawaited(
                    runner.setPieceN(
                      v ? null : general,
                      confirm: confirmNewCut,
                    ),
                  ),
                ),
                if (runner.pieceN case final pieceN?)
                  TrailNSelector(
                    value: pieceN,
                    max: _trailMaxN(runner),
                    onChanged: (v) => unawaited(
                      runner.setPieceN(v, confirm: confirmNewCut),
                    ),
                  ),
              ],
            );
          },
        ),
      );

  /// Maior N que o controle do hino oferece: 20, ou os compassos lógicos.
  int _trailMaxN(TrailRunnerCubit runner) {
    final measures = runner.trail?.path.measureCount ?? 20;
    if (measures < kTrailMinMeasures) return kTrailMinMeasures;
    return measures < 20 ? measures : 20;
  }
}

/// A partitura é a mesma para todos os hinos: o tamanho, o ajuste da página
/// e as páginas ficam juntos, fora da seção deste hino.
class _ScoreSection extends StatelessWidget {
  const _ScoreSection({
    required this.onCommitLayout,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  final VoidCallback onCommitLayout;
  final VoidCallback onPreviousPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ScoreRenderCubit, ScoreRenderState>(
        builder: (context, _) {
          final session = context.read<ScoreRenderCubit>();
          final panels = context.read<HomePanelsCubit>();
          final count = session.pageCount;
          final index = session.pageIndex;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PhoneSectionLabel('PARTITURA'),
              PhoneSliderRow(
                label: 'TAMANHO DA NOTAÇÃO',
                value: (session.layout['unit']! as num).toDouble(),
                min: 4.5,
                max: 12,
                divisions: 15,
                formatValue: (v) => v.toStringAsFixed(1),
                onChanged: (v) => session.setLayoutValue('unit', v),
                onChangeEnd: (_) => onCommitLayout(),
              ),
              PhoneActionRow(
                icon: Icons.tune,
                label: 'Ajustes da partitura (avançado)',
                onTap: panels.openLayout,
              ),
              PhoneActionRow(
                icon: Icons.chevron_left,
                label: 'Página anterior',
                onTap: index > 0 && !session.busy ? onPreviousPage : null,
                trailing: Text(
                  count == 0 ? '—' : '${index + 1} / $count',
                  style: const TextStyle(fontSize: 13, color: kInkCaption),
                ),
              ),
              PhoneActionRow(
                icon: Icons.chevron_right,
                label: 'Próxima página',
                onTap: index < count - 1 && !session.busy ? onNextPage : null,
              ),
            ],
          );
        },
      );
}
