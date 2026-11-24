import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny_mockup/mockup/measure_jump_cubit.dart';

void main() {
  group('MeasureJumpState', () {
    test('copyWith troca só o alvo pedido', () {
      const estado = MeasureJumpState(target: 4);

      expect(estado.copyWith(), estado);
      expect(estado.copyWith(target: 9).target, 9);
    });

    test('é igual pelo valor (Equatable)', () {
      expect(
        const MeasureJumpState(target: 4),
        equals(const MeasureJumpState(target: 4)),
      );
      expect(
        const MeasureJumpState(target: 4),
        isNot(equals(const MeasureJumpState(target: 5))),
      );
    });
  });

  group('MeasureJumpCubit', () {
    test('começa no compasso atual', () {
      final cubit = MeasureJumpCubit(4);
      addTearDown(cubit.close);

      expect(cubit.state.target, 4);
    });

    blocTest<MeasureJumpCubit, MeasureJumpState>(
      'escolher emite o compasso do slider',
      build: () => MeasureJumpCubit(4),
      act: (cubit) => cubit.escolher(17),
      expect: () => [const MeasureJumpState(target: 17)],
    );

    blocTest<MeasureJumpCubit, MeasureJumpState>(
      'escolher o mesmo compasso de novo não emite',
      build: () => MeasureJumpCubit(4),
      act: (cubit) {
        cubit.escolher(17);
        cubit.escolher(17);
      },
      expect: () => [const MeasureJumpState(target: 17)],
    );
  });
}
