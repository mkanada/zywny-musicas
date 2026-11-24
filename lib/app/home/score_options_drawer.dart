import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zywny/app/playback_cubit.dart';
import 'package:zywny/app/score_render_cubit.dart';
import 'package:zywny/app/trail_runner_cubit.dart';
import 'package:zywny_comum/practice/hand.dart';
import 'package:zywny_comum/practice/study_mode.dart';
import 'package:zywny_comum/settings/settings_cubit.dart';
import 'package:zywny_comum/trail/trail_widgets.dart';
import 'package:zywny_comum/ui/phone_chrome.dart';
import 'package:zywny_comum/ui/theme.dart';
import 'package:zywny_library/library_package.dart' show LibraryTerm;

/// O que a gaveta "⋯" do celular usa da tela, no build em que é montada. Os
/// `setState` ficam no State: a gaveta só chama o que ele dá.
typedef OptionsDrawerHost = ({
  StudyMode mode,
  ValueChanged<StudyMode>? onModeChanged,
  Hand hand,
  ValueChanged<Hand> onHandChanged,
  int tempoPercent,
  ValueChanged<int> onTempoChanged,
  VoidCallback closeOptions,
  VoidCallback toggleTrailFree,
  void Function(bool)? chooseVersion,
  bool simplified,
  Widget? transposeSection,
  VoidCallback openLoopSheet,
  LibraryTerm term,
  int trailMaxN,
  Future<bool> Function() confirmNewCut,
  ScoreRenderCubit session,
  VoidCallback commitLayout,
  VoidCallback previousPage,
  VoidCallback nextPage,
  VoidCallback openLayoutPanel,
  VoidCallback openGeneral,
  SettingsCubit settings,
  PlaybackCubit playback,
  TrailRunnerCubit runner,
});

/// A gaveta "⋯" do celular: modo, mão, andamento, a trilha, o trecho, a
/// partitura e as configurações gerais.
Widget buildOptionsDrawer(OptionsDrawerHost h) {
  final trailActive = h.runner.trailMode;
  return PhoneOptionsDrawer(
    mode: h.mode,
    onModeChanged: h.onModeChanged,
    trailMode: trailActive,
    hand: h.hand,
    onHandChanged: h.onHandChanged,
    tempoPercent: h.tempoPercent,
    onTempoChanged: h.onTempoChanged,
    onClose: h.closeOptions,
    // A trilha vem primeiro: na trilha a gaveta abre por ela, e no treino
    // livre "Voltar à trilha" fica no topo, à vista (U11).
    top: _drawerTop(h, trailActive),
    children: [
      // Na trilha a etapa manda no modo, no metrônomo e no trecho.
      if (!trailActive) ..._drawerTraining(h),
      ?h.transposeSection,
      ..._drawerCut(h),
      ..._drawerScore(h),
      // O que vale para todos os hinos fica num painel só.
      const PhoneSectionLabel('GERAL'),
      PhoneActionRow(
        icon: Icons.settings_outlined,
        label: 'Configurações gerais',
        trailing: const Text(
          'som, MIDI, cores',
          style: TextStyle(fontSize: 13, color: kInkCaption),
        ),
        onTap: h.openGeneral,
      ),
    ],
  );
}

/// O topo da gaveta: a versão (se o hino tem as duas) e a trilha.
List<Widget> _drawerTop(OptionsDrawerHost h, bool trailActive) => [
  if (h.chooseVersion case final choose?) ...[
    const PhoneSectionLabel('VERSÃO'),
    PhoneActionRow(
      icon: Icons.swap_horiz,
      label: h.simplified
          ? 'Simplificada — ver a completa'
          : 'Completa — ver a simplificada',
      onTap: () {
        h.closeOptions();
        choose(!h.simplified);
      },
    ),
  ],
  if (h.runner.trail != null) ...[
    const PhoneSectionLabel('TRILHA'),
    PhoneActionRow(
      icon: trailActive ? Icons.school_outlined : Icons.route,
      label: trailActive ? 'Treino livre' : 'Voltar à trilha',
      onTap: h.toggleTrailFree,
    ),
  ],
];

/// O treino livre: o metrônomo, o trecho que se repete e o andamento.
List<Widget> _drawerTraining(OptionsDrawerHost h) => [
  const PhoneSectionLabel('TREINO'),
  PhoneToggleRow(
    label: 'Metrônomo (com som)',
    value: h.settings.state.metronomeOn,
    onChanged: (_) => h.playback.toggleMetronome(),
  ),
  PhoneActionRow(
    icon: Icons.repeat,
    label: h.playback.loop == null
        ? 'Repetir um trecho'
        : 'Trecho: compassos ${h.playback.loop!.a + 1}–${h.playback.loop!.b + 1} — mudar',
    onTap: h.playback.player == null ? null : h.openLoopSheet,
  ),
];

/// Os trechos deste hino: o padrão do geral ou um N escolhido.
List<Widget> _drawerCut(OptionsDrawerHost h) => [
  PhoneSectionLabel('${h.term.este} ${h.term.singular}'.toUpperCase()),
  PhoneToggleRow(
    label: 'Trechos de ${h.settings.state.trailMeasures} compassos (padrão)',
    value: h.runner.pieceN == null,
    onChanged: (v) => unawaited(
      h.runner.setPieceN(
        v ? null : h.settings.state.trailMeasures,
        confirm: h.confirmNewCut,
      ),
    ),
  ),
  if (h.runner.pieceN case final pieceN?)
    TrailNSelector(
      value: pieceN,
      max: h.trailMaxN,
      onChanged: (v) =>
          unawaited(h.runner.setPieceN(v, confirm: h.confirmNewCut)),
    ),
];

/// A partitura é a mesma para todos os hinos: o tamanho, o ajuste da página
/// e as páginas ficam juntos, fora da seção deste hino.
List<Widget> _drawerScore(OptionsDrawerHost h) => [
  const PhoneSectionLabel('PARTITURA'),
  PhoneSliderRow(
    label: 'TAMANHO DA NOTAÇÃO',
    value: (h.session.layout['unit']! as num).toDouble(),
    min: 4.5,
    max: 12,
    divisions: 15,
    formatValue: (v) => v.toStringAsFixed(1),
    onChanged: (v) => h.session.setLayoutValue('unit', v),
    onChangeEnd: (_) => h.commitLayout(),
  ),
  PhoneActionRow(
    icon: Icons.tune,
    label: 'Ajustes da partitura (avançado)',
    onTap: h.openLayoutPanel,
  ),
  PhoneActionRow(
    icon: Icons.chevron_left,
    label: 'Página anterior',
    onTap: h.session.pageIndex > 0 && !h.session.busy ? h.previousPage : null,
    trailing: Text(
      h.session.pageCount == 0
          ? '—'
          : '${h.session.pageIndex + 1} / ${h.session.pageCount}',
      style: const TextStyle(fontSize: 13, color: kInkCaption),
    ),
  ),
  PhoneActionRow(
    icon: Icons.chevron_right,
    label: 'Próxima página',
    onTap: h.session.pageIndex < h.session.pageCount - 1 && !h.session.busy
        ? h.nextPage
        : null,
  ),
];
