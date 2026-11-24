import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart';

/// Gaveta da trilha (J06): lista de etapas, pular, refazer e reiniciar.
/// Os retornos falam com o `runner.trail` corrente (não o da construção), pois
/// reiniciar troca o controlador com a gaveta aberta. [footer] é a legenda das
/// cores; [onClose] esconde a gaveta.
Widget buildTrailDrawer(
  TrailRunnerCubit runner, {
  required Widget footer,
  required VoidCallback onClose,
}) {
  final trail = runner.trail;
  if (trail == null) return const SizedBox.shrink();
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
