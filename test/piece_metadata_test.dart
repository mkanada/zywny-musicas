// Correções locais dos dados das músicas: modelo e store.
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:zywny_library/piece.dart';

import 'package:zywny/app/piece_metadata.dart';

Piece _piece() => Piece(
  libraryId: 'hinos',
  id: '001',
  number: 1,
  title: 'Santo, Santo, Santo!',
  composer: 'John B. Dykes',
  lyricist: 'Reginald Heber',
  originalTitle: 'Holy, Holy',
  fifths: 2,
  titleKey: foldForSearch('Santo, Santo, Santo!'),
  composerKey: foldForSearch('John B. Dykes'),
  searchKey: foldForSearch('1 Santo Holy Dykes Heber'),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  group('PieceMetadata', () {
    test('vazio é só o intocado (tudo nulo)', () {
      expect(const PieceMetadata().isEmpty, isTrue);
      // Em branco não é intocado: é uma decisão (vazio no opcional limpa).
      expect(const PieceMetadata(title: '  ').isEmpty, isFalse);
      expect(const PieceMetadata(title: 'X').isEmpty, isFalse);
    });

    test('volta do JSON como foi', () {
      const meta = PieceMetadata(
        title: 'Novo nome',
        composer: 'Novo autor',
        lyricist: 'Letrista',
        originalTitle: 'Op. 1',
      );
      final back = PieceMetadata.fromJson(
        Map<String, dynamic>.from(meta.toJson()),
      );
      expect(back, meta);
    });

    test('ignora o que não conhece; vazio é "limpar", não "igual"', () {
      final meta = PieceMetadata.fromJson({
        'l': ' ',
        'c': 'Autor',
        'desconhecido': 1,
      });
      expect(meta.lyricist, '');
      expect(meta.composer, 'Autor');
      expect(meta.title, isNull);
      expect(meta.isEmpty, isFalse);
    });

    test('applyTo troca os dados e refaz as chaves de busca', () {
      final edited = const PieceMetadata(
        title: 'Vinde, Povo',
        composer: 'Elvey',
      ).applyTo(_piece());
      expect(edited.title, 'Vinde, Povo');
      expect(edited.composer, 'Elvey');
      expect(edited.lyricist, 'Reginald Heber');
      expect(edited.originalTitle, 'Holy, Holy');
      expect(edited.titleKey, foldForSearch('Vinde, Povo'));
      expect(edited.composerKey, foldForSearch('Elvey'));
      expect(edited.searchKey.contains(foldForSearch('vinde')), isTrue);
      expect(edited.searchKey.contains(foldForSearch('elvey')), isTrue);
      // O resto não muda.
      expect(edited.id, '001');
      expect(edited.number, 1);
      expect(edited.fifths, 2);
      expect(edited.libraryId, 'hinos');
    });

    test('applyTo vazio devolve a mesma peça', () {
      final piece = _piece();
      expect(identical(const PieceMetadata().applyTo(piece), piece), isTrue);
    });

    test('limpar o opcional zera, limpar o obrigatório mantém', () {
      final edited = const PieceMetadata(
        lyricist: ' ',
        originalTitle: '',
      ).applyTo(_piece());
      expect(edited.lyricist, isNull);
      expect(edited.originalTitle, isNull);
      expect(edited.title, 'Santo, Santo, Santo!');
    });
  });

  group('PieceMetadataStore', () {
    test('guarda e lê por biblioteca e música', () async {
      final store = PieceMetadataStore();
      await store.save(
        'hinos',
        '001',
        const PieceMetadata(title: 'Novo'),
      );
      expect(store.get('hinos', '001')?.title, 'Novo');
      expect(store.get('hinos', '002'), isNull);
      expect(store.get('classicos', '001'), isNull);
    });

    test('load traz do disco sem apagar outras bibliotecas', () async {
      final first = PieceMetadataStore();
      await first.save('hinos', '001', const PieceMetadata(title: 'A'));
      await first.save('classicos', 'x', const PieceMetadata(title: 'B'));

      final store = PieceMetadataStore();
      await store.load('hinos', ['001']);
      expect(store.get('hinos', '001')?.title, 'A');
      expect(store.get('classicos', 'x'), isNull);
      await store.load('classicos', ['x']);
      expect(store.get('hinos', '001')?.title, 'A');
      expect(store.get('classicos', 'x')?.title, 'B');
    });

    test('salvar vazio limpa, e clear restaura', () async {
      final store = PieceMetadataStore();
      await store.save('hinos', '001', const PieceMetadata(title: 'A'));
      await store.save('hinos', '001', const PieceMetadata());
      expect(store.get('hinos', '001'), isNull);

      await store.save('hinos', '001', const PieceMetadata(title: 'A'));
      await store.clear('hinos', '001');
      expect(store.get('hinos', '001'), isNull);
    });

    test('avisa quem escuta', () async {
      final store = PieceMetadataStore();
      var calls = 0;
      store.addListener(() => calls++);
      await store.save('hinos', '001', const PieceMetadata(title: 'A'));
      expect(calls, 1);
    });

    test('applyAll mantém quem não tem correção', () async {
      final store = PieceMetadataStore();
      await store.save('hinos', '001', const PieceMetadata(title: 'Novo'));
      final other = Piece(
        libraryId: 'hinos',
        id: '002',
        number: 2,
        title: 'Outra',
        composer: 'Alguém',
        titleKey: foldForSearch('Outra'),
        composerKey: foldForSearch('Alguém'),
        searchKey: foldForSearch('2 Outra Alguém'),
      );
      final out = store.applyAll('hinos', [_piece(), other]);
      expect(out[0].title, 'Novo');
      expect(out[1].title, 'Outra');
    });

    test('o "limpar" sobrevive à volta do disco', () async {
      final first = PieceMetadataStore();
      await first.save(
        'hinos',
        '001',
        const PieceMetadata(lyricist: ''),
      );
      final store = PieceMetadataStore();
      await store.load('hinos', ['001']);
      final edited = store.get('hinos', '001')!.applyTo(_piece());
      expect(edited.lyricist, isNull);
    });
  });

  group('chave', () {
    test('segue o padrão das outras chaves de música', () {
      expect(pieceMetaKeyFor('hinos', '001'), 'piece_meta_hinos_001');
    });

    test('Uint8List importa (o teste usa archive de verdade)', () {
      final bytes = Uint8List.fromList(
        ZipEncoder().encode(Archive()),
      );
      expect(bytes.take(2).toList(), [0x50, 0x4B]);
    });
  });
}
