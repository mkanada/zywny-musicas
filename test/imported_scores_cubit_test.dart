// O Cubit das partituras importadas (BL12): as transições do estado, com
// blocTest. O comportamento de índice e XML fica em imported_scores_test.dart.
import 'dart:convert';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/library_blob_store.dart';

import 'package:zywny/app/imported_scores.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

ImportedScoresCubit _novo() =>
    ImportedScoresCubit(blobs: MemoryLibraryBlobStore());

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('ImportedScoresState e ImportedScore', () {
    test('começa sem importadas', () {
      expect(const ImportedScoresState().scores, isEmpty);
    });

    test('é igual pelo conteúdo (Equatable)', () {
      const a = ImportedScore(id: 'xml-a', fileName: 'a.musicxml', fifths: 1);
      const igual = ImportedScore(
        id: 'xml-a',
        fileName: 'a.musicxml',
        fifths: 1,
      );
      const outra = ImportedScore(
        id: 'xml-b',
        fileName: 'a.musicxml',
        fifths: 1,
      );

      expect(
        const ImportedScoresState(scores: [a]),
        const ImportedScoresState(scores: [igual]),
      );
      expect(
        const ImportedScoresState(scores: [a]),
        isNot(const ImportedScoresState(scores: [outra])),
      );
    });
  });

  group('ImportedScoresCubit', () {
    blocTest<ImportedScoresCubit, ImportedScoresState>(
      'load sem índice emite a lista vazia (a primeira emissão nunca é ignorada)',
      build: _novo,
      act: (cubit) => cubit.load(),
      expect: () => [const ImportedScoresState()],
    );

    blocTest<ImportedScoresCubit, ImportedScoresState>(
      'load com índice gravado emite a lista',
      setUp: () async {
        await SharedPreferencesAsync().setString(
          ImportedScoresCubit.indexKey,
          jsonEncode([
            {'id': 'xml-a', 'arquivo': 'a.musicxml', 'a': 2},
          ]),
        );
      },
      build: _novo,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ImportedScoresState(
          scores: [
            ImportedScore(id: 'xml-a', fileName: 'a.musicxml', fifths: 2),
          ],
        ),
      ],
    );

    blocTest<ImportedScoresCubit, ImportedScoresState>(
      'add emite a entrada nova e grava o índice',
      build: _novo,
      act: (cubit) async {
        await cubit.add(
          fileName: 'a.musicxml',
          scoreXml: _bytes('<score-partwise/>'),
          fifths: 0,
        );
      },
      expect: () => [
        const ImportedScoresState(
          scores: [
            ImportedScore(id: 'xml-a', fileName: 'a.musicxml', fifths: 0),
          ],
        ),
      ],
      verify: (_) async {
        final text = await SharedPreferencesAsync().getString(
          ImportedScoresCubit.indexKey,
        );
        expect(text, contains('xml-a'));
      },
    );

    blocTest<ImportedScoresCubit, ImportedScoresState>(
      'remove emite a lista sem a importada',
      build: _novo,
      act: (cubit) async {
        final added = await cubit.add(
          fileName: 'a.musicxml',
          scoreXml: _bytes('<score-partwise/>'),
        );
        await cubit.remove(added.id);
      },
      expect: () => [
        const ImportedScoresState(
          scores: [ImportedScore(id: 'xml-a', fileName: 'a.musicxml')],
        ),
        const ImportedScoresState(),
      ],
    );

    blocTest<ImportedScoresCubit, ImportedScoresState>(
      'nome repetido emite duas entradas com ids diferentes',
      build: _novo,
      act: (cubit) async {
        await cubit.add(fileName: 'a.musicxml', scoreXml: _bytes('x'));
        await cubit.add(fileName: 'a.musicxml', scoreXml: _bytes('y'));
      },
      expect: () => [
        const ImportedScoresState(
          scores: [ImportedScore(id: 'xml-a', fileName: 'a.musicxml')],
        ),
        const ImportedScoresState(
          scores: [
            ImportedScore(id: 'xml-a', fileName: 'a.musicxml'),
            ImportedScore(id: 'xml-a-2', fileName: 'a.musicxml'),
          ],
        ),
      ],
    );
  });
}
