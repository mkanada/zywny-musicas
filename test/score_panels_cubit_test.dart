// As gavetas e os painéis da partitura (BL14b): o que abrir fecha junto, e
// o "voltar" fecha tudo. Com blocTest, as transições do estado.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny/app/home/score_panels_cubit.dart';

void main() {
  group('HomePanelsState', () {
    test('começa tudo fechado e é igual pelo conteúdo', () {
      const fechado = HomePanelsState();
      expect(fechado.anyOpen, isFalse);
      expect(
        const HomePanelsState(midi: true),
        isNot(const HomePanelsState()),
      );
      expect(const HomePanelsState(options: true).anyOpen, isTrue);
    });
  });

  group('HomePanelsCubit', () {
    blocTest<HomePanelsCubit, HomePanelsState>(
      'abrir e fechar a gaveta ⋯',
      build: HomePanelsCubit.new,
      act: (cubit) {
        cubit.openOptions();
        cubit.closeOptions();
      },
      expect: () => const [
        HomePanelsState(options: true),
        HomePanelsState(),
      ],
    );

    blocTest<HomePanelsCubit, HomePanelsState>(
      'o layout fecha a gaveta ⋯ e o geral',
      build: HomePanelsCubit.new,
      seed: () => const HomePanelsState(options: true, general: true),
      act: (cubit) => cubit.openLayout(),
      expect: () => const [HomePanelsState(layout: true)],
    );

    blocTest<HomePanelsCubit, HomePanelsState>(
      'o geral fecha a gaveta ⋯ e o layout',
      build: HomePanelsCubit.new,
      seed: () => const HomePanelsState(options: true, layout: true),
      act: (cubit) => cubit.openGeneral(),
      expect: () => const [HomePanelsState(general: true)],
    );

    blocTest<HomePanelsCubit, HomePanelsState>(
      'o monitor do MIDI abre a partir do geral, que fecha',
      build: HomePanelsCubit.new,
      seed: () => const HomePanelsState(general: true),
      act: (cubit) => cubit.openMidi(),
      expect: () => const [HomePanelsState(midi: true)],
    );

    blocTest<HomePanelsCubit, HomePanelsState>(
      'a gaveta da trilha abre e fecha sem mexer nos outros',
      build: HomePanelsCubit.new,
      seed: () => const HomePanelsState(options: true),
      act: (cubit) {
        cubit.openStageDrawer();
        cubit.closeTrailDrawer();
      },
      expect: () => const [
        HomePanelsState(options: true, trailDrawer: true),
        HomePanelsState(options: true),
      ],
    );

    blocTest<HomePanelsCubit, HomePanelsState>(
      'o voltar com tudo aberto fecha tudo',
      build: HomePanelsCubit.new,
      seed: () => const HomePanelsState(
        options: true,
        layout: false,
        general: true,
        midi: true,
        trailDrawer: true,
      ),
      act: (cubit) => cubit.closeAll(),
      expect: () => const [HomePanelsState()],
    );
  });
}
