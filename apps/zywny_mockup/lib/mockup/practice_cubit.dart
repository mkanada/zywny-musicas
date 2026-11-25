// Estado da tela de estudo do mockup (`PracticeScreen`): o que o aluno escolhe
// no painel, o que a tela mostra (tocando, painel aberto, compasso) e o placar.
// O "ao vivo" de enfeite (o relógio que anda o compasso e soma acertos) é um
// Timer daqui, parado no close.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zywny_bloc/zywny_bloc.dart';

import 'practice_state.dart';

/// O que o aluno escolhe no treino: modo, mão, andamento, repetição A–B,
/// metrônomo e tamanho da partitura.
class PracticeSetup extends Equatable {
  const PracticeSetup({
    required this.mode,
    required this.hand,
    required this.tempoPercent,
    this.repeatAB = false,
    this.metronome = true,
    this.size = ScoreSize.padrao,
  });

  final PracticeMode mode;
  final Hand hand;
  final int tempoPercent;
  final bool repeatAB;
  final bool metronome;
  final ScoreSize size;

  PracticeSetup copyWith({
    PracticeMode? mode,
    Hand? hand,
    int? tempoPercent,
    bool? repeatAB,
    bool? metronome,
    ScoreSize? size,
  }) => PracticeSetup(
    mode: mode ?? this.mode,
    hand: hand ?? this.hand,
    tempoPercent: tempoPercent ?? this.tempoPercent,
    repeatAB: repeatAB ?? this.repeatAB,
    metronome: metronome ?? this.metronome,
    size: size ?? this.size,
  );

  @override
  List<Object?> get props => [
    mode,
    hand,
    tempoPercent,
    repeatAB,
    metronome,
    size,
  ];
}

/// O placar do treino: acertos, lembretes e erros.
class PracticeCounts extends Equatable {
  const PracticeCounts({
    this.correct = 0,
    this.reminders = 0,
    this.mistakes = 0,
  });

  final int correct;
  final int reminders;
  final int mistakes;

  PracticeCounts copyWith({int? correct, int? reminders, int? mistakes}) =>
      PracticeCounts(
        correct: correct ?? this.correct,
        reminders: reminders ?? this.reminders,
        mistakes: mistakes ?? this.mistakes,
      );

  @override
  List<Object?> get props => [correct, reminders, mistakes];
}

/// Tudo o que a tela de estudo mostra. As escolhas ficam em [setup]; o resto
/// (tocando, painel, compasso e placar) fica aqui.
class MockupPracticeState extends Equatable {
  const MockupPracticeState({
    required this.setup,
    required this.measure,
    this.playing = false,
    this.panelOpen = false,
    this.counts = const PracticeCounts(),
  });

  final PracticeSetup setup;
  final int measure;
  final bool playing;
  final bool panelOpen;
  final PracticeCounts counts;

  /// Fora do modo Ouvir o treino tem status, placar e "Tocar" de verdade.
  bool get praticando => setup.mode != PracticeMode.ouvir;

  MockupPracticeState copyWith({
    PracticeSetup? setup,
    int? measure,
    bool? playing,
    bool? panelOpen,
    PracticeCounts? counts,
  }) => MockupPracticeState(
    setup: setup ?? this.setup,
    measure: measure ?? this.measure,
    playing: playing ?? this.playing,
    panelOpen: panelOpen ?? this.panelOpen,
    counts: counts ?? this.counts,
  );

  @override
  List<Object?> get props => [setup, measure, playing, panelOpen, counts];
}

const _paisagem = [
  DeviceOrientation.landscapeLeft,
  DeviceOrientation.landscapeRight,
];
const _retrato = [DeviceOrientation.portraitUp];

/// O estado inicial vem dos argumentos da peça; o placar só começa com
/// números fora do modo Ouvir (são de enfeite, como no artboard).
MockupPracticeState _estadoInicial(PracticeArgs args, bool painelAberto) {
  final ouvindo = args.mode == PracticeMode.ouvir;
  return MockupPracticeState(
    setup: PracticeSetup(
      mode: args.mode,
      hand: args.hand,
      tempoPercent: args.tempoPercent,
      size: args.size,
    ),
    measure: args.measure,
    panelOpen: painelAberto,
    counts: ouvindo
        ? const PracticeCounts()
        : const PracticeCounts(correct: 23, reminders: 3, mistakes: 1),
  );
}

/// A tela de estudo. Os métodos mudam o estado na hora (síncronos). A
/// orientação da tela (paisagem ao abrir, retrato ao fechar) passa por
/// [_setOrientations], que os testes trocam por um falso.
class MockupPracticeCubit extends Cubit<MockupPracticeState> {
  MockupPracticeCubit({
    required this.args,
    bool startWithPanelOpen = false,
    this.tickInterval = const Duration(seconds: 2),
    Future<void> Function(List<DeviceOrientation>)? setOrientations,
  }) : _setOrientations =
           setOrientations ?? SystemChrome.setPreferredOrientations,
       super(_estadoInicial(args, startWithPanelOpen));

  /// Título, compositor e total de compassos da peça (não mudam).
  final PracticeArgs args;

  /// Intervalo do "ao vivo" de enfeite; os testes encurtam.
  final Duration tickInterval;

  final Future<void> Function(List<DeviceOrientation>) _setOrientations;
  Timer? _liveTicker;

  /// Trava a tela em paisagem, como a partitura pede.
  void iniciar() => unawaited(_setOrientations(_paisagem));

  /// Para o "ao vivo", solta a orientação e fecha o estado.
  @override
  Future<void> close() {
    _liveTicker?.cancel();
    unawaited(_setOrientations(_retrato));
    return super.close();
  }

  void alternarTocar() {
    _liveTicker?.cancel();
    final tocando = !state.playing;
    emit(state.copyWith(playing: tocando));
    if (tocando && state.praticando) {
      // Só de enfeite: dá vida à tela quando demonstrada no aparelho, sem MIDI
      // real por trás (o motor de som/MIDI é a fase K/M, ainda pendente).
      _liveTicker = Timer.periodic(tickInterval, (_) => tique());
    }
  }

  /// Um passo do "ao vivo": mais um acerto, e o compasso avança até o último.
  void tique() {
    if (isClosed) return;
    final compasso = state.measure < args.totalMeasures
        ? state.measure + 1
        : state.measure;
    emit(
      state.copyWith(
        measure: compasso,
        counts: state.counts.copyWith(correct: state.counts.correct + 1),
      ),
    );
  }

  /// "Parar" da barra larga: pausa e volta ao começo (diferente de pausar, que
  /// retoma de onde estava).
  void parar() {
    _liveTicker?.cancel();
    emit(state.copyWith(playing: false, measure: 1));
  }

  /// Troca o modo. Ao entrar num modo de treino, o andamento vai a 80% e a mão
  /// "ambas" vira a direita; ao voltar ao Ouvir, andamento 100%, ambas as mãos
  /// e o placar zerado.
  void mudarModo(PracticeMode proximo) {
    final atual = state.setup.mode;
    final entrando = atual == PracticeMode.ouvir && proximo != atual;
    final saindo = atual != PracticeMode.ouvir && proximo == PracticeMode.ouvir;
    var setup = state.setup.copyWith(mode: proximo);
    var counts = state.counts;
    if (entrando) {
      setup = setup.copyWith(
        tempoPercent: 80,
        hand: setup.hand == Hand.ambas ? Hand.direita : setup.hand,
      );
    } else if (saindo) {
      setup = setup.copyWith(tempoPercent: 100, hand: Hand.ambas);
      counts = const PracticeCounts();
    }
    emit(state.copyWith(setup: setup, counts: counts));
  }

  void escolherMao(Hand mao) =>
      emit(state.copyWith(setup: state.setup.copyWith(hand: mao)));

  /// Andamento direto (o painel), sem limite.
  void definirAndamento(int percentual) => emit(
    state.copyWith(setup: state.setup.copyWith(tempoPercent: percentual)),
  );

  /// Passo do andamento (os botões da barra), entre 25% e 150%.
  void mudarAndamento(int passo) =>
      definirAndamento((state.setup.tempoPercent + passo).clamp(25, 150));

  void escolherTamanho(ScoreSize tamanho) =>
      emit(state.copyWith(setup: state.setup.copyWith(size: tamanho)));

  void definirRepeticaoAB(bool ligada) =>
      emit(state.copyWith(setup: state.setup.copyWith(repeatAB: ligada)));

  void definirMetronomo(bool ligado) =>
      emit(state.copyWith(setup: state.setup.copyWith(metronome: ligado)));

  void definirPainel(bool aberto) => emit(state.copyWith(panelOpen: aberto));

  /// Vai ao compasso escolhido na folha "Ir para o compasso".
  void irParaCompasso(int compasso) => emit(state.copyWith(measure: compasso));
}
