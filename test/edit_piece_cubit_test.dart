// O Cubit do erro do formulário "Editar dados da música" (BL15).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zywny/app/edit_piece_cubit.dart';

void main() {
  group('EditPieceState', () {
    test('começa sem erro e é igual pelo valor', () {
      expect(const EditPieceState().nomeVazio, isFalse);
      expect(
        const EditPieceState(nomeVazio: true),
        equals(const EditPieceState(nomeVazio: true)),
      );
      expect(
        const EditPieceState(nomeVazio: true),
        isNot(equals(const EditPieceState())),
      );
    });
  });

  group('EditPieceCubit', () {
    blocTest<EditPieceCubit, EditPieceState>(
      'exigirNome marca o nome vazio',
      build: EditPieceCubit.new,
      act: (cubit) => cubit.exigirNome(),
      expect: () => [const EditPieceState(nomeVazio: true)],
    );

    blocTest<EditPieceCubit, EditPieceState>(
      'limparErroNome tira o erro depois de exigirNome',
      build: EditPieceCubit.new,
      seed: () => const EditPieceState(nomeVazio: true),
      act: (cubit) => cubit.limparErroNome(),
      expect: () => [const EditPieceState()],
    );

    blocTest<EditPieceCubit, EditPieceState>(
      'limparErroNome sem erro não emite',
      build: EditPieceCubit.new,
      act: (cubit) => cubit.limparErroNome(),
      expect: () => <EditPieceState>[],
    );
  });
}
