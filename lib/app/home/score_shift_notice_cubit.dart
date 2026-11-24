// O aviso da faixa no topo da partitura (Q07): o do detector de
// deslocamento e o lembrete de voltar o TRANSPOSE a 0. Era um notificador
// de valor do `_ScoreHomePageState`. A faixa do comum ainda pede um
// notificador de valor: a ponte para ela fica em `score_home_page.dart`.

import 'package:zywny_bloc/zywny_bloc.dart';
import 'package:zywny_comum/practice/shift_detector.dart';

/// O aviso que a faixa mostra agora (`null`: nenhum).
class ShiftNoticeState extends Equatable {
  const ShiftNoticeState({this.notice});

  final ShiftNotice? notice;

  @override
  List<Object?> get props => [notice];
}

/// Mostra e fecha o aviso da faixa.
class ShiftNoticeCubit extends Cubit<ShiftNoticeState> {
  ShiftNoticeCubit() : super(const ShiftNoticeState());

  /// Mostra [notice]. O mesmo aviso, ou fechar sem aviso, não avisa de novo
  /// (o `emit` do BLoC deixa passar o primeiro estado mesmo que seja igual).
  void show(ShiftNotice notice) {
    if (notice == state.notice) return;
    emit(ShiftNoticeState(notice: notice));
  }

  void clear() {
    if (state.notice == null) return;
    emit(const ShiftNoticeState());
  }
}
