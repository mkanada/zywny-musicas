// Estado da biblioteca do mockup (`LibraryScreen`): a busca, a ordenação e o
// indicador do teclado MIDI. A lista filtrada sai do estado, não de um campo
// da tela.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zywny_bloc/zywny_bloc.dart';

import 'models.dart';

class LibraryState extends Equatable {
  const LibraryState({
    this.sort = const SortState(),
    this.query = '',
    this.midiConnected = true,
  });

  final SortState sort;

  /// O que está escrito na busca (título ou compositor).
  final String query;

  /// O teclado MIDI está ligado (o ponto verde do cabeçalho).
  final bool midiConnected;

  /// As peças na ordem escolhida, só as que a busca acha (sem maiúsculas).
  List<Piece> get filtradas {
    final pecas = sortedPieces(kPieces, sort);
    if (query.trim().isEmpty) return pecas;
    final q = query.toLowerCase();
    return pecas
        .where(
          (p) =>
              p.title.toLowerCase().contains(q) ||
              p.composer.toLowerCase().contains(q),
        )
        .toList();
  }

  LibraryState copyWith({
    SortState? sort,
    String? query,
    bool? midiConnected,
  }) => LibraryState(
    sort: sort ?? this.sort,
    query: query ?? this.query,
    midiConnected: midiConnected ?? this.midiConnected,
  );

  // `SortState` não tem igualdade pelo valor: compara-se a chave e a direção.
  @override
  List<Object?> get props => [sort.key, sort.ascending, query, midiConnected];
}

/// A biblioteca, em retrato (`CelularBiblioteca`). A orientação passa por
/// [_setOrientations], que os testes trocam por um falso.
class LibraryCubit extends Cubit<LibraryState> {
  LibraryCubit({
    Future<void> Function(List<DeviceOrientation>)? setOrientations,
  }) : _setOrientations =
           setOrientations ?? SystemChrome.setPreferredOrientations,
       super(const LibraryState());

  final Future<void> Function(List<DeviceOrientation>) _setOrientations;

  /// Trava a biblioteca em retrato, como ao abrir a tela.
  void iniciar() =>
      unawaited(_setOrientations(const [DeviceOrientation.portraitUp]));

  void buscar(String texto) => emit(state.copyWith(query: texto));

  /// Toca a chave: inverte a direção, ou troca de chave (`SortState.toggled`).
  void ordenar(SortKey chave) =>
      emit(state.copyWith(sort: state.sort.toggled(chave)));

  void alternarMidi() =>
      emit(state.copyWith(midiConnected: !state.midiConnected));
}
