import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/home/score_overlays.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart';

/// Gaveta da trilha (J06): lista de etapas, pular, refazer e reiniciar. Lê a
/// trilha do [TrailRunnerCubit] a cada build e fala com o `runner.trail`
/// corrente (não o da abertura), pois reiniciar troca o controlador com a
/// gaveta aberta. A legenda das cores vem das configurações.
class ScoreTrailDrawer extends StatelessWidget {
  const ScoreTrailDrawer({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<TrailRunnerCubit, TrailRunnerState>(
        builder: (context, _) => BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, settings) => _drawer(
            context,
            practiceLegendOf(settings),
          ),
        ),
      );

  Widget _drawer(BuildContext context, Widget footer) {
    final runner = context.read<TrailRunnerCubit>();
    final trail = runner.trail;
    if (trail == null) return const SizedBox.shrink();
    final panels = context.read<HomePanelsCubit>();
    void onClose() => panels.closeTrailDrawer();
    return TrailDrawer(
      plan: trail.plan,
      progress: trail.progress,
      selectedId: trail.selected?.id,
      currentId: trail.progress.current(trail.plan)?.id,
      blocks: trail.blockViews,
      footer: footer,
      alsoStudied: runner.alsoStudied,
      onClose: onClose,
      onSelectStage: (id) {
        // Etapa rodando: escolher outra encerra a que roda (sem registro),
        // senão a faixa mostraria a nova com o treino ainda na antiga.
        if (runner.trail?.running ?? false) runner.abandonStage();
        runner.trail?.select(id);
        onClose();
      },
      onRepeatStage: trail.running
          ? null
          : (id) {
              runner.trail?.select(id);
              onClose();
              unawaited(runner.startStage());
            },
      onSkipCurrent: () async {
        final current = runner.trail;
        if (current == null) return;
        if (current.running) runner.abandonStage();
        await current.skipSelected();
        current.next();
      },
      onRestartTrail: runner.restartTrail,
    );
  }
}
