// O TourCubit (BL15): o passo atual, a ida e a volta entre os passos com alvo
// na tela, o "3 de 9" e o recorte medido. As transições com blocTest.
import 'dart:ui' show Rect;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:flutter_test/flutter_test.dart';

import 'package:zywny/tutorial/tour.dart';

const _cartao = TourStep(title: 'Um', body: 'Cartão sem alvo.');

/// Passo com alvo que não está montado: o passeio o pula.
TourStep _semAlvo() => TourStep(
  title: 'Escondido',
  body: 'Alvo fora da tela.',
  targets: [GlobalKey()],
);

void main() {
  // Os alvos são GlobalKeys, que consultam o binding do Flutter.
  TestWidgetsFlutterBinding.ensureInitialized();

  _testesDoEstado();
  _testesDoCubit();
  _testesDaRemedicao();
  _testesDoRecorte();
}

void _testesDoEstado() {
  group('TourState', () {
    test('é igual pelo passo e pelo recorte', () {
      const a = TourState(index: 1, hole: Rect.fromLTWH(0, 0, 10, 10));
      const b = TourState(index: 1, hole: Rect.fromLTWH(0, 0, 10, 10));

      expect(a, equals(b));
      expect(a, isNot(equals(const TourState(index: 2))));
    });
  });
}

void _testesDoCubit() {
  group('TourCubit', () {
    test('começa no primeiro passo com alvo (ou cartão)', () {
      final cubit = TourCubit(steps: [_semAlvo(), _cartao]);
      addTearDown(cubit.close);

      expect(cubit.state.index, 1);
      expect(cubit.step, _cartao);
      expect(cubit.first, isTrue);
    });

    test('pula os passos sem alvo na tela ao andar', () {
      final cubit = TourCubit(
        steps: [
          _cartao,
          _semAlvo(),
          const TourStep(title: 'Três', body: ''),
        ],
      );
      addTearDown(cubit.close);

      expect(cubit.ir(1), isTrue);
      expect(cubit.state.index, 2);
      expect(cubit.last, isTrue);
      expect(cubit.ir(1), isFalse, reason: 'não há passo depois do último');
      expect(cubit.state.index, 2);
    });

    test('"3 de 9": os passos sem alvo não contam', () {
      final cubit = TourCubit(
        steps: [
          _cartao,
          _semAlvo(),
          const TourStep(title: 'Três', body: ''),
        ],
      );
      addTearDown(cubit.close);

      expect(cubit.progress, (position: 1, total: 2));
      cubit.ir(1);
      expect(cubit.progress, (position: 2, total: 2));
    });
  });
}

void _testesDoRecorte() {
  group('TourCubit (passo e recorte)', () {
    blocTest<TourCubit, TourState>(
      'ir para um passo emite o passo e zera o recorte',
      build: () => TourCubit(steps: [_cartao, _cartao]),
      seed: () => const TourState(index: 0, hole: Rect.fromLTWH(1, 1, 2, 2)),
      act: (cubit) => cubit.ir(1),
      expect: () => [const TourState(index: 1)],
    );

    blocTest<TourCubit, TourState>(
      'medir guarda o recorte',
      build: () => TourCubit(steps: [_cartao]),
      act: (cubit) => cubit.medir(const Rect.fromLTWH(4, 4, 8, 8)),
      expect: () => [
        const TourState(index: 0, hole: Rect.fromLTWH(4, 4, 8, 8)),
      ],
    );

    blocTest<TourCubit, TourState>(
      'medir o mesmo recorte (até meio pixel) não emite',
      build: () => TourCubit(steps: [_cartao]),
      seed: () => const TourState(index: 0, hole: Rect.fromLTWH(4, 4, 8, 8)),
      act: (cubit) => cubit.medir(const Rect.fromLTWH(4.2, 4, 8, 8.3)),
      expect: () => <TourState>[],
    );

    blocTest<TourCubit, TourState>(
      'medir null tira o recorte',
      build: () => TourCubit(steps: [_cartao]),
      seed: () => const TourState(index: 0, hole: Rect.fromLTWH(4, 4, 8, 8)),
      act: (cubit) => cubit.medir(null),
      expect: () => [const TourState(index: 0)],
    );
  });
}

void _testesDaRemedicao() {
  test(
    'comecarRemedicao chama o remedir a cada intervalo, e para no close',
    () async {
      final cubit = TourCubit(
        steps: [_cartao],
        remeasureEvery: const Duration(milliseconds: 5),
      );
      var chamadas = 0;

      cubit.comecarRemedicao(() => chamadas++);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(chamadas, greaterThan(0));

      await cubit.close();
      final noClose = chamadas;
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(chamadas, noClose, reason: 'o Timer para no close');
    },
  );
}
