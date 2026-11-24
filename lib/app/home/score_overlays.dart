import 'package:flutter/material.dart';
import 'package:score_bridge/score_bridge.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_comum/practice/practice_colors.dart';
import 'package:zywny_comum/settings/settings_state.dart';
import 'package:zywny_comum/ui/practice_legend.dart';
import 'package:zywny_comum/ui/theme.dart';

/// A legenda das cores do treino, com as do aluno (U08): a da gaveta da
/// trilha e a do resumo.
Widget practiceLegendOf(SettingsState settings) => PracticeLegend(
  pending: settings.practicePendingColor,
  correct: settings.highlightColor,
  offBeat: kPracticeOffBeatColor,
  wrong: settings.practiceWrongColor,
  missed: kPracticeMissedColor,
);

/// Todos os compassos da música, para o véu dos que não são do trecho.
Iterable<String> allMeasureIds(ScorePlayer player) => {
  for (final m in player.measures) m.id,
};

/// O que a partitura pinta sobre cada compasso: os erros da última passagem,
/// o véu fora do trecho da etapa e o fundo azul do trecho.
Widget? measureOverlay(TrailRunnerCubit runner, String id, Rect rect) {
  // Erros da última passagem: um fundo vermelho leve sobre o compasso.
  if (runner.errorMeasureIds.contains(id)) {
    return IgnorePointer(
      child: ColoredBox(color: kBadColor.withValues(alpha: 0.12)),
    );
  }
  if (runner.markedIds().isEmpty) return null;
  if (!runner.isMarked(id)) {
    return IgnorePointer(
      child: ColoredBox(color: kSurface.withValues(alpha: 0.55)),
    );
  }
  if (runner.trail?.running ?? false) return null;
  // Compassos do trecho: fundo azul leve, sem barra na base.
  return IgnorePointer(
    child: ColoredBox(color: kAccent.withValues(alpha: 0.10)),
  );
}
