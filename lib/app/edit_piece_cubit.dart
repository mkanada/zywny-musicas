// O erro do formulário "Editar dados da música" (BL15): o nome vazio ao
// salvar. Antes era `_titleError`, mudado com `setState` no diálogo. Os campos
// de texto continuam no State do diálogo (são controladores do framework).

import 'package:zywny_bloc/zywny_bloc.dart';

/// `nomeVazio`: a pessoa tentou salvar sem nome; o diálogo mostra a mensagem.
class EditPieceState extends Equatable {
  const EditPieceState({this.nomeVazio = false});

  final bool nomeVazio;

  @override
  List<Object?> get props => [nomeVazio];
}

class EditPieceCubit extends Cubit<EditPieceState> {
  EditPieceCubit() : super(const EditPieceState());

  /// Salvar sem nome: marca o erro até a pessoa digitar.
  void exigirNome() => emit(const EditPieceState(nomeVazio: true));

  /// Digitar no campo do nome tira o erro.
  void limparErroNome() {
    if (state.nomeVazio) emit(const EditPieceState());
  }
}
