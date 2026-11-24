// O Cubit do destaque do arrastar e soltar na Web (BL15): a contagem de
// elementos sobre a página. Só a lógica; os ouvintes do DOM ficam em
// web_drop_web.dart (não rodam no teste).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zywny/app/web_drop_cubit.dart';

void main() {
  group('WebDropState', () {
    test('sem arrastar, não destaca; com um, destaca', () {
      expect(const WebDropState().arrastando, isFalse);
      expect(const WebDropState(profundidade: 1).arrastando, isTrue);
    });
  });

  group('WebDropCubit', () {
    blocTest<WebDropCubit, WebDropState>(
      'entrou soma um e destaca',
      build: WebDropCubit.new,
      act: (cubit) => cubit.entrou(),
      expect: () => [const WebDropState(profundidade: 1)],
    );

    blocTest<WebDropCubit, WebDropState>(
      'saiu com ninguém por cima tira o destaque',
      build: WebDropCubit.new,
      seed: () => const WebDropState(profundidade: 1),
      act: (cubit) => cubit.saiu(),
      expect: () => [const WebDropState()],
    );

    blocTest<WebDropCubit, WebDropState>(
      'saiu com outro elemento por cima mantém o destaque',
      build: WebDropCubit.new,
      seed: () => const WebDropState(profundidade: 2),
      act: (cubit) => cubit.saiu(),
      expect: () => [const WebDropState(profundidade: 1)],
    );

    blocTest<WebDropCubit, WebDropState>(
      'saiu não passa de zero',
      build: WebDropCubit.new,
      act: (cubit) => cubit.saiu(),
      expect: () => [const WebDropState()],
    );

    blocTest<WebDropCubit, WebDropState>(
      'soltou zera a contagem',
      build: WebDropCubit.new,
      seed: () => const WebDropState(profundidade: 3),
      act: (cubit) => cubit.soltou(),
      expect: () => [const WebDropState()],
    );
  });
}
