import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny_mockup/mockup/practice_cubit.dart';
import 'package:zywny_mockup/mockup/practice_state.dart';

PracticeArgs _peca({
  PracticeMode mode = PracticeMode.espera,
  Hand hand = Hand.direita,
  int measure = 4,
  int totalMeasures = 41,
}) => PracticeArgs(
  title: 'Little bird, op. 43 nº 4',
  composer: 'Edvard Grieg',
  mode: mode,
  hand: hand,
  tempoPercent: 80,
  measure: measure,
  totalMeasures: totalMeasures,
);

PracticeCubit _criar({
  PracticeArgs? args,
  bool painel = false,
  Duration intervalo = const Duration(seconds: 2),
  List<List<DeviceOrientation>>? giros,
}) => PracticeCubit(
  args: args ?? _peca(),
  startWithPanelOpen: painel,
  tickInterval: intervalo,
  setOrientations: (orientacoes) async {
    giros?.add(orientacoes);
  },
);

void main() {
  group('começo', () {
    test('escolhas e placar vêm dos argumentos da peça', () {
      final cubit = _criar();
      addTearDown(cubit.close);

      expect(cubit.state.setup.mode, PracticeMode.espera);
      expect(cubit.state.setup.hand, Hand.direita);
      expect(cubit.state.setup.tempoPercent, 80);
      expect(cubit.state.measure, 4);
      expect(cubit.state.playing, isFalse);
      expect(cubit.state.panelOpen, isFalse);
      expect(cubit.state.counts.correct, 23);
      expect(cubit.state.counts.reminders, 3);
      expect(cubit.state.counts.mistakes, 1);
    });

    test('no Ouvir o placar começa zerado', () {
      final cubit = _criar(args: _peca(mode: PracticeMode.ouvir));
      addTearDown(cubit.close);

      expect(cubit.state.counts, const PracticeCounts());
      expect(cubit.state.praticando, isFalse);
    });

    test('startWithPanelOpen abre a tela com o painel aberto', () {
      final cubit = _criar(painel: true);
      addTearDown(cubit.close);

      expect(cubit.state.panelOpen, isTrue);
    });
  });

  group('orientação', () {
    test('iniciar trava em paisagem e close volta ao retrato', () async {
      final giros = <List<DeviceOrientation>>[];
      final cubit = _criar(giros: giros);

      cubit.iniciar();
      expect(giros.last, const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

      await cubit.close();
      expect(giros.last, const [DeviceOrientation.portraitUp]);
    });
  });

  group('ao vivo', () {
    blocTest<PracticeCubit, PracticeState>(
      'tique avança o compasso e soma um acerto',
      build: _criar,
      act: (cubit) => cubit.tique(),
      expect: () => [
        isA<PracticeState>()
            .having((s) => s.measure, 'compasso', 5)
            .having((s) => s.counts.correct, 'acertos', 24),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'tique no último compasso não passa do total',
      build: () => _criar(args: _peca(measure: 41)),
      act: (cubit) => cubit.tique(),
      expect: () => [
        isA<PracticeState>()
            .having((s) => s.measure, 'compasso', 41)
            .having((s) => s.counts.correct, 'acertos', 24),
      ],
    );

    test('Tocar fora do Ouvir liga o ao vivo; pausar para', () async {
      final cubit = _criar(intervalo: const Duration(milliseconds: 5));
      addTearDown(cubit.close);

      cubit.alternarTocar();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(cubit.state.playing, isTrue);
      expect(cubit.state.counts.correct, greaterThan(23));

      cubit.alternarTocar();
      final parado = cubit.state.counts.correct;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.playing, isFalse);
      expect(cubit.state.counts.correct, parado);
    });

    test('no Ouvir, Tocar não liga o ao vivo', () async {
      final cubit = _criar(
        args: _peca(mode: PracticeMode.ouvir),
        intervalo: const Duration(milliseconds: 5),
      );
      addTearDown(cubit.close);

      cubit.alternarTocar();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(cubit.state.playing, isTrue);
      expect(cubit.state.counts, const PracticeCounts());
      expect(cubit.state.measure, 4);
    });

    test('fechar a tela para o ao vivo, sem emitir depois', () async {
      final cubit = _criar(intervalo: const Duration(milliseconds: 5));

      cubit.alternarTocar();
      await cubit.close();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(cubit.isClosed, isTrue);
      expect(cubit.state.counts.correct, 23);
    });
  });

  group('parar', () {
    blocTest<PracticeCubit, PracticeState>(
      'volta ao começo e para, sem mexer no placar',
      build: _criar,
      seed: () => const PracticeState(
        setup: PracticeSetup(
          mode: PracticeMode.espera,
          hand: Hand.direita,
          tempoPercent: 80,
        ),
        measure: 9,
        playing: true,
        counts: PracticeCounts(correct: 5, reminders: 1, mistakes: 0),
      ),
      act: (cubit) => cubit.parar(),
      expect: () => [
        const PracticeState(
          setup: PracticeSetup(
            mode: PracticeMode.espera,
            hand: Hand.direita,
            tempoPercent: 80,
          ),
          measure: 1,
          counts: PracticeCounts(correct: 5, reminders: 1, mistakes: 0),
        ),
      ],
    );
  });

  group('modo', () {
    blocTest<PracticeCubit, PracticeState>(
      'do Ouvir a um treino: andamento 80% e a mão ambas vira a direita',
      build: () => _criar(
        args: _peca(mode: PracticeMode.ouvir, hand: Hand.ambas),
      ),
      act: (cubit) => cubit.mudarModo(PracticeMode.tempoReal),
      expect: () => [
        isA<PracticeState>()
            .having((s) => s.setup.mode, 'modo', PracticeMode.tempoReal)
            .having((s) => s.setup.tempoPercent, 'andamento', 80)
            .having((s) => s.setup.hand, 'mão', Hand.direita),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'do Ouvir a um treino, uma mão escolhida fica',
      build: () => _criar(
        args: _peca(mode: PracticeMode.ouvir, hand: Hand.esquerda),
      ),
      act: (cubit) => cubit.mudarModo(PracticeMode.espera),
      expect: () => [
        isA<PracticeState>().having((s) => s.setup.hand, 'mão', Hand.esquerda),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'de um treino ao Ouvir: andamento 100%, ambas as mãos e placar zerado',
      build: _criar,
      act: (cubit) => cubit.mudarModo(PracticeMode.ouvir),
      expect: () => [
        isA<PracticeState>()
            .having((s) => s.setup.mode, 'modo', PracticeMode.ouvir)
            .having((s) => s.setup.tempoPercent, 'andamento', 100)
            .having((s) => s.setup.hand, 'mão', Hand.ambas)
            .having((s) => s.counts, 'placar', const PracticeCounts()),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'entre dois treinos só troca o modo',
      build: _criar,
      act: (cubit) => cubit.mudarModo(PracticeMode.tempoReal),
      expect: () => [
        isA<PracticeState>()
            .having((s) => s.setup.mode, 'modo', PracticeMode.tempoReal)
            .having((s) => s.setup.tempoPercent, 'andamento', 80)
            .having((s) => s.setup.hand, 'mão', Hand.direita)
            .having((s) => s.counts.correct, 'acertos', 23),
      ],
    );
  });

  group('andamento e mão', () {
    blocTest<PracticeCubit, PracticeState>(
      'mudarAndamento soma o passo',
      build: _criar,
      act: (cubit) => cubit.mudarAndamento(10),
      expect: () => [
        isA<PracticeState>().having(
          (s) => s.setup.tempoPercent,
          'andamento',
          90,
        ),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'mudarAndamento não desce de 25%',
      build: _criar,
      act: (cubit) => cubit.mudarAndamento(-100),
      expect: () => [
        isA<PracticeState>().having(
          (s) => s.setup.tempoPercent,
          'andamento',
          25,
        ),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'mudarAndamento não sobe de 150%',
      build: _criar,
      act: (cubit) => cubit.mudarAndamento(100),
      expect: () => [
        isA<PracticeState>().having(
          (s) => s.setup.tempoPercent,
          'andamento',
          150,
        ),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'definirAndamento vai ao valor pedido, sem limite',
      build: _criar,
      act: (cubit) => cubit.definirAndamento(60),
      expect: () => [
        isA<PracticeState>().having(
          (s) => s.setup.tempoPercent,
          'andamento',
          60,
        ),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'escolherMao troca a mão',
      build: _criar,
      act: (cubit) => cubit.escolherMao(Hand.esquerda),
      expect: () => [
        isA<PracticeState>().having((s) => s.setup.hand, 'mão', Hand.esquerda),
      ],
    );
  });

  group('painel, compasso e opções', () {
    blocTest<PracticeCubit, PracticeState>(
      'definirPainel abre e fecha o painel',
      build: _criar,
      act: (cubit) {
        cubit.definirPainel(true);
        cubit.definirPainel(false);
      },
      expect: () => [
        isA<PracticeState>().having((s) => s.panelOpen, 'painel', isTrue),
        isA<PracticeState>().having((s) => s.panelOpen, 'painel', isFalse),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'irParaCompasso vai ao compasso escolhido',
      build: _criar,
      act: (cubit) => cubit.irParaCompasso(12),
      expect: () => [
        isA<PracticeState>().having((s) => s.measure, 'compasso', 12),
      ],
    );

    blocTest<PracticeCubit, PracticeState>(
      'tamanho, repetição A–B e metrônomo mudam só o seu campo',
      build: _criar,
      act: (cubit) {
        cubit.escolherTamanho(ScoreSize.grande);
        cubit.definirRepeticaoAB(true);
        cubit.definirMetronomo(false);
      },
      expect: () => [
        isA<PracticeState>().having(
          (s) => s.setup.size,
          'tamanho',
          ScoreSize.grande,
        ),
        isA<PracticeState>().having((s) => s.setup.repeatAB, 'A–B', isTrue),
        isA<PracticeState>().having(
          (s) => s.setup.metronome,
          'metrônomo',
          isFalse,
        ),
      ],
    );
  });
}
