import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zywny_mockup/mockup/library_cubit.dart';
import 'package:zywny_mockup/mockup/models.dart';

LibraryCubit _criar({List<List<DeviceOrientation>>? giros}) => LibraryCubit(
  setOrientations: (orientacoes) async {
    giros?.add(orientacoes);
  },
);

/// Os títulos que a lista mostra, na ordem.
List<String> _titulos(LibraryState estado) =>
    estado.filtradas.map((p) => p.title).toList();

void main() {
  group('LibraryState', () {
    test('sem busca, mostra todas as peças', () {
      expect(_titulos(const LibraryState()), hasLength(kPieces.length));
    });

    test('a busca acha pelo título, sem maiúsculas', () {
      const estado = LibraryState(query: 'LITTLE');

      expect(_titulos(estado), ['Little bird, op. 43 nº 4']);
    });

    test('a busca acha pelo compositor', () {
      final titulos = _titulos(const LibraryState(query: 'chopin'));

      expect(titulos, isNotEmpty);
      expect(
        kPieces.where((p) => p.composer == 'Frédéric Chopin').length,
        titulos.length,
      );
    });

    test('espaços antes e depois da busca não contam', () {
      expect(
        _titulos(const LibraryState(query: '   ')),
        hasLength(kPieces.length),
      );
    });

    test('busca sem resposta deixa a lista vazia', () {
      expect(_titulos(const LibraryState(query: 'zzz-nada')), isEmpty);
    });

    test('a ordem vem do SortState', () {
      final porNome = _titulos(
        const LibraryState(sort: SortState(key: SortKey.title)),
      );

      final ordenados = [...porNome]..sort();
      expect(porNome, ordenados);
    });

    test('é igual pelo valor, e a direção da ordem entra na comparação', () {
      expect(
        const LibraryState(query: 'x'),
        equals(const LibraryState(query: 'x')),
      );
      expect(
        const LibraryState(sort: SortState(key: SortKey.title)),
        isNot(
          equals(
            const LibraryState(
              sort: SortState(key: SortKey.title, ascending: false),
            ),
          ),
        ),
      );
    });
  });

  group('LibraryCubit', () {
    blocTest<LibraryCubit, LibraryState>(
      'buscar guarda o texto',
      build: _criar,
      act: (cubit) => cubit.buscar('bach'),
      expect: () => [const LibraryState(query: 'bach')],
    );

    blocTest<LibraryCubit, LibraryState>(
      'ordenar pela mesma chave inverte a direção',
      build: _criar,
      act: (cubit) => cubit.ordenar(SortKey.recent),
      expect: () => [const LibraryState(sort: SortState(ascending: false))],
    );

    blocTest<LibraryCubit, LibraryState>(
      'ordenar por outra chave volta à direção padrão dela',
      build: _criar,
      act: (cubit) => cubit.ordenar(SortKey.score),
      expect: () => [
        const LibraryState(
          sort: SortState(key: SortKey.score, ascending: false),
        ),
      ],
    );

    blocTest<LibraryCubit, LibraryState>(
      'alternarMidi liga e desliga o indicador',
      build: _criar,
      act: (cubit) => cubit.alternarMidi(),
      expect: () => [const LibraryState(midiConnected: false)],
    );

    test('iniciar trava a biblioteca em retrato', () {
      final giros = <List<DeviceOrientation>>[];
      final cubit = _criar(giros: giros);
      addTearDown(cubit.close);

      cubit.iniciar();

      expect(giros, [
        [DeviceOrientation.portraitUp],
      ]);
    });
  });
}
