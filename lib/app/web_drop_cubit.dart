// O destaque do arrastar e soltar na Web (BL15): quantos elementos com
// arquivos estão sobre a página. `dragenter` e `dragleave` disparam também
// nos filhos, então o destaque só apaga quando ninguém mais está por cima.
// Os ouvintes do documento ficam em `web_drop_web.dart`.

import 'package:zywny_bloc/zywny_bloc.dart';

class WebDropState extends Equatable {
  const WebDropState({this.profundidade = 0});

  /// Quantos `dragenter` (com arquivos) ainda não tiveram o `dragleave`.
  final int profundidade;

  /// O destaque ("Solte para instalar") aparece.
  bool get arrastando => profundidade > 0;

  @override
  List<Object?> get props => [profundidade];
}

class WebDropCubit extends Cubit<WebDropState> {
  WebDropCubit() : super(const WebDropState());

  /// Entrou um arrastar com arquivos.
  void entrou() => emit(WebDropState(profundidade: state.profundidade + 1));

  /// Saiu um arrastar; não passa de zero.
  void saiu() => emit(
    WebDropState(
      profundidade: state.profundidade > 0 ? state.profundidade - 1 : 0,
    ),
  );

  /// Soltou (ou a página zerou): o destaque some.
  void soltou() => emit(const WebDropState());
}
