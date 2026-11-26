import 'package:flutter/material.dart';
import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_clock/zywny_clock.dart';
import 'package:zywny_comum/ui/theme.dart';

import 'measure_jump_cubit.dart';
import 'options_panel.dart';
import 'practice_cubit.dart';
import 'practice_state.dart';
import 'practice_wide.dart';

/// Tela de estudo, em paisagem — cobre os quatro artboards `Celular*` que
/// não são a biblioteca (`Estudo`, `Grande`, `Painel`, `Treino`): são o
/// mesmo layout em estados diferentes (modo, mão, tamanho, painel
/// aberto/fechado), não telas separadas.
class PracticeScreen extends StatelessWidget {
  const PracticeScreen({
    super.key,
    required this.clock,
    required this.args,
    this.startWithPanelOpen = false,
  });

  /// O relógio do app (CT05f), repassado ao cubit da tela.
  final AppClock clock;

  final PracticeArgs args;

  /// Abre a tela já com o painel de opções aberto — usado pela rota
  /// `/painel` (deep link de captura de tela, `lib/main_mockup.dart`) para
  /// reproduzir `CelularPainel.dc.html` diretamente.
  final bool startWithPanelOpen;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MockupPracticeCubit(
        clock: clock,
        args: args,
        startWithPanelOpen: startWithPanelOpen,
      )..iniciar(),
      child: const _PracticeView(),
    );
  }
}

/// A tela: tudo o que aparece vem do [MockupPracticeCubit] acima dela.
class _PracticeView extends StatelessWidget {
  const _PracticeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      body: SafeArea(
        child: BlocBuilder<MockupPracticeCubit, MockupPracticeState>(
          builder: (context, state) => LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= kWidePracticeBreakpoint;
              return Stack(
                children: [
                  wide
                      ? _wideLayout(context, state)
                      : Row(
                          children: [
                            Expanded(child: _scoreArea(context, state)),
                            _sideRail(context, state),
                          ],
                        ),
                  if (state.panelOpen) _panelOverlay(context, state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Layout largo (tablet/desktop) — `Main.dc.html` / `Treino.dc.html` /
  /// `TabletEstudo.dc.html`: barra de topo com título, faixa de status do
  /// treino (só fora do modo Ouvir) e barra de transporte com tudo à
  /// vista, em vez da barra lateral + painel escondido do celular.
  Widget _wideLayout(BuildContext context, MockupPracticeState state) {
    final cubit = context.read<MockupPracticeCubit>();
    final setup = state.setup;
    return Column(
      children: [
        WideTopBar(
          title: cubit.args.title,
          composer: cubit.args.composer,
          midiConnected: true,
          onBack: () => Navigator.of(context).pop(),
          onSettings: () => cubit.definirPainel(true),
        ),
        if (state.praticando)
          WideStatusBar(
            mode: setup.mode,
            hand: setup.hand,
            correct: state.counts.correct,
            reminders: state.counts.reminders,
            mistakes: state.counts.mistakes,
          ),
        Expanded(child: _wideScoreArea(setup.size)),
        WideTransportBar(
          playing: state.playing,
          onPlayPause: cubit.alternarTocar,
          onStop: cubit.parar,
          measure: state.measure,
          totalMeasures: cubit.args.totalMeasures,
          onMeasureTap: () => _abrirIrParaCompasso(context),
          tempoPercent: setup.tempoPercent,
          onTempoStep: cubit.mudarAndamento,
          hand: setup.hand,
          onHandChanged: cubit.escolherMao,
          mode: setup.mode,
          onModeChanged: cubit.mudarModo,
          repeatAB: setup.repeatAB,
          onRepeatABChanged: cubit.definirRepeticaoAB,
          metronome: setup.metronome,
          onMetronomeChanged: cubit.definirMetronomo,
        ),
      ],
    );
  }

  Widget _wideScoreArea(ScoreSize tamanho) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 56),
              child: Image.asset(_partituraDe(tamanho), fit: BoxFit.contain),
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: WidePageArrow(
              icon: Icons.chevron_left,
              label: 'Página anterior',
            ),
          ),
        ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Center(
            child: WidePageArrow(
              icon: Icons.chevron_right,
              label: 'Próxima página',
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreArea(BuildContext context, MockupPracticeState state) {
    return Stack(
      children: [
        Positioned.fill(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Image.asset(
                _partituraDe(state.setup.size),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10,
          top: 4,
          child: IconButton(
            tooltip: 'Voltar à biblioteca',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left, size: 28, color: kInkCaption),
          ),
        ),
        if (state.praticando)
          Positioned(
            left: 54,
            right: 12,
            top: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusPill(
                  text:
                      '${state.setup.mode.statusVerb} · mão ${state.setup.hand.shortLabel.toLowerCase()}',
                ),
                _CountersPill(
                  correct: state.counts.correct,
                  reminders: state.counts.reminders,
                  mistakes: state.counts.mistakes,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _sideRail(BuildContext context, MockupPracticeState state) {
    final cubit = context.read<MockupPracticeCubit>();
    final setup = state.setup;
    return Container(
      width: 84,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        color: kPanelSideBg,
        border: Border(left: BorderSide(color: kBorderPanel)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filled(
            tooltip: state.playing ? 'Pausar' : 'Tocar',
            onPressed: cubit.alternarTocar,
            style: IconButton.styleFrom(
              backgroundColor: kAccent,
              minimumSize: const Size(52, 52),
            ),
            icon: Icon(state.playing ? Icons.pause : Icons.play_arrow),
          ),
          _RailButton(
            top: '${state.measure}',
            bottom: 'de ${cubit.args.totalMeasures}',
            tooltip: 'Ir para compasso',
            onTap: () => _abrirIrParaCompasso(context),
          ),
          _RailButton(
            top: '${setup.tempoPercent}%',
            bottom: 'andamento',
            tooltip: 'Andamento',
            onTap: () => cubit.definirPainel(true),
          ),
          _RailButton(
            top: setup.hand.shortLabel,
            bottom: 'mão',
            tooltip: 'Mão',
            onTap: () => cubit.definirPainel(true),
          ),
          IconButton(
            tooltip: 'Mais opções',
            onPressed: () => cubit.definirPainel(true),
            icon: const Icon(Icons.more_horiz, color: kInkCaption),
          ),
        ],
      ),
    );
  }

  Widget _panelOverlay(BuildContext context, MockupPracticeState state) {
    final cubit = context.read<MockupPracticeCubit>();
    final setup = state.setup;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () => cubit.definirPainel(false),
            child: Container(color: kScrim),
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          width: 340,
          child: OptionsPanel(
            mode: setup.mode,
            onModeChanged: cubit.mudarModo,
            hand: setup.hand,
            onHandChanged: cubit.escolherMao,
            size: setup.size,
            onSizeChanged: cubit.escolherTamanho,
            tempoPercent: setup.tempoPercent,
            onTempoChanged: cubit.definirAndamento,
            repeatAB: setup.repeatAB,
            onRepeatABChanged: cubit.definirRepeticaoAB,
            metronome: setup.metronome,
            onMetronomeChanged: cubit.definirMetronomo,
            onClose: () => cubit.definirPainel(false),
          ),
        ),
      ],
    );
  }

  /// A folha "Ir para o compasso": o slider escolhe, "Ir" confirma. Fechá-la
  /// sem "Ir" não muda o compasso.
  Future<void> _abrirIrParaCompasso(BuildContext context) async {
    final cubit = context.read<MockupPracticeCubit>();
    final compasso = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: kSurface,
      builder: (_) => _FolhaIrParaCompasso(
        inicial: cubit.state.measure,
        total: cubit.args.totalMeasures,
      ),
    );
    if (compasso != null && context.mounted) cubit.irParaCompasso(compasso);
  }
}

/// A folha do slider de compasso: o alvo vive num [MeasureJumpCubit] só dela.
class _FolhaIrParaCompasso extends StatelessWidget {
  const _FolhaIrParaCompasso({required this.inicial, required this.total});

  final int inicial;
  final int total;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MeasureJumpCubit(inicial),
      child: BlocBuilder<MeasureJumpCubit, MeasureJumpState>(
        builder: (context, state) {
          final alvo = state.target;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Ir para o compasso $alvo de $total',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider(
                    value: alvo.toDouble(),
                    min: 1,
                    max: total.toDouble(),
                    divisions: total - 1,
                    onChanged: (v) =>
                        context.read<MeasureJumpCubit>().escolher(v.round()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, alvo),
                    child: const Text('Ir'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A partitura pré-renderizada do tamanho escolhido (`assets/`).
String _partituraDe(ScoreSize tamanho) => tamanho == ScoreSize.grande
    ? 'assets/partitura_grande.png'
    : 'assets/partitura_padrao.png';

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.top,
    required this.bottom,
    required this.tooltip,
    required this.onTap,
  });

  final String top;
  final String bottom;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 64,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                top,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  color: kInk,
                ),
              ),
              Text(
                bottom,
                style: const TextStyle(fontSize: 10.5, color: kInkCaption),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kAccentSoftBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: kAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: kAccentDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _CountersPill extends StatelessWidget {
  const _CountersPill({
    required this.correct,
    required this.reminders,
    required this.mistakes,
  });

  final int correct;
  final int reminders;
  final int mistakes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kLibraryCardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(color: kGoodColor, count: correct),
          const SizedBox(width: 12),
          _Dot(color: kOkColor, count: reminders),
          const SizedBox(width: 12),
          Text(
            '×',
            style: TextStyle(
              color: kBadColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$mistakes',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.count});

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ],
    );
  }
}
