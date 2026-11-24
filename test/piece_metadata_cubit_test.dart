// O Cubit das correções dos dados (BL12): as transições do estado, com
// blocTest. A leitura e a gravação em si ficam em piece_metadata_test.dart.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:zywny/app/piece_metadata.dart';

const _chave = 'piece_meta_hinos_001';

PieceMetadataState _com(PieceMetadata meta) =>
    PieceMetadataState(byKey: {_chave: meta});

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('PieceMetadataState', () {
    test('começa sem correções e é igual pelo conteúdo', () {
      expect(const PieceMetadataState().byKey, isEmpty);
      expect(
        _com(const PieceMetadata(title: 'A')),
        _com(const PieceMetadata(title: 'A')),
      );
      expect(
        _com(const PieceMetadata(title: 'A')),
        isNot(_com(const PieceMetadata(title: 'B'))),
      );
    });
  });

  group('PieceMetadataCubit', () {
    blocTest<PieceMetadataCubit, PieceMetadataState>(
      'save emite a correção',
      build: PieceMetadataCubit.new,
      act: (cubit) =>
          cubit.save('hinos', '001', const PieceMetadata(title: 'A')),
      expect: () => [_com(const PieceMetadata(title: 'A'))],
    );

    blocTest<PieceMetadataCubit, PieceMetadataState>(
      'save vazio é o mesmo que limpar',
      build: PieceMetadataCubit.new,
      act: (cubit) async {
        await cubit.save('hinos', '001', const PieceMetadata(title: 'A'));
        await cubit.save('hinos', '001', const PieceMetadata());
      },
      expect: () => [
        _com(const PieceMetadata(title: 'A')),
        const PieceMetadataState(),
      ],
    );

    blocTest<PieceMetadataCubit, PieceMetadataState>(
      'clear emite só quando havia correção',
      build: PieceMetadataCubit.new,
      act: (cubit) async {
        await cubit.save('hinos', '001', const PieceMetadata(title: 'A'));
        await cubit.clear('hinos', '001');
        await cubit.clear('hinos', '001');
      },
      expect: () => [
        _com(const PieceMetadata(title: 'A')),
        const PieceMetadataState(),
      ],
    );

    blocTest<PieceMetadataCubit, PieceMetadataState>(
      'load lê o que está guardado e emite',
      setUp: () async {
        await PieceMetadataCubit().save(
          'hinos',
          '001',
          const PieceMetadata(title: 'Guardado'),
        );
      },
      build: PieceMetadataCubit.new,
      act: (cubit) => cubit.load('hinos', ['001']),
      expect: () => [_com(const PieceMetadata(title: 'Guardado'))],
    );

    blocTest<PieceMetadataCubit, PieceMetadataState>(
      'load sem correção guardada emite o estado vazio (a primeira emissão '
      'nunca é ignorada)',
      build: PieceMetadataCubit.new,
      act: (cubit) => cubit.load('hinos', ['001']),
      expect: () => [const PieceMetadataState()],
    );

    test('save põe a correção na memória antes de a gravação acabar', () async {
      final cubit = PieceMetadataCubit();
      addTearDown(cubit.close);

      final gravacao = cubit.save(
        'hinos',
        '001',
        const PieceMetadata(title: 'A'),
      );
      expect(cubit.get('hinos', '001')?.title, 'A');
      await gravacao;

      final lido = PieceMetadataCubit();
      addTearDown(lido.close);
      await lido.load('hinos', ['001']);
      expect(lido.get('hinos', '001')?.title, 'A');
    });

    test('fechado, não emite nem lança ao chegar a leitura', () async {
      final cubit = PieceMetadataCubit();
      final carga = cubit.load('hinos', ['001']);
      await cubit.close();

      await expectLater(carga, completes);
      expect(cubit.isClosed, isTrue);
    });
  });
}
