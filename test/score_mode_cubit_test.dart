// O modo de treino e a mão da partitura (BL14b): entrar no treino pede uma
// mão só, sair devolve as duas, e a troca de mão fica no estado.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny/app/home/score_mode_cubit.dart';
import 'package:zywny_comum/practice/hand.dart';

void main() {
  group('ScoreModeState', () {
    test('começa fora do treino, com a mão dada', () {
      const estado = ScoreModeState();
      expect(estado.trainingMode, isFalse);
      expect(estado.hand, Hand.direita);
      expect(
        const ScoreModeState(hand: Hand.esquerda),
        isNot(const ScoreModeState()),
      );
    });
  });

  group('ScoreModeCubit', () {
    blocTest<ScoreModeCubit, ScoreModeState>(
      'trocar a mão muda só a mão',
      build: () => ScoreModeCubit(hand: Hand.ambas),
      act: (cubit) => cubit.setHand(Hand.esquerda),
      expect: () => const [ScoreModeState(hand: Hand.esquerda)],
    );

    blocTest<ScoreModeCubit, ScoreModeState>(
      'entrar no treino com as duas mãos fica com a direita',
      build: () => ScoreModeCubit(hand: Hand.ambas),
      act: (cubit) => cubit.setTraining(true),
      expect: () => const [
        ScoreModeState(trainingMode: true, hand: Hand.direita),
      ],
    );

    blocTest<ScoreModeCubit, ScoreModeState>(
      'entrar no treino com uma mão mantém a mão',
      build: () => ScoreModeCubit(hand: Hand.esquerda),
      act: (cubit) => cubit.setTraining(true),
      expect: () => const [
        ScoreModeState(trainingMode: true, hand: Hand.esquerda),
      ],
    );

    blocTest<ScoreModeCubit, ScoreModeState>(
      'sair do treino devolve as duas mãos',
      build: () => ScoreModeCubit(hand: Hand.esquerda),
      seed: () => const ScoreModeState(
        trainingMode: true,
        hand: Hand.esquerda,
      ),
      act: (cubit) => cubit.setTraining(false),
      expect: () => const [ScoreModeState(hand: Hand.ambas)],
    );

    blocTest<ScoreModeCubit, ScoreModeState>(
      'o mesmo modo não emite nada',
      build: () => ScoreModeCubit(hand: Hand.direita),
      act: (cubit) => cubit.setTraining(false),
      expect: () => const <ScoreModeState>[],
    );
  });
}
