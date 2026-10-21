// As partituras importadas: índice, XML e peça para a lista.
import 'dart:convert';

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/library_blob_store.dart';

import 'package:zywny/app/imported_scores.dart';
import 'package:zywny/app/piece_metadata.dart';

Uint8List _bytes(String text) => Uint8List.fromList(utf8.encode(text));

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  ImportedScoresStore makeStore() =>
      ImportedScoresStore(blobs: MemoryLibraryBlobStore());

  group('ImportedScoresStore', () {
    test('entra no índice e o XML volta ao abrir', () async {
      final store = makeStore();
      await store.load();
      expect(store.scores, isEmpty);

      final added = await store.add(
        fileName: 'Für Elise.mxl',
        scoreXml: _bytes('<score-partwise/>'),
        fifths: 0,
      );
      expect(added.fileName, 'Für Elise.mxl');
      expect(store.scores.map((s) => s.id), [added.id]);
      expect(await store.loadScore(added.id), _bytes('<score-partwise/>'));

      // Outra instância lê o mesmo índice.
      final again = makeStore();
      await again.load();
      expect(again.scores.map((s) => s.id), [added.id]);
    });

    test('nome repetido ganha sufixo', () async {
      final store = makeStore();
      final a = await store.add(
        fileName: 'a.musicxml',
        scoreXml: _bytes('<score-partwise/>'),
      );
      final b = await store.add(
        fileName: 'a.musicxml',
        scoreXml: _bytes('<score-partwise/>'),
      );
      expect(a.id, isNot(b.id));
    });

    test('remove some do índice e do XML', () async {
      final store = makeStore();
      final added = await store.add(
        fileName: 'a.musicxml',
        scoreXml: _bytes('<score-partwise/>'),
      );
      await store.remove(added.id);
      expect(store.scores, isEmpty);
      expect(await store.loadScore(added.id), isNull);
    });

    test('índice estragado começa vazio', () async {
      final prefs = SharedPreferencesAsync();
      await prefs.setString(ImportedScoresStore.indexKey, 'lixo');
      final store = makeStore();
      await store.load();
      expect(store.scores, isEmpty);
    });
  });

  group('toPiece', () {
    test('sem edição mostra o nome do arquivo', () {
      final piece = const ImportedScore(
        id: 'xml-fur-elise',
        fileName: 'Für Elise.mxl',
        fifths: 0,
      ).toPiece(null);
      expect(piece.libraryId, kImportedLibraryId);
      expect(piece.id, 'xml-fur-elise');
      expect(piece.number, isNull);
      expect(piece.title, 'Für Elise');
      expect(piece.composer, '');
      expect(piece.fifths, 0);
      // A busca acha pelo nome do arquivo.
      expect(piece.searchKey.contains('fur elise'), isTrue);
    });

    test('com edição mostra os dados editados', () {
      final piece = const ImportedScore(
        id: 'xml-x',
        fileName: 'x.musicxml',
      ).toPiece(const PieceMetadata(title: 'Novo', composer: 'Eu'));
      expect(piece.title, 'Novo');
      expect(piece.composer, 'Eu');
      expect(piece.titleKey.contains('novo'), isTrue);
    });
  });
}
